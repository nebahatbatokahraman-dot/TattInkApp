import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart'; // Master Data buradan geliyor
import '../theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final List<File> _selectedImages = [];
  final List<File> _selectedVideos = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  UserModel? _currentUser;

  // --- Filtreleme Seçenekleri ---
  String? _selectedApplication; 
  final List<String> _selectedStyles = [];

  // ESKİ SABİT LİSTELER KALDIRILDI
  // Artık AppConstants.applications ve AppConstants.styles kullanılıyor.

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      final userModel = await authService.getUserModel(user.uid);
      if (mounted) {
        setState(() {
          _currentUser = userModel;
        });
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((x) => File(x.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görsel seçilirken hata: $e')),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedVideos.add(File(video.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video seçilirken hata: $e')),
        );
      }
    }
  }

  Future<void> _uploadPost() async {
    if (_selectedImages.isEmpty && _selectedVideos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir görsel veya video seçin')),
      );
      return;
    }

    if (_selectedApplication == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir uygulama türü seçin')),
      );
      return;
    }

    if (_currentUser == null) return;

    setState(() => _isUploading = true);

    try {
      final imageService = ImageService();
      final List<String> imageUrls = [];

      // Görselleri yükle
      for (final imageFile in _selectedImages) {
        final optimizedImage = await imageService.optimizeImage(imageFile);
        final url = await imageService.uploadImage(
          imageBytes: optimizedImage,
          path: AppConstants.storagePostImages,
        );
        imageUrls.add(url);
      }

      final postRef = FirebaseFirestore.instance.collection(AppConstants.collectionPosts).doc();

      double currentArtistScore = (_currentUser!.totalLikes ?? 0).toDouble();

      // Caption'ı hazırla: Filtrelerin %100 çalışması için seçilen etiketleri metnin sonuna görünmez şekilde ekleyebiliriz
      // Veya olduğu gibi bırakırız. Şimdilik olduğu gibi bırakıyoruz çünkü HomeScreen'i güncelledik.
      String finalCaption = _captionController.text.trim();
      
      // ÖNEMLİ: Seçilen etiketleri caption'a ekleyerek metin tabanlı aramayı güçlendiriyoruz.
      // Kullanıcı "Dövme" seçtiyse ama metne yazmadıysa bile aramada çıksın diye.
      String tagsSuffix = "\n\n${_selectedApplication ?? ''} ${_selectedStyles.join(' ')}";
      finalCaption = "$finalCaption $tagsSuffix".trim();

      final postData = {
        'id': postRef.id,
        'artistId': _currentUser!.uid,
        'artistUsername': _currentUser!.username ?? _currentUser!.fullName,
        'artistProfileImageUrl': _currentUser!.profileImageUrl,
        'imageUrls': imageUrls,
        'videoUrls': [],
        'caption': finalCaption, // Güncellenmiş caption
        'likeCount': 0,
        'likedBy': [],
        'application': _selectedApplication, 
        'styles': _selectedStyles,
        'district': _currentUser!.district,
        'city': _currentUser!.city,
        'locationString': _currentUser!.locationString.isNotEmpty 
            ? _currentUser!.locationString 
            : "${_currentUser!.district}, ${_currentUser!.city}",
        'artistScore': currentArtistScore, 
        'createdAt': FieldValue.serverTimestamp(),
      };

      await postRef.set(postData);

      await FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.uid)
          .update({'tattooCount': FieldValue.increment(1)});

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paylaşım başarıyla yayınlandı'), 
            backgroundColor: Colors.green
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paylaşım yüklenirken hata: $e'), 
            backgroundColor: Colors.red
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161616), // Koyu Tema Arka Plan
      appBar: AppBar(
        title: const Text('Yeni Paylaşım', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _uploadPost,
            child: _isUploading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                : const Text('Paylaş', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Medya Önizleme
              if (_selectedImages.isNotEmpty || _selectedVideos.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._selectedImages.map((image) => _buildImagePreview(image)),
                      ..._selectedVideos.map((video) => _buildVideoPreview(video)),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.image, color: Colors.white),
                      label: const Text('Fotoğraf Ekle', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[800]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.videocam, color: Colors.white),
                      label: const Text('Video Ekle', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[800]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 32, color: Colors.white12),

              // --- Uygulama Türü (MASTER DATA) ---
              const Text('Uygulama Türü', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.applications.map((app) {
                  final isSelected = _selectedApplication == app;
                  return ChoiceChip(
                    label: Text(app),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedApplication = selected ? app : null);
                    },
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: const Color(0xFF252525),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.transparent),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // --- Stiller (MASTER DATA) ---
              const Text('Stiller', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.styles.map((style) {
                  final isSelected = _selectedStyles.contains(style);
                  return FilterChip(
                    label: Text(style),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedStyles.add(style);
                        } else {
                          _selectedStyles.remove(style);
                        }
                      });
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.3),
                    backgroundColor: const Color(0xFF252525),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.transparent),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              
              // Açıklama Kutusu
              TextFormField(
                controller: _captionController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'Paylaşımınız hakkında detay verin...',
                  hintStyle: TextStyle(color: Colors.grey[700]),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: const Color(0xFF252525),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(File image) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(image, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _selectedImages.remove(image)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview(File video) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF252525), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!)
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(Icons.play_circle_outline, size: 48, color: Colors.white)
          ),
           Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _selectedVideos.remove(video)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}