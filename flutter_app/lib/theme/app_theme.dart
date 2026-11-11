import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const navy = Color(0xFF08104E);
  static const blue = Color(0xFF3158D8);
  static const background = Color(0xFFF4F6FB);
  static const muted = Color(0xFF68708A);

  static const _darkBackground = Color(0xFF0B0F1F);
  static const _darkSurface = Color(0xFF161B30);

  static ThemeData light() => _build(
    brightness: Brightness.light,
    background: background,
    surface: Colors.white,
    inputFill: const Color(0xFFF7F8FC),
    appBar: navy,
    button: navy,
    palette: AppPalette.light,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    background: _darkBackground,
    surface: _darkSurface,
    inputFill: const Color(0xFF1E2440),
    appBar: const Color(0xFF111735),
    button: blue,
    palette: AppPalette.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color inputFill,
    required Color appBar,
    required Color button,
    required AppPalette palette,
  }) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: navy,
        brightness: brightness,
        primary: isDark ? const Color(0xFF8FA8FF) : navy,
        secondary: blue,
        surface: surface,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(color: surface),
      appBarTheme: AppBarTheme(
        backgroundColor: appBar,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: button,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      extensions: [palette],
    );
  }
}

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.title,
    required this.muted,
    required this.iconBg,
    required this.accent,
  });

  final Color title;
  final Color muted;
  final Color iconBg;
  final Color accent;

  static const light = AppPalette(
    title: AppTheme.navy,
    muted: AppTheme.muted,
    iconBg: Color(0xFFE9EDFF),
    accent: AppTheme.blue,
  );

  static const dark = AppPalette(
    title: Color(0xFFE6E9F5),
    muted: Color(0xFF9AA1B9),
    iconBg: Color(0xFF252C4A),
    accent: Color(0xFF8FA8FF),
  );

  @override
  AppPalette copyWith({
    Color? title,
    Color? muted,
    Color? iconBg,
    Color? accent,
  }) => AppPalette(
    title: title ?? this.title,
    muted: muted ?? this.muted,
    iconBg: iconBg ?? this.iconBg,
    accent: accent ?? this.accent,
  );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      title: Color.lerp(title, other.title, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      iconBg: Color.lerp(iconBg, other.iconBg, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
