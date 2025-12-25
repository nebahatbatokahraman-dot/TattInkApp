import '../chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../models/notification_model.dart';
import '../../models/post_model.dart';
import '../../utils/constants.dart';
import '../../theme/app_theme.dart';
import '../profile/artist_profile_screen.dart';
import '../post_detail_screen.dart'; // YENİ EKRANI IMPORT ETTİK

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  Stream<QuerySnapshot>? _notificationsStream;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _currentUser = authService.currentUser;

    if (_currentUser != null) {
      _notificationsStream = FirebaseFirestore.instance
          .collection(AppConstants.collectionNotifications)
          .where('receiverId', isEqualTo: _currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  Future<void> _markAllAsRead(String userId) async {
    final query = await FirebaseFirestore.instance
        .collection(AppConstants.collectionNotifications)
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    if (query.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // --- POST DETAYINA GİTME FONKSİYONU (DÜZELTİLDİ) ---
  Future<void> _handleLikeNavigation(String postId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );

      final doc = await FirebaseFirestore.instance.collection(AppConstants.collectionPosts).doc(postId).get();

      if (mounted) Navigator.pop(context); // Loading kapat

      if (doc.exists) {
        final post = PostModel.fromFirestore(doc);
        if (mounted) {
          // YENİ EKRANA YÖNLENDİRME
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                posts: [post],     // <-- TEK POSTU LİSTE YAPTIK
                initialIndex: 0,   // <-- INDEX 0
                isOwner: true, 
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bu gönderi silinmiş olabilir.")));
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      debugPrint("Post açma hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF161616),
        body: Center(child: Text("Giriş yapmalısınız", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF161616),
      appBar: AppBar(
        title: const Text('Bildirimler', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => _markAllAsRead(_currentUser!.uid),
            child: const Text(
              "Okundu",
              style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[800]),
                  const SizedBox(height: 16),
                  const Text("Henüz bildirim yok", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              try {
                final notification = NotificationModel.fromFirestore(docs[index]);
                return _buildNotificationItem(context, notification);
              } catch (e) {
                return const SizedBox.shrink();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationModel notification) {
    IconData icon;
    switch (notification.type) {
      case 'like': icon = Icons.favorite; break;
      case 'follow': icon = Icons.person_add; break;
      case 'message': icon = Icons.message; break;
      default: icon = Icons.notifications;
    }

    return Container(
      color: notification.isRead ? Colors.transparent : const Color(0xFF252525).withOpacity(0.5),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[800],
          backgroundImage: (notification.senderAvatar != null && notification.senderAvatar!.isNotEmpty)
              ? NetworkImage(notification.senderAvatar!) : null,
          child: (notification.senderAvatar == null || notification.senderAvatar!.isEmpty)
              ? const Icon(Icons.person, color: Colors.white) : null,
        ),
        title: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.white, fontSize: 14),
            children: [
              TextSpan(text: "${notification.senderName} ", style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(
                text: notification.type == 'like' ? "gönderini beğendi." : 
                      notification.type == 'follow' ? "seni takip etmeye başladı." : "sana mesaj gönderdi."
              ),
            ],
          ),
        ),
        subtitle: Text(_formatDate(notification.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        
        onTap: () async {
          await FirebaseFirestore.instance
              .collection(AppConstants.collectionNotifications)
              .doc(notification.id)
              .update({'isRead': true});

          if (!context.mounted) return;

          if (notification.type == 'message') {
            Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  receiverId: notification.senderId,
                  receiverName: notification.senderName,
                  referenceImageUrl: null,
                )
              )
            );
          } 
          else if (notification.type == 'follow') {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => ArtistProfileScreen(userId: notification.senderId))
            );
          }
          else if (notification.type == 'like') {
            if (notification.relatedId != null && notification.relatedId!.isNotEmpty) {
              _handleLikeNavigation(notification.relatedId!);
            } else {
               Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => ArtistProfileScreen(userId: notification.senderId))
              );
            }
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes}dk önce";
    if (diff.inHours < 24) return "${diff.inHours}sa önce";
    return "${diff.inDays}g önce";
  }
}