import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Resim gösterimi için
import '../../theme/app_theme.dart';

class AdminAdsScreen extends StatefulWidget {
  const AdminAdsScreen({super.key});

  @override
  State<AdminAdsScreen> createState() => _AdminAdsScreenState();
}

class _AdminAdsScreenState extends State<AdminAdsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  // YENİ: Link için controller ekledik
  final TextEditingController _linkController = TextEditingController(); 
  
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  // Reklam Ekleme/Düzenleme Dialogu
  void _showAdDialog({DocumentSnapshot? adDoc}) {
    // Eğer düzenleme modundaysak verileri doldur
    if (adDoc != null) {
      final data = adDoc.data() as Map<String, dynamic>;
      _titleController.text = data['title'] ?? '';
      _contentController.text = data['content'] ?? '';
      _linkController.text = data['link'] ?? ''; // YENİ: Varsa linki doldur
    } else {
      _titleController.clear();
      _contentController.clear();
      _linkController.clear(); // YENİ: Temizle
      setState(() {
        _selectedImage = null;
      });
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(adDoc == null ? "Yeni Reklam Ekle" : "Reklamı Düzenle", style: const TextStyle(color: AppTheme.textColor)),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Resim Seçme Alanı
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImage!, fit: BoxFit.cover))
                        : (adDoc != null && (adDoc.data() as Map)['imageUrl'] != null)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: (adDoc.data() as Map)['imageUrl'],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) => const Icon(Icons.add_a_photo, color: Colors.white, size: 40),
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: Colors.white, size: 40),
                                  SizedBox(height: 8),
                                  Text("Resim Seç", style: TextStyle(color: Colors.white70)),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Başlık Alanı
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: AppTheme.textColor),
                  decoration: const InputDecoration(
                    labelText: "Başlık",
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor)),
                  ),
                  validator: (val) => val!.isEmpty ? "Başlık gerekli" : null,
                ),
                const SizedBox(height: 12),
                
                // İçerik Alanı
                TextFormField(
                  controller: _contentController,
                  style: const TextStyle(color: AppTheme.textColor),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "İçerik / Açıklama",
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor)),
                  ),
                ),
                const SizedBox(height: 12),

                // YENİ: Link Alanı
                TextFormField(
                  controller: _linkController,
                  style: const TextStyle(color: AppTheme.textColor),
                  decoration: const InputDecoration(
                    labelText: "Hedef Link (Web sitesi veya Profil ID)",
                    hintText: "https://... veya user_id",
                    hintStyle: TextStyle(color: Colors.grey),
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () => _saveAd(adDoc?.id),
            child: Text(adDoc == null ? "Ekle" : "Güncelle", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      (context as Element).markNeedsBuild(); 
    }
  }

  Future<void> _saveAd(String? docId) async {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context); // Dialogu kapat
    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      // Resim yükleme
      if (_selectedImage != null) {
        final ref = FirebaseStorage.instance.ref().child('ads_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_selectedImage!);
        imageUrl = await ref.getDownloadURL();
      }

      final adData = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'link': _linkController.text.trim(), // YENİ: Link verisini kaydet
        'isActive': true, 
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (imageUrl != null) {
        adData['imageUrl'] = imageUrl;
      }

      if (docId == null) {
        // Yeni Ekleme
        await FirebaseFirestore.instance.collection('ads').add(adData);
      } else {
        // Güncelleme
        await FirebaseFirestore.instance.collection('ads').doc(docId).update(adData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reklam kaydedildi"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAd(String docId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text("Sil?", style: TextStyle(color: AppTheme.textColor)),
        content: const Text("Bu reklamı silmek istediğine emin misin?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hayır", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Evet", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('ads').doc(docId).delete();
    }
  }

  Future<void> _toggleActive(String docId, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('ads').doc(docId).update({'isActive': !currentStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Reklam Yönetimi", style: TextStyle(color: AppTheme.textColor)),
        backgroundColor: AppTheme.cardColor,
        iconTheme: const IconThemeData(color: AppTheme.textColor),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAdDialog(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('ads').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Henüz reklam yok.", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final bool isActive = data['isActive'] ?? false;
                    final String linkInfo = data['link'] ?? "";

                    return Card(
                      color: AppTheme.cardColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isActive ? AppTheme.primaryColor : Colors.grey.withOpacity(0.3))),
                      child: ListTile(
                        leading: (data['imageUrl'] != null && data['imageUrl'].toString().startsWith('http'))
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(data['imageUrl'], width: 60, height: 60, fit: BoxFit.cover),
                              )
                            : Container(width: 60, height: 60, color: Colors.grey[800], child: const Icon(Icons.image_not_supported)),
                        title: Text(data['title'] ?? "Başlıksız", style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isActive ? "Yayında" : "Pasif", style: TextStyle(color: isActive ? Colors.green : Colors.red)),
                            if (linkInfo.isNotEmpty)
                              Text("Link: $linkInfo", style: TextStyle(color: Colors.blue[300], fontSize: 10), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: isActive,
                              activeColor: AppTheme.primaryColor,
                              onChanged: (val) => _toggleActive(doc.id, isActive),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAdDialog(adDoc: doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteAd(doc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}