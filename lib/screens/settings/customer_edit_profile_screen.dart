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
import '../../app_localizations.dart'; // Çeviri sınıfı eklendi

class CustomerEditProfileScreen extends StatefulWidget {
  const CustomerEditProfileScreen({super.key});

  @override
  State<CustomerEditProfileScreen> createState() => _CustomerEditProfileScreenState();
}

class _CustomerEditProfileScreenState extends State<CustomerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cityController = TextEditingController(); 
  final _districtController = TextEditingController(); 
  
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isUploading = false;

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
          
          if (userModel.city != null && userModel.city!.isNotEmpty) {
            try {
              final matchedCity = TurkeyLocations.cities.firstWhere(
                (city) => city.toLowerCase() == userModel.city!.toLowerCase(),
              );
              _cityController.text = matchedCity;
            } catch (e) {
              _cityController.text = userModel.city!;
            }
          }

          if (userModel.district != null && userModel.district!.isNotEmpty) {
            _districtController.text = userModel.district!;
          }
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
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.translate('error_picking_image')}: $e')),
        );
      }
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
        
        if (profileImageUrl != null) {
          await imageService.deleteImage(profileImageUrl);
        }

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
        'city': _cityController.text.trim(),
        'district': _districtController.text.trim(),
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('profile_updated_success')), 
            backgroundColor: Colors.green
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.translate('update_error')}: $e'), 
            backgroundColor: Colors.red
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('profile_info_title')),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 20),
                          color: AppTheme.textColor,
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isUploading) const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: LinearProgressIndicator()),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _firstNameController,
                style: const TextStyle(color: AppTheme.textColor),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.translate('first_name'), 
                  prefixIcon: const Icon(Icons.person_outline)
                ),
                validator: (value) => Validators.validateRequired(value, AppLocalizations.of(context)!.translate('first_name')),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _lastNameController,
                style: const TextStyle(color: AppTheme.textColor),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.translate('last_name'), 
                  prefixIcon: const Icon(Icons.person_outline)
                ),
                validator: (value) => Validators.validateRequired(value, AppLocalizations.of(context)!.translate('last_name')),
              ),
              const SizedBox(height: 16),

              Autocomplete<String>(
                optionsBuilder: _getCityOptions,
                onSelected: (selection) => setState(() {
                  _cityController.text = selection;
                  _districtController.clear();
                }),
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  if (controller.text.isEmpty && _cityController.text.isNotEmpty) {
                    controller.text = _cityController.text;
                  }
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(color: AppTheme.textColor),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.translate('city'), 
                      prefixIcon: const Icon(Icons.location_city)
                    ),
                    validator: (value) => Validators.validateRequired(value, AppLocalizations.of(context)!.translate('city')),
                  );
                },
              ),
              const SizedBox(height: 16),

              Autocomplete<String>(
                optionsBuilder: _getDistrictOptions,
                onSelected: (selection) => setState(() => _districtController.text = selection),
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  if (controller.text.isEmpty && _districtController.text.isNotEmpty) {
                    controller.text = _districtController.text;
                  }
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(color: AppTheme.textColor),
                    enabled: _cityController.text.isNotEmpty,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.translate('district'), 
                      prefixIcon: const Icon(Icons.location_on)
                    ),
                    validator: (value) => Validators.validateRequired(value, AppLocalizations.of(context)!.translate('district')),
                  );
                },
              ),

              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textColor)))
                      : Text(
                          AppLocalizations.of(context)!.translate('save'), 
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.backgroundColor)
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}