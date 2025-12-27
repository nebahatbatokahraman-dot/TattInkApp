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

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthService>(context).currentUser;

    if (currentUser == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mesajlar', style: TextStyle(color: AppTheme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Kullanıcının dahil olduğu sohbetleri getir
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
            separatorBuilder: (context, index) => Divider(color: Colors.grey[900], height: 1),
            itemBuilder: (context, index) {
              final chatDoc = snapshot.data!.docs[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              
              // Konuşulan diğer kişinin ID'sini bul
              final List<dynamic> users = chatData['users'];
              final String otherUserId = users.firstWhere((id) => id != currentUser.uid, orElse: () => '');

              if (otherUserId.isEmpty) return const SizedBox();

              // --- KRİTİK NOKTA: DİĞER KULLANICININ VERİSİNİ CANLI ÇEK ---
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(AppConstants.collectionUsers)
                    .doc(otherUserId)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  // Kullanıcı verisi yüklenirken geçici görünüm
                  if (!userSnapshot.hasData) {
                    return Container(height: 70, color: AppTheme.backgroundColor); 
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  
                  // İsim belirleme (Önce Ad Soyad, yoksa Username, yoksa Mail Başı)
                  String displayName = 'Kullanıcı';
                  String? profileImage;
                  
                  if (userData != null) {
                    displayName = userData['fullName'] ?? userData['username'] ?? 'Kullanıcı';
                    profileImage = userData['profileImageUrl'];
                    
                    // Eğer isim yine boşsa veya mail adresiyse düzelt
                    if (displayName.contains('@')) {
                      displayName = displayName.split('@')[0];
                    }
                  }

                  final lastMessage = chatData['lastMessage'] ?? '';
                  final Timestamp? lastTime = chatData['lastMessageTime'];
                  
                  // Okunmamış mesaj sayısı (Basit bir kontrol, detaylandırılabilir)
                  // Not: Tam okunmamış sayısı için messages koleksiyonuna sorgu gerekir, 
                  // bu örnekte basit tutuyoruz.

                  return ListTile(
                    tileColor: AppTheme.backgroundSecondaryColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.backgroundColor,
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
                      style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (lastTime != null)
                          Text(
                            _formatDate(lastTime.toDate()),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        const SizedBox(height: 4),
                        const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
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
      return DateFormat('EEEE', 'tr_TR').format(date); // Gün adı (Pazartesi vb.)
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}