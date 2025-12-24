import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
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

  final List<String> _applicationOptions = [
    'Dövme', 'Piercing', 'Geçici Dövme', 'Rasta', 'Makyaj', 'Kına'
  ];
  final List<String> _styleOptions = [
    'Minimal', 'Old School', 'Dot Work', 'Realist', 'Tribal', 
    'Blackwork', 'Watercolor', 'Trash Polka', 'Fine Line', 'Traditional'
  ];

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

      // Yeni "Denormalize" sistemle puanı doğrudan modelden alıyoruz
      // Not: totalLikes alanının UserModel'de tanımlı olduğundan emin olun.
      double currentArtistScore = (_currentUser!.totalLikes ?? 0).toDouble();

      final postData = {
        'id': postRef.id,
        'artistId': _currentUser!.uid,
        'artistUsername': _currentUser!.username,
        'artistProfileImageUrl': _currentUser!.profileImageUrl,
        'imageUrls': imageUrls,
        'videoUrls': [],
        'caption': _captionController.text.trim().isEmpty ? null : _captionController.text.trim(),
        'likeCount': 0,
        'likedBy': [],
        'application': _selectedApplication, 
        'styles': _selectedStyles,
        'district': _currentUser!.district,
        'city': _currentUser!.city,
        'locationString': "${_currentUser!.district}, ${_currentUser!.city}",
        'artistScore': currentArtistScore, 
        'createdAt': FieldValue.serverTimestamp(),
      };

      await postRef.set(postData);

      // Kullanıcının profilindeki dövme sayısını güncelle
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
      appBar: AppBar(
        title: const Text('Yeni Paylaşım'),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _uploadPost,
            child: _isUploading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Paylaş', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  height: 250,
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
                      icon: const Icon(Icons.image),
                      label: const Text('Fotoğraf'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.videocam),
                      label: const Text('Video'),
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 32),

              // --- Uygulama Türü ---
              const Text('Uygulama Türü', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _applicationOptions.map((app) {
                  final isSelected = _selectedApplication == app;
                  return ChoiceChip(
                    label: Text(app),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedApplication = selected ? app : null);
                    },
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // --- Stiller ---
              const Text('Stiller', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _styleOptions.map((style) {
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
                    selectedColor: AppTheme.primaryColor.withOpacity(0.8),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              
              // Açıklama Kutusu
              TextFormField(
                controller: _captionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Paylaşımınız hakkında detay verin...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
      width: 180,
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
      width: 180,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.black, 
        borderRadius: BorderRadius.circular(12)
      ),
      child: const Center(
        child: Icon(Icons.play_circle_outline, size: 48, color: Colors.white)
      ),
    );
  }
}