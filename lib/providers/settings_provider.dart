import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/preference_service.dart';
import '../theme/app_theme.dart';

class SettingsProvider extends ChangeNotifier {
  final PreferenceService _preferenceService;

  SettingsProvider({required PreferenceService preferenceService})
      : _preferenceService = preferenceService {
    _applyTheme();
  }

  String get audioQuality => _preferenceService.audioQuality;

  // 语言: null=跟随系统, 'zh'=中文, 'en'=英文
  Locale? get locale {
    final code = _preferenceService.locale;
    if (code == null) return null;
    return Locale(code);
  }

  Future<void> setLocale(String? languageCode) async {
    await _preferenceService.setLocale(languageCode);
    notifyListeners();
  }
  bool get notificationEnabled => _preferenceService.notificationEnabled;
  bool get hasScanned => _preferenceService.hasScanned;

  // 0=dark, 1=light, 2=system
  int get themeMode => _preferenceService.themeMode;

  ThemeMode get flutterThemeMode {
    switch (_preferenceService.themeMode) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(int value) async {
    await _preferenceService.setThemeMode(value);
    _applyTheme();
    notifyListeners();
  }

  void applySystemBrightness(Brightness brightness) {
    if (_preferenceService.themeMode == 2) {
      AppColors.setDark(brightness == Brightness.dark);
    }
  }

  void _applyTheme() {
    switch (_preferenceService.themeMode) {
      case 1:
        AppColors.setDark(false);
      case 2:
        final brightness =
            ui.PlatformDispatcher.instance.platformBrightness;
        AppColors.setDark(brightness == Brightness.dark);
      default:
        AppColors.setDark(true);
    }
  }

  Future<void> setAudioQuality(String value) async {
    await _preferenceService.setAudioQuality(value);
    notifyListeners();
  }

  Future<void> setNotificationEnabled(bool value) async {
    await _preferenceService.setNotificationEnabled(value);
    notifyListeners();
  }

  Future<void> setHasScanned(bool value) async {
    await _preferenceService.setHasScanned(value);
    notifyListeners();
  }
}
