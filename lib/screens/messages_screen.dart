import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/slide_route.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  // --- SİLME İŞLEMİ (SOHBETİ GİZLEME VE TÜM MESAJLARI "BENDEN SİL" YAPMA) ---
  Future<void> _deleteChat(BuildContext context, String chatId, String currentUserId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Kullanıcıyı sohbetin aktif kullanıcılar listesinden çıkar
      final chatRef = FirebaseFirestore.instance.collection(AppConstants.collectionChats).doc(chatId);
      batch.update(chatRef, {
        'users': FieldValue.arrayRemove([currentUserId])
      });

      // 2. Bu sohbetteki TÜM mesajları bu kullanıcı için silinmiş işaretle
      final messagesQuery = await FirebaseFirestore.instance
          .collection(AppConstants.collectionMessages)
          .where('chatId', isEqualTo: chatId)
          .get();

      for (var doc in messagesQuery.docs) {
        batch.update(doc.reference, {
          'deletedBy': FieldValue.arrayUnion([currentUserId])
        });
      }

      await batch.commit();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sohbet ve geçmişi benden silindi"), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      debugPrint("Sohbet silinemedi: $e");
    }
  }

  // --- SİLME MENÜSÜ ---
  void _showDeleteOption(BuildContext context, String chatId, String currentUserId, String otherUserName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor.withOpacity(0.95), // Okunabilirlik için opaklık artırıldı
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
            ),
            Text(
              "$otherUserName ile sohbeti benden sil?",
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Bu işlem sohbet geçmişini sadece sizin ekranınızdan temizler.",
              style: TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            InkWell(
              onTap: () {
                Navigator.pop(context); 
                _deleteChat(context, chatId, currentUserId); 
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Text("Konuşmayı Benden Sil", style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Center(
                  child: Text("İptal", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthService>(context).currentUser;

    if (currentUser == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor, 
      
      appBar: AppBar(
        title: const Text('Mesajlar', style: TextStyle(color: AppTheme.textColor)),
        backgroundColor: AppTheme.backgroundColor, 
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0, 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.collectionChats)
            .where('users', arrayContains: currentUser.uid)
            .orderBy('updatedAt', descending: true)
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
                  Icon(Icons.mail_outline, size: 80, color: Colors.grey[800]),
                  const SizedBox(height: 16),
                  const Text("Henüz mesajınız yok", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => Divider(color: Colors.grey[850], height: 1),
            itemBuilder: (context, index) {
              final chatDoc = snapshot.data!.docs[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              final String chatId = chatDoc.id; 
              
              final List<dynamic> users = chatData['users'];
              final String otherUserId = users.firstWhere((id) => id != currentUser.uid, orElse: () => '');

              if (otherUserId.isEmpty) return const SizedBox();

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(AppConstants.collectionUsers)
                    .doc(otherUserId)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return Container(height: 70, color: Colors.transparent); 

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  
                  String displayName = 'Kullanıcı';
                  String? profileImage;
                  
                  if (userData != null) {
                    displayName = userData['fullName'] ?? userData['username'] ?? 'Kullanıcı';
                    profileImage = userData['profileImageUrl'];
                    if (displayName.contains('@')) displayName = displayName.split('@')[0];
                  }

                  final lastMessage = chatData['lastMessage'] ?? '';
                  final Timestamp? lastTime = chatData['lastMessageTime'];
                  
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(AppConstants.collectionMessages)
                        .where('chatId', isEqualTo: chatId)
                        .where('receiverId', isEqualTo: currentUser.uid) 
                        .where('isRead', isEqualTo: false) 
                        .snapshots(),
                    builder: (context, unreadSnapshot) {
                      
                      int unreadCount = 0;
                      if (unreadSnapshot.hasData) {
                        unreadCount = unreadSnapshot.data!.docs.length;
                      }

                      final bool hasUnread = unreadCount > 0;

                      // --- GÜNCELLEME: DISMISSIBLE (KAYDIRARAK SİLME) ---
                      return Dismissible(
                        key: Key(chatId),
                        direction: DismissDirection.endToStart, // Sağdan sola kaydırma
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.redAccent.withOpacity(0.8),
                          child: const Icon(Icons.delete_sweep, color: Colors.white, size: 30),
                        ),
                        confirmDismiss: (direction) async {
                          final bool? res = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: AppTheme.cardColor,
                                title: const Text("Sohbeti Sil", style: TextStyle(color: Colors.white)),
                                content: Text("$displayName ile olan sohbet geçmişini silmek istediğinize emin misiniz?", style: const TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text("İPTAL", style: TextStyle(color: Colors.grey)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text("SİL", style: TextStyle(color: Colors.redAccent)),
                                  ),
                                ],
                              );
                            },
                          );
                          return res;
                        },
                        onDismissed: (direction) {
                          _deleteChat(context, chatId, currentUser.uid);
                        },
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            // --- BURADAN RENKLERİ AYARLAYABİLİRSİN ---
                            highlightColor: AppTheme.cardColor, // Basılı tutunca arkada kalan renk
                            splashColor: AppTheme.cardColor,    // Tıklayınca yayılan dalga efekti
                          ),
                          child: ListTile(
                            tileColor: hasUnread 
                                ? AppTheme.cardLightColor.withOpacity(0.3)
                                : AppTheme.cardColor.withOpacity(0.3),
                            
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey[800],
                              backgroundImage: (profileImage != null && profileImage.isNotEmpty)
                                  ? NetworkImage(profileImage)
                                  : null,
                              child: (profileImage == null || profileImage.isEmpty)
                                  ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?', 
                                      style: const TextStyle(color: AppTheme.textColor))
                                  : null,
                            ),
                            
                            title: Text(
                              displayName,
                              style: TextStyle(
                                color: Colors.white, 
                                fontWeight: hasUnread ? FontWeight.w900 : FontWeight.bold, 
                                fontSize: 16
                              ),
                            ),
                            
                            subtitle: Text(
                              lastMessage.startsWith('http') && lastMessage.contains('firebasestorage') 
                                  ? '📷 Fotoğraf' 
                                  : lastMessage,
                              style: TextStyle(
                                color: hasUnread ? Colors.grey : Colors.grey[500], 
                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (lastTime != null)
                                  Text(
                                    _formatDate(lastTime.toDate()),
                                    style: TextStyle(
                                      color: hasUnread ? AppTheme.primaryLightColor : Colors.grey[600],
                                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12
                                    ),
                                  ),
                                
                                const SizedBox(height: 6),
                                
                                if (hasUnread)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  )
                                else
                                  Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[700]),
                              ],
                            ),
                            
                            onTap: () {
                              Navigator.push(
                                context,
                                SlideRoute(page: ChatScreen(
                                  receiverId: otherUserId,
                                  receiverName: displayName,
                                )),
                              );
                            },
                            onLongPress: () {
                              _showDeleteOption(context, chatId, currentUser.uid, displayName);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE', 'tr_TR').format(date); 
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}