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
import 'blocked_users_screen.dart'; // Import ettiğinden emin ol

class ArtistSettingsScreen extends StatelessWidget {
  const ArtistSettingsScreen({super.key});

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
      backgroundColor: AppTheme.backgroundColor, // Arka plan rengini garantiye alalım
      appBar: AppBar(
        title: const Text('Ayarlar', style: TextStyle(color: AppTheme.textColor)),
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
            _buildSectionHeader('Hesap'),
            _buildSettingsTile(
              context,
              icon: Icons.person,
              title: 'Profil Bilgileri',
              subtitle: 'Stüdyo, stil ve uzmanlık etiketlerinizi düzenleyin',
              onTap: () {
                Navigator.push(context, SlideRoute(page: const ArtistEditProfileScreen()));
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.security,
              title: 'Email ve Şifre',
              subtitle: 'Giriş bilgilerinizi güncelleyin',
              onTap: () {
                Navigator.push(context, SlideRoute(page: const EmailPasswordScreen()));
              },
            ),
            
            _buildSectionHeader('Tercihler'),
            _buildSettingsTile(
              context,
              icon: Icons.notifications,
              title: 'Bildirimler',
              subtitle: 'Bildirim ayarlarınızı yönetin',
              onTap: () {
                Navigator.push(context, SlideRoute(page: const NotificationSettingsScreen()));
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.language,
              title: 'Dil',
              subtitle: 'Uygulama dilini seçin',
              onTap: () {
                Navigator.push(context, SlideRoute(page: const LanguageScreen()));
              },
            ),

            // --- YENİ EKLENEN KISIM: GİZLİLİK BÖLÜMÜ ---
            _buildSectionHeader('Gizlilik'),
            _buildSettingsTile(
              context,
              icon: Icons.block, // Engelleme ikonu
              title: 'Engellenen Kullanıcılar',
              subtitle: 'Engellediğiniz kişileri yönetin',
              onTap: () {
                Navigator.push(context, SlideRoute(page: const BlockedUsersScreen()));
              },
            ),
            // -------------------------------------------
            
            _buildSectionHeader('Destek'),
            _buildSettingsTile(
              context,
              icon: Icons.help_outline,
              title: 'Yardım',
              subtitle: 'Sık sorulan sorular ve yardım',
              onTap: () {
                Navigator.push(context, SlideRoute(page: const HelpScreen()));
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.gavel_rounded,
              title: 'Hukuki Metinler',
              subtitle: 'Kullanım şartları ve gizlilik politikası',
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title.toUpperCase(),
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
      color: AppTheme.cardColor, // Şeffaflığı kaldırdım daha net dursun diye
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
        title: const Text('Çıkış Yap', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
        onTap: () async {
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.cardColor,
              title: const Text('Çıkış Yap', style: TextStyle(color: AppTheme.textColor)),
              content: const Text('Çıkış yapmak istediğinize emin misiniz?', style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal', style: TextStyle(color: Colors.grey))),
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
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.redAccent.withOpacity(0.1),
      child: ListTile(
        leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
        title: const Text('Hesabımı Sil', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        subtitle: const Text('Tüm verileriniz kalıcı olarak kaldırılır', style: TextStyle(color: Colors.grey, fontSize: 11)),
        onTap: () => _handleDeleteAccount(context),
      ),
    );
  }
}