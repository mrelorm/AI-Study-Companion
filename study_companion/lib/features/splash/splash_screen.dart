import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
      ),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Subtle radial glow behind logo
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo
                FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: AppTheme.border, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppTheme.primary,
                        size: 54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // App name
                FadeTransition(
                  opacity: _fade,
                  child: const Text(
                    'AI Study Companion',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                FadeTransition(
                  opacity: _taglineFade,
                  child: const Text(
                    'Study smarter. Ace your exams.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading indicator
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _taglineFade,
              child: Column(
                children: [
                  SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor:
                            AppTheme.border,
                        valueColor: const AlwaysStoppedAnimation(
                            AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Loading your workspace...',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
