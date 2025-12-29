import 'package:flutter/material.dart';
import '../../theme/app_theme.dart'; // Tema dosyanın yolu (kendi projene göre gerekirse düzelt)

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Varsayılan ayarlar
  bool _messages = true;
  bool _likes = true;
  bool _comments = true;
  bool _follows = true;
  bool _campaigns = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Bildirim Ayarları', style: TextStyle(color: AppTheme.textColor)),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader("Sohbet"),
          _buildSwitch("Yeni Mesajlar", "Mesaj aldığında bildir", _messages, (v) => setState(() => _messages = v)),

          const SizedBox(height: 24),

          _buildHeader("Etkileşimler"),
          _buildSwitch("Beğeniler", "Biri gönderini beğendiğinde", _likes, (v) => setState(() => _likes = v)),
          _buildSwitch("Yeni Takipçiler", "Biri seni takip ettiğinde", _follows, (v) => setState(() => _follows = v)),

          const SizedBox(height: 24),

          _buildHeader("Diğer"),
          _buildSwitch("Kampanyalar", "Duyuru ve yenilikler", _campaigns, (v) => setState(() => _campaigns = v)),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildSwitch(String title, String subtitle, bool val, Function(bool) onChange) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: AppTheme.cardColor.withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
    ),
    // --- DÜZELTME BURADA ---
    // SwitchListTile'ı Theme ile sarmalıyoruz
    child: Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent, // Tıklayınca çıkan dalga yok olsun
        highlightColor: Colors.transparent, // Basılı tutunca çıkan gri renk yok olsun
        hoverColor: Colors.transparent, // Mouse ile üzerine gelince (Web/Desktop için)
      ),
      child: SwitchListTile(
        activeColor: AppTheme.primaryColor,
        inactiveThumbColor: AppTheme.primaryColor.withOpacity(0.5),
        inactiveTrackColor: AppTheme.primaryLightColor.withOpacity(0.1),
        
        // Çerçeveyi kaldırma kodu (önceki sorudan)
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent), 

        title: Text(title, style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        value: val,
        onChanged: onChange,
      ),
    ),
  );
}
}