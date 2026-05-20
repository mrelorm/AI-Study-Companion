import 'package:flutter/material.dart';

class AppTheme {
  // ── Core palette ───────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFFFF6B35); // Brilliant warm orange
  static const Color primaryDark  = Color(0xFFE55020);
  static const Color primaryLight = Color(0xFF2A1510); // dark tinted surface

  static const Color pink   = Color(0xFFFF6B9D);
  static const Color teal   = Color(0xFF00D4AA);
  static const Color amber  = Color(0xFFFFB347);
  static const Color orange = Color(0xFFFF8C42);
  static const Color blue   = Color(0xFF4A9EFF);
  static const Color purple = Color(0xFF8B5CF6);

  static const Color background    = Color(0xFF0E1421); // deep navy
  static const Color surface       = Color(0xFF151D2E); // card background
  static const Color surfaceHigh   = Color(0xFF1C2640); // elevated / modals
  static const Color border        = Color(0xFF2A3855); // subtle borders

  static const Color error         = Color(0xFFFF5252);
  static const Color success       = Color(0xFF00D4AA);
  static const Color textPrimary   = Color(0xFFE8EEFB);
  static const Color textSecondary = Color(0xFF7A90B4);

  // ── Module card gradients (Brilliant course-tile style) ────────────────────
  static const LinearGradient materialsGradient = LinearGradient(
    colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF0D3325), Color(0xFF059669)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient quizGradient = LinearGradient(
    colors: [Color(0xFF3A2000), Color(0xFFD97706)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient plannerGradient = LinearGradient(
    colors: [Color(0xFF240A40), Color(0xFF7C3AED)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // ── Shared gradients ───────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF9F43)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1A2A4A), Color(0xFF0E1421)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
  static const LinearGradient pinkGradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFEE4B8E)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF00D4AA), Color(0xFF00A878)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFFFB347), Color(0xFFE8960D)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // ── Shadows ────────────────────────────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.5),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  // ── ThemeData ──────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: primary,
          secondary: teal,
          surface: background,
          error: error,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: background,
          foregroundColor: textPrimary,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: border, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            side: const BorderSide(color: border, width: 1.5),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: border, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: error),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: textSecondary),
          prefixIconColor: textSecondary,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: surfaceHigh,
          selectedColor: primary.withValues(alpha: 0.2),
          labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: border),
          ),
          side: const BorderSide(color: border),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface,
          elevation: 0,
          indicatorColor: primary.withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11);
            }
            return const TextStyle(
                color: textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 11);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: primary, size: 22);
            }
            return const IconThemeData(color: textSecondary, size: 22);
          }),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: primary,
          thumbColor: primary,
          overlayColor: Color(0x20FF6B35),
          inactiveTrackColor: border,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: primary,
          linearTrackColor: border,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: surfaceHigh,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: surfaceHigh,
          contentTextStyle:
              const TextStyle(color: textPrimary, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: border),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        dividerTheme:
            const DividerThemeData(color: border, thickness: 1),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textPrimary),
          bodySmall: TextStyle(color: textSecondary),
        ),
      );
}
