import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';
import '../../utils/validators.dart';
import '../../utils/constants.dart';
import '../../utils/turkey_locations.dart'; // Eklendi
import '../main_screen.dart';

class ArtistRegisterScreen extends StatefulWidget {
  const ArtistRegisterScreen({super.key});

  @override
  State<ArtistRegisterScreen> createState() => _ArtistRegisterScreenState();
}

class _ArtistRegisterScreenState extends State<ArtistRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studioAddressController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _instagramController = TextEditingController();
  
  bool _isApprovedArtist = true; 
  bool _obscurePassword = true;
  bool _isLoading = false;
  
  File? _documentFile;
  final List<File> _portfolioImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _studioAddressController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  // --- Şehir ve Semt için Autocomplete Seçeneklerini Filtreleyen Fonksiyonlar ---
  Iterable<String> _getCityOptions(TextEditingValue textEditingValue) {
    if (textEditingValue.text == '') {
      return const Iterable<String>.empty();
    }
    return TurkeyLocations.cities.where((String option) {
      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
    });
  }

  Iterable<String> _getDistrictOptions(TextEditingValue textEditingValue) {
    if (textEditingValue.text == '' || _cityController.text.isEmpty) {
      return const Iterable<String>.empty();
    }
    final districts = TurkeyLocations.getDistricts(_cityController.text);
    return districts.where((String option) {
      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
    });
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _documentFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya seçilirken hata: $e')),
        );
      }
    }
  }

  Future<void> _pickPortfolioImage() async {
    if (_portfolioImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zaten 3 portfolyo fotoğrafı eklediniz')),
      );
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          for (var xFile in images) {
            if (_portfolioImages.length < 3) {
              _portfolioImages.add(File(xFile.path));
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf seçilirken hata: $e')),
        );
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isApprovedArtist && _documentFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Onaylı artist için belge yüklemeniz gerekiyor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_portfolioImages.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen 3 adet portfolyo fotoğrafı ekleyin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final imageService = ImageService();
      final List<String> portfolioUrls = [];

      for (final imageFile in _portfolioImages) {
        final optimizedImage = await imageService.optimizeImage(imageFile);
        final url = await imageService.uploadImage(
          imageBytes: optimizedImage,
          path: AppConstants.storagePortfolioImages,
        );
        portfolioUrls.add(url);
      }

      String? documentUrl;
      if (_documentFile != null) {
        documentUrl = await imageService.uploadFile(
          file: _documentFile!,
          path: AppConstants.storageDocuments,
        );
      }

      if (!mounted) return;
      
      final authService = Provider.of<AuthService>(context, listen: false);

      if (_isApprovedArtist) {
        await authService.registerApprovedArtist(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _usernameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          studioAddress: _studioAddressController.text.trim(),
          instagramUsername: _instagramController.text.trim(),
          documentUrl: documentUrl!,
          portfolioImages: portfolioUrls,
          district: _districtController.text.trim(),
          city: _cityController.text.trim(),
        );
      } else {
        await authService.registerUnapprovedArtist(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _usernameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          address: _studioAddressController.text.trim(),
          instagramUsername: _instagramController.text.trim(),
          portfolioImages: portfolioUrls,
          district: _districtController.text.trim(),
          city: _cityController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hesabınız onaya gönderilmiştir'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt sırasında hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Kaydı'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Artist Türü',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<bool>(
                        title: const Text('Onaylı Artist'),
                        subtitle: const Text('Vergi levhası veya çalışma izni gerekli'),
                        value: true,
                        groupValue: _isApprovedArtist,
                        onChanged: (value) {
                          setState(() {
                            _isApprovedArtist = value!;
                          });
                        },
                      ),
                      RadioListTile<bool>(
                        title: const Text('Onaysız Artist'),
                        subtitle: const Text('Belge gerekmez'),
                        value: false,
                        groupValue: _isApprovedArtist,
                        onChanged: (value) {
                          setState(() {
                            _isApprovedArtist = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Stüdyo Adı',
                  hintText: 'Örn: Dream Tattoo Studio',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Lütfen stüdyo adınızı girin';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Ad',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => Validators.validateRequired(value, 'Ad'),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Soyad',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => Validators.validateRequired(value, 'Soyad'),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon Numarası',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: Validators.validatePhone,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _studioAddressController,
                decoration: InputDecoration(
                  labelText: _isApprovedArtist ? 'Stüdyo Adresi' : 'Adres',
                  prefixIcon: const Icon(Icons.location_on),
                ),
                validator: (value) => Validators.validateRequired(
                  value,
                  _isApprovedArtist ? 'Stüdyo adresi' : 'Adres',
                ),
              ),
              const SizedBox(height: 16),

              // --- ŞEHİR SEÇİCİ (Hatadan arındırılmış Autocomplete) ---
              Autocomplete<String>(
                optionsBuilder: _getCityOptions,
                onSelected: (String selection) {
                  setState(() {
                    _cityController.text = selection;
                    _districtController.clear(); 
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  // Kendi controller'ımızı Autocomplete'in içindekine eşitliyoruz
                  if (_cityController.text != controller.text && _cityController.text.isNotEmpty && controller.text.isEmpty) {
                    controller.text = _cityController.text;
                  }
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Şehir',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    validator: (value) => Validators.validateRequired(value, 'Şehir'),
                  );
                },
              ),
              const SizedBox(height: 16),

              // --- SEMT SEÇİCİ (Hatadan arındırılmış Autocomplete) ---
              Autocomplete<String>(
                optionsBuilder: _getDistrictOptions,
                onSelected: (String selection) {
                  setState(() {
                    _districtController.text = selection;
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  if (_districtController.text != controller.text && _districtController.text.isNotEmpty && controller.text.isEmpty) {
                    controller.text = _districtController.text;
                  }
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: _cityController.text.isNotEmpty,
                    decoration: InputDecoration(
                      labelText: 'Semt',
                      prefixIcon: const Icon(Icons.location_city),
                      hintText: _cityController.text.isEmpty ? 'Önce şehir seçin' : 'Semt yazın...',
                    ),
                    validator: (value) => Validators.validateRequired(value, 'Semt'),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _instagramController,
                decoration: const InputDecoration(
                  labelText: 'Instagram Kullanıcı Adı',
                  prefixIcon: Icon(Icons.camera_alt),
                ),
                validator: (value) => Validators.validateRequired(
                  value,
                  'Instagram kullanıcı adı',
                ),
              ),
              const SizedBox(height: 16),
              
              if (_isApprovedArtist) ...[
                const Text(
                  'Vergi Levhası veya Çalışma İzni',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickDocument,
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    _documentFile != null
                        ? _documentFile!.path.split('/').last
                        : 'PDF veya Fotoğraf Yükle',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              const Text(
                'Portfolyo Fotoğrafları (3 adet seçin)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._portfolioImages.map((image) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              image,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -10,
                            right: -10,
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _portfolioImages.remove(image);
                                });
                              },
                            ),
                          ),
                        ],
                      )),
                  if (_portfolioImages.length < 3)
                    GestureDetector(
                      onTap: _pickPortfolioImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo, size: 30, color: Colors.grey),
                            Text('Seç', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kayıt Ol'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}