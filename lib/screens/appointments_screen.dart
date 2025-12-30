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
  TabController? _tabController; 
  bool _isLoading = true;
  bool _isArtist = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final uid = authService.currentUser?.uid;

    if (uid != null) {
      final user = await authService.getUserModel(uid);
      if (user != null) {
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
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;

    if (currentUserId == null) return const Scaffold(body: Center(child: Text("Giriş yapmalısınız")));

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

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
              Tab(text: 'Randevularım'), 
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAppointmentList(currentUserId, isArtistView: true), 
            _buildAppointmentList(currentUserId, isArtistView: false),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Randevularım', style: TextStyle(color: AppTheme.textColor)),
          backgroundColor: AppTheme.backgroundColor,
          iconTheme: const IconThemeData(color: AppTheme.textColor),
        ),
        body: _buildAppointmentList(currentUserId, isArtistView: false),
      );
    }
  }

  Widget _buildAppointmentList(String userId, {required bool isArtistView}) {
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final appointment = AppointmentModel.fromFirestore(doc);
            final Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
            
            return _buildAppointmentCard(appointment, isArtistView, docData);
          },
        );
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment, bool isArtistView, Map<String, dynamic> docData) {
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

    final Timestamp? requestedDateTs = docData['requestedDate'];
    final DateTime? requestedDate = requestedDateTs?.toDate();
    final String? requestedBy = docData['requestedBy'];
    final String? cancelledBy = docData['cancelledBy']; // YENİ: İptal eden bilgisi

    // --- YENİ: TARİH KONTROLÜ (Zamanı geçti mi?) ---
    final bool isExpired = appointment.appointmentDate.isBefore(DateTime.now());

    // --- BUTON STİLİ (YAZILARI YAKLAŞTIRAN AYAR) ---
    final ButtonStyle tightButtonStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 4), // İç boşluğu kıstık
      minimumSize: Size.zero, // Minimum genişlik engelini kaldırdık
      tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Tıklama alanını sıkıştırdık
    );

    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isArtistView 
                        ? (appointment.customerName ?? 'Müşteri')
                        : (appointment.artistName ?? 'Artist'),
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

            // --- İPTAL BİLGİSİ GÖSTERİMİ ---
            if (appointment.status == AppointmentStatus.cancelled && cancelledBy != null) ...[
              const SizedBox(height: 6),
              Text(
                cancelledBy == (_isArtist ? 'artist' : 'customer')
                    ? "• Sizin tarafınızdan iptal edildi"
                    : "• Karşı taraf tarafından iptal edildi",
                style: TextStyle(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],

            if (requestedDate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        requestedBy == (isArtistView ? 'customer' : 'artist')
                            ? "${DateFormat('dd.MM.yyyy - HH:mm').format(requestedDate)} için onayınız bekleniyor"
                            : "${DateFormat('dd.MM.yyyy - HH:mm').format(requestedDate)} için karşı tarafın onayı bekleniyor",
                        style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(appointment.appointmentDate),
                  style: TextStyle(
                    color: isExpired ? Colors.grey : AppTheme.textColor, 
                  ),
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

            if (!isExpired && (appointment.status == AppointmentStatus.pending || appointment.status == AppointmentStatus.confirmed)) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.grey, height: 1),
              const SizedBox(height: 8),

              if (requestedDate != null && requestedBy == (isArtistView ? 'customer' : 'artist')) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end, // Sağa yasla
                  children: [
                    const Text("Yeni Saat Onayı:", style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _handleRescheduleResponse(appointment, false),
                          style: tightButtonStyle,
                          child: const Text('Reddet', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () => _handleRescheduleResponse(appointment, true),
                          style: tightButtonStyle,
                          child: const Text('Onayla', style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ] 
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _updateStatus(appointment, AppointmentStatus.cancelled),
                          style: tightButtonStyle,
                          icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                          label: const Text('İptal Et', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          onPressed: () => _showEditDialog(appointment),
                          style: tightButtonStyle,
                          icon: const Icon(Icons.edit, size: 16, color: Colors.blueAccent),
                          label: const Text('Düzenle', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                        ),
                      ],
                    ),
                    if (isArtistView && appointment.status == AppointmentStatus.pending)
                      TextButton.icon(
                        onPressed: () => _updateStatus(appointment, AppointmentStatus.confirmed),
                        style: tightButtonStyle,
                        icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                        label: const Text('Onayla', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _showEditDialog(AppointmentModel appointment) {
    DateTime selectedDate = appointment.appointmentDate;
    String selectedTime = DateFormat('HH:00').format(appointment.appointmentDate);

    final List<String> timeSlots = [
      "09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00"
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Randevu Düzenle", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(DateFormat('dd MMMM yyyy', 'tr_TR').format(selectedDate), style: const TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.calendar_month, color: AppTheme.primaryColor),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setModalState(() => selectedDate = picked);
                    },
                  ),
                  
                  const SizedBox(height: 10),
                  const Text("Saat Seçin", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: timeSlots.map((time) {
                      bool isSelected = selectedTime == time;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedTime = time),
                        child: Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryColor),
                          ),
                          child: Center(
                            child: Text(
                              time,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.primaryColor,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final hour = int.parse(selectedTime.split(':')[0]);
                        final newFullDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour, 0);
                        Navigator.pop(context);
                        _rescheduleAppointment(appointment, newFullDate);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      child: const Text("Güncelleme Talebi Gönder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Future<void> _rescheduleAppointment(AppointmentModel appointment, DateTime newDate) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.collectionAppointments)
          .doc(appointment.id)
          .update({
        'requestedDate': Timestamp.fromDate(newDate),
        'requestedBy': _isArtist ? 'artist' : 'customer',
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = authService.currentUser?.uid;

      if (currentUserId != null) {
        final user = await authService.getUserModel(currentUserId);
        final String receiverId = _isArtist ? appointment.customerId : appointment.artistId;
        
        String dateStr = DateFormat('dd.MM.yyyy HH:mm').format(newDate);

        await NotificationService.sendNotification(
          currentUserId: currentUserId,
          currentUserName: user?.fullName ?? 'Kullanıcı',
          currentUserAvatar: user?.profileImageUrl ?? '',
          receiverId: receiverId,
          title: 'Randevu Değişikliği Talebi 🕒',
          body: '${user?.fullName} randevu saatini $dateStr olarak güncelledi.',
          type: 'appointment_update',
          relatedId: appointment.id,
        );
      }

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Değişiklik talebi iletildi.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<void> _handleRescheduleResponse(AppointmentModel appointment, bool isAccepted) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.collectionAppointments)
          .doc(appointment.id)
          .get();
      
      final Map<String, dynamic>? docData = doc.data();
      final Timestamp? requestedTs = docData?['requestedDate'];
      
      if (requestedTs == null) return;

      if (isAccepted) {
        await FirebaseFirestore.instance
            .collection(AppConstants.collectionAppointments)
            .doc(appointment.id)
            .update({
          'appointmentDate': requestedTs,
          'requestedDate': FieldValue.delete(),
          'requestedBy': FieldValue.delete(),
          'status': AppointmentStatus.confirmed.name,
        });
      } else {
        await FirebaseFirestore.instance
            .collection(AppConstants.collectionAppointments)
            .doc(appointment.id)
            .update({
          'requestedDate': FieldValue.delete(),
          'requestedBy': FieldValue.delete(),
        });
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final me = await authService.getUserModel(authService.currentUser!.uid);
      final String receiverId = _isArtist ? appointment.customerId : appointment.artistId;

      await NotificationService.sendNotification(
        currentUserId: authService.currentUser!.uid,
        currentUserName: me?.fullName ?? 'Kullanıcı',
        currentUserAvatar: me?.profileImageUrl ?? '',
        receiverId: receiverId,
        title: isAccepted ? 'Tarih Değişikliği Kabul Edildi ✅' : 'Tarih Değişikliği Reddedildi ❌',
        body: isAccepted 
            ? 'Randevu saati ${DateFormat('dd.MM.yyyy HH:mm').format(requestedTs.toDate())} olarak güncellendi.' 
            : 'Randevu saati değişikliği reddedildi. Farklı bir tarih deneyin.',
        type: 'appointment_update',
        relatedId: appointment.id,
      );

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAccepted ? 'Yeni saat onaylandı' : 'Talep reddedildi')));
    } catch (e) {
      debugPrint("Cevap verme hatası: $e");
    }
  }

  Future<void> _updateStatus(AppointmentModel appointment, AppointmentStatus newStatus) async {
    try {
      // GÜNCELLEME: İptal durumunda 'cancelledBy' bilgisini ekliyoruz
      Map<String, dynamic> updateData = {'status': newStatus.name};
      
      if (newStatus == AppointmentStatus.cancelled) {
        updateData['cancelledBy'] = _isArtist ? 'artist' : 'customer';
      }

      await FirebaseFirestore.instance
          .collection(AppConstants.collectionAppointments)
          .doc(appointment.id)
          .update(updateData);

      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = authService.currentUser?.uid;
      final me = await authService.getUserModel(currentUserId!);
      final String receiverId = currentUserId == appointment.artistId ? appointment.customerId : appointment.artistId;

      String title = '';
      String body = '';

      if (newStatus == AppointmentStatus.confirmed) {
        title = 'Randevunuz Onaylandı! ✅';
        body = '${me?.fullName} randevu talebinizi onayladı.';
      } else if (newStatus == AppointmentStatus.rejected) {
        title = 'Randevu Talebi Reddedildi ❌';
        body = '${me?.fullName} randevu talebinizi reddetti.';
      } else if (newStatus == AppointmentStatus.cancelled) {
        title = 'Randevu İptal Edildi ⚠️';
        body = '${me?.fullName} randevuyu iptal etti.';
      }

      if (title.isNotEmpty) {
        await NotificationService.sendNotification(
          currentUserId: currentUserId,
          currentUserName: me?.fullName ?? 'Kullanıcı',
          currentUserAvatar: me?.profileImageUrl ?? '',
          receiverId: receiverId,
          title: title,
          body: body,
          type: 'appointment_update',
          relatedId: appointment.id,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem başarılı')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }
}