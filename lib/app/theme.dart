import 'package:flutter/material.dart';

/// Bảng màu: xanh chàm đậm + vàng hổ phách (không dùng xanh lá/cam như app của bạn khác trong nhóm).
class Palette {
  static const navy = Color(0xFF111A3E);
  static const indigo = Color(0xFF3949AB);
  static const indigoSoft = Color(0xFFE8EAF8);
  static const amber = Color(0xFFFFB300);
  static const background = Color(0xFFF3F4FA);
  static const ink = Color(0xFF1B2040);
  static const muted = Color(0xFF6B7194);
  static const ok = Color(0xFF1E8E5A);
  static const warn = Color(0xFFE67E00);
  static const bad = Color(0xFFD32F4A);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.indigo,
    primary: Palette.indigo,
    secondary: Palette.amber,
    surface: Colors.white,
    error: Palette.bad,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  OutlineInputBorder border(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.background,
      foregroundColor: Palette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: Palette.ink, fontSize: 20, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE3E5F2)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(const Color(0xFFD6D9EC)),
      enabledBorder: border(const Color(0xFFD6D9EC)),
      focusedBorder: border(Palette.indigo, 2),
      errorBorder: border(Palette.bad),
      focusedErrorBorder: border(Palette.bad, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: shape,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: shape,
        side: const BorderSide(color: Palette.indigo),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Palette.indigoSoft,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? Palette.indigo : Palette.muted,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: shape),
    dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
    chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
  );
}
