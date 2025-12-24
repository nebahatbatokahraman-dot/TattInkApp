import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/appointment_model.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

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
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tarih ve saat seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final customerId = authService.currentUser?.uid;
    final customer = await authService.getUserModel(customerId ?? '');

    if (customerId == null || customer == null) {
      return;
    }

    // Get artist info
    final artistDoc = await FirebaseFirestore.instance
        .collection(AppConstants.collectionUsers)
        .doc(widget.artistId)
        .get();

    if (!mounted) return;
    
    if (!artistDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artist bulunamadı')),
      );
      return;
    }

    final artist = artistDoc.data() as Map<String, dynamic>;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final appointmentDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final appointmentRef = FirebaseFirestore.instance
          .collection(AppConstants.collectionAppointments)
          .doc();

      final appointment = AppointmentModel(
        id: appointmentRef.id,
        customerId: customerId,
        artistId: widget.artistId,
        customerName: customer.fullName,
        artistName: artist['username'] ?? artist['firstName'],
        appointmentDate: appointmentDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        referenceImageUrl: widget.referenceImageUrl,
        status: AppointmentStatus.pending,
        createdAt: DateTime.now(),
      );

      await appointmentRef.set(appointment.toMap());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Randevu talebi gönderildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Randevu oluşturulurken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevu Oluştur'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Reference image if exists
              if (widget.referenceImageUrl != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.referenceImageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              
              // Date picker
              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _selectedDate != null
                      ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                      : 'Tarih Seç',
                ),
              ),
              const SizedBox(height: 16),
              
              // Time picker
              OutlinedButton.icon(
                onPressed: _selectTime,
                icon: const Icon(Icons.access_time),
                label: Text(
                  _selectedTime != null
                      ? _selectedTime!.format(context)
                      : 'Saat Seç',
                ),
              ),
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Notlar (Opsiyonel)',
                  hintText: 'Randevu hakkında eklemek istedikleriniz...',
                ),
              ),
              const SizedBox(height: 24),
              
              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAppointment,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Randevu Talebi Gönder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

