import 'package:flutter/material.dart';

/// Design tokens for the app.
///
/// Colours are sampled from the reference design: a light neutral canvas,
/// white cards, a deep teal primary action and a set of pastel accents used
/// for stat tiles and status chips.
class AppColors {
  const AppColors._();

  // Brand ------------------------------------------------------------------
  static const Color primary = Color(0xFF007878);
  static const Color primaryDark = Color(0xFF00605F);
  static const Color primarySoft = Color(0xFFE0F0EF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Surfaces ---------------------------------------------------------------
  static const Color canvas = Color(0xFFF6F7F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color field = Color(0xFFF2F3F7);
  static const Color border = Color(0xFFE8EAEF);

  // Text -------------------------------------------------------------------
  static const Color ink = Color(0xFF1D2029);
  static const Color inkMuted = Color(0xFF6B7280);
  static const Color inkFaint = Color(0xFF9AA1AC);

  // Pastel accents (tile background + badge fill + text) --------------------
  static const Color peach = Color(0xFFF4A283);
  static const Color peachSoft = Color(0xFFFDEDE6);
  static const Color leaf = Color(0xFFA6D585);
  static const Color leafSoft = Color(0xFFEBF6E3);
  static const Color periwinkle = Color(0xFF87A6F5);
  static const Color periwinkleSoft = Color(0xFFE9EEFD);
  static const Color rose = Color(0xFFF495A6);
  static const Color roseSoft = Color(0xFFFDEAEE);

  // Semantic ---------------------------------------------------------------
  static const Color success = Color(0xFF007050);
  static const Color successSoft = Color(0xFFE3F4EC);
  static const Color warning = Color(0xFF9A7B10);
  static const Color warningSoft = Color(0xFFFBF3B4);
  static const Color danger = Color(0xFFD9484A);
  static const Color dangerSoft = Color(0xFFFDE7E7);
  static const Color info = Color(0xFF6D4BE0);
  static const Color infoSoft = Color(0xFFEDE8FD);
}

/// Corner radii. The reference uses generous, consistent rounding.
class AppRadius {
  const AppRadius._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;
}

/// 4pt spacing rhythm.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double section = 32;
}

/// A single, soft elevation used for every raised surface so shadows stay
/// consistent instead of drifting per-widget.
class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0D101828),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> raised = [
    BoxShadow(
      color: Color(0x14101828),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}

const String kFontFamily = 'Poppins';

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.primaryDark,
    onSecondary: AppColors.onPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    error: AppColors.danger,
    onError: Colors.white,
    outline: AppColors.border,
  );

  TextStyle t(double size, FontWeight weight, {Color? color, double? height}) =>
      TextStyle(
        fontFamily: kFontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.ink,
        height: height,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: kFontFamily,
    scaffoldBackgroundColor: AppColors.canvas,
    splashFactory: InkSparkle.splashFactory,
    textTheme: TextTheme(
      displaySmall: t(34, FontWeight.w700, height: 1.15),
      headlineMedium: t(26, FontWeight.w700, height: 1.2),
      headlineSmall: t(22, FontWeight.w700, height: 1.25),
      titleLarge: t(18, FontWeight.w600, height: 1.3),
      titleMedium: t(16, FontWeight.w600),
      titleSmall: t(14, FontWeight.w600),
      bodyLarge: t(15, FontWeight.w400, height: 1.5),
      bodyMedium: t(14, FontWeight.w400, color: AppColors.inkMuted, height: 1.5),
      bodySmall: t(12, FontWeight.w400, color: AppColors.inkMuted, height: 1.45),
      labelLarge: t(15, FontWeight.w600),
      labelMedium: t(13, FontWeight.w500, color: AppColors.inkMuted),
      labelSmall: t(11, FontWeight.w500, color: AppColors.inkFaint),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: t(20, FontWeight.w600),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.inkFaint,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        textStyle: t(15, FontWeight.w600, color: AppColors.onPrimary),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: t(14, FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: t(14, FontWeight.w600, color: AppColors.primary),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.inkFaint,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: t(11, FontWeight.w600),
      unselectedLabelStyle: t(11, FontWeight.w500),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: t(14, FontWeight.w500, color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
  );
}
