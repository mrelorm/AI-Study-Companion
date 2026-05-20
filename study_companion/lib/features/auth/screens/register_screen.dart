import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import 'mfa_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _termsAccepted = false;

  // ── Password criteria ──────────────────────────────────────────────────────
  bool get _hasMinLength => _passCtrl.text.length >= 8;
  bool get _hasUppercase => _passCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber => _passCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial =>
      _passCtrl.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\]'));
  bool get _passwordsMatch =>
      _passCtrl.text == _confirmPassCtrl.text &&
      _confirmPassCtrl.text.isNotEmpty;
  bool get _allCriteriaMet =>
      _hasMinLength && _hasUppercase && _hasNumber && _hasSpecial;

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(() => setState(() {}));
    _confirmPassCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_allCriteriaMet) return;
    if (!_passwordsMatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Privacy Policy to continue'),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final result = await auth.register(
        _nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;

    switch (result) {
      case LoginMfaPending(:final pendingToken, :final maskedEmail):
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MfaScreen(
              pendingToken: pendingToken,
              maskedEmail: maskedEmail,
            ),
          ),
        );
      case LoginFailed():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Registration failed'),
            backgroundColor: AppTheme.error,
          ),
        );
      case LoginSuccess():
        Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    final canSubmit =
        _allCriteriaMet && _passwordsMatch && _termsAccepted && !loading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
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

                const Text(
                  'Create account',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Join thousands of students studying smarter',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 15),
                ),

                const SizedBox(height: 32),

                // Full name
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) =>
                      v != null && v.trim().isNotEmpty ? null : 'Enter your name',
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => v != null && v.contains('@')
                      ? null
                      : 'Enter a valid email',
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (_) => _allCriteriaMet
                      ? null
                      : 'Password does not meet all requirements',
                ),
                const SizedBox(height: 12),

                // Real-time password checklist
                _PasswordChecklist(
                  hasMinLength: _hasMinLength,
                  hasUppercase: _hasUppercase,
                  hasNumber: _hasNumber,
                  hasSpecial: _hasSpecial,
                ),

                const SizedBox(height: 14),

                // Confirm password
                TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    // Live match indicator on the suffix
                    suffixIconConstraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                  ),
                  validator: (v) => v == _passCtrl.text
                      ? null
                      : 'Passwords do not match',
                ),

                // Match indicator row
                if (_confirmPassCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _CriterionRow(
                    met: _passwordsMatch,
                    label: 'Passwords match',
                  ),
                ],

                const SizedBox(height: 24),

                // Terms & Privacy
                GestureDetector(
                  onTap: () =>
                      setState(() => _termsAccepted = !_termsAccepted),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _termsAccepted
                          ? const Color(0xFF0D2A1A)
                          : AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _termsAccepted
                            ? AppTheme.teal.withValues(alpha: 0.5)
                            : AppTheme.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _termsAccepted
                                ? AppTheme.teal
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _termsAccepted
                                  ? AppTheme.teal
                                  : AppTheme.border,
                              width: 2,
                            ),
                          ),
                          child: _termsAccepted
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  height: 1.4),
                              children: [
                                TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600),
                                ),
                                TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // CTA button
                _SolidButton(
                  label: 'Create Account',
                  loading: loading,
                  enabled: canSubmit,
                  onPressed: _submit,
                ),

                const SizedBox(height: 24),

                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(
                      text: const TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Sign in',
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Password checklist ─────────────────────────────────────────────────────────

class _PasswordChecklist extends StatelessWidget {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasNumber;
  final bool hasSpecial;

  const _PasswordChecklist({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasNumber,
    required this.hasSpecial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _CriterionRow(met: hasMinLength, label: 'At least 8 characters'),
          const SizedBox(height: 8),
          _CriterionRow(met: hasUppercase, label: 'One uppercase letter (A–Z)'),
          const SizedBox(height: 8),
          _CriterionRow(met: hasNumber, label: 'One number (0–9)'),
          const SizedBox(height: 8),
          _CriterionRow(
              met: hasSpecial, label: 'One special character (!@#\$%...)'),
        ],
      ),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  final bool met;
  final String label;

  const _CriterionRow({required this.met, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: met
                ? AppTheme.teal.withValues(alpha: 0.15)
                : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: met ? AppTheme.teal : AppTheme.border,
              width: 1.5,
            ),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: met
                  ? const Icon(
                      Icons.check_rounded,
                      key: ValueKey('check'),
                      color: AppTheme.teal,
                      size: 13,
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ),
        ),
        const SizedBox(width: 10),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: TextStyle(
            fontSize: 13,
            fontWeight: met ? FontWeight.w600 : FontWeight.w400,
            color: met ? AppTheme.teal : AppTheme.textSecondary,
          ),
          child: Text(label),
        ),
      ],
    );
  }
}

// ── Button ─────────────────────────────────────────────────────────────────────

class _SolidButton extends StatelessWidget {
  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  const _SolidButton({
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
