import '../../theme/app_theme.dart';
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
        // İpucu: Firebase Console'daki indeksin "Enabled" (Etkin) olduğundan emin olun.
        stream: FirebaseFirestore.instance
            .collection(AppConstants.collectionArtistApprovals)
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Hata Kontrolü
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Hata: ${snapshot.error}\n\nEğer index hatası ise lütfen Firebase linkine tıklayıp indeksi oluşturun.'),
              ),
            );
          }

          // 2. İlk Yüklenme Durumu (Bağlantı kurulurken)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3. Veri Var mı ve Boş mu Kontrolü
          // 'snapshot.data == null' kontrolü eklendi, böylece anlık kaybolmaların önüne geçilir.
          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.how_to_reg_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Bekleyen onay talebi bulunmuyor.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Veriyi işle
          final approvals = snapshot.data!.docs
              .map((doc) => ArtistApprovalModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: approvals.length,
            itemBuilder: (context, index) {
              final approval = approvals[index];
              
              // Baş harf alırken hata vermemesi için güvenli kontrol
              String initial = approval.firstName.isNotEmpty 
                  ? approval.firstName.substring(0, 1).toUpperCase() 
                  : "?";

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  title: Text(
                    '${approval.firstName} ${approval.lastName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('@${approval.username}', style: const TextStyle(color: Colors.grey)),
                      Text(approval.email),
                      const SizedBox(height: 8),
                      // Durum etiketleri
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            padding: EdgeInsets.zero,
                            label: Text(
                              approval.isApprovedArtist ? 'Onaylı Hesap' : 'Yeni Kayıt',
                              style: const TextStyle(fontSize: 10, color: AppTheme.textColor),
                            ),
                            backgroundColor: approval.isApprovedArtist ? Colors.blue : Colors.orange,
                          ),
                          const Chip(
                            padding: EdgeInsets.zero,
                            label: Text('Beklemede', style: TextStyle(fontSize: 10)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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