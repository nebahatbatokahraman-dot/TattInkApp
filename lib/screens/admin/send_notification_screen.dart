import '../../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  String selectedTarget = 'all'; // Varsayılan hedef: Herkes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toplu Bildirim Gönder')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Hedef Seçimi (Dropdown)
            DropdownButtonFormField<String>(
              value: selectedTarget,
              decoration: const InputDecoration(labelText: 'Hedef Kitle'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Herkes')),
                DropdownMenuItem(value: 'customers', child: Text('Sadece Müşteriler')),
                DropdownMenuItem(value: 'artists', child: Text('Sadece Sanatçılar')),
              ],
              onChanged: (val) => setState(() => selectedTarget = val!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Bildirim Başlığı', hintText: 'Örn: Yeni Kampanya!'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bodyController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Mesaj İçeriği', hintText: 'Bildirim detayını buraya yazın...'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _sendNotification,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                child: const Text('BİLDİRİMİ GÖNDER', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendNotification() async {
    if (titleController.text.isEmpty || bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen tüm alanları doldurun')));
      return;
    }

    // BURASI ÖNEMLİ: Normalde bildirim gönderme işlemi güvenlik nedeniyle 
    // bir Backend (Node.js, Python vb.) üzerinden veya Cloud Functions ile yapılır.
    // Şimdilik bu veriyi Firestore'a 'broadcast_notifications' koleksiyonuna atalım,
    // bir Cloud Function bunu tetikleyip bildirimleri gönderebilir.
    
    await FirebaseFirestore.instance.collection('broadcast_notifications').add({
      'title': titleController.text,
      'body': bodyController.text,
      'target': selectedTarget,
      'sentAt': FieldValue.serverTimestamp(),
      'status': 'pending', // Cloud Function bunu 'sent' yapacak
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bildirim sıraya alındı!')));
    Navigator.pop(context);
  }
}
