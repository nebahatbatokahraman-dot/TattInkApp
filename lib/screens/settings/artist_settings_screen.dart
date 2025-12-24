import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/slide_route.dart';
import '../auth/login_screen.dart';
import 'artist_edit_profile_screen.dart'; // Artist Edit sayfası
import 'email_password_screen.dart';
import 'notifications_screen.dart'; // EKSİK OLAN IMPORT BU
import 'language_screen.dart';
import 'help_screen.dart';

// DÜZELTME: Sınıf ismini ArtistSettingsScreen yaptık (Eskiden Customer kalmıştı)
class ArtistSettingsScreen extends StatelessWidget {
  const ArtistSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Ayarları'),
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
            subtitle: 'Stüdyo, stil ve uzmanlık etiketlerinizi düzenleyin',
            onTap: () {
              Navigator.push(
                context,
                // const SİLİNDİ
                SlideRoute(page: ArtistEditProfileScreen()),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.security,
            title: 'Email ve Şifre',
            subtitle: 'Giriş bilgilerinizi güncelleyin',
            onTap: () {
              Navigator.push(
                context,
                // const SİLİNDİ
                SlideRoute(page: EmailPasswordScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Tercihler'),
          _buildSettingsTile(
            context,
            icon: Icons.notifications,
            title: 'Bildirimler',
            subtitle: 'Bildirim ayarlarınızı yönetin',
            onTap: () {
              Navigator.push(
                context,
                // const SİLİNDİ (Burada hata veriyordu)
                SlideRoute(page: NotificationsScreen()),
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
                // const SİLİNDİ
                SlideRoute(page: LanguageScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Destek'),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: 'Yardım',
            subtitle: 'Sık sorulan sorular ve yardım',
            onTap: () {
              Navigator.push(
                context,
                // const SİLİNDİ
                SlideRoute(page: HelpScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildLogoutButton(context),
        ],
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

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          'Çıkış Yap',
          style: TextStyle(color: Colors.red),
        ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
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
}