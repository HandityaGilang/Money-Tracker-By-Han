import 'package:flutter/material.dart';

import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _currentThemeMode = AppThemeMode.white;

  AppThemeMode get currentThemeMode => _currentThemeMode;

  String get themeModeName {
    if (_currentThemeMode == AppThemeMode.white) {
      return ThemeMode.light.name;
    }
    return ThemeMode.dark.name;
  }

  void setTheme(AppThemeMode mode) {
    if (mode == _currentThemeMode) {
      return;
    }
    _currentThemeMode = mode;
    notifyListeners();
  }
}

