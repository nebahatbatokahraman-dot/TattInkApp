import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

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
      // Kişi kendine bildirim göndermesin
      if (currentUserId == receiverId) return;

      // Belge referansı oluştur (ID'yi içine de kaydedebilmek için)
      final notificationRef = FirebaseFirestore.instance
          .collection(AppConstants.collectionNotifications)
          .doc();

      await notificationRef.set({
        'id': notificationRef.id, // Bildirim ID'sini belgeye ekledik, silme/güncelleme için lazım olur
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
    } catch (e) {
      print("Bildirim gönderme hatası: $e");
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
        relatedId: currentUserId, // Profiline tıklanınca gidilebilsin diye
      );
  }

  // --- 3. BEĞENİ BİLDİRİMİ ---
  static Future<void> sendLikeNotification(String currentUserId, String currentUserName, String? currentUserAvatar, String postOwnerId, String postId) async {
    // Daha önce bu gönderi için beğeni bildirimi gitmiş mi kontrol et (Spam önleme)
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
}