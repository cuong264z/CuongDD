import 'package:flutter/material.dart';

/// Bảng màu: xanh chàm đậm + vàng hổ phách
class Palette {
  static const navy = Color(0xFF111A3E);
  static const indigo = Color(0xFF3949AB);
  static const indigoSoft = Color(0xFFE8EAF8);
  static const amber = Color(0xFFFFB300);
  static const background = Color(0xFFF3F4FA);
  static const darkBackground = Color(0xFF121212); // Thêm nền tối
  static const ink = Color(0xFF1B2040);
  static const muted = Color(0xFF6B7194);
  static const ok = Color(0xFF1E8E5A);
  static const warn = Color(0xFFE67E00);
  static const bad = Color(0xFFD32F4A);
}

ThemeData buildTheme({bool isDark = false, double fontFactor = 1.0}) {
  final bgColor = isDark ? Palette.darkBackground : Palette.background;
  final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
  final textColor = isDark ? Colors.white : Palette.ink;

  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.indigo,
    brightness: isDark ? Brightness.dark : Brightness.light,
    primary: Palette.indigo,
    secondary: Palette.amber,
    surface: cardBg,
    error: Palette.bad,
  );

  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  OutlineInputBorder border(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));

  final baseTheme = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: isDark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: bgColor,
    appBarTheme: AppBarTheme(
      backgroundColor: bgColor,
      foregroundColor: textColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: textColor, fontSize: 20 * fontFactor, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: cardBg,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE3E5F2)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD6D9EC)),
      enabledBorder: border(isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD6D9EC)),
      focusedBorder: border(Palette.indigo, 2),
      errorBorder: border(Palette.bad),
      focusedErrorBorder: border(Palette.bad, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: shape,
        textStyle: TextStyle(fontSize: 16 * fontFactor, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: shape,
        side: const BorderSide(color: Palette.indigo),
        textStyle: TextStyle(fontSize: 16 * fontFactor, fontWeight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardBg,
      indicatorColor: Palette.indigoSoft,
      labelTextStyle: WidgetStateProperty.resolveWith(
            (s) => TextStyle(
          fontSize: 12 * fontFactor,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? Palette.indigo : Palette.muted,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: shape),
    dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
    chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
  );

  // Áp dụng hệ số cỡ chữ fontFactor an toàn (chỉ tính khi fontFactor != 1.0)
  if (fontFactor == 1.0) return baseTheme;

  final textTheme = baseTheme.textTheme;
  return baseTheme.copyWith(
    textTheme: textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(fontSize: (textTheme.displayLarge?.fontSize ?? 57) * fontFactor),
      displayMedium: textTheme.displayMedium?.copyWith(fontSize: (textTheme.displayMedium?.fontSize ?? 45) * fontFactor),
      displaySmall: textTheme.displaySmall?.copyWith(fontSize: (textTheme.displaySmall?.fontSize ?? 36) * fontFactor),
      headlineLarge: textTheme.headlineLarge?.copyWith(fontSize: (textTheme.headlineLarge?.fontSize ?? 32) * fontFactor),
      headlineMedium: textTheme.headlineMedium?.copyWith(fontSize: (textTheme.headlineMedium?.fontSize ?? 28) * fontFactor),
      headlineSmall: textTheme.headlineSmall?.copyWith(fontSize: (textTheme.headlineSmall?.fontSize ?? 24) * fontFactor),
      titleLarge: textTheme.titleLarge?.copyWith(fontSize: (textTheme.titleLarge?.fontSize ?? 22) * fontFactor),
      titleMedium: textTheme.titleMedium?.copyWith(fontSize: (textTheme.titleMedium?.fontSize ?? 16) * fontFactor),
      titleSmall: textTheme.titleSmall?.copyWith(fontSize: (textTheme.titleSmall?.fontSize ?? 14) * fontFactor),
      bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: (textTheme.bodyLarge?.fontSize ?? 16) * fontFactor),
      bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: (textTheme.bodyMedium?.fontSize ?? 14) * fontFactor),
      bodySmall: textTheme.bodySmall?.copyWith(fontSize: (textTheme.bodySmall?.fontSize ?? 12) * fontFactor),
      labelLarge: textTheme.labelLarge?.copyWith(fontSize: (textTheme.labelLarge?.fontSize ?? 14) * fontFactor),
      labelMedium: textTheme.labelMedium?.copyWith(fontSize: (textTheme.labelMedium?.fontSize ?? 12) * fontFactor),
      labelSmall: textTheme.labelSmall?.copyWith(fontSize: (textTheme.labelSmall?.fontSize ?? 11) * fontFactor),
    ),
  );
}