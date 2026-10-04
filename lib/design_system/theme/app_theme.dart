import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(_lightScheme);
  static ThemeData dark() => _build(_darkScheme);

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, scheme),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest;
        }),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 48,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
        color: scheme.onSurface,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 32,
        height: 1.18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: scheme.onSurface,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 26,
        height: 1.22,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 17,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.55,
        color: scheme.onSurface,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.5,
        color: scheme.onSurface,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFDBEAFE),
    onPrimaryContainer: Color(0xFF1E3A8A),
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFCCFBF1),
    onSecondaryContainer: Color(0xFF115E59),
    tertiary: AppColors.tertiary,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFEDE9FE),
    onTertiaryContainer: Color(0xFF4C1D95),
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF991B1B),
    surface: AppColors.backgroundLight,
    onSurface: AppColors.textLight,
    surfaceContainerLowest: AppColors.surfaceLight,
    surfaceContainerLow: Color(0xFFF8FAFC),
    surfaceContainer: AppColors.surfaceVariantLight,
    surfaceContainerHigh: Color(0xFFE2E8F0),
    surfaceContainerHighest: Color(0xFFCBD5E1),
    onSurfaceVariant: AppColors.textMutedLight,
    outline: AppColors.outlineLight,
    outlineVariant: AppColors.outlineVariantLight,
    shadow: Color(0x1F0F172A),
    scrim: Color(0x99000000),
    inverseSurface: Color(0xFF1E293B),
    onInverseSurface: Color(0xFFF8FAFC),
    inversePrimary: AppColors.primaryDark,
    surfaceTint: AppColors.primary,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryDark,
    onPrimary: Color(0xFF172554),
    primaryContainer: Color(0xFF1E40AF),
    onPrimaryContainer: Color(0xFFDBEAFE),
    secondary: AppColors.secondaryDark,
    onSecondary: Color(0xFF042F2E),
    secondaryContainer: Color(0xFF0F766E),
    onSecondaryContainer: Color(0xFFCCFBF1),
    tertiary: AppColors.tertiaryDark,
    onTertiary: Color(0xFF2E1065),
    tertiaryContainer: Color(0xFF6D28D9),
    onTertiaryContainer: Color(0xFFEDE9FE),
    error: Color(0xFFFCA5A5),
    onError: Color(0xFF7F1D1D),
    errorContainer: Color(0xFF991B1B),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: AppColors.backgroundDark,
    onSurface: AppColors.textDark,
    surfaceContainerLowest: AppColors.surfaceDark,
    surfaceContainerLow: Color(0xFF111827),
    surfaceContainer: AppColors.surfaceVariantDark,
    surfaceContainerHigh: Color(0xFF334155),
    surfaceContainerHighest: Color(0xFF475569),
    onSurfaceVariant: AppColors.textMutedDark,
    outline: AppColors.outlineDark,
    outlineVariant: AppColors.outlineVariantDark,
    shadow: Colors.black,
    scrim: Color(0xCC000000),
    inverseSurface: Color(0xFFF1F5F9),
    onInverseSurface: Color(0xFF0F172A),
    inversePrimary: AppColors.primary,
    surfaceTint: AppColors.primaryDark,
  );
}
