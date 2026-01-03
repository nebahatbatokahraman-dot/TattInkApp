import '../../theme/app_theme.dart';
import 'admin_stats_screen.dart';
import 'send_notification_screen.dart';
import 'ad_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart'; 
import 'artist_approval_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_ads_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
      ),
      body: FutureBuilder<UserModel?>(
        future: user != null ? authService.getUserModel(user.uid) : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final adminUser = snapshot.data;
          if (adminUser == null || adminUser.role != 'admin') {
            return const Center(
              child: Text('Bu sayfaya erişim yetkiniz yok'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- BEKLEYEN ONAY SAYACI ---
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(AppConstants.collectionArtistApprovals)
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  int count = (snapshot.hasData) ? snapshot.data!.docs.length : 0;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor, 
                          AppTheme.primaryColor.withOpacity(0.7)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Bekleyen Onay Talebi",
                          style: TextStyle(
                            color: AppTheme.textColor, 
                            fontSize: 16, 
                            fontWeight: FontWeight.w500
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$count",
                          style: const TextStyle(
                            color: AppTheme.textColor, 
                            fontSize: 48, 
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // --- 1. MADDE: ŞİKAYET YÖNETİMİ (YANDAN KAYARAK AÇILMA EKLENDİ) ---
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('reports').snapshots(),
                  builder: (context, snapshot) {
                    int reportCount = 0;
                    if (snapshot.hasData) {
                      reportCount = snapshot.data!.docs.length;
                    }

                    return ListTile(
                      leading: const Icon(
                        Icons.report_problem_rounded, 
                        size: 30, 
                        color: Colors.redAccent
                      ),
                      title: const Text(
                        'Şikayet Yönetimi', 
                        style: TextStyle(fontWeight: FontWeight.bold)
                      ),
                      subtitle: const Text('Gelen kullanıcı şikayetlerini incele'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (reportCount > 0)
                            Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "$reportCount", 
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                              ),
                            ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () {
                        // --- ÖZEL YANDAN KAYMA EFEKTİ ---
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const AdminReportsScreen(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0); // Sağdan başla
                              const end = Offset.zero; // Ortada bitir
                              const curve = Curves.easeInOut;
                              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                              var offsetAnimation = animation.drive(tween);
                              return SlideTransition(position: offsetAnimation, child: child);
                            },
                          ),
                        );
                      },
                    );
                  }
                ),
              ),

              // --- ARTİST ONAYLARI ---
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.how_to_reg, 
                    size: 30, 
                    color: AppTheme.primaryColor
                  ),
                  title: const Text(
                    'Artist Onayları', 
                    style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: const Text('Bekleyen artist başvurularını görüntüle'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ArtistApprovalScreen(),
                      ),
                    );
                  },
                ),
              ),

              // --- REKLAM YÖNETİMİ ---
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  // İkonu 'campaign' yaparsan reklam olduğu daha belli olur, ama ad_units de kalabilir.
                  leading: const Icon(Icons.campaign, size: 30, color: AppTheme.primaryColor),
                  title: const Text('Reklamları Yönet', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Anasayfa kampanya kartlarını düzenle'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // GÜNCELLEME BURADA: Gelişmiş olan sayfaya yönlendiriyoruz
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminAdsScreen()),
                    );
                  },
                ),
              ),

              // --- TOPLU BİLDİRİM GÖNDER ---
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.notification_add, size: 30, color: Colors.orange),
                  title: const Text('Toplu Bildirim Gönder', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Müşterilere veya artistlere duyuru yap'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SendNotificationScreen()),
                    );
                  },
                ),
              ),

              // --- DETAYLI İSTATİSTİKLER ---
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.bar_chart_rounded, size: 30, color: Colors.blueAccent),
                  title: const Text('Detaylı İstatistikler', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Kullanıcı dağılımı ve popülerlik analizleri'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminStatsScreen()),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}