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
import 'notifications_screen.dart';
import 'language_screen.dart';
import 'help_screen.dart';
import 'legal_documents_screen.dart';
import 'notification_settings_screen.dart';

class CustomerSettingsScreen extends StatelessWidget {
  const CustomerSettingsScreen({super.key});

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Sil', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
            'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz ve tüm randevularınız, mesajlarınız ve profil verileriniz kalıcı olarak silinecektir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
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
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context,
      {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Theme(
      data: Theme.of(context).copyWith(
        // Tıklama dalga rengi (Primary rengin hafif tonu)
        splashColor: AppTheme.backgroundColor.withOpacity(0.6),
        highlightColor: AppTheme.backgroundColor.withOpacity(0.1),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(icon, color: AppTheme.primaryColor),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
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
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.logout, color: AppTheme.primaryColor),
          title: const Text('Çıkış Yap', style: TextStyle(color: AppTheme.primaryColor)),
          onTap: () async {
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Çıkış Yap'),
                content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('İptal'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                    child: const Text('Çıkış Yap'),
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
        // Hesap silme için kırmızı splash efekti
        splashColor: Colors.red.withOpacity(0.2),
        highlightColor: Colors.red.withOpacity(0.1),
      ),
      child: Card(
        margin: const EdgeInsets.only(top: 8),
        child: ListTile(
          leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
          title: const Text('Hesabımı Sil', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          subtitle: const Text('Tüm verileriniz kalıcı olarak kaldırılır', style: TextStyle(fontSize: 12)),
          onTap: () => _handleDeleteAccount(context),
        ),
      ),
    );
  }
}