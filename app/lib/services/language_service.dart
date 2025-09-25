import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';

  Locale _currentLocale = const Locale('vi', 'VN');

  Locale get currentLocale => _currentLocale;

  String get currentLanguageCode => _currentLocale.languageCode;

  // Danh sách các ngôn ngữ được hỗ trợ
  static const List<Locale> supportedLocales = [
    Locale('vi', 'VN'), // Tiếng Việt
    Locale('en', 'US'), // Tiếng Anh
    Locale('zh', 'CN'), // Tiếng Trung
    Locale('ko', 'KR'), // Tiếng Hàn
  ];

  // Tên hiển thị của các ngôn ngữ
  static const Map<String, String> languageNames = {
    'vi': 'Tiếng Việt',
    'en': 'English',
    'zh': '中文',
    'ko': '한국어',
  };

  LanguageService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);

    if (languageCode != null) {
      _currentLocale = Locale(languageCode);
    } else {
      // Mặc định là tiếng Việt
      _currentLocale = const Locale('vi', 'VN');
    }

    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (supportedLocales.any((locale) => locale.languageCode == languageCode)) {
      _currentLocale = Locale(languageCode);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);

      notifyListeners();
    }
  }

  String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? languageCode;
  }

  bool isCurrentLanguage(String languageCode) {
    return _currentLocale.languageCode == languageCode;
  }
}
