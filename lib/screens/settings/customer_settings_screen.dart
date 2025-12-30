import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/slide_route.dart';
import '../auth/login_screen.dart';
import 'customer_edit_profile_screen.dart'; 
import 'email_password_screen.dart';
import 'language_screen.dart';
import 'help_screen.dart';
import 'legal_documents_screen.dart';
import 'notification_settings_screen.dart';
import 'blocked_users_screen.dart'; // <-- UNUTMA: Bunu import etmelisin

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
        title: const Text('Hesabı Sil', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
            'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz ve tüm randevularınız, mesajlarınız ve profil verileriniz kalıcı olarak silinecektir.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Evet, Kalıcı Olarak Sil', style: TextStyle(color: Colors.white)),
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
            const SnackBar(
              content: Text('Güvenlik nedeniyle, bu işlemden önce tekrar giriş yapmalısınız.'),
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
        title: const Text('Ayarlar', style: TextStyle(color: AppTheme.textColor)),
        backgroundColor: AppTheme.cardColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Hesap'),
          _buildSettingsTile(
            context,
            icon: Icons.person,
            title: 'Profil Bilgileri',
            subtitle: 'Ad, soyad ve profil fotoğrafınızı düzenleyin',
            onTap: () {
              Navigator.push(
                context,
                SlideRoute(page: const CustomerEditProfileScreen()),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.security,
            title: 'Email ve Şifre',
            subtitle: 'Email adresinizi ve şifrenizi değiştirin',
            onTap: () {
              Navigator.push(
                context,
                SlideRoute(page: const EmailPasswordScreen()),
              );
            },
          ),
          
          _buildSectionHeader('Tercihler'),
          _buildSettingsTile(
            context,
            icon: Icons.notifications,
            title: 'Bildirimler',
            subtitle: 'Bildirim ayarlarınızı yönetin',
            onTap: () {
              Navigator.push(
                context,
                SlideRoute(page: const NotificationSettingsScreen()),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: 'Dil',
            subtitle: 'Uygulama dilini seçin',
            onTap: () {
              Navigator.push(
                context,
                SlideRoute(page: const LanguageScreen()),
              );
            },
          ),

          // --- YENİ EKLENEN: GİZLİLİK BÖLÜMÜ ---
          _buildSectionHeader('Gizlilik'),
          _buildSettingsTile(
            context,
            icon: Icons.block,
            title: 'Engellenen Kullanıcılar',
            subtitle: 'Engellediğiniz kişileri yönetin',
            onTap: () {
              Navigator.push(
                context,
                SlideRoute(page: const BlockedUsersScreen()),
              );
            },
          ),
          // ------------------------------------

          _buildSectionHeader('Destek'),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: 'Yardım',
            subtitle: 'Sık sorulan sorular ve yardım',
            onTap: () {
              Navigator.push(
                context,
                SlideRoute(page: const HelpScreen()),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.gavel_rounded,
            title: 'Hukuki Metinler',
            subtitle: 'Kullanım şartları ve gizlilik politikası',
            onTap: () {
              Navigator.push(
                context,
                SlideRoute(page: const LegalDocumentsScreen()),
              );
            },
          ),
          
          const SizedBox(height: 24),
          _buildLogoutButton(context),
          _buildDeleteAccountButton(context), 
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: AppTheme.backgroundColor.withOpacity(0.6),
        highlightColor: AppTheme.backgroundColor.withOpacity(0.1),
      ),
      child: Card(
        color: AppTheme.cardColor,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.logout, color: AppTheme.primaryColor),
          title: const Text('Çıkış Yap', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          onTap: () async {
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppTheme.cardColor,
                title: const Text('Çıkış Yap', style: TextStyle(color: AppTheme.textColor)),
                content: const Text('Çıkış yapmak istediğinize emin misiniz?', style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('İptal', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                    child: const Text('Çıkış Yap', style: TextStyle(color: AppTheme.backgroundColor)),
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
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.red.withOpacity(0.2),
        highlightColor: Colors.red.withOpacity(0.1),
      ),
      child: Card(
        color: Colors.redAccent.withOpacity(0.1),
        elevation: 0,
        margin: const EdgeInsets.only(top: 8),
        child: ListTile(
          leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
          title: const Text('Hesabımı Sil', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          subtitle: const Text('Tüm verileriniz kalıcı olarak kaldırılır', style: TextStyle(fontSize: 12, color: Colors.grey)),
          onTap: () => _handleDeleteAccount(context),
        ),
      ),
    );
  }
}