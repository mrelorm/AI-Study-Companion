import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import 'models.dart';

// Returned by login() so the UI knows whether to show the MFA screen or not.
sealed class LoginResult {}

class LoginSuccess extends LoginResult {}

class LoginMfaPending extends LoginResult {
  final String pendingToken;
  final String maskedEmail;
  LoginMfaPending(this.pendingToken, this.maskedEmail);
}

class LoginFailed extends LoginResult {}

class AuthProvider extends ChangeNotifier {
  final ApiClient _api;
  AuthResponse? _user;
  bool _loading = false;
  String? _error;

  static const _storage = FlutterSecureStorage();
  static const _keyUserId = 'user_id';
  static const _keyEmail = 'user_email';
  static const _keyName = 'user_name';

  AuthProvider(this._api) {
    ApiClient.setOnUnauthorized(_handleUnauthorized);
    ApiClient.setOnRefreshNeeded(_tryRefresh);
  }

  bool get isAuthenticated => _user != null;
  AuthResponse? get user => _user;
  bool get loading => _loading;
  String? get error => _error;

  // ── Auth flow ────────────────────────────────────────────────────────────

  /// Step 1 — validate password. Returns a [LoginMfaPending] if the server
  /// requires OTP confirmation, [LoginSuccess] should never happen here
  /// (server always requires MFA), or [LoginFailed] on bad credentials.
  Future<LoginResult> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.post('/auth/login',
          data: {'email': email, 'password': password});
      _user = AuthResponse.fromJson(res.data);
      await _persistSession(_user!);
      notifyListeners();
      return LoginSuccess();
    } catch (e) {
      _error = _extractError(e);
      return LoginFailed();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Step 2 — submit the 6-digit OTP from email. Returns true on success.
  Future<bool> verifyMfa(String pendingToken, String otp) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.post('/auth/mfa/verify',
          data: {'pendingToken': pendingToken, 'otp': otp});
      _user = AuthResponse.fromJson(res.data);
      await _persistSession(_user!);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Requests a fresh OTP for an existing pending session.
  Future<bool> resendOtp(String pendingToken) async {
    try {
      await _api.post('/auth/mfa/resend', data: {'pendingToken': pendingToken});
      return true;
    } catch (e) {
      _error = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  Future<LoginResult> register(String name, String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.post('/auth/register',
          data: {'name': name, 'email': email, 'password': password});
      final data = res.data as Map<String, dynamic>;
      return LoginMfaPending(
        data['pendingToken'] as String,
        data['maskedEmail'] as String? ?? '',
      );
    } catch (e) {
      _error = _extractError(e);
      return LoginFailed();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final accessToken = await ApiClient.getAccessToken();
    final refreshToken = await ApiClient.getRefreshToken();
    await _api.logoutRequest(accessToken, refreshToken);
    await _clearSession();
    _user = null;
    notifyListeners();
  }

  /// Called on app launch — restores session or silently refreshes.
  Future<void> tryAutoLogin() async {
    final accessToken = await ApiClient.getAccessToken();
    final refreshToken = await ApiClient.getRefreshToken();

    if (accessToken == null && refreshToken == null) return;

    if (accessToken != null && !_isTokenExpired(accessToken)) {
      await _restoreUserFromStorage(accessToken);
      return;
    }

    if (refreshToken != null) {
      final newAccessToken = await _tryRefresh();
      if (newAccessToken != null) {
        await _restoreUserFromStorage(newAccessToken);
        return;
      }
    }

    await _clearSession();
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  Future<String?> _tryRefresh() async {
    try {
      final refreshToken = await ApiClient.getRefreshToken();
      if (refreshToken == null) return null;

      final res = await _api.refreshTokenRequest(refreshToken);
      final data = AuthResponse.fromJson(res.data);
      await ApiClient.saveAccessToken(data.accessToken);
      await ApiClient.saveRefreshToken(data.refreshToken);

      if (_user != null) {
        _user = AuthResponse(
          accessToken: data.accessToken,
          refreshToken: data.refreshToken,
          userId: _user!.userId,
          email: _user!.email,
          name: _user!.name,
        );
        notifyListeners();
      }
      return data.accessToken;
    } catch (_) {
      return null;
    }
  }

  void _handleUnauthorized() {
    _clearSession();
    _user = null;
    notifyListeners();
  }

  Future<void> _persistSession(AuthResponse user) async {
    await ApiClient.saveAccessToken(user.accessToken);
    await ApiClient.saveRefreshToken(user.refreshToken);
    await _storage.write(key: _keyUserId, value: user.userId);
    await _storage.write(key: _keyEmail, value: user.email);
    await _storage.write(key: _keyName, value: user.name);
  }

  Future<void> _restoreUserFromStorage(String accessToken) async {
    final refreshToken = await ApiClient.getRefreshToken();
    final userId = await _storage.read(key: _keyUserId) ?? '';
    final email = await _storage.read(key: _keyEmail) ?? '';
    final name = await _storage.read(key: _keyName) ?? '';
    _user = AuthResponse(
      accessToken: accessToken,
      refreshToken: refreshToken ?? '',
      userId: userId,
      email: email,
      name: name,
    );
    notifyListeners();
  }

  Future<void> _clearSession() async {
    await ApiClient.clearTokens();
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyName);
  }

  /// Checks whether the JWT access token's [exp] claim is in the past.
  ///
  /// ⚠️ SECURITY NOTE: This decodes the JWT payload WITHOUT verifying the
  /// signature. It is used solely as a performance heuristic to avoid
  /// unnecessary refresh calls on app launch (i.e. skip the refresh request
  /// if the token is clearly still valid).
  ///
  /// This must NEVER be used for local authorisation decisions (e.g. checking
  /// user roles or permissions). All access control is enforced server-side.
  /// A tampered token that passes this check will still be rejected by the
  /// backend with a 401.
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final data = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = data['exp'] as int?;
      if (exp == null) return true;
      return DateTime.now()
          .isAfter(DateTime.fromMillisecondsSinceEpoch(exp * 1000));
    } catch (_) {
      return true;
    }
  }

  String _extractError(dynamic e) {
    if (e is DioException) {
      final msg = e.response?.data?['error'] ?? e.response?.data?['message'];
      if (msg is String) return msg;
    }
    return 'An error occurred. Please try again.';
  }
}
