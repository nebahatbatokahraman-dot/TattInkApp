import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart'; // AppConstants buradan geliyor
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
  
  // AppBar Kaydırma Durumu
  bool _isScrolled = false;

  // Seçimler
  String? _selectedApplication; 
  final List<String> _selectedStyles = [];

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

  // --- OTOMATİK VERİ ÇEKME FONKSİYONU ---
  List<String> _getRelevantStyles() {
    if (_selectedApplication == null) return [];
    
    // AppConstants içindeki haritadan otomatik çekiyoruz
    if (AppConstants.applicationStylesMap.containsKey(_selectedApplication)) {
      return AppConstants.applicationStylesMap[_selectedApplication]!;
    }
    return [];
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<void> _uploadPost() async {
    if (_selectedImages.isEmpty && _selectedVideos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen en az bir görsel veya video seçin')));
      return;
    }

    if (_selectedApplication == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bir uygulama türü seçin')));
      return;
    }

    if (_currentUser == null) return;

    setState(() => _isUploading = true);

    try {
      final imageService = ImageService();
      final List<String> imageUrls = [];

      for (final imageFile in _selectedImages) {
        final optimizedImage = await imageService.optimizeImage(imageFile);
        final url = await imageService.uploadImage(
          imageBytes: optimizedImage,
          path: AppConstants.storagePostImages,
        );
        imageUrls.add(url);
      }

      final postRef = FirebaseFirestore.instance.collection(AppConstants.collectionPosts).doc();

      String finalCaption = _captionController.text.trim();
      // Aramada kolay bulunması için etiketleri sona ekliyoruz
      String tagsSuffix = "\n\n${_selectedApplication ?? ''} ${_selectedStyles.join(' ')}";
      finalCaption = "$finalCaption $tagsSuffix".trim();

      final postData = {
        'id': postRef.id,
        'artistId': _currentUser!.uid,
        'artistUsername': _currentUser!.username ?? _currentUser!.fullName,
        'artistProfileImageUrl': _currentUser!.profileImageUrl,
        'imageUrls': imageUrls,
        'videoUrls': [],
        'caption': finalCaption,
        'likeCount': 0,
        'likedBy': [],
        'application': _selectedApplication, 
        'styles': _selectedStyles,
        'district': _currentUser!.district,
        'city': _currentUser!.city,
        'locationString': _currentUser!.locationString.isNotEmpty 
            ? _currentUser!.locationString 
            : "${_currentUser!.district}, ${_currentUser!.city}",
        'artistScore': (_currentUser!.totalLikes ?? 0).toDouble(),
        
        // --- BURASI EKLENDİ ---
        'isFeatured': false, // Varsayılan olarak öne çıkan değil
        // ---------------------
        
        'createdAt': FieldValue.serverTimestamp(),
      };

      await postRef.set(postData);

      await FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.uid)
          .update({'tattooCount': FieldValue.increment(1)});

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paylaşım başarıyla yayınlandı'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dinamik stilleri Constants dosyasından çekiyoruz
    final relevantStyles = _getRelevantStyles();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text('Yeni Paylaşım', style: TextStyle(color: AppTheme.textColor)),
        backgroundColor: _isScrolled ? AppTheme.cardColor : Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textColor),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _uploadPost,
            child: _isUploading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                : const Text('Paylaş', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 16)),
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollUpdateNotification) {
            final isScrolledNow = scrollNotification.metrics.pixels > 0;
            if (isScrolledNow != _isScrolled) setState(() => _isScrolled = isScrolledNow);
          }
          return false;
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
              left: 16, right: 16, bottom: 16
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                        icon: const Icon(Icons.image, color: AppTheme.textColor),
                        label: const Text('Fotoğraf Ekle', style: TextStyle(color: AppTheme.textColor)),
                        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey[800]!), padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickVideo,
                        icon: const Icon(Icons.videocam, color: AppTheme.textColor),
                        label: const Text('Video Ekle', style: TextStyle(color: AppTheme.textColor)),
                        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey[800]!), padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: 32, color: AppTheme.textColor),

                // --- UYGULAMA TÜRÜ (AppConstants'tan otomatik geliyor) ---
                const Text('Uygulama Türü', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.applications.map((app) {
                    final isSelected = _selectedApplication == app;
                    return Theme(
                      data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
                      child: ChoiceChip(
                        label: Text(app),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (selected) {
                          setState(() {
                            // Seçim değişirse Application'ı güncelle, Stilleri sıfırla
                            _selectedApplication = selected ? app : null;
                            _selectedStyles.clear();
                          });
                        },
                        selectedColor: AppTheme.primaryColor,
                        backgroundColor: AppTheme.cardColor,
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.textColor : Colors.grey[400],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.transparent),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // --- STİLLER (Otomatik hesaplanan relevantStyles listesi) ---
                if (_selectedApplication != null && relevantStyles.isNotEmpty) ...[
                  const Text('Stiller', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: relevantStyles.map((style) {
                      final isSelected = _selectedStyles.contains(style);
                      return Theme(
                        data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
                        child: FilterChip(
                          label: Text(style),
                          selected: isSelected,
                          showCheckmark: false,
                          onSelected: (selected) {
                            setState(() {
                              selected ? _selectedStyles.add(style) : _selectedStyles.remove(style);
                            });
                          },
                          selectedColor: AppTheme.primaryColor.withOpacity(0.3),
                          backgroundColor: AppTheme.cardColor,
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.textColor : Colors.grey[400],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.transparent),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
                
                TextFormField(
                  controller: _captionController,
                  maxLines: 4,
                  style: const TextStyle(color: AppTheme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Açıklama',
                    labelStyle: const TextStyle(color: Colors.grey),
                    hintText: 'Paylaşımınız hakkında detay verin...',
                    hintStyle: TextStyle(color: Colors.grey[700]),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: AppTheme.cardColor,
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
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(image, fit: BoxFit.cover)),
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _selectedImages.remove(image)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: AppTheme.textColor, size: 16),
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
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[800]!)),
      child: Stack(
        children: [
          const Center(child: Icon(Icons.play_circle_outline, size: 48, color: AppTheme.textColor)),
           Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _selectedVideos.remove(video)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: AppTheme.textColor, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}