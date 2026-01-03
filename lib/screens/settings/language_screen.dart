import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../language_provider.dart'; // Yolunu projene göre kontrol et
import '../../app_localizations.dart'; // Yolunu projene göre kontrol et

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('change_language'),
          style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('select_preferred_language'),
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 20),
            _buildLanguageOption(
              context,
              name: 'Türkçe',
              subName: 'Turkish',
              code: 'tr',
              flag: '🇹🇷',
              langProvider: langProvider,
            ),
            const SizedBox(height: 12),
            _buildLanguageOption(
              context,
              name: 'English',
              subName: 'İngilizce',
              code: 'en',
              flag: '🇺🇸',
              langProvider: langProvider,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String name,
    required String subName,
    required String code,
    required String flag,
    required LanguageProvider langProvider,
  }) {
    final isSelected = langProvider.appLocale.languageCode == code;

    return GestureDetector(
      onTap: () {
        langProvider.changeLanguage(Locale(code));
        
        // Kullanıcıya anlık geri bildirim ver
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              code == 'tr' 
                ? AppLocalizations.of(context)!.translate('language_updated_tr') 
                : AppLocalizations.of(context)!.translate('language_updated_en')
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.1) 
              : AppTheme.cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.05),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subName,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primaryColor)
            else
              Icon(Icons.circle_outlined, color: Colors.grey[800]),
          ],
        ),
      ),
    );
  }
}