import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // BuildContext için gerekli
import '../utils/constants.dart';
import '../screens/appointments_screen.dart'; // Randevular ekranını buraya import et

class NotificationService {
  
  // --- 1. GENEL BİLDİRİM GÖNDERME (ANA METOT) ---
  static Future<void> sendNotification({
    required String currentUserId,      
    required String currentUserName,    
    required String? currentUserAvatar, 
    required String receiverId,         
    required String type,               
    required String title,
    required String body,
    String? relatedId,                  
  }) async {
    try {
      if (currentUserId == receiverId) return;

      final notificationRef = FirebaseFirestore.instance
          .collection(AppConstants.collectionNotifications)
          .doc();

      await notificationRef.set({
        'id': notificationRef.id,
        'senderId': currentUserId,
        'senderName': currentUserName,
        'senderAvatar': currentUserAvatar,
        'receiverId': receiverId,
        'type': type,
        'title': title,
        'body': body,
        'relatedId': relatedId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // NOT: Eğer gerçek zamanlı push notification (FCM) kullanacaksan 
      // buraya bir de http post isteği (Cloud Functions) eklemen gerekecektir.
      // Şu an veritabanına kayıt başarılı.
    } catch (e) {
      debugPrint("Bildirim gönderme hatası: $e");
    }
  }

  // --- 2. TAKİP BİLDİRİMİ ---
  static Future<void> sendFollowNotification(String currentUserId, String currentUserName, String? currentUserAvatar, String targetUserId) async {
     await sendNotification(
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        currentUserAvatar: currentUserAvatar,
        receiverId: targetUserId,
        type: 'follow',
        title: 'Yeni Takipçi',
        body: '$currentUserName seni takip etmeye başladı.',
        relatedId: currentUserId,
      );
  }

  // --- 3. BEĞENİ BİLDİRİMİ ---
  static Future<void> sendLikeNotification(String currentUserId, String currentUserName, String? currentUserAvatar, String postOwnerId, String postId) async {
    final query = await FirebaseFirestore.instance
        .collection(AppConstants.collectionNotifications)
        .where('senderId', isEqualTo: currentUserId)
        .where('receiverId', isEqualTo: postOwnerId)
        .where('relatedId', isEqualTo: postId)
        .where('type', isEqualTo: 'like')
        .get();

    if (query.docs.isEmpty) {
      await sendNotification(
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        currentUserAvatar: currentUserAvatar,
        receiverId: postOwnerId,
        type: 'like',
        title: 'Yeni Beğeni',
        body: '$currentUserName gönderini beğendi.',
        relatedId: postId,
      );
    }
  }

  // --- 4. BİLDİRİM TIKLAMA YÖNETİMİ ---
  // Uygulama içindeki bildirim listesinden tıklandığında veya Push bildiriminden gelindiğinde çalışır
  static void handleNotificationClick(BuildContext context, String type, String? relatedId) {
    if (type == 'appointment_request' || type == 'appointment_update') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AppointmentsScreen()),
      );
    } 
    else if (type == 'follow') {
      // Örnek: Takip edenin profiline gitme mantığı buraya eklenebilir
    }
  }
}