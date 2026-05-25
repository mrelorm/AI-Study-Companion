import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  // Android emulator cannot reach the host via 'localhost' — it uses 10.0.2.2.
  // Physical Android devices on the same network would need the Mac's LAN IP instead.
  static String get _baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api';
    }
    return 'http://localhost:8080/api';
  }
  static const _storage = FlutterSecureStorage();

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  static void Function()? _onUnauthorized;
  static void setOnUnauthorized(void Function() callback) {
    _onUnauthorized = callback;
  }

  // Called by AuthProvider after a successful token refresh so the interceptor
  // can pass the new access token to queued retries.
  static Future<String?> Function()? _onRefreshNeeded;
  static void setOnRefreshNeeded(Future<String?> Function() callback) {
    _onRefreshNeeded = callback;
  }

  late final Dio _dio;
  // Separate Dio instance with no auth interceptor — used only for /auth/refresh
  late final Dio _refreshDio;

  bool _isRefreshing = false;

  ApiClient._internal() {
    _refreshDio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401) {
          handler.next(error);
          return;
        }

        // Only attempt one refresh at a time; QueuedInterceptorsWrapper
        // serialises concurrent 401s so they wait for this to resolve.
        if (_isRefreshing) {
          handler.next(error);
          return;
        }
        _isRefreshing = true;
        try {
          final newToken = await _onRefreshNeeded?.call();
          if (newToken != null) {
            // Retry the original request with the fresh access token
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newToken';
            final response = await _dio.fetch(opts);
            handler.resolve(response);
          } else {
            _onUnauthorized?.call();
            handler.next(error);
          }
        } catch (_) {
          _onUnauthorized?.call();
          handler.next(error);
        } finally {
          _isRefreshing = false;
        }
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> postFormData(String path, FormData formData) =>
      _dio.post(path, data: formData);

  /// Posts to /auth/refresh without going through the auth interceptor.
  Future<Response> refreshTokenRequest(String refreshToken) =>
      _refreshDio.post('/auth/refresh', data: {'refreshToken': refreshToken});

  /// Posts to /auth/logout without triggering another 401 cycle.
  Future<void> logoutRequest(String? accessToken, String? refreshToken) async {
    try {
      await _refreshDio.post(
        '/auth/logout',
        data: refreshToken != null ? {'refreshToken': refreshToken} : null,
        options: Options(headers: accessToken != null
            ? {'Authorization': 'Bearer $accessToken'}
            : null),
      );
    } catch (_) {
      // Best-effort — local state is cleared regardless
    }
  }

  static Future<void> saveAccessToken(String token) =>
      _storage.write(key: 'access_token', value: token);

  static Future<void> saveRefreshToken(String token) =>
      _storage.write(key: 'refresh_token', value: token);

  static Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  static Future<String?> getAccessToken() => _storage.read(key: 'access_token');

  static Future<String?> getRefreshToken() => _storage.read(key: 'refresh_token');
}
