import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../app_localizations.dart'; // Çeviri sınıfını ekledik

class LegalDocumentsScreen extends StatelessWidget {
  const LegalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Çeviriye kolay erişim için helper
    String tr(String key) => AppLocalizations.of(context)?.translate(key) ?? key;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          // ARTIK DİNAMİK:
          title: Text(tr('legal_docs_title'), style: const TextStyle(color: AppTheme.textColor)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: AppTheme.textColor),
          bottom: TabBar(
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: [
              // ARTIK DİNAMİK:
              Tab(text: tr('tab_terms')),
              Tab(text: tr('tab_privacy')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ARTIK DİNAMİK: İçerikleri context üzerinden çekiyoruz
            _buildScrollableText(tr('terms_content')),
            _buildScrollableText(tr('privacy_content')),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableText(String text) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        text,
        style: const TextStyle(color: AppTheme.textColor, fontSize: 14, height: 1.5),
      ),
    );
  }
}