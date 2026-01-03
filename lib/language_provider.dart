import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _appLocale = const Locale('tr'); // Varsayılan Türkçe
  bool _isInitialized = false;

  Locale get appLocale => _appLocale;
  bool get isInitialized => _isInitialized;

  LanguageProvider() {
    initializeLanguage();
  }

  Future<void> initializeLanguage() async {
    try {
      var prefs = await SharedPreferences.getInstance();
      String? langCode = prefs.getString('language_code');

      if (langCode != null) {
        // Kaydedilmiş dil varsa onu kullan
        _appLocale = Locale(langCode);
      } else {
        // Kaydedilmiş dil yoksa cihaz dilini kontrol et
        Locale deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
        String deviceLangCode = deviceLocale.languageCode.toLowerCase();

        if (deviceLangCode == 'tr') {
          _appLocale = const Locale('tr');
        } else {
          _appLocale = const Locale('en');
        }

        // İlk kez cihaz dilini kaydet
        await prefs.setString('language_code', _appLocale.languageCode);
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // Hata durumunda varsayılan olarak Türkçe kullan
      _appLocale = const Locale('tr');
      _isInitialized = true;
      notifyListeners();
    }
  }

  void changeLanguage(Locale type) async {
    if (_appLocale == type) return;

    try {
      var prefs = await SharedPreferences.getInstance();
      _appLocale = type;
      await prefs.setString('language_code', type.languageCode);
      notifyListeners();
    } catch (e) {
      // SharedPreferences hatası durumunda sessizce devam et
    }
  }

  // Eski fonksiyon - artık kullanılmıyor ama uyumluluk için bırakıldı
  @deprecated
  void loadSavedLanguage() async {
    // Bu fonksiyon artık kullanılmıyor, initializeLanguage kullanılıyor
  }
}