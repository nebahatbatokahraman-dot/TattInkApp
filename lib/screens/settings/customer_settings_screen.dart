import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/slide_route.dart';
import '../auth/login_screen.dart';
import 'customer_edit_profile_screen.dart'; // Doğru dosyayı import ettik
import 'email_password_screen.dart';
import 'notifications_screen.dart';
import 'language_screen.dart';
import 'help_screen.dart';

class CustomerSettingsScreen extends StatelessWidget {
  const CustomerSettingsScreen({super.key});

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
                // SlideRoute const olmadığı için başındaki const'u sildik
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
                SlideRoute(page: const NotificationsScreen()),
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
                SlideRoute(page: const HelpScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  // Yardımcı widgetlar (_buildSectionHeader, _buildSettingsTile, _buildLogoutButton) senin kodundakiyle aynı kalabilir...
  // (Kodun kısalığı için buraya tekrar eklemedim, senin dosyadaki kısımları aynen koru)
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
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
        title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
        onTap: () async {
          // Çıkış onay diyaloğu mantığın burada devam eder...
          await authService.signOut();
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        },
      ),
    );
  }
}