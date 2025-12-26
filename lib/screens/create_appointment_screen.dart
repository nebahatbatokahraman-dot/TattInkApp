import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// --- IMPORTS ---
import '../models/appointment_model.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart'; // Resim yükleme servisin
import '../utils/constants.dart';
import '../theme/app_theme.dart'; // AppTheme.primaryColor için

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
    // Tema ayarları AppTheme üzerinden de gelebilir ama burada manuel dark theme zorladık
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Color(0xFF252525),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF252525),
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

  // --- ÖZEL SAAT SEÇİCİ (08:00 - 20:00) ---
  void _showCustomTimePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF202020),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        // 08:00'den 20:00'e kadar saatleri oluştur
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
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // Yan yana 4 tane
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
                        // Seçiliyse dolu, değilse boş (outlined)
                        backgroundColor: isSelected ? AppTheme.primaryColor : Colors.transparent,
                        side: BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        "${time.hour.toString().padLeft(2, '0')}:00",
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.primaryColor,
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

  // --- KAYDETME İŞLEMİ ---
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
      
      final customer = await authService.getUserModel(customerId);
      if (customer == null) return;

      // Artist bilgisini çek
      final artistDoc = await FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(widget.artistId)
          .get();
      
      if (!artistDoc.exists) throw Exception("Artist bulunamadı");
      final artistData = artistDoc.data() as Map<String, dynamic>;

      // Eğer yeni resim seçildiyse onu yükle, yoksa var olan referansı kullan
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

      final appointment = AppointmentModel(
        id: appointmentRef.id,
        customerId: customerId,
        artistId: widget.artistId,
        customerName: customer.fullName.isNotEmpty ? customer.fullName : customer.username,
        artistName: artistData['fullName'] ?? artistData['username'] ?? 'Artist',
        appointmentDate: appointmentDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        referenceImageUrl: finalImageUrl,
        status: AppointmentStatus.pending,
        createdAt: DateTime.now(),
      );

      await appointmentRef.set(appointment.toMap());

      if (mounted) {
        Navigator.pop(context); // BottomSheet'i kapat
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
      // --- İSTEK: Ekranın 2/3'ünü kaplasın ---
      height: screenHeight * 0.50, 
      decoration: const BoxDecoration(
        color: Color(0xFF161616),
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
                      // Resmi kaldırma butonu (sadece yeni seçilen varsa)
                      if (_selectedImageFile != null)
                        IconButton(
                          onPressed: () => setState(() => _selectedImageFile = null),
                          icon: const CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, color: Colors.white, size: 20),
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
                          side: const BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center, // İçeriği ortalar
                          children: [
                            const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                            const SizedBox(width: 8), // Yan yana olduğu için width (genişlik) kullanıyoruz
                            Text(
                              _selectedDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                                  : 'Tarih Seç',
                              style: const TextStyle(color: Colors.white),
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
                          side: const BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center, // İçeriği ortalar
                          children: [
                            const Icon(Icons.access_time, color: AppTheme.primaryColor),
                            const SizedBox(width: 8), // Yan yana olduğu için artık width (genişlik) kullanıyoruz
                            Text(
                              _selectedTime != null
                                  ? "${_selectedTime!.hour.toString().padLeft(2,'0')}:00"
                                  : 'Saat Seç',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 15),

                // --- NOTLAR VE FOTOĞRAF EKLEME BUTONU ---
                // 1. Row'u IntrinsicHeight ile sarmala
                IntrinsicHeight( 
                  child: Row(
                    // 2. Elemanları dikeyde esnet (stretch)
                    crossAxisAlignment: CrossAxisAlignment.stretch, 
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _notesController,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Notlar (Opsiyonel)',
                            labelStyle: const TextStyle(color: Colors.grey),
                            hintText: 'Dövme fikri, boyutu vb...',
                            hintStyle: TextStyle(color: Colors.grey[700]),
                            filled: true,
                            fillColor: const Color(0xFF252525),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 3. Buradaki Column'u kaldırdık ve Container'ın height değerini sildik.
                      InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF252525),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5)),
                          ),
                          child: const Column( // İkonu ortalamak için Column burada kalabilir ama height'ı etkilemez
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: AppTheme.primaryColor),
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Randevu Talebi Gönder',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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