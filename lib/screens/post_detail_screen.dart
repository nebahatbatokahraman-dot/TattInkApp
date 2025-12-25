import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';
import '../services/image_service.dart';

class PostDetailScreen extends StatefulWidget {
  final List<PostModel> posts;
  final int initialIndex;
  final bool isOwner;

  const PostDetailScreen({
    super.key, 
    required this.posts, 
    required this.initialIndex, 
    required this.isOwner
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late PageController _verticalPageController;
  late int _currentPostIndex;
  
  // Düzenlenen açıklamaları anlık göstermek için yerel hafıza
  final Map<String, String> _localCaptions = {};

  @override
  void initState() {
    super.initState();
    _currentPostIndex = widget.initialIndex;
    _verticalPageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _verticalPageController.dispose();
    super.dispose();
  }

  PostModel get currentPost => widget.posts[_currentPostIndex];

  // O anki postun açıklamasını (varsa düzenlenmiş halini) getir
  String get currentCaption => _localCaptions[currentPost.id] ?? currentPost.caption ?? "";

  Future<void> _deletePost() async {
    final postToDelete = currentPost;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Text("Gönderiyi Sil", style: TextStyle(color: Colors.white)),
        content: const Text("Bu gönderiyi silmek istediğine emin misin?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal", style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Sil", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Siliniyor...")));

      final imageService = ImageService();
      for (var url in postToDelete.imageUrls) {
        await imageService.deleteImage(url);
      }

      await FirebaseFirestore.instance.collection(AppConstants.collectionPosts).doc(postToDelete.id).delete();

      if (postToDelete.likeCount > 0) {
        await FirebaseFirestore.instance.collection(AppConstants.collectionUsers).doc(postToDelete.artistId).update({
          'totalLikes': FieldValue.increment(-postToDelete.likeCount),
        });
      }

      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gönderi silindi.")));
      }
    } catch (e) {
      debugPrint("Silme hatası: $e");
    }
  }

  Future<void> _editPost() async {
    final postToEdit = currentPost;
    // O anki görünen açıklamayı al
    final TextEditingController captionController = TextEditingController(text: currentCaption);

    final newCaption = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Text("Düzenle", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: captionController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Açıklama...",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () => Navigator.pop(context, captionController.text), child: const Text("Kaydet", style: TextStyle(color: AppTheme.primaryColor))),
        ],
      ),
    );

    if (newCaption != null && newCaption != currentCaption) {
      await FirebaseFirestore.instance
          .collection(AppConstants.collectionPosts)
          .doc(postToEdit.id)
          .update({'caption': newCaption});
      
      if (mounted) {
        setState(() {
          // Model final olduğu için değiştiremeyiz, yerel map'e kaydediyoruz
          _localCaptions[postToEdit.id] = newCaption; 
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          "${_currentPostIndex + 1} / ${widget.posts.length}", 
          style: const TextStyle(color: Colors.white70, fontSize: 14)
        ),
        centerTitle: true,
        actions: [
          if (widget.isOwner)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: const Color(0xFF252525),
              onSelected: (value) {
                if (value == 'edit') _editPost();
                if (value == 'delete') _deletePost();
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.white), SizedBox(width: 8), Text('Düzenle', style: TextStyle(color: Colors.white))])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.redAccent), SizedBox(width: 8), Text('Sil', style: TextStyle(color: Colors.redAccent))])),
              ],
            ),
        ],
      ),
      
      body: PageView.builder(
        controller: _verticalPageController,
        itemCount: widget.posts.length,
        scrollDirection: Axis.vertical, 
        onPageChanged: (index) {
          setState(() {
            _currentPostIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return _buildSinglePostView(widget.posts[index]);
        },
      ),
    );
  }

  Widget _buildSinglePostView(PostModel post) {
    // Bu post için güncel açıklamayı al (düzenlendiyse o gelir, yoksa orjinal)
    String displayCaption = _localCaptions[post.id] ?? post.caption ?? "";

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.width, 
              child: _buildImageCarousel(post),
            ),
            
            if (displayCaption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  displayCaption, 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(color: Colors.white, fontSize: 16)
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Text(
                "${post.likeCount} Beğeni", 
                style: const TextStyle(color: Colors.grey, fontSize: 14)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(PostModel post) {
    if (post.imageUrls.length <= 1) {
      return InteractiveViewer(
        child: CachedNetworkImage(
          imageUrl: post.imageUrls.isNotEmpty ? post.imageUrls[0] : '',
          fit: BoxFit.contain,
          placeholder: (c, u) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          errorWidget: (c, u, e) => const Icon(Icons.error, color: Colors.white),
        ),
      );
    }
    return _HorizontalImageSlider(imageUrls: post.imageUrls);
  }
}

class _HorizontalImageSlider extends StatefulWidget {
  final List<String> imageUrls;
  const _HorizontalImageSlider({required this.imageUrls});

  @override
  State<_HorizontalImageSlider> createState() => _HorizontalImageSliderState();
}

class _HorizontalImageSliderState extends State<_HorizontalImageSlider> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PageView.builder(
          scrollDirection: Axis.horizontal, 
          itemCount: widget.imageUrls.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.contain,
                placeholder: (c, u) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                errorWidget: (c, u, e) => const Icon(Icons.error, color: Colors.white),
              ),
            );
          },
        ),
        
        Positioned(
          bottom: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.imageUrls.asMap().entries.map((entry) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == entry.key
                      ? AppTheme.primaryColor
                      : Colors.white.withOpacity(0.4),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}