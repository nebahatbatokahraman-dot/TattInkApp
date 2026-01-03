import '../app_localizations.dart';
import 'package:flutter/material.dart';

class Validators {
  static String? validateEmail(String? value, [BuildContext? context]) {
    if (value == null || value.isEmpty) {
      if (context != null) {
        return AppLocalizations.of(context)!.translate('email_required');
      }
      return 'Email adresi gereklidir';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      if (context != null) {
        return AppLocalizations.of(context)!.translate('invalid_email');
      }
      return 'Geçerli bir email adresi giriniz';
    }
    return null;
  }
  
  static String? validatePassword(String? value, [BuildContext? context]) {
    if (value == null || value.isEmpty) {
      if (context != null) {
        return AppLocalizations.of(context)!.translate('password_required');
      }
      return 'Şifre gereklidir';
    }
    if (value.length < 6) {
      if (context != null) {
        return AppLocalizations.of(context)!.translate('password_min_length');
      }
      return 'Şifre en az 6 karakter olmalıdır';
    }
    return null;
  }
  
  static String? validateRequired(String? value, String fieldName, [BuildContext? context]) {
    if (value == null || value.isEmpty) {
      if (context != null) {
        return '$fieldName ${AppLocalizations.of(context)!.translate('field_required')}';
      }
      return '$fieldName gereklidir';
    }
    return null;
  }
  
  static String? validatePhone(String? value, [BuildContext? context]) {
    if (value == null || value.isEmpty) {
      if (context != null) {
        return AppLocalizations.of(context)!.translate('phone_required');
      }
      return 'Telefon numarası gereklidir';
    }
    final phoneRegex = RegExp(r'^[0-9]{10,11}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      if (context != null) {
        return AppLocalizations.of(context)!.translate('invalid_phone');
      }
      return 'Geçerli bir telefon numarası giriniz';
    }
    return null;
  }
  
  static String? validateUsername(String? value, [BuildContext? context]) {
    if (value == null || value.isEmpty) {
      if (context != null) {
        return AppLocalizations.of(context)!.translate('username_required');
      }
      return 'Kullanıcı adı gereklidir';
    }
    if (value.length < 3) {
      if (context != null) {
        return AppLocalizations.of(context)!.translate('username_min_length');
      }
      return 'Kullanıcı adı en az 3 karakter olmalıdır';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      if (context != null) {
        return AppLocalizations.of(context)!.translate('username_invalid_chars');
      }
      return 'Kullanıcı adı sadece harf, rakam ve alt çizgi içerebilir';
    }
    return null;
  }
}

