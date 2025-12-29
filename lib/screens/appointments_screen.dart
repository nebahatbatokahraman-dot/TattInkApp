import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/auth_service.dart';
import '../models/appointment_model.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import 'dart:ui';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController; // Nullable yaptık çünkü müşteri ise buna gerek yok
  bool _isLoading = true;
  bool _isArtist = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  // --- KULLANICI ROLÜNÜ KONTROL ET ---
  Future<void> _checkUserRole() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final uid = authService.currentUser?.uid;

    if (uid != null) {
      final user = await authService.getUserModel(uid);
      if (user != null) {
        // Kullanıcı rolü 'artist' veya 'approved_artist' ise (Senin AppConstants yapına göre)
        // Buradaki kontrolü kendi role yapına göre düzenleyebilirsin
        if (user.role == AppConstants.roleArtistApproved || 
            user.role == AppConstants.roleArtistUnapproved || 
            user.role == 'artist') {
          _isArtist = true;
          _tabController = TabController(length: 2, vsync: this);
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose(); // Sadece tanımlıysa dispose et
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;

    if (currentUserId == null) return const Scaffold(body: Center(child: Text("Giriş yapmalısınız")));

    // Rol kontrolü bitene kadar yükleniyor göster
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    // --- ARTIST GÖRÜNÜMÜ (MEVCUT TAB'LI YAPI) ---
    if (_isArtist) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Randevular', style: TextStyle(color: AppTheme.textColor)),
          backgroundColor: AppTheme.backgroundColor,
          iconTheme: const IconThemeData(color: AppTheme.textColor),
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'Gelen Talepler'),
              Tab(text: 'Randevularım'), // Artistin kendi aldığı randevular (müşteri gibi davrandığı)
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAppointmentList(currentUserId, isArtistView: true),  // Artist'e gelenler
            _buildAppointmentList(currentUserId, isArtistView: false), // Artist'in aldıkları
          ],
        ),
      );
    }

    // --- MÜŞTERİ GÖRÜNÜMÜ (TEK LİSTE - TAB YOK) ---
    else {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Randevularım', style: TextStyle(color: AppTheme.textColor)),
          backgroundColor: AppTheme.backgroundColor,
          iconTheme: const IconThemeData(color: AppTheme.textColor),
        ),
        // Müşteri sadece kendi aldığı randevuları görür (isArtistView: false)
        body: _buildAppointmentList(currentUserId, isArtistView: false),
      );
    }
  }

  Widget _buildAppointmentList(String userId, {required bool isArtistView}) {
    // ArtistView true ise -> Artist ID'sine göre ara (Bana gelenler)
    // ArtistView false ise -> Customer ID'sine göre ara (Benim aldıklarım)
    final String queryField = isArtistView ? 'artistId' : 'customerId';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.collectionAppointments)
          .where(queryField, isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: AppTheme.textColor)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 60, color: Colors.grey[800]),
                const SizedBox(height: 16),
                Text(
                  isArtistView ? 'Henüz gelen bir talep yok.' : 'Henüz randevu almadınız.',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final appointments = snapshot.data!.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            return _buildAppointmentCard(appointment, isArtistView);
          },
        );
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment, bool isArtistView) {
    Color statusColor;
    String statusText;

    switch (appointment.status) {
      case AppointmentStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Bekliyor';
        break;
      case AppointmentStatus.confirmed:
        statusColor = Colors.green;
        statusText = 'Onaylandı';
        break;
      case AppointmentStatus.rejected:
        statusColor = Colors.red;
        statusText = 'Reddedildi';
        break;
      case AppointmentStatus.completed:
        statusColor = Colors.blue;
        statusText = 'Tamamlandı';
        break;
      case AppointmentStatus.cancelled:
         statusColor = Colors.grey;
        statusText = 'İptal Edildi';
        break;
    }

    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // İsim Alanı (Güvenli)
                Expanded(
                  child: Text(
                    isArtistView 
                        ? ((appointment.customerName != null && appointment.customerName!.isNotEmpty) 
                            ? appointment.customerName! 
                            : 'Müşteri')
                        : ((appointment.artistName != null && appointment.artistName!.isNotEmpty) 
                            ? appointment.artistName! 
                            : 'Artist'),
                    style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(appointment.appointmentDate),
                  style: const TextStyle(color: AppTheme.textColor),
                ),
              ],
            ),
            
            if (appointment.referenceImageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: appointment.referenceImageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[900]),
                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.grey),
                ),
              ),
            ],

            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                "Not: ${appointment.notes}",
                style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],

            // Artist İşlem Butonları (Sadece Bekliyorsa ve Artist Bakıyorsa)
            if (isArtistView && appointment.status == AppointmentStatus.pending) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _updateStatus(appointment, AppointmentStatus.rejected),
                    child: const Text('Reddet', style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _updateStatus(appointment, AppointmentStatus.confirmed),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Onayla', style: TextStyle(color: AppTheme.textColor)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- GÜNCELLENEN FONKSİYON (Bildirimli Versiyon) ---
  Future<void> _updateStatus(AppointmentModel appointment, AppointmentStatus newStatus) async {
    try {
      // 1. Veritabanında durumu güncelle
      await FirebaseFirestore.instance
          .collection(AppConstants.collectionAppointments)
          .doc(appointment.id)
          .update({
        'status': newStatus.name,
      });

      // 2. Bildirim Hazırla
      String title = '';
      String body = '';
      
      if (newStatus == AppointmentStatus.confirmed) {
        title = 'Randevunuz Onaylandı! ✅';
        body = 'randevu talebinizi kabul etti.';
      } else if (newStatus == AppointmentStatus.rejected) {
        title = 'Randevu Reddedildi ❌';
        body = 'randevu talebinizi maalesef kabul edemedi.';
      }

      // 3. Bildirimi Gönder
      if (title.isNotEmpty) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final currentUserId = authService.currentUser?.uid;
        
        if (currentUserId != null) {
          final artistUser = await authService.getUserModel(currentUserId);
          
          String senderName = 'Artist';
          String? senderAvatar;
          
          if (artistUser != null) {
            senderName = (artistUser.fullName != null && artistUser.fullName!.isNotEmpty) 
                ? artistUser.fullName! 
                : (artistUser.username ?? 'Artist');
            senderAvatar = artistUser.profileImageUrl;
          } else {
            senderName = appointment.artistName ?? 'Artist';
          }

          await NotificationService.sendNotification(
            currentUserId: currentUserId,
            currentUserName: senderName,
            currentUserAvatar: senderAvatar,
            receiverId: appointment.customerId,
            title: title,
            body: '$senderName $body',
            type: 'appointment_update',
            relatedId: appointment.id,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == AppointmentStatus.confirmed ? 'Randevu onaylandı' : 'Randevu reddedildi'),
            backgroundColor: newStatus == AppointmentStatus.confirmed ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }
}