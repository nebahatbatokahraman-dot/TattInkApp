import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Resimler için daha iyi
import 'package:timeago/timeago.dart' as timeago; // Zaman formatı için

// --- IMPORTLAR ---
import '../../services/auth_service.dart';
import '../../models/post_model.dart';
import '../../utils/constants.dart';
import '../../theme/app_theme.dart';
import '../../utils/slide_route.dart'; // Animasyonlu geçiş için (varsa)

// --- EKRAN IMPORTLARI ---
import '../chat_screen.dart';
import '../profile/artist_profile_screen.dart';
import '../post_detail_screen.dart';
import '../appointments_screen.dart'; // RANDEVU EKRANI EKLENDİ

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  Stream<QuerySnapshot>? _notificationsStream;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // TimeAgo Türkçe ayarı
    timeago.setLocaleMessages('tr', timeago.TrMessages());

    final authService = Provider.of<AuthService>(context, listen: false);
    _currentUserId = authService.currentUser?.uid;

    if (_currentUserId != null) {
      _notificationsStream = FirebaseFirestore.instance
          .collection(AppConstants.collectionNotifications)
          .where('receiverId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  // --- TÜMÜNÜ OKUNDU İŞARETLE ---
  Future<void> _markAllAsRead() async {
    if (_currentUserId == null) return;
    final query = await FirebaseFirestore.instance
        .collection(AppConstants.collectionNotifications)
        .where('receiverId', isEqualTo: _currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    if (query.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // --- POST DETAYINA GİTME (SENİN KODUN) ---
  Future<void> _handleLikeNavigation(String postId) async {
    try {
      // Yükleniyor göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );

      final doc = await FirebaseFirestore.instance.collection(AppConstants.collectionPosts).doc(postId).get();

      if (mounted) Navigator.pop(context); // Yükleniyor kapat

      if (doc.exists) {
        final post = PostModel.fromFirestore(doc);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                posts: [post],     
                initialIndex: 0,   
                isOwner: _currentUserId == post.artistId, 
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
    if (_currentUserId == null) {
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
            onPressed: _markAllAsRead,
            child: const Text(
              "Tümünü Oku",
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

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              // Model yerine Map kullanıyoruz ki "appointment" gibi yeni alanlar hata vermesin
              final data = doc.data() as Map<String, dynamic>; 
              return _buildNotificationItem(context, doc.id, data, doc.reference);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, String docId, Map<String, dynamic> data, DocumentReference ref) {
    // Verileri güvenli çekelim
    final String type = data['type'] ?? 'unknown';
    final String senderName = data['senderName'] ?? 'Biri';
    final String? senderAvatar = data['senderAvatar'];
    final String senderId = data['senderId'] ?? '';
    final String? relatedId = data['relatedId'];
    final bool isRead = data['isRead'] ?? false;
    final Timestamp? createdAt = data['createdAt'];

    // İkon ve Metin Belirleme
    IconData icon;
    String description;
    
    switch (type) {
      case 'like': 
        icon = Icons.favorite; 
        description = "gönderini beğendi.";
        break;
      case 'follow': 
        icon = Icons.person_add; 
        description = "seni takip etmeye başladı.";
        break;
      case 'message': 
        icon = Icons.message; 
        description = "sana mesaj gönderdi.";
        break;
      case 'appointment_request':
        icon = Icons.calendar_today;
        description = "yeni bir randevu talep etti.";
        break;
      case 'appointment_update':
        icon = Icons.event_available;
        description = "randevu durumunu güncelledi."; // "Onaylandı" veya "Reddedildi" başlıkta yazar
        break;
      default: 
        icon = Icons.notifications;
        description = "bir işlem yaptı.";
    }

    return Container(
      color: isRead ? Colors.transparent : AppTheme.primaryColor.withOpacity(0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // --- AVATAR KISMI ---
        leading: GestureDetector(
          onTap: () {
            if (senderId.isNotEmpty) {
               Navigator.push(context, MaterialPageRoute(builder: (context) => ArtistProfileScreen(userId: senderId)));
            }
          },
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[800],
            backgroundImage: (senderAvatar != null && senderAvatar.isNotEmpty)
                ? CachedNetworkImageProvider(senderAvatar)
                : null,
            child: (senderAvatar == null || senderAvatar.isEmpty)
                ? Icon(icon, color: Colors.white70, size: 20) 
                : null,
          ),
        ),
        // --- METİN KISMI ---
        title: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.white, fontSize: 14),
            children: [
              TextSpan(text: "$senderName ", style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: description),
            ],
          ),
        ),
        // --- TARİH KISMI (TimeAgo) ---
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            createdAt != null ? timeago.format(createdAt.toDate(), locale: 'tr') : '',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
        ),
        
        // --- TIKLAMA İŞLEMİ ---
        onTap: () async {
          // 1. Okundu yap
          await ref.update({'isRead': true});

          if (!context.mounted) return;

          // 2. Yönlendirme
          if (type == 'message') {
            Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  receiverId: senderId,
                  receiverName: senderName,
                )
              )
            );
          } 
          else if (type == 'follow') {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => ArtistProfileScreen(userId: senderId))
            );
          }
          else if (type == 'like' && relatedId != null) {
            _handleLikeNavigation(relatedId);
          }
          else if (type == 'appointment_request' || type == 'appointment_update') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AppointmentsScreen())
            );
          }
        },
      ),
    );
  }
}