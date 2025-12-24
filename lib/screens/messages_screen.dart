import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/message_model.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/slide_route.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Lütfen mesajlarınızı görmek için giriş yapın.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlarım', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.collectionMessages)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Henüz bir mesajlaşma bulunmuyor.'));
          }

          final chatGroups = <String, MessageModel>{};
          final unreadCounts = <String, int>{};

          for (var doc in snapshot.data!.docs) {
            final msg = MessageModel.fromFirestore(doc);
            if (msg.senderId == currentUserId || msg.receiverId == currentUserId) {
              if (!chatGroups.containsKey(msg.chatId)) {
                chatGroups[msg.chatId] = msg;
              }
              if (msg.receiverId == currentUserId && !msg.isRead) {
                unreadCounts[msg.chatId] = (unreadCounts[msg.chatId] ?? 0) + 1;
              }
            }
          }

          final chatList = chatGroups.values.toList();

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chatList.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white10),
            itemBuilder: (context, index) {
              final chat = chatList[index];
              final bool isMeSender = chat.senderId == currentUserId;
              final int unreadCount = unreadCounts[chat.chatId] ?? 0;
              final bool hasUnread = unreadCount > 0;

              // Konuştuğumuz diğer kişinin ID'si
              final String otherUserId = isMeSender ? chat.receiverId : chat.senderId;

              // Karşı tarafın bilgilerini Firestore'dan anlık çekiyoruz
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection(AppConstants.collectionUsers).doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  String displayName = "Yükleniyor...";
                  String? displayImage;

                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    // Eğer sanatçı ise studioName, değilse fullName kullan
                    displayName = userData['studioName']?.toString().isNotEmpty == true 
                        ? userData['studioName'] 
                        : (userData['fullName'] ?? "Kullanıcı");
                    displayImage = userData['profileImageUrl'];
                  }

                  return Container(
                    color: hasUnread ? AppTheme.primaryColor.withOpacity(0.05) : Colors.transparent,
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          SlideRoute(
                            page: ChatScreen(
                              receiverId: otherUserId,
                              receiverName: displayName,
                            ),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: displayImage != null
                            ? CachedNetworkImageProvider(displayImage)
                            : null,
                        child: displayImage == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: hasUnread ? FontWeight.w900 : FontWeight.bold,
                          fontSize: 16,
                          color: hasUnread ? Colors.white : Colors.white.withOpacity(0.9),
                        ),
                      ),
                      subtitle: Text(
                        chat.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasUnread ? Colors.white : Colors.grey[400],
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatDateTime(chat.createdAt),
                            style: TextStyle(
                              fontSize: 12, 
                              color: hasUnread ? AppTheme.primaryColor : Colors.grey,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (hasUnread)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays == 0) {
      return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} g önce";
    } else {
      return "${dateTime.day}.${dateTime.month}";
    }
  }
}