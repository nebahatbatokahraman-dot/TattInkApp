import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// --- IMPORTS ---
import '../models/appointment_model.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final String artistId;
  final String? referenceImageUrl;

  const CreateAppointmentScreen({
    super.key,
    required this.artistId,
    this.referenceImageUrl,
  });

  @override
  State<CreateAppointmentScreen> createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  File? _selectedImageFile; // Galeriden seçilen yeni foto
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // --- TARİH SEÇİCİ ---
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryLightColor,
              onPrimary: AppTheme.textDarkColor,
              surface: AppTheme.cardColor,
              onSurface: AppTheme.textColor,
            ),
            dialogBackgroundColor: AppTheme.cardColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- ÖZEL SAAT SEÇİCİ (09:00 - 20:00) ---
  void _showCustomTimePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundSecondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        List<TimeOfDay> timeSlots = [];
        for (int i = 9; i <= 20; i++) {
          timeSlots.add(TimeOfDay(hour: i, minute: 0));
        }

        return Container(
          padding: const EdgeInsets.all(16),
          height: 350,
          child: Column(
            children: [
              const Text(
                "Saat Seçin",
                style: TextStyle(color: AppTheme.textColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, 
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: timeSlots.length,
                  itemBuilder: (context, index) {
                    final time = timeSlots[index];
                    final isSelected = _selectedTime == time;
                    
                    return OutlinedButton(
                      onPressed: () {
                        setState(() => _selectedTime = time);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected ? AppTheme.primaryLightColor : Colors.transparent,
                        side: const BorderSide(color: AppTheme.primaryLightColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        "${time.hour.toString().padLeft(2, '0')}:00",
                        style: TextStyle(
                          color: isSelected ? AppTheme.textDarkColor : AppTheme.primaryLightColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- FOTOĞRAF SEÇME ---
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _selectedImageFile = File(image.path);
      });
    }
  }

  // --- KAYDETME VE BİLDİRİM ---
  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tarih ve saat seçin'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final customerId = authService.currentUser?.uid;
      
      if (customerId == null) return;
      
      // Müşteri bilgilerini çekiyoruz (İsim ve Resim için)
      final customer = await authService.getUserModel(customerId);
      if (customer == null) return;

      // Artist bilgisini çek
      final artistDoc = await FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(widget.artistId)
          .get();
      
      if (!artistDoc.exists) throw Exception("Artist bulunamadı");
      final artistData = artistDoc.data() as Map<String, dynamic>;

      // Resim yükleme işlemi...
      String? finalImageUrl = widget.referenceImageUrl;
      if (_selectedImageFile != null) {
        final imageService = ImageService();
        finalImageUrl = await imageService.uploadImage(
          imageBytes: await _selectedImageFile!.readAsBytes(),
          path: 'appointment_refs/${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      final appointmentDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final appointmentRef = FirebaseFirestore.instance.collection(AppConstants.collectionAppointments).doc();

      // Müşteri adını belirle
      final String customerName = (customer.fullName != null && customer.fullName!.isNotEmpty) 
          ? customer.fullName! 
          : (customer.username ?? 'Müşteri');

      final appointment = AppointmentModel(
        id: appointmentRef.id,
        customerId: customerId,
        artistId: widget.artistId,
        customerName: customerName,
        artistName: artistData['fullName'] ?? artistData['username'] ?? 'Artist',
        appointmentDate: appointmentDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        referenceImageUrl: finalImageUrl,
        status: AppointmentStatus.pending,
        createdAt: DateTime.now(),
      );

      // 1. Randevuyu Kaydet
      await appointmentRef.set(appointment.toMap());

      // 2. Bildirim Gönder
      await NotificationService.sendNotification(
        receiverId: widget.artistId,
        currentUserId: customerId,
        currentUserName: customerName,
        currentUserAvatar: customer.profileImageUrl,
        type: 'appointment_request',
        title: 'Yeni Randevu Talebi',
        body: '$customerName sizden ${DateFormat('dd/MM HH:mm').format(appointmentDate)} tarihi için randevu talep etti.',
        relatedId: appointmentRef.id,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Randevu talebi gönderildi'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekranın yüksekliğini al
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      // Ekranın %50'si kadar yükseklik
      height: screenHeight * 0.50, 
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- REFERANS RESMİ (VARSA VEYA YENİ SEÇİLDİYSE) ---
                if (_selectedImageFile != null || widget.referenceImageUrl != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        height: 100,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[800]!),
                          image: DecorationImage(
                            image: _selectedImageFile != null
                                ? FileImage(_selectedImageFile!) as ImageProvider
                                : NetworkImage(widget.referenceImageUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Resmi kaldırma butonu
                      if (_selectedImageFile != null)
                        IconButton(
                          onPressed: () => setState(() => _selectedImageFile = null),
                          icon: const CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, color: AppTheme.textColor, size: 20),
                          ),
                        ),
                    ],
                  ),

                // --- TARİH VE SAAT (YAN YANA) ---
                Row(
                  children: [
                    // Tarih Butonu
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _selectDate,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryLightColor),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today, color: AppTheme.primaryLightColor),
                            const SizedBox(width: 8), 
                            Text(
                              _selectedDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                                  : 'Tarih Seç',
                              style: const TextStyle(color: AppTheme.textColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Saat Butonu
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _showCustomTimePicker,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryLightColor),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time, color: AppTheme.primaryLightColor),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTime != null
                                  ? "${_selectedTime!.hour.toString().padLeft(2,'0')}:00"
                                  : 'Saat Seç',
                              style: const TextStyle(color: AppTheme.textColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 15),

                // --- NOTLAR VE FOTOĞRAF EKLEME BUTONU ---
                IntrinsicHeight( 
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch, 
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _notesController,
                          maxLines: 4,
                          style: const TextStyle(color: AppTheme.textColor),
                          decoration: InputDecoration(
                            labelText: 'Notlar (Opsiyonel)',
                            labelStyle: const TextStyle(color: Colors.grey),
                            hintText: 'Dövme fikri, boyutu vb...',
                            hintStyle: TextStyle(color: Colors.grey[700]),
                            filled: true,
                            fillColor: AppTheme.cardColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Fotoğraf Ekle İkonu
                      InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryLightColor.withOpacity(0.5)),
                          ),
                          child: const Column( 
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: AppTheme.primaryLightColor),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- GÖNDER BUTONU ---
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textColor),
                          )
                        : const Text(
                            'Randevu Talebi Gönder',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}