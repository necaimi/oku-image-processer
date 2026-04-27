import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color glow;

  const AppColors({
    required this.background,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.glow,
  });

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? primary,
    Color? glow,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      primary: primary ?? this.primary,
      glow: glow ?? this.glow,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
    );
  }

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  // Helper for static access if needed (defaults to dark for safety/legacy)
  static const Color primaryBlue = Color(0xFF007AFF);
}

final AppColors darkColors = AppColors(
  background: const Color(0xFF121212),
  surface: const Color(0xFF1E1E1E),
  border: const Color(0xFF2C2C2E),
  textPrimary: const Color(0xFFFFFFFF),
  textSecondary: const Color(0xFFA1A1A6),
  primary: AppColors.primaryBlue,
  glow: const Color(0x33007AFF),
);

final AppColors lightColors = AppColors(
  background: const Color(0xFFF5F5F7),
  surface: const Color(0xFFFFFFFF),
  border: const Color(0xFFE5E5E7),
  textPrimary: const Color(0xFF1D1D1F),
  textSecondary: const Color(0xFF86868B),
  primary: AppColors.primaryBlue,
  glow: const Color(0x33007AFF),
);

ThemeData getAppTheme(ThemeMode mode) {
  final isDark = mode == ThemeMode.dark;
  final brightness = isDark ? Brightness.dark : Brightness.light;
  final colors = isDark ? darkColors : lightColors;

  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: colors.background,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: Colors.white,
      secondary: colors.primary,
      onSecondary: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: colors.surface,
      onSurface: colors.textPrimary,
    ),
    textTheme: GoogleFonts.manropeTextTheme(
      TextTheme(
        bodyLarge: TextStyle(color: colors.textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: colors.textPrimary, fontSize: 14),
        bodySmall: TextStyle(color: colors.textSecondary, fontSize: 12),
        labelSmall: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colors.border,
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.border),
      ),
      elevation: 0,
    ),
    extensions: [colors],
  );
}
