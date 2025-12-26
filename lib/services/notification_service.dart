import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class NotificationService {
  
  // --- ANA BİLDİRİM GÖNDERME FONKSİYONU ---
  static Future<void> sendNotification({
    required String receiverId,
    required String senderId,     
    required String title,
    required String body,
    required String type,
    String? senderName,            
    String? senderAvatar,          
    String? relatedId,             
  }) async {
    try {
      if (senderId == receiverId) return;

      await FirebaseFirestore.instance.collection(AppConstants.collectionNotifications).add({
        'receiverId': receiverId,
        'senderId': senderId,
        'senderName': senderName ?? '',
        'senderAvatar': senderAvatar ?? '',
        'title': title,
        'body': body,
        'type': type,
        'relatedId': relatedId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Bildirim hatası: $e");
    }
  }

  // --- RANDEVU BİLDİRİMİ ---
  static Future<void> sendAppointmentNotification({
    required String receiverId,
    required String senderId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    await sendNotification(
      receiverId: receiverId,
      senderId: senderId,
      title: title,
      body: body,
      type: type,
      relatedId: relatedId,
    );
  }

  // --- TAKİP BİLDİRİMİ ---
  static Future<void> sendFollowNotification(
    String senderId,      
    String senderName,      
    String? senderAvatar,   
    String targetUserId     
  ) async {
     await sendNotification(
        receiverId: targetUserId,
        senderId: senderId,          
        senderName: senderName,
        senderAvatar: senderAvatar,
        type: 'follow',
        title: 'Yeni Takipçi',
        body: '$senderName seni takip etmeye başladı.',
        relatedId: senderId,          
      );
  }

  // --- MESAJ BİLDİRİMİ ---
  static Future<void> sendMessageNotification(
    String senderId,
    String senderName,
    String? senderAvatar,
    String receiverId,
    String chatId,
  ) async {
    await sendNotification(
      receiverId: receiverId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: 'message',
      title: senderName,
      body: 'Sana bir mesaj gönderdi.',
      relatedId: chatId,
    );
  }

  // --- BEĞENİ BİLDİRİMİ ---
  static Future<void> sendLikeNotification(
    String senderId,      
    String senderName,    
    String? senderAvatar, 
    String postOwnerId,   
    String postId         
  ) async {
    final query = await FirebaseFirestore.instance
        .collection(AppConstants.collectionNotifications)
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: postOwnerId)
        .where('relatedId', isEqualTo: postId)
        .where('type', isEqualTo: 'like')
        .get();

    if (query.docs.isEmpty) {
      await sendNotification(
        receiverId: postOwnerId,
        senderId: senderId,           
        senderName: senderName,
        senderAvatar: senderAvatar,
        type: 'like',
        title: 'Yeni Beğeni',
        body: '$senderName gönderini beğendi.',
        relatedId: postId,
      );
    }
  }
}