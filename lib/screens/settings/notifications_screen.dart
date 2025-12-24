import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushNotifications = true;
  bool _messageNotifications = true;
  bool _appointmentNotifications = true;
  bool _campaignNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _messageNotifications = prefs.getBool('message_notifications') ?? true;
      _appointmentNotifications = prefs.getBool('appointment_notifications') ?? true;
      _campaignNotifications = prefs.getBool('campaign_notifications') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Genel'),
          _buildSwitchTile(
            'Push Bildirimleri',
            'Uygulama bildirimlerini aç/kapat',
            _pushNotifications,
            (value) {
              setState(() {
                _pushNotifications = value;
              });
              _saveSetting('push_notifications', value);
            },
          ),
          _buildSwitchTile(
            'Kampanya ve Haberler',
            'Kampanya ve haber bildirimlerini al',
            _campaignNotifications,
            (value) {
              setState(() {
                _campaignNotifications = value;
              });
              _saveSetting('campaign_notifications', value);
            },
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Etkileşimler'),
          _buildSwitchTile(
            'Mesaj Bildirimleri',
            'Mesaj bildirimlerini al',
            _messageNotifications,
            (value) {
              setState(() {
                _messageNotifications = value;
              });
              _saveSetting('message_notifications', value);
            },
          ),
          _buildSwitchTile(
            'Randevu Bildirimleri',
            'Randevu bildirimlerini al',
            _appointmentNotifications,
            (value) {
              setState(() {
                _appointmentNotifications = value;
              });
              _saveSetting('appointment_notifications', value);
            },
          ),
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

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
