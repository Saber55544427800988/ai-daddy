import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

/// Provider that manages the app locale (language).
/// Auto-detects device language on first launch.
/// Persists the chosen language to SharedPreferences.
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  String get langCode => _locale.languageCode;

  /// Supported language codes for quick lookup
  static final Set<String> _supported = AppLocalizations.supportedLocales
      .map((l) => l.languageCode)
      .toSet();

  /// Load saved language from prefs, or auto-detect from device
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_language');

    if (saved != null) {
      // User explicitly chose a language — respect it
      _locale = Locale(saved);
    } else {
      // First launch — try device language, but only if supported
      // Don't persist auto-detect; only persist on explicit user choice
      final deviceLang = ui.PlatformDispatcher.instance.locale.languageCode;
      if (_supported.contains(deviceLang)) {
        _locale = Locale(deviceLang);
      } else {
        _locale = const Locale('en');
      }
    }
    notifyListeners();
  }

  /// Change application language — always persists the choice
  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', languageCode);
    notifyListeners();
  }

  /// Whether current locale is RTL
  bool get isRTL => AppLocalizations.isRTL(_locale.languageCode);
}
