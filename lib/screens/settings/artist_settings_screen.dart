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

class ArtistSettingsScreen extends StatelessWidget {
  const ArtistSettingsScreen({super.key});

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
        title: const Text('Artist Ayarları'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Scrollbar( // Kullanıcının nerede olduğunu görmesi için scrollbar ekledik
        child: ListView(
          // --- DÜZELTME: Kaydırma fiziğini otomatiğe çektik ---
          physics: const BouncingScrollPhysics(), 
          
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), // Alt tarafa ekstra boşluk (32) verdik ki buton rahat görünsün
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
            
            const SizedBox(height: 24), // Bölümler arası geniş boşluk
            
            _buildLogoutButton(context),
            
            const SizedBox(height: 8), // İki buton arası küçük boşluk
            
            _buildDeleteAccountButton(context),
            
            // En altta biraz daha nefes payı bırakalım
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
      color: AppTheme.cardColor.withOpacity(0.5),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: AppTheme.cardLightColor.withOpacity(0.8),
          highlightColor: Colors.transparent,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Icon(icon, color: AppTheme.primaryColor),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
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
              title: const Text('Çıkış Yap'),
              content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
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
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.redAccent.withOpacity(0.05),
      child: ListTile(
        leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
        title: const Text('Hesabımı Sil', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        subtitle: const Text('Tüm verileriniz kalıcı olarak kaldırılır', style: TextStyle(color: Colors.grey, fontSize: 11)),
        onTap: () => _handleDeleteAccount(context),
      ),
    );
  }
}