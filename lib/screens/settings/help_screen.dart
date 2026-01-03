import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app_localizations.dart'; // Çeviri sınıfını ekledik

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  bool _isScrolled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('help')),
        backgroundColor: _isScrolled ? AppTheme.cardColor : Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollUpdateNotification) {
            final isScrolledNow = scrollNotification.metrics.pixels > 0;
            if (isScrolledNow != _isScrolled) {
              setState(() => _isScrolled = isScrolledNow);
            }
          }
          return false;
        },
        child: ListView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
            left: 16,
            right: 16,
            bottom: 16
          ),
          children: [
            _buildSectionHeader(AppLocalizations.of(context)!.translate('faq_title')),
            
            _buildFAQItem(
              AppLocalizations.of(context)!.translate('faq_follow_q'),
              AppLocalizations.of(context)!.translate('faq_follow_a'),
            ),
            _buildFAQItem(
              AppLocalizations.of(context)!.translate('faq_appointment_q'),
              AppLocalizations.of(context)!.translate('faq_appointment_a'),
            ),
            _buildFAQItem(
              AppLocalizations.of(context)!.translate('faq_message_q'),
              AppLocalizations.of(context)!.translate('faq_message_a'),
            ),
            _buildFAQItem(
              AppLocalizations.of(context)!.translate('faq_favorites_q'),
              AppLocalizations.of(context)!.translate('faq_favorites_a'),
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader(AppLocalizations.of(context)!.translate('contact')),
            
            _buildContactItem(
              context,
              icon: Icons.email,
              title: AppLocalizations.of(context)!.translate('email'),
              subtitle: 'destek@tattink.com',
              onTap: () async {
                final uri = Uri(
                  scheme: 'mailto',
                  path: 'destek@tattink.com',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            _buildContactItem(
              context,
              icon: Icons.phone,
              title: AppLocalizations.of(context)!.translate('phone'),
              subtitle: '+90 (555) 123 45 67',
              onTap: () async {
                final uri = Uri(
                  scheme: 'tel',
                  path: '+905551234567',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(question, style: const TextStyle(color: AppTheme.textColor)),
          iconColor: AppTheme.primaryColor,
          collapsedIconColor: Colors.grey,
          shape: const Border(),
          collapsedShape: const Border(),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(answer, style: const TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ListTile(
          leading: Icon(icon, color: AppTheme.primaryColor),
          title: Text(title, style: const TextStyle(color: AppTheme.textColor)),
          subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap,
        ),
      ),
    );
  }
}