import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart'; 
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
  
  // Controllerlar
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _studioNameController = TextEditingController();
  final _addressController = TextEditingController(); 
  final _cityController = TextEditingController(); 
  final _districtController = TextEditingController(); 
  final _biographyController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  UserModel? _currentUser;
  
  
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isScrolled = false; 

  // Seçilen etiketler
  List<String> _selectedApplications = [];
  List<String> _selectedStyles = [];

  // NOT: Manuel Map değişkenini kaldırdık. 
  // Artık AppConstants.applicationStylesMap kullanıyoruz.

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studioNameController.dispose();
    _addressController.dispose();
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
          
          if (userModel.firstName != null && userModel.firstName!.isNotEmpty) {
            _firstNameController.text = userModel.firstName!;
            _lastNameController.text = userModel.lastName ?? '';
          } else {
            var names = userModel.fullName.split(' ');
            if (names.isNotEmpty) {
               _firstNameController.text = names.first;
               _lastNameController.text = names.length > 1 ? names.sublist(1).join(' ') : '';
            }
          }

          _studioNameController.text = userModel.studioName ?? '';
          _biographyController.text = userModel.biography ?? '';
          _addressController.text = userModel.address ?? ''; 
          _cityController.text = userModel.city ?? '';
          _districtController.text = userModel.district ?? '';

          _selectedApplications = List<String>.from(userModel.applications)
              .where((item) => AppConstants.applications.contains(item))
              .toList();
          
          _selectedStyles = List<String>.from(userModel.applicationStyles)
              .where((item) => AppConstants.styles.contains(item))
              .toList();
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

      final String firstName = _firstNameController.text.trim();
      final String lastName = _lastNameController.text.trim();
      final String fullName = "$firstName $lastName";
      final String city = _cityController.text.trim();
      final String district = _districtController.text.trim();
      final String studioName = _studioNameController.text.trim();
      
      final String address = _addressController.text.trim();
      final String locationString = "$district, $city";

      double? latitude;
      double? longitude;

      try {
        String searchAddress = "$address, $district, $city";
        if (address.isEmpty) {
           searchAddress = "$studioName, $district, $city";
        }

        if (searchAddress.length > 5) {
          List<Location> locations = await locationFromAddress(searchAddress);
          if (locations.isNotEmpty) {
            latitude = locations.first.latitude;
            longitude = locations.first.longitude;
          }
        }
      } catch (e) {
        print("⚠️ Koordinat hatası: $e");
      }

      await FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.uid)
          .update({
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'studioName': studioName,
        'biography': _biographyController.text.trim(),
        'city': city,
        'district': district,
        'locationString': locationString,
        'address': address,     
        'latitude': latitude,   
        'longitude': longitude, 
        'applications': _selectedApplications,
        'applicationStyles': _selectedStyles,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil güncellendi!'), backgroundColor: Colors.green),
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
      backgroundColor: AppTheme.backgroundColor, 
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profili Düzenle', style: TextStyle(color: AppTheme.textColor)),
        backgroundColor: _isScrolled ? AppTheme.cardColor : Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollUpdateNotification) {
            final isScrolledNow = scrollNotification.metrics.pixels > 0;
            if (isScrolledNow != _isScrolled) {
              setState(() {
                _isScrolled = isScrolledNow;
              });
            }
          }
          return false;
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 16, 
              left: 16, 
              right: 16, 
              bottom: 16
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- PROFİL FOTOĞRAFI ---
                Center(
                  child: GestureDetector( 
                    onTap: _pickImage, 
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryColor, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[800],
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (_currentUser!.profileImageUrl != null
                                    ? NetworkImage(_currentUser!.profileImageUrl!)
                                    : null) as ImageProvider?,
                            child: _selectedImage == null && _currentUser!.profileImageUrl == null
                                ? const Icon(Icons.person, size: 50, color: AppTheme.textColor)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 18, color: AppTheme.textColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isUploading) 
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: LinearProgressIndicator(color: AppTheme.primaryColor),
                  ),
                const SizedBox(height: 24),
                
                // --- FORM ALANLARI ---
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: _firstNameController, label: 'Ad', icon: Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(controller: _lastNameController, label: 'Soyad', icon: Icons.person_outline)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(controller: _studioNameController, label: 'Stüdyo Adı', icon: Icons.store),
                const SizedBox(height: 16),
                _buildTextField(controller: _biographyController, label: 'Biyografi', icon: Icons.edit_note, maxLines: 3),
                const SizedBox(height: 16),
                _buildTextField(controller: _addressController, label: 'Açık Adres', icon: Icons.map, maxLines: 2),
                const SizedBox(height: 16),
                
                // --- ŞEHİR / SEMT ---
                Row(
                  children: [
                    Expanded(
                      child: Autocomplete<String>(
                        optionsBuilder: _getCityOptions,
                        onSelected: (selection) => setState(() {
                          _cityController.text = selection;
                          _districtController.clear();
                        }),
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          if (controller.text.isEmpty && _cityController.text.isNotEmpty) controller.text = _cityController.text;
                          return _buildTextField(controller: controller, label: 'Şehir', icon: Icons.location_city, focusNode: focusNode);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Autocomplete<String>(
                        optionsBuilder: _getDistrictOptions,
                        onSelected: (selection) => setState(() => _districtController.text = selection),
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          if (controller.text.isEmpty && _districtController.text.isNotEmpty) controller.text = _districtController.text;
                          return _buildTextField(controller: controller, label: 'Semt', icon: Icons.location_on, focusNode: focusNode);
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
        
                // --- HİZMETLER (Applications) ---
                const Text('Hizmetler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                const SizedBox(height: 12),
                _buildApplicationSelector(),
        
                const SizedBox(height: 24),
        
                // --- DİNAMİK STİL SEÇİMİ (APPCONSTANTS'TAN ÇEKİLİYOR) ---
                if (_selectedApplications.isEmpty)
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(8)),
                     child: const Row(
                       children: [
                         Icon(Icons.info_outline, color: Colors.grey, size: 20),
                         SizedBox(width: 8),
                         Text("Stilleri görmek için yukarıdan hizmet seçiniz.", style: TextStyle(color: Colors.grey)),
                       ],
                     ),
                   )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _selectedApplications.map((app) {
                      
                      // DEĞİŞİKLİK BURADA: Constants dosyasından çekiyoruz
                      final stylesForApp = AppConstants.applicationStylesMap[app];
                      
                      if (stylesForApp == null || stylesForApp.isEmpty) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$app Stilleri', 
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                            ),
                            const SizedBox(height: 8),
                            _buildMultiSelectChips(stylesForApp, _selectedStyles),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
        
                const SizedBox(height: 48),
                
                // --- KAYDET BUTONU ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppTheme.textColor, strokeWidth: 2)) 
                      : const Text('DEĞİŞİKLİKLERİ KAYDET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.backgroundColor)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: AppTheme.cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
      ),
      validator: (value) => Validators.validateRequired(value, label),
    );
  }

  // --- HİZMET SEÇİMİ ---
  Widget _buildApplicationSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      // Burayı da constants'tan çekiyoruz (veya applicationStylesMap.keys)
      children: AppConstants.applications.map((option) {
        final isSelected = _selectedApplications.contains(option);
        
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          showCheckmark: false,
          selectedColor: AppTheme.primaryColor,
          backgroundColor: AppTheme.cardColor,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.backgroundColor : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.grey[800]!),
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedApplications.add(option);
              } else {
                _selectedApplications.remove(option);
                // DEĞİŞİKLİK BURADA: Constants dosyasından temizlenecek stilleri çekiyoruz
                final stylesToRemove = AppConstants.applicationStylesMap[option];
                if (stylesToRemove != null) {
                  _selectedStyles.removeWhere((style) => stylesToRemove.contains(style));
                }
              }
            });
          },
        );
      }).toList(),
    );
  }

  // --- STİL SEÇİMİ ---
  Widget _buildMultiSelectChips(List<String> options, List<String> selectedList) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedList.contains(option);
        
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          showCheckmark: false, 
          onSelected: (selected) {
            setState(() {
              selected ? selectedList.add(option) : selectedList.remove(option);
            });
          },
          selectedColor: AppTheme.primaryColor.withOpacity(0.7),
          backgroundColor: AppTheme.cardColor,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.backgroundColor : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? AppTheme.primaryColor : Colors.grey[800]!,
            ),
          ),
        );
      }).toList(),
    );
  }
}