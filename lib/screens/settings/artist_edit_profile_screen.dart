import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../utils/turkey_locations.dart';
import '../../theme/app_theme.dart';

class ArtistEditProfileScreen extends StatefulWidget {
  const ArtistEditProfileScreen({super.key});

  @override
  State<ArtistEditProfileScreen> createState() => _ArtistEditProfileScreenState();
}

class _ArtistEditProfileScreenState extends State<ArtistEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cityController = TextEditingController(); 
  final _districtController = TextEditingController(); 
  final _biographyController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isUploading = false;

  // Artist'e özel etiket listeleri
  List<String> _selectedApplications = [];
  List<String> _selectedStyles = [];

  // Sabit Seçenekler
  final List<String> _applicationOptions = ['Dövme', 'Piercing', 'Geçici Dövme', 'Rasta', 'Makyaj', 'Kına'];
  final List<String> _styleOptions = ['Minimal', 'Old School', 'Dot Work', 'Realist', 'Tribal', 'Blackwork', 'Watercolor', 'Trash Polka', 'Fine Line', 'Traditional'];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _biographyController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      final userModel = await authService.getUserModel(user.uid);
      if (mounted && userModel != null) {
        setState(() {
          _currentUser = userModel;
          _firstNameController.text = userModel.firstName ?? '';
          _lastNameController.text = userModel.lastName ?? '';
          _biographyController.text = userModel.biography ?? '';
          
          // Etiketleri yükle
          _selectedApplications = List<String>.from(userModel.applications);
          _selectedStyles = List<String>.from(userModel.applicationStyles);

          // Lokasyon bilgilerini yükle
          _cityController.text = userModel.city ?? '';
          _districtController.text = userModel.district ?? '';
        });
      }
    }
  }

  Iterable<String> _getCityOptions(TextEditingValue textEditingValue) {
    if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
    return TurkeyLocations.cities.where((city) =>
        city.toLowerCase().contains(textEditingValue.text.toLowerCase()));
  }

  Iterable<String> _getDistrictOptions(TextEditingValue textEditingValue) {
    if (textEditingValue.text.isEmpty || _cityController.text.isEmpty) {
      return const Iterable<String>.empty();
    }
    return TurkeyLocations.getDistricts(_cityController.text).where((d) =>
        d.toLowerCase().contains(textEditingValue.text.toLowerCase()));
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      String? profileImageUrl = _currentUser!.profileImageUrl;

      if (_selectedImage != null) {
        setState(() => _isUploading = true);
        final imageService = ImageService();
        final optimizedImage = await imageService.optimizeImage(_selectedImage!);
        profileImageUrl = await imageService.uploadImage(
          imageBytes: optimizedImage,
          path: AppConstants.storageProfileImages,
        );
        setState(() => _isUploading = false);
      }

      await FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.uid)
          .update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'biography': _biographyController.text.trim(),
        'city': _cityController.text.trim(),
        'district': _districtController.text.trim(),
        'applications': _selectedApplications,
        'applicationStyles': _selectedStyles,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil başarıyla güncellendi'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Sanatçı Profilini Düzenle')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fotoğraf Bölümü
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (_currentUser!.profileImageUrl != null
                              ? NetworkImage(_currentUser!.profileImageUrl!)
                              : null) as ImageProvider?,
                      child: _selectedImage == null && _currentUser!.profileImageUrl == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isUploading) const LinearProgressIndicator(),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'Ad', prefixIcon: Icon(Icons.person)),
                validator: (value) => Validators.validateRequired(value, 'Ad'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Soyad', prefixIcon: Icon(Icons.person_outline)),
                validator: (value) => Validators.validateRequired(value, 'Soyad'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _biographyController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Biyografi', prefixIcon: Icon(Icons.edit_note)),
              ),
              const SizedBox(height: 16),

              // Şehir & Semt
              Autocomplete<String>(
                optionsBuilder: _getCityOptions,
                onSelected: (selection) => setState(() {
                  _cityController.text = selection;
                  _districtController.clear();
                }),
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  if (controller.text.isEmpty && _cityController.text.isNotEmpty) controller.text = _cityController.text;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Şehir', prefixIcon: Icon(Icons.location_city)),
                  );
                },
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                optionsBuilder: _getDistrictOptions,
                onSelected: (selection) => setState(() => _districtController.text = selection),
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  if (controller.text.isEmpty && _districtController.text.isNotEmpty) controller.text = _districtController.text;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: _cityController.text.isNotEmpty,
                    decoration: const InputDecoration(labelText: 'Semt', prefixIcon: Icon(Icons.location_on)),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              const Text('Uygulamalar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildMultiSelectChips(_applicationOptions, _selectedApplications),

              const SizedBox(height: 24),
              const Text('Stiller', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildMultiSelectChips(_styleOptions, _selectedStyles),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('DEĞİŞİKLİKLERİ KAYDET'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectChips(List<String> options, List<String> selectedList) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedList.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              selected ? selectedList.add(option) : selectedList.remove(option);
            });
          },
          selectedColor: AppTheme.primaryColor.withOpacity(0.3),
          checkmarkColor: AppTheme.primaryColor,
          backgroundColor: const Color(0xFF212121),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
      }).toList(),
    );
  }
}