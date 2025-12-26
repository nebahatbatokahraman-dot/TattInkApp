import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

// --- IMPORTS ---
import '../models/appointment_model.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF161616),
        body: Center(child: Text("Giriş yapmalısınız", style: TextStyle(color: Colors.white))),
      );
    }

    return FutureBuilder(
      future: authService.getUserModel(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF161616),
            body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          );
        }
        
        final userModel = snapshot.data!;
        // Kullanıcı Artist mi Müşteri mi?
        final isArtist = (userModel.role == 'artist' || userModel.role == AppConstants.roleArtistApproved);

        return Scaffold(
          backgroundColor: const Color(0xFF161616),
          appBar: AppBar(
            title: const Text('Randevular', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const BackButton(color: Colors.white),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.collectionAppointments)
                .where(isArtist ? 'artistId' : 'customerId', isEqualTo: user.uid)
                .orderBy('appointmentDate', descending: false) // En yakın tarih en üstte
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
              }

              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey[800]),
                      const SizedBox(height: 16),
                      const Text("Henüz randevu kaydı yok.", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  // Firestore dökümanını senin Model yapına çeviriyoruz
                  final appointment = AppointmentModel.fromFirestore(docs[index]);
                  return _buildAppointmentCard(context, appointment, isArtist);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(BuildContext context, AppointmentModel appointment, bool isArtist) {
    // Enum'a göre renk ve metin belirleme
    Color statusColor;
    String statusText;

    switch (appointment.status) {
      case AppointmentStatus.confirmed:
        statusColor = Colors.green;
        statusText = 'Onaylandı';
        break;
      case AppointmentStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'İptal / Red';
        break;
      case AppointmentStatus.completed:
        statusColor = Colors.grey;
        statusText = 'Tamamlandı';
        break;
      case AppointmentStatus.pending:
      default:
        statusColor = Colors.orange;
        statusText = 'Bekliyor';
    }

    // Basit Tarih Formatlama
    final date = appointment.appointmentDate;
    final dateStr = "${date.day}/${date.month}/${date.year}";
    final timeStr = "${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}";

    // Karşı tarafın adı (Artist ise müşteriyi görsün, Müşteri ise artisti görsün)
    final displayName = isArtist 
        ? (appointment.customerName ?? 'Müşteri') 
        : (appointment.artistName ?? 'Artist');

    return Card(
      color: const Color(0xFF252525),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Kısım: İsim, Tarih ve Statü
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[800],
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$dateStr • $timeStr",
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            
            // Varsa Notlar
            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const Divider(color: Colors.white10, height: 24),
              Text("Not: ${appointment.notes}", style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],

            // Referans Resim Varsa (Posttan geldiyse)
            if (appointment.referenceImageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: appointment.referenceImageUrl!,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(height: 100, color: Colors.grey[900]),
                ),
              ),
            ],
            
            // Eğer Artist ise ve Durum 'Bekliyor' ise Butonları Göster
            if (isArtist && appointment.status == AppointmentStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      // Reddet -> Status: Cancelled
                      onPressed: () => _updateStatus(appointment.id, AppointmentStatus.cancelled),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                      ),
                      child: const Text("Reddet"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      // Onayla -> Status: Confirmed
                      onPressed: () => _updateStatus(appointment.id, AppointmentStatus.confirmed),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("Onayla", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String docId, AppointmentStatus newStatus) async {
    // Modelindeki toMap yapısına veya direkt string olarak güncellemeye dikkat et.
    // Modelde 'status': status.name şeklinde kaydettiğin için burada da .name kullanıyoruz.
    await FirebaseFirestore.instance
        .collection(AppConstants.collectionAppointments)
        .doc(docId)
        .update({
          'status': newStatus.name, // Enum'ı string'e çevirip kaydet
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }
}