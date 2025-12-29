import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../appointments_screen.dart';

// --- SERVICE & MODELS ---
import '../../services/auth_service.dart';
import '../../models/notification_model.dart';
import '../../models/post_model.dart';
import '../../utils/constants.dart';
import '../../theme/app_theme.dart';

// --- EKRANLAR ---
import '../profile/artist_profile_screen.dart';
import '../chat_screen.dart';
import '../post_detail_screen.dart';
import '../appointments_screen.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  // TÜMÜNÜ OKUNDU İŞARETLE
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

  // YARDIMCI FONKSİYON: Post verisini çekip detay sayfasına gitmek için
  Future<void> _fetchAndNavigateToPost(BuildContext context, String postId, String currentUserId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection(AppConstants.collectionPosts)
          .doc(postId)
          .get();

      if (doc.exists && context.mounted) {
        PostModel post = PostModel.fromFirestore(doc);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(
              posts: [post],
              initialIndex: 0,
              isOwner: post.artistId == currentUserId,
            ),
          ),
        );
      } else {
        if(context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Bu gönderi artık mevcut değil."))
          );
        }
      }
    } catch (e) {
      debugPrint("Post çekme hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthService>(context).currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: Text("Giriş yapmalısınız", style: TextStyle(color: AppTheme.textColor))),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Bildirimler', style: TextStyle(color: AppTheme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => _markAllAsRead(currentUser.uid),
            child: const Text(
              "Okundu",
              style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.collectionNotifications)
            .where('receiverId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
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
              final notification = NotificationModel.fromFirestore(docs[index]);
              return _buildNotificationItem(context, notification, currentUser.uid);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationModel notification, String currentUserId) {
    IconData icon;
    Color iconColor;
    String descriptionText;

    // Dinamik Metin Ayarları
    switch (notification.type) {
      case 'like': 
        icon = Icons.favorite; 
        iconColor = Colors.redAccent; 
        descriptionText = "gönderini beğendi.";
        break;
      case 'follow': 
        icon = Icons.person_add; 
        iconColor = Colors.blueAccent; 
        descriptionText = "seni takip etmeye başladı.";
        break;
      case 'message': 
        icon = Icons.message; 
        iconColor = Colors.greenAccent; 
        descriptionText = "sana mesaj gönderdi.";
        break;
      case 'appointment_request': 
        icon = Icons.calendar_today; 
        iconColor = Colors.orangeAccent; 
        descriptionText = "randevu talebi oluşturdu."; 
        break;
      case 'appointment_update':
        icon = Icons.notifications_active;
        iconColor = AppTheme.primaryColor;
        descriptionText = notification.body ?? "randevu talebinizi güncelledi.";
        break;
      default: 
        icon = Icons.notifications; 
        iconColor = AppTheme.primaryColor;
        descriptionText = "yeni bir bildirim gönderdi.";
    }

    return Container(
      // Okunmamış bildirimlerin arkasını hafifçe vurgular
      color: notification.isRead ? Colors.transparent : AppTheme.primaryColor.withOpacity(0.05),
      child: Theme(
        // TIKLAMA EFEKTİ (Splash Color) düzenlemesi burada yapılıyor
        data: Theme.of(context).copyWith(
          splashColor: AppTheme.cardColor.withOpacity(0.9),
          highlightColor: Colors.transparent,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: GestureDetector(
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => ArtistProfileScreen(userId: notification.senderId)));
            },
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[800],
              backgroundImage: (notification.senderAvatar != null && notification.senderAvatar!.isNotEmpty)
                  ? NetworkImage(notification.senderAvatar!) : null,
              child: (notification.senderAvatar == null || notification.senderAvatar!.isEmpty)
                  ? const Icon(Icons.person, color: AppTheme.textColor) : null,
            ),
          ),
          title: RichText(
            text: TextSpan(
              style: const TextStyle(color: AppTheme.textColor, fontSize: 14),
              children: [
                TextSpan(text: "${notification.senderName} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: descriptionText),
              ],
            ),
          ),
          subtitle: Text(_formatDate(notification.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          
          onTap: () async {
            // 1. Okundu olarak işaretle
            await FirebaseFirestore.instance
                .collection(AppConstants.collectionNotifications)
                .doc(notification.id)
                .update({'isRead': true});

            if (!context.mounted) return;

            // 2. Yönlendirme Mantığı
            if (notification.type == 'follow') {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ArtistProfileScreen(userId: notification.senderId)));
            } 
            else if (notification.type == 'message') {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => ChatScreen(
                  receiverId: notification.senderId,
                  receiverName: notification.senderName,
                  referenceImageUrl: null,
                ),
              ));
            } 
            else if (notification.type == 'like') {
              if (notification.relatedId != null && notification.relatedId!.isNotEmpty) {
                 await _fetchAndNavigateToPost(context, notification.relatedId!, currentUserId);
              }
            }
            // RANDEVU YÖNLENDİRMESİ (Açıldı)
            else if (notification.type == 'appointment_request' || notification.type == 'appointment_update') {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const AppointmentsScreen())
              );
            }
          },
        ),
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