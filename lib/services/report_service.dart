import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ReportService {
  static const List<String> reportReasons = [
    "İstenmeyen İçerik (Spam)",
    "Çıplaklık veya Cinsellik",
    "Nefret Söylemi veya Taciz",
    "Şiddet veya Tehlikeli Örgütler",
    "Fikri Mülkiyet İhlali",
    "Yanlış Bilgi",
    "Diğer",
  ];

  static Future<void> showReportDialog({
    required BuildContext context,
    required String contentId, 
    required String contentType, 
    String? reportedUserId,
    List<Map<String, dynamic>>? evidenceMessages, // ChatScreen'den gelen hazır paket için eklendi
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text("İçeriği Şikayet Et", style: TextStyle(color: AppTheme.textColor)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: reportReasons.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(reportReasons[index], style: const TextStyle(color: Colors.white70)),
                onTap: () async {
                  Navigator.pop(dialogContext); 
                  
                  List<Map<String, dynamic>> evidence = [];

                  // Eğer ChatScreen bize hazır paket (evidenceMessages) göndermişse onu kullan
                  if (evidenceMessages != null && evidenceMessages.isNotEmpty) {
                    evidence = evidenceMessages;
                    print("✅ ChatScreen'den gelen hazır kanıtlar kullanılıyor.");
                  } 
                  // Eğer hazır paket yoksa ama tür 'chat' ise senin mevcut toplama mantığın çalışsın
                  else if (contentType == 'chat' && contentId.isNotEmpty) {
                    try {
                      print("🔎 Sorgu Başlıyor. ChatID: $contentId");
                      
                      final chatSnap = await FirebaseFirestore.instance
                          .collection('messages') 
                          .where('chatId', isEqualTo: contentId) 
                          .limit(20) 
                          .get();
                      
                      if (chatSnap.docs.isNotEmpty) {
                        var docs = chatSnap.docs;
                        
                        evidence = docs.map((doc) {
                          final mData = doc.data();
                          return {
                            'senderId': mData['senderId'] ?? '',
                            'message': mData['message'] ?? mData['text'] ?? mData['content'] ?? '',
                            'timestamp': mData['timestamp'] ?? mData['createdAt'], // createdAt desteği de eklendi
                            'imageUrl': mData['imageUrl'], // Görsel desteği eklendi
                          };
                        }).toList();

                        evidence.sort((a, b) {
                          Timestamp t1 = a['timestamp'] ?? Timestamp.now();
                          Timestamp t2 = b['timestamp'] ?? Timestamp.now();
                          return t2.compareTo(t1);
                        });

                        print("✅ ${evidence.length} adet mesaj kanıt olarak toplandı.");
                      }
                    } catch (e) {
                      print("❌ Kanıt toplama sırasında teknik hata: $e");
                    }
                  }

                  _submitReport(
                    messenger: messenger,
                    contentId: contentId, 
                    contentType: contentType, 
                    reason: reportReasons[index], 
                    reportedUserId: reportedUserId,
                    evidenceMessages: evidence,
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  static Future<void> _submitReport({
    required ScaffoldMessengerState messenger,
    required String contentId, 
    required String contentType, 
    required String reason,
    String? reportedUserId,
    List<Map<String, dynamic>>? evidenceMessages,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterId': FirebaseAuth.instance.currentUser?.uid,
        'contentId': contentId,
        'contentType': contentType,
        'reason': reason,
        'reportedUserId': reportedUserId ?? '',
        'evidenceMessages': evidenceMessages ?? [], 
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Şikayetiniz alındı. Kanıtlar kaydedildi."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print("❌ Kayıt hatası: $e");
      messenger.showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  static Future<void> blockUser({
    required BuildContext context,
    required String currentUserId,
    required String blockedUserId,
  }) async {
    try {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Kullanıcıyı Engelle", style: TextStyle(color: Colors.white)),
          content: const Text(
            "Bu kullanıcıyı engellemek istediğine emin misin?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("İptal", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Engelle", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true) return; 

      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .doc(blockedUserId)
          .set({
        'blockedAt': FieldValue.serverTimestamp(),
      });

      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Kullanıcı engellendi."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 2500),
        ),
      );

      if (navigator.canPop()) {
        navigator.pop(); 
      }

    } catch (e) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    }
  }

  static Future<void> unblockUser({
    required BuildContext context,
    required String currentUserId,
    required String blockedUserId,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .doc(blockedUserId)
          .delete();

      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Engelleme kaldırıldı."),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }
}