import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class AdManagementScreen extends StatelessWidget {
  const AdManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reklam Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAdForm(context), // Yeni reklam ekleme formu
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('ads').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final ads = snapshot.data!.docs;

          return ListView.builder(
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = ads[index];
              final adId = ad.id;
              final bool isActive = ad['isActive'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.ad_units, color: AppTheme.primaryColor),
                  title: Text(ad['title']),
                  subtitle: Text(ad['subtitle']),
                  trailing: Switch(
                    value: isActive,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (val) {
                      FirebaseFirestore.instance.collection('ads').doc(adId).update({'isActive': val});
                    },
                  ),
                  onLongPress: () {
                    // Uzun basınca silme onayı
                    _showDeleteConfirm(context, adId);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- REKLAM EKLEME FORMU (DIALOG) ---
  void _showAdForm(BuildContext context) {
    final titleController = TextEditingController();
    final subController = TextEditingController();
    final contentController = TextEditingController();
    final imageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Reklam Ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Başlık (Örn: TattInk Premium)')),
              TextField(controller: subController, decoration: const InputDecoration(labelText: 'Alt Başlık (Örn: Sponsorlu)')),
              TextField(controller: contentController, decoration: const InputDecoration(labelText: 'İçerik Metni'), maxLines: 3),
              TextField(controller: imageController, decoration: const InputDecoration(labelText: 'Görsel URL (Opsiyonel)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('ads').add({
                'title': titleController.text,
                'subtitle': subController.text,
                'content': contentController.text,
                'imageUrl': imageController.text.isEmpty ? null : imageController.text,
                'isActive': true,
                'createdAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
            },
            child: const Text('Yayınla'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reklamı Sil'),
        content: const Text('Bu reklam kalıcı olarak silinecek. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hayır')),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('ads').doc(id).delete();
              Navigator.pop(context);
            },
            child: const Text('Evet, Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}