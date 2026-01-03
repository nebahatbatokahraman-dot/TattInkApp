import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/slide_route.dart';
import '../../app_localizations.dart'; // Çeviri sınıfını import ettik
import '../auth/login_screen.dart';
import 'customer_edit_profile_screen.dart'; 
import 'email_password_screen.dart';
import 'language_screen.dart';
import 'help_screen.dart';
import 'legal_documents_screen.dart';
import 'notification_settings_screen.dart';
import 'blocked_users_screen.dart';

class CustomerSettingsScreen extends StatelessWidget {
  const CustomerSettingsScreen({super.key});

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(
          AppLocalizations.of(context)!.translate('delete_account'), 
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
        ),
        content: Text(
          AppLocalizations.of(context)!.translate('delete_account_warning'), 
          style: const TextStyle(color: Colors.white70)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.translate('cancel'), 
              style: const TextStyle(color: Colors.grey)
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              AppLocalizations.of(context)!.translate('delete_permanently'), 
              style: const TextStyle(color: Colors.white)
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true && context.mounted) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.collectionUsers)
            .doc(user.uid)
            .delete();
        await user.delete();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('relogin_required')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('settings'), 
          style: const TextStyle(color: AppTheme.textColor)
        ),
        backgroundColor: AppTheme.cardColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // HESAP BÖLÜMÜ
          _buildSectionHeader(context, AppLocalizations.of(context)!.translate('account')),
          _buildSettingsTile(
            context,
            icon: Icons.person,
            title: AppLocalizations.of(context)!.translate('profile_info'),
            subtitle: AppLocalizations.of(context)!.translate('profile_info_sub'),
            onTap: () {
              Navigator.push(context, SlideRoute(page: const CustomerEditProfileScreen()));
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.security,
            title: AppLocalizations.of(context)!.translate('email_password'),
            subtitle: AppLocalizations.of(context)!.translate('email_password_sub'),
            onTap: () {
              Navigator.push(context, SlideRoute(page: const EmailPasswordScreen()));
            },
          ),
          
          // TERCİHLER BÖLÜMÜ
          _buildSectionHeader(context, AppLocalizations.of(context)!.translate('preferences')),
          _buildSettingsTile(
            context,
            icon: Icons.notifications,
            title: AppLocalizations.of(context)!.translate('notifications'),
            subtitle: AppLocalizations.of(context)!.translate('notifications_sub'),
            onTap: () {
              Navigator.push(context, SlideRoute(page: const NotificationSettingsScreen()));
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: AppLocalizations.of(context)!.translate('language'),
            subtitle: AppLocalizations.of(context)!.translate('language_sub'),
            onTap: () {
              Navigator.push(context, SlideRoute(page: const LanguageScreen()));
            },
          ),

          // GİZLİLİK BÖLÜMÜ
          _buildSectionHeader(context, AppLocalizations.of(context)!.translate('privacy')),
          _buildSettingsTile(
            context,
            icon: Icons.block,
            title: AppLocalizations.of(context)!.translate('blocked_users'),
            subtitle: AppLocalizations.of(context)!.translate('blocked_users_sub'),
            onTap: () {
              Navigator.push(context, SlideRoute(page: const BlockedUsersScreen()));
            },
          ),

          // DESTEK BÖLÜMÜ
          _buildSectionHeader(context, AppLocalizations.of(context)!.translate('support')),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: AppLocalizations.of(context)!.translate('help'),
            subtitle: AppLocalizations.of(context)!.translate('help_sub'),
            onTap: () {
              Navigator.push(context, SlideRoute(page: const HelpScreen()));
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.gavel_rounded,
            title: AppLocalizations.of(context)!.translate('legal'),
            subtitle: AppLocalizations.of(context)!.translate('legal_sub'),
            onTap: () {
              Navigator.push(context, SlideRoute(page: const LegalDocumentsScreen()));
            },
          ),
          
          const SizedBox(height: 24),
          _buildLogoutButton(context),
          _buildDeleteAccountButton(context), 
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context,
      {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: AppTheme.backgroundColor.withOpacity(0.6),
        highlightColor: AppTheme.backgroundColor.withOpacity(0.1),
      ),
      child: Card(
        color: AppTheme.cardColor,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(icon, color: AppTheme.primaryColor),
          title: Text(title, style: const TextStyle(color: AppTheme.textColor)),
          subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.logout, color: AppTheme.primaryColor),
        title: Text(
          AppLocalizations.of(context)!.translate('logout'), 
          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)
        ),
        onTap: () async {
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.cardColor,
              title: Text(
                AppLocalizations.of(context)!.translate('logout'), 
                style: const TextStyle(color: AppTheme.textColor)
              ),
              content: Text(
                AppLocalizations.of(context)!.translate('logout_confirm'), 
                style: const TextStyle(color: Colors.white70)
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    AppLocalizations.of(context)!.translate('cancel'), 
                    style: const TextStyle(color: Colors.grey)
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: Text(
                    AppLocalizations.of(context)!.translate('logout'), 
                    style: const TextStyle(color: AppTheme.backgroundColor)
                  ),
                ),
              ],
            ),
          );

          if (shouldLogout == true && context.mounted) {
            await authService.signOut();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context) {
    return Card(
      color: Colors.redAccent.withOpacity(0.1),
      elevation: 0,
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
        title: Text(
          AppLocalizations.of(context)!.translate('delete_account'), 
          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)
        ),
        subtitle: Text(
          AppLocalizations.of(context)!.translate('delete_account_sub'), 
          style: const TextStyle(fontSize: 12, color: Colors.grey)
        ),
        onTap: () => _handleDeleteAccount(context),
      ),
    );
  }
}