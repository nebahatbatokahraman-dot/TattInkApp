import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../app_localizations.dart'; // Çeviri sınıfını ekledik

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;

  bool _messages = true;
  bool _likes = true;
  bool _follows = true;
  bool _campaigns = true;

  @override
  void initState() {
    super.initState();
    _loadSettings(); 
  }

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
        title: Text(
          AppLocalizations.of(context)!.translate('notification_settings_title'), 
          style: const TextStyle(color: AppTheme.textColor)
        ),
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
          _buildHeader(AppLocalizations.of(context)!.translate('notif_header_chat')),
          _buildSwitch(
            AppLocalizations.of(context)!.translate('notif_new_messages'), 
            AppLocalizations.of(context)!.translate('notif_new_messages_sub'), 
            _messages, 
            (v) {
              setState(() => _messages = v);
              _updateSetting('notifMessages', v);
            }
          ),

          const SizedBox(height: 24),

          _buildHeader(AppLocalizations.of(context)!.translate('notif_header_interactions')),
          _buildSwitch(
            AppLocalizations.of(context)!.translate('notif_likes'), 
            AppLocalizations.of(context)!.translate('notif_likes_sub'), 
            _likes, 
            (v) {
              setState(() => _likes = v);
              _updateSetting('notifLikes', v);
            }
          ),
          _buildSwitch(
            AppLocalizations.of(context)!.translate('notif_follows'), 
            AppLocalizations.of(context)!.translate('notif_follows_sub'), 
            _follows, 
            (v) {
              setState(() => _follows = v);
              _updateSetting('notifFollows', v);
            }
          ),

          const SizedBox(height: 24),

          _buildHeader(AppLocalizations.of(context)!.translate('notif_header_other')),
          _buildSwitch(
            AppLocalizations.of(context)!.translate('notif_campaigns'), 
            AppLocalizations.of(context)!.translate('notif_campaigns_sub'), 
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