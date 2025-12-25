import 'package:flutter/material.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class NotificationService {
  
  // GENEL BİLDİRİM GÖNDERME
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

      await FirebaseFirestore.instance.collection(AppConstants.collectionNotifications).add({
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
      print("Bildirim hatası: $e");
    }
  }

  // TAKİP BİLDİRİMİ
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

// Mesaj Bildirimi Gönderme Fonksiyonu
  static Future<void> sendMessageNotification(
    String senderId,
    String senderName,
    String? senderAvatar,
    String receiverId,
    String chatId,
  ) async {
    // Kendi kendine bildirim atmasını engelle
    if (senderId == receiverId) return;

    try {
      await FirebaseFirestore.instance.collection(AppConstants.collectionNotifications).add({
        'receiverId': receiverId,      // Bildirimi alacak kişi
        'senderId': senderId,          // Gönderen kişi
        'senderName': senderName,      // Gönderen adı (ChatScreen'de düzelttiğimiz)
        'senderAvatar': senderAvatar ?? '', // Profil resmi
        'type': 'message',             // KRİTİK: Listeleme sayfasındaki switch-case buraya bakıyor!
        'isRead': false,               // Okunmadı olarak işaretle
        'createdAt': FieldValue.serverTimestamp(), // Sıralama için şart
        'relatedId': chatId,           // Tıklayınca sohbete gitmek için (Opsiyonel)
        'body': 'Sana bir mesaj gönderdi.', 
      });
    } catch (e) {
      debugPrint("Bildirim gönderme hatası: $e");
    }
  }

  // BEĞENİ BİLDİRİMİ
  static Future<void> sendLikeNotification(String currentUserId, String currentUserName, String? currentUserAvatar, String postOwnerId, String postId) async {
    final query = await FirebaseFirestore.instance
        .collection(AppConstants.collectionNotifications)
        .where('senderId', isEqualTo: currentUserId)
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