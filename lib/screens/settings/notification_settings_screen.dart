import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Başlangıçta yükleniyor durumu
  bool _isLoading = true;

  // Varsayılan ayarlar (Firebase'den gelecek)
  bool _messages = true;
  bool _likes = true;
  bool _follows = true;
  bool _campaigns = true;

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Sayfa açılırken ayarları yükle
  }

  // --- 1. AYARLARI FİREBASE'DEN ÇEK ---
  Future<void> _loadSettings() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final uid = authService.currentUser?.uid;

    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection(AppConstants.collectionUsers)
            .doc(uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          // Eğer veritabanında bu alanlar yoksa varsayılan değerleri kullanır
          setState(() {
            _messages = data['notifMessages'] ?? true;
            _likes = data['notifLikes'] ?? true;
            _follows = data['notifFollows'] ?? true;
            _campaigns = data['notifCampaigns'] ?? true;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint("Ayarlar yüklenirken hata: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  // --- 2. AYARLARI FİREBASE'E KAYDET ---
  Future<void> _updateSetting(String field, bool value) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final uid = authService.currentUser?.uid;

    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.collectionUsers)
            .doc(uid)
            .update({field: value});
      } catch (e) {
        debugPrint("Ayar güncellenirken hata: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

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
          _buildSwitch(
            "Yeni Mesajlar", 
            "Mesaj aldığında bildir", 
            _messages, 
            (v) {
              setState(() => _messages = v);
              _updateSetting('notifMessages', v);
            }
          ),

          const SizedBox(height: 24),

          _buildHeader("Etkileşimler"),
          _buildSwitch(
            "Beğeniler", 
            "Biri gönderini beğendiğinde", 
            _likes, 
            (v) {
              setState(() => _likes = v);
              _updateSetting('notifLikes', v);
            }
          ),
          _buildSwitch(
            "Yeni Takipçiler", 
            "Biri seni takip ettiğinde", 
            _follows, 
            (v) {
              setState(() => _follows = v);
              _updateSetting('notifFollows', v);
            }
          ),

          const SizedBox(height: 24),

          _buildHeader("Diğer"),
          _buildSwitch(
            "Kampanyalar", 
            "Duyuru ve yenilikler", 
            _campaigns, 
            (v) {
              setState(() => _campaigns = v);
              _updateSetting('notifCampaigns', v);
            }
          ),
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
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: SwitchListTile(
          activeColor: AppTheme.primaryColor,
          inactiveThumbColor: AppTheme.primaryColor.withOpacity(0.5),
          inactiveTrackColor: AppTheme.primaryLightColor.withOpacity(0.1),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent), 
          title: Text(title, style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          value: val,
          onChanged: onChange,
        ),
      ),
    );
  }
}