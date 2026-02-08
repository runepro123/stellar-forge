import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'nl':
        return 'Nederlands';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      case 'es':
        return 'Español';
      default:
        return 'English';
    }
  }

  List<Locale> get supportedLocales => [
    const Locale('en'),
    const Locale('nl'),
    const Locale('fr'),
    const Locale('de'),
    const Locale('es'),
  ];
}
