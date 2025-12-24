import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/artist_approval_model.dart';
import '../../utils/constants.dart';
import 'artist_detail_screen.dart';

class ArtistApprovalScreen extends StatelessWidget {
  const ArtistApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Onayları'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.collectionArtistApprovals)
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Bekleyen onay talebi yok'),
            );
          }

          final approvals = snapshot.data!.docs
              .map((doc) => ArtistApprovalModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: approvals.length,
            itemBuilder: (context, index) {
              final approval = approvals[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      approval.firstName.substring(0, 1).toUpperCase(),
                    ),
                  ),
                  title: Text('${approval.firstName} ${approval.lastName}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('@${approval.username}'),
                      Text(approval.email),
                      if (approval.isApprovedArtist)
                        const Chip(
                          label: Text('Onaylı Artist'),
                          labelStyle: TextStyle(fontSize: 10),
                        )
                      else
                        const Chip(
                          label: Text('Onaysız Artist'),
                          labelStyle: TextStyle(fontSize: 10),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArtistDetailScreen(
                          approval: approval,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

