import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/slide_route.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import 'artist_edit_profile_screen.dart';
import 'email_password_screen.dart';
import 'language_screen.dart';
import 'help_screen.dart';
import 'legal_documents_screen.dart';
import 'notification_settings_screen.dart'; 
import 'blocked_users_screen.dart'; 

// --- LOCALIZATION IMPORT ---
import '../../app_localizations.dart'; 

class ArtistSettingsScreen extends StatelessWidget {
  const ArtistSettingsScreen({super.key});

  // Helper method for translation shortcut
  String tr(BuildContext context, String key) {
    return AppLocalizations.of(context)?.translate(key) ?? key;
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(tr(context, 'delete_account_title'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(
            tr(context, 'delete_account_warning'),
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(context, 'cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(tr(context, 'delete_permanently'), style: const TextStyle(color: Colors.white)),
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
              content: Text(tr(context, 'relogin_required')),
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
        title: Text(tr(context, 'settings'), style: const TextStyle(color: AppTheme.textColor)),
        backgroundColor: AppTheme.cardColor,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Scrollbar(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _buildSectionHeader(context, 'account'), // Key gönderiyoruz
            _buildSettingsTile(
              context,
              icon: Icons.person,
              title: tr(context, 'profile_info'),
              subtitle: tr(context, 'profile_info_sub_artist'),
              onTap: () {
                Navigator.push(context, SlideRoute(page: const ArtistEditProfileScreen()));
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.security,
              title: tr(context, 'email_password'),
              subtitle: tr(context, 'email_password_sub'),
              onTap: () {
                Navigator.push(context, SlideRoute(page: const EmailPasswordScreen()));
              },
            ),
            
            _buildSectionHeader(context, 'preferences'), // Key
            _buildSettingsTile(
              context,
              icon: Icons.notifications,
              title: tr(context, 'notifications'),
              subtitle: tr(context, 'notifications_sub'),
              onTap: () {
                Navigator.push(context, SlideRoute(page: const NotificationSettingsScreen()));
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.language,
              title: tr(context, 'language'),
              subtitle: tr(context, 'language_sub'),
              onTap: () {
                Navigator.push(context, SlideRoute(page: const LanguageScreen()));
              },
            ),

            // --- GİZLİLİK BÖLÜMÜ ---
            _buildSectionHeader(context, 'privacy'), // Key
            _buildSettingsTile(
              context,
              icon: Icons.block, 
              title: tr(context, 'blocked_users'),
              subtitle: tr(context, 'blocked_users_sub'),
              onTap: () {
                Navigator.push(context, SlideRoute(page: const BlockedUsersScreen()));
              },
            ),
            // -----------------------
            
            _buildSectionHeader(context, 'support'), // Key
            _buildSettingsTile(
              context,
              icon: Icons.help_outline,
              title: tr(context, 'help'),
              subtitle: tr(context, 'help_sub'),
              onTap: () {
                Navigator.push(context, SlideRoute(page: const HelpScreen()));
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.gavel_rounded,
              title: tr(context, 'legal'),
              subtitle: tr(context, 'legal_sub'),
              onTap: () {
                Navigator.push(context, SlideRoute(page: const LegalDocumentsScreen()));
              },
            ),
            
            const SizedBox(height: 24), 
            
            _buildLogoutButton(context),
            
            const SizedBox(height: 12), 
            
            _buildDeleteAccountButton(context),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String titleKey) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        tr(context, titleKey).toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppTheme.cardColor, 
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: AppTheme.cardLightColor.withOpacity(0.3),
          highlightColor: Colors.transparent,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8)
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textColor)),
          subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppTheme.cardColor,
      child: ListTile(
        leading: const Icon(Icons.logout, color: AppTheme.primaryColor),
        title: Text(tr(context, 'logout'), style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
        onTap: () async {
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.cardColor,
              title: Text(tr(context, 'logout'), style: const TextStyle(color: AppTheme.textColor)),
              content: Text(tr(context, 'logout_confirm'), style: const TextStyle(color: Colors.white70)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context, 'cancel'), style: const TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: Text(tr(context, 'logout'), style: const TextStyle(color: AppTheme.backgroundColor)),
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
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.redAccent.withOpacity(0.1),
      child: ListTile(
        leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
        title: Text(tr(context, 'delete_account'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        subtitle: Text(tr(context, 'delete_account_sub'), style: const TextStyle(color: Colors.grey, fontSize: 11)),
        onTap: () => _handleDeleteAccount(context),
      ),
    );
  }
}