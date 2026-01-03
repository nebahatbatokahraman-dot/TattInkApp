import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';
import '../models/user_model.dart';
import '../models/post_model.dart'; 
import '../utils/constants.dart';
import '../app_localizations.dart';
import '../theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  final PostModel? post;
  final bool isEditing;

  const CreatePostScreen({
    super.key, 
    this.post, 
    this.isEditing = false
  });

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
  
  bool _isScrolled = false;

  String? _selectedApplication; 
  List<String> _selectedStyles = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
    
    if (widget.isEditing && widget.post != null) {
      _loadExistingPostData();
    }
  }

  void _loadExistingPostData() {
    final post = widget.post!;
    _captionController.text = _extractCaptionWithoutTags(post.caption ?? "");
    
    if (post.application != null && AppConstants.applications.contains(post.application)) {
      _selectedApplication = post.application;
    }
    
    if (post.styles.isNotEmpty) {
      _selectedStyles.addAll(post.styles);
    }
  }
  
  String _extractCaptionWithoutTags(String fullCaption) {
    if (!fullCaption.contains('#')) return fullCaption;
    return fullCaption.split('#').first.trim();
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

  List<String> _getRelevantStyles() {
    if (_selectedApplication == null) return [];
    if (AppConstants.applicationStylesMap.containsKey(_selectedApplication)) {
      return AppConstants.applicationStylesMap[_selectedApplication]!;
    }
    return [];
  }

  Future<void> _pickImages() async {
    if (widget.isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.translate('media_cannot_be_changed_edit_mode'))));
      return;
    }
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((x) => File(x.path)));
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.translate('error_prefix')}: $e')));
    }
  }

  Future<void> _pickVideo() async {
    if (widget.isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.translate('media_cannot_be_changed_edit_mode'))));
      return;
    }
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedVideos.add(File(video.path));
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.translate('error_prefix')}: $e')));
    }
  }

  Future<void> _uploadPost() async {
    if (!widget.isEditing && _selectedImages.isEmpty && _selectedVideos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.translate('please_select_media'))));
      return;
    }

    if (_selectedApplication == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.translate('please_select_application'))));
      return;
    }

    if (_currentUser == null) return;

    setState(() => _isUploading = true);

    try {
      String finalCaption = _captionController.text.trim();
      
      List<String> allTags = [];
      if (_selectedApplication != null) allTags.add(_selectedApplication!);
      allTags.addAll(_selectedStyles);
      
      String formattedTags = allTags.map((tag) {
        final cleanTag = tag.replaceAll(' ', ''); 
        return "#$cleanTag"; 
      }).join(' ');
      
      finalCaption = "$finalCaption\n\n$formattedTags".trim();

      if (widget.isEditing) {
        await FirebaseFirestore.instance.collection(AppConstants.collectionPosts).doc(widget.post!.id).update({
          'caption': finalCaption,
          'application': _selectedApplication,
          'styles': _selectedStyles,
        });
        
        if (mounted) {
          final updatedPost = widget.post!.copyWith(
            caption: finalCaption,
            application: _selectedApplication,
            styles: _selectedStyles,
          );
          Navigator.pop(context, updatedPost);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.translate('post_updated')), backgroundColor: Colors.green));
        }
      } 
      else {
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
        
        String? uploadedVideoUrl;
        
        if (_selectedVideos.isNotEmpty) {
          File videoFile = _selectedVideos.first;
          
          try {
            String fileExtension = videoFile.path.split('.').last.toLowerCase();
            String fileName = 'post_videos/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
            
            String contentType = (fileExtension == 'mov' || fileExtension == 'qt') 
                ? 'video/quicktime' 
                : 'video/mp4';

            Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
            
            final videoBytes = await videoFile.readAsBytes();
            
            UploadTask uploadTask = storageRef.putData(
              videoBytes,
              SettableMetadata(contentType: contentType),
            );
            
            TaskSnapshot snapshot = await uploadTask;
            uploadedVideoUrl = await snapshot.ref.getDownloadURL();
            
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${AppLocalizations.of(context)!.translate('video_error')}: $e'),
                backgroundColor: Colors.red,
              ));
            }
            setState(() => _isUploading = false); 
            return;
          }
        }

        final postRef = FirebaseFirestore.instance.collection(AppConstants.collectionPosts).doc();

        final postData = {
          'id': postRef.id,
          'artistId': _currentUser!.uid,
          'artistUsername': _currentUser!.username ?? _currentUser!.fullName,
          'artistProfileImageUrl': _currentUser!.profileImageUrl,
          'imageUrls': imageUrls,
          'videoUrl': uploadedVideoUrl, 
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
          'isFeatured': false,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await postRef.set(postData);

        await FirebaseFirestore.instance
            .collection(AppConstants.collectionUsers)
            .doc(_currentUser!.uid)
            .update({'tattooCount': FieldValue.increment(1)});

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.translate('post_published_successfully')), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final relevantStyles = _getRelevantStyles();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: Text(widget.isEditing ? AppLocalizations.of(context)!.translate('edit_post') : AppLocalizations.of(context)!.translate('new_post'), style: const TextStyle(color: AppTheme.textColor)),
        backgroundColor: _isScrolled ? AppTheme.cardColor : Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textColor),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _uploadPost,
            child: _isUploading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                : Text(widget.isEditing ? AppLocalizations.of(context)!.translate('save') : AppLocalizations.of(context)!.translate('share_post'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 16)),
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
                
                if (!widget.isEditing) ...[
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
                          label: Text(AppLocalizations.of(context)!.translate('add_photo'), style: TextStyle(color: AppTheme.textColor)),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey[800]!), padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickVideo,
                          icon: const Icon(Icons.videocam, color: AppTheme.textColor),
                          label: Text(AppLocalizations.of(context)!.translate('add_video'), style: TextStyle(color: AppTheme.textColor)),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey[800]!), padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                   Text(AppLocalizations.of(context)!.translate('existing_media_cannot_edit'), style: TextStyle(color: Colors.grey, fontSize: 12)),
                   const SizedBox(height: 8),
                   SizedBox(
                     height: 120,
                     child: ListView.builder(
                       scrollDirection: Axis.horizontal,
                       itemCount: widget.post?.imageUrls.length ?? 0,
                       itemBuilder: (context, index) {
                         return Padding(
                           padding: const EdgeInsets.only(right: 8.0),
                           child: ClipRRect(
                             borderRadius: BorderRadius.circular(12),
                             child: Image.network(widget.post!.imageUrls[index], width: 120, fit: BoxFit.cover),
                           ),
                         );
                       },
                     ),
                   ),
                ],
                
                const Divider(height: 32, color: AppTheme.textColor),

                Text(AppLocalizations.of(context)!.translate('application_type'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.applications.map((app) {
                    final isSelected = _selectedApplication == app;
                    return Theme(
                      data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
                      child: ChoiceChip(
                        // DÜZELTME BURADA YAPILDI: Çeviri eklendi
                        label: Text(AppLocalizations.of(context)!.translate(app)),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (selected) {
                          setState(() {
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

                if (_selectedApplication != null && relevantStyles.isNotEmpty) ...[
                  Text(AppLocalizations.of(context)!.translate('styles'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: relevantStyles.map((style) {
                      final isSelected = _selectedStyles.contains(style);
                      return Theme(
                        data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
                        child: FilterChip(
                          // DÜZELTME BURADA YAPILDI: Çeviri eklendi
                          label: Text(AppLocalizations.of(context)!.translate(style)),
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
                    labelText: AppLocalizations.of(context)!.translate('description'),
                    labelStyle: const TextStyle(color: Colors.grey),
                    hintText: AppLocalizations.of(context)!.translate('provide_post_details'),
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