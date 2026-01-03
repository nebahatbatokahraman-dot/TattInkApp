import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../services/report_service.dart';
import '../../app_localizations.dart'; // Çeviri sınıfını ekledik

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        title: Text(
          AppLocalizations.of(context)!.translate('blocked_users_title'), 
          style: const TextStyle(color: AppTheme.textColor)
        ),
        leading: const BackButton(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('blocked_users')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.translate('no_blocked_users'), 
                style: const TextStyle(color: Colors.white54)
              ),
            );
          }

          final blockedDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: blockedDocs.length,
            itemBuilder: (context, index) {
              final blockedUserId = blockedDocs[index].id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(blockedUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox();

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  if (userData == null) return const SizedBox(); 

                  final username = userData['username'] ?? AppLocalizations.of(context)!.translate('user_default');
                  final photoUrl = userData['profileImageUrl'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[800],
                      backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
                      child: photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                    ),
                    title: Text(username, style: const TextStyle(color: Colors.white)),
                    trailing: TextButton(
                      onPressed: () {
                        ReportService.unblockUser(
                          context: context, 
                          currentUserId: currentUser.uid, 
                          blockedUserId: blockedUserId
                        );
                      },
                      child: Text(
                        AppLocalizations.of(context)!.translate('unblock'), 
                        style: const TextStyle(color: Colors.redAccent)
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
}