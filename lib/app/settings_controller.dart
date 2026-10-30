import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsController {
  static final SettingsController instance = SettingsController._();
  SettingsController._();

  static const _storage = FlutterSecureStorage();

  final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> fontSizeFactorNotifier = ValueNotifier<double>(1.0);

  // Getter alias hỗ trợ settings_screen
  ValueNotifier<bool> get themeModeNotifier => isDarkModeNotifier;

  Future<void> loadSettings() async {
    final darkStr = await _storage.read(key: 'app_is_dark');
    if (darkStr != null) {
      isDarkModeNotifier.value = darkStr == 'true';
    }

    final fontStr = await _storage.read(key: 'app_font_factor');
    if (fontStr != null) {
      fontSizeFactorNotifier.value = double.tryParse(fontStr) ?? 1.0;
    }
  }

  Future<void> setDarkMode(bool isDark) async {
    isDarkModeNotifier.value = isDark;
    await _storage.write(key: 'app_is_dark', value: isDark.toString());
  }

  // Alias tương thích
  Future<void> updateThemeMode(ThemeMode mode) async {
    await setDarkMode(mode == ThemeMode.dark);
  }

  Future<void> setFontSizeFactor(double factor) async {
    fontSizeFactorNotifier.value = factor;
    await _storage.write(key: 'app_font_factor', value: factor.toString());
  }

  // Alias tương thích
  Future<void> updateFontSizeFactor(double factor) async {
    await setFontSizeFactor(factor);
  }
}