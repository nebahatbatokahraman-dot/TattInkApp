import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  // Kaydırma durumunu takip etmek için
  bool _isScrolled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar'ın arkasının görünmesi için body'i yukarı taşıyoruz
      extendBodyBehindAppBar: true,
      
      appBar: AppBar(
        title: const Text('Yardım'),
        
        // 1. DÜZELTME: Kaydırılınca CardColor, tepedeyken Şeffaf
        backgroundColor: _isScrolled ? AppTheme.cardColor : Colors.transparent,
        
        // Varsayılan kırmızılaşmayı kapatıyoruz
        scrolledUnderElevation: 0,
        elevation: 0,
        
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      
      // Kaydırma hareketini dinliyoruz
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
          // AppBar şeffaf olduğu için içeriğin üstte kalmaması adına padding veriyoruz
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
            left: 16,
            right: 16,
            bottom: 16
          ),
          children: [
            _buildSectionHeader('Sık Sorulan Sorular'),
            
            _buildFAQItem(
              'Nasıl artist takip edebilirim?',
              'Artist profil sayfasına gidip "Takip Et" butonuna tıklayabilirsiniz.',
            ),
            _buildFAQItem(
              'Randevu nasıl oluşturulur?',
              'Artist profil sayfasında "Randevu" butonuna tıklayıp tarih ve saat seçerek randevu oluşturabilirsiniz.',
            ),
            _buildFAQItem(
              'Mesaj nasıl gönderilir?',
              'Anasayfadaki bir paylaşıma tıklayıp "Mesaj At" butonuna basabilir veya artist profil sayfasından mesaj gönderebilirsiniz.',
            ),
            _buildFAQItem(
              'Favorilerim nerede?',
              'Profil sayfanızdaki "Favoriler" sekmesinde beğendiğiniz paylaşımları görebilirsiniz.',
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader('İletişim'),
            
            _buildContactItem(
              context,
              icon: Icons.email,
              title: 'Email',
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
              title: 'Telefon',
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
      margin: const EdgeInsets.only(bottom: 8),
      // 2. DÜZELTME: Splash efektini kaldırmak için Theme
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          dividerColor: Colors.transparent, // Eski versiyonlarda ayırıcı rengi
        ),
        child: ExpansionTile(
          title: Text(question),
          
          // 3. DÜZELTME: Alt ve Üstteki Çizgileri Kaldırma
          shape: const Border(), // Açıldığındaki çerçeve yok
          collapsedShape: const Border(), // Kapalıykenki çerçeve yok
          
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(answer),
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
      margin: const EdgeInsets.only(bottom: 8),
      // Splash efektini kaldırmak için Theme
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}