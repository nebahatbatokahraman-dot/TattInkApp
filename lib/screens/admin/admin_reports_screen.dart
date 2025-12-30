import 'report_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../profile/artist_profile_screen.dart';
import '../profile/customer_profile_screen.dart';
import 'package:intl/intl.dart'; // Tarih formatlamak için gerekli (Dosyanın başında pubspec.yaml'da intl varsa çalışır)

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  // 1. ŞİKAYETİ YOKSAY (SİL)
  Future<void> _ignoreReport(String reportId) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();
  }

  // 2. KULLANICIYI BANLA
  Future<void> _banUser(BuildContext context, String userId, String reportId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isBanned': true,
      });
      await _ignoreReport(reportId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kullanıcı süresiz olarak yasaklandı."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print("Ban hatası: $e");
    }
  }

  // --- TAM EKRAN RESİM GÖSTERİCİ ---
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 5.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
                errorBuilder: (context, error, stackTrace) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white54, size: 60),
                    SizedBox(height: 10),
                    Text("Resim yüklenemedi", style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 3. İÇERİĞİ / PROFİLİ İNCELE (5. MADDE: AYRI SAYFAYA YÖNLENDİRME)
  void _inspectContent(BuildContext context, String reportId, Map<String, dynamic> reportData) {
    // Burada artık pop-up açmıyoruz, 
    // şikayet verilerini paketleyip yeni oluşturduğumuz sayfaya gönderiyoruz.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(
          reportId: reportId,
          reportData: reportData,
        ),
      ),
    );
  }

  // --- YARDIMCI FONKSİYON: TARİHİ FORMATLA ---
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Bilinmiyor";
    try {
      DateTime date = timestamp.toDate();
      // Örnek: 30 Ara 14:20
      return DateFormat('dd MMM HH:mm', 'tr_TR').format(date);
    } catch (e) {
      return "Bilinmiyor";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Tattink Admin - Raporlar"),
        backgroundColor: Colors.redAccent[700],
        elevation: 10,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // --- BURASI GÜNCELLENDİ: Sıralama eklendi ---
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user, size: 100, color: Colors.green.withOpacity(0.3)),
                  const SizedBox(height: 20),
                  const Text("Aktif şikayet bulunmuyor!", style: TextStyle(color: Colors.white54, fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final reportDoc = snapshot.data!.docs[index];
              final data = reportDoc.data() as Map<String, dynamic>;
              
              final reason = data['reason'] ?? 'Belirsiz';
              final contentType = data['contentType'] ?? 'Genel';
              final reportId = reportDoc.id;
              final Timestamp? timestamp = data['timestamp'] as Timestamp?;

              // --- 3. MADDE: BAŞLIK VE RENK BELİRLEME ---
              Color typeColor;
              IconData typeIcon;
              String typeTitle;

              if (contentType == 'chat') {
                typeColor = Colors.blueAccent;
                typeIcon = Icons.chat;
                typeTitle = "Mesaj Şikayeti";
              } else if (contentType == 'post') {
                typeColor = Colors.orangeAccent;
                typeIcon = Icons.photo_library;
                typeTitle = "Gönderi Şikayeti";
              } else {
                typeColor = Colors.purpleAccent;
                typeIcon = Icons.person;
                typeTitle = "Profil Şikayeti";
              }

              return InkWell(
                onTap: () => _inspectContent(context, reportId, data), // Artık sadece id ve datayı gönderiyoruz
                child: Card(
                  elevation: 8,
                  margin: const EdgeInsets.only(bottom: 20),
                  color: AppTheme.cardColor,
                  shadowColor: Colors.black54,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    children: [
                      // Renkli Başlık Şeridi
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.15),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                        child: Row(
                          children: [
                            Icon(typeIcon, color: typeColor, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              typeTitle, 
                              style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 14)
                            ),
                            const Spacer(),
                            // --- YENİ EKLENEN TARİH ETİKETİ ---
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _formatTimestamp(timestamp), 
                                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- 4. MADDE: MİNİK PUNTOLU GEREKÇE ---
                            const Text(
                              "ŞİKAYET GEREKÇESİ", 
                              style: TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.bold)
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reason, 
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "ID: ${reportId.substring(0, 6)}", 
                                  style: const TextStyle(color: Colors.white10, fontSize: 10)
                                ),
                                const Row(
                                  children: [
                                    Text(
                                      "Detayları incelemek için dokunun", 
                                      style: TextStyle(color: Colors.white24, fontSize: 11, fontStyle: FontStyle.italic)
                                    ),
                                    SizedBox(width: 5),
                                    Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white24),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}