import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';

class MfaScreen extends StatefulWidget {
  final String pendingToken;
  final String maskedEmail;

  const MfaScreen({
    super.key,
    required this.pendingToken,
    required this.maskedEmail,
  });

  @override
  State<MfaScreen> createState() => _MfaScreenState();
}

class _MfaScreenState extends State<MfaScreen> with TickerProviderStateMixin {
  static const _codeLength = 6;
  static const _resendCooldown = 60;

  final List<TextEditingController> _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_codeLength, (_) => FocusNode());

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  int _resendSeconds = 0;
  Timer? _resendTimer;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNodes[0].requestFocus());
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _shakeCtrl.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < _codeLength && i < digits.length; i++) {
        _controllers[index + i > _codeLength - 1
                ? _codeLength - 1
                : index + i]
            .text = digits[i];
      }
      final nextEmpty =
          _controllers.indexWhere((c) => c.text.isEmpty, index);
      if (nextEmpty != -1) {
        _focusNodes[nextEmpty].requestFocus();
      } else {
        _focusNodes[_codeLength - 1].requestFocus();
        _trySubmit();
      }
      return;
    }
    if (value.isNotEmpty) {
      if (index < _codeLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _trySubmit();
      }
    }
    setState(() {});
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
    }
  }

  void _clearBoxes() {
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
    setState(() {});
  }

  Future<void> _trySubmit() async {
    final otp = _otp;
    if (otp.length < _codeLength) return;

    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyMfa(widget.pendingToken, otp);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _shakeCtrl.forward(from: 0);
      _clearBoxes();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Incorrect code. Please try again.'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.resendOtp(widget.pendingToken);
    if (!mounted) return;

    if (ok) {
      _clearBoxes();
      setState(() => _resendSeconds = _resendCooldown);
      _resendTimer?.cancel();
      _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() {
          if (_resendSeconds > 0) {
            _resendSeconds--;
          } else {
            t.cancel();
          }
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New code sent — check your inbox.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Could not resend. Try again.'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    final filledCount =
        _controllers.where((c) => c.text.isNotEmpty).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: AppTheme.textPrimary, size: 20),
                ),
              ),

              const SizedBox(height: 36),

              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.mark_email_read_rounded,
                    color: AppTheme.primary, size: 30),
              ),
              const SizedBox(height: 20),

              // Heading
              const Text(
                'Check your inbox',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.5),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to '),
                    TextSpan(
                      text: widget.maskedEmail,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: '. It expires in 5 minutes.'),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // OTP boxes
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(_shakeAnim.value, 0),
                  child: child,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    _codeLength,
                    (i) => _OtpBox(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      onChanged: (v) => _onDigitChanged(i, v),
                      onKeyEvent: (e) => _onKeyEvent(i, e),
                      filled: _controllers[i].text.isNotEmpty,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_codeLength, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i < filledCount ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < filledCount
                          ? AppTheme.primary
                          : AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 36),

              // Verify button
              _VerifyButton(
                label: 'Verify & Sign In',
                loading: loading || _submitting,
                enabled: filledCount == _codeLength,
                onPressed: _trySubmit,
              ),

              const SizedBox(height: 24),

              // Resend
              Center(
                child: _resendSeconds > 0
                    ? RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 14, color: AppTheme.textSecondary),
                          children: [
                            const TextSpan(text: 'Resend in '),
                            TextSpan(
                              text: '$_resendSeconds s',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: _resend,
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary),
                            children: [
                              TextSpan(text: "Didn't get it? "),
                              TextSpan(
                                text: 'Resend code',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              // Security note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.security_rounded,
                        size: 18, color: AppTheme.textSecondary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This step keeps your account secure. Never share this code with anyone.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;
  final bool filled;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 46,
      height: 58,
      decoration: BoxDecoration(
        color: filled ? AppTheme.primary : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focusNode.hasFocus
              ? AppTheme.primary
              : filled
                  ? AppTheme.primary
                  : AppTheme.border,
          width: focusNode.hasFocus || filled ? 2 : 1,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: onKeyEvent,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: filled ? Colors.white : AppTheme.textPrimary,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            filled: false,
            counterText: '',
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _VerifyButton extends StatelessWidget {
  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  const _VerifyButton({
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && !loading;
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: active
            ? AppTheme.primary
            : AppTheme.primary.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        boxShadow: active ? AppTheme.primaryShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: active ? onPressed : null,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
