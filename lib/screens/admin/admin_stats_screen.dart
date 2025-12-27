import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Genel Analiz')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Uygulama Özeti", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // 1. GENEL SAYILAR (Müşteri vs Artist)
            _buildUserDistribution(),
            
            const SizedBox(height: 24),
            const Text("Sanatçı Listesi (Popülerlik)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // 2. LİSTELEME
            _buildTopArtists(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDistribution() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(AppConstants.collectionUsers).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Veri okunamadı"));
        if (!snapshot.hasData) return const LinearProgressIndicator();
        
        final users = snapshot.data!.docs;
        
        int customers = users.where((u) {
          final data = u.data() as Map<String, dynamic>;
          return data['role'] == 'customer';
        }).length;

        int artists = users.where((u) {
          final data = u.data() as Map<String, dynamic>;
          // 'artist' veya 'artist_approved' içeren her şeyi sayıyoruz
          return data['role'].toString().contains('artist');
        }).length;

        return Row(
          children: [
            _statBox("Toplam Müşteri", customers.toString(), Colors.purple),
            const SizedBox(width: 12),
            _statBox("Toplam Sanatçı", artists.toString(), Colors.teal),
          ],
        );
      },
    );
  }

  Widget _buildTopArtists() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .snapshots(), // orderBy kullanmıyoruz (Index hatasını önlemek için)
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Hata: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        // Artist olanları ayıkla ve manuel sırala
        final List<DocumentSnapshot> artists = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['role'].toString().contains('artist');
        }).toList();

        artists.sort((a, b) {
          final aLikes = (a.data() as Map<String, dynamic>)['totalLikes'] ?? 0;
          final bLikes = (b.data() as Map<String, dynamic>)['totalLikes'] ?? 0;
          return bLikes.compareTo(aLikes);
        });

        if (artists.isEmpty) return const Text("Henüz sanatçı kaydı yok.");

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: artists.length > 10 ? 10 : artists.length,
          itemBuilder: (context, index) {
            final data = artists[index].data() as Map<String, dynamic>;
            final String name = data['fullName'] ?? data['username'] ?? 'İsimsiz';
            final int likes = data['totalLikes'] ?? 0;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.grey[800],
                backgroundImage: (data['profileImageUrl'] != null && data['profileImageUrl'] != "")
                    ? NetworkImage(data['profileImageUrl'])
                    : null,
                child: data['profileImageUrl'] == null ? const Icon(Icons.person, color: AppTheme.textColor) : null,
              ),
              title: Text(name),
              subtitle: Text("$likes Beğeni"),
              trailing: index < 3 
                ? const Icon(Icons.emoji_events, color: Colors.amber)
                : Text("#${index + 1}", style: const TextStyle(color: Colors.grey)),
            );
          },
        );
      },
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppTheme.textColor, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}