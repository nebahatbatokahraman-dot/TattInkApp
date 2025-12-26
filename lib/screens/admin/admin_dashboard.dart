import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Eksik olan import eklendi
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart'; // AppConstants için gerekli
import '../../theme/app_theme.dart';   // AppTheme için gerekli
import 'artist_approval_screen.dart';

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
          // Güvenlik kontrolü
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
                  // Veri yüklenirken veya hata oluşursa 0 göster
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
                            color: Colors.white, 
                            fontSize: 16, 
                            fontWeight: FontWeight.w500
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$count",
                          style: const TextStyle(
                            color: Colors.white, 
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

              // --- LİSTE KARTLARI ---
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)
                ),
                child: ListTile(
                  // Burada 'const' sildik çünkü color dinamik AppTheme'den geliyor
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
            ],
          );
        },
      ),
    );
  }
}