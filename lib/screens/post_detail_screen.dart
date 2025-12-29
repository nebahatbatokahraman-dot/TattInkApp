import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import '../theme/app_theme.dart';

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

  Future<void> _deletePost() async { 
    // Silme işlemleri...
  }
  Future<void> _editPost() async { 
    // Düzenleme işlemleri...
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.atmosphericBackgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, 
        extendBodyBehindAppBar: true,
        
        appBar: AppBar(
          backgroundColor: Colors.transparent, 
          elevation: 0,
          leading: const BackButton(color: Colors.grey), 
          centerTitle: true,
          actions: [
            if (widget.isOwner)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                color: AppTheme.cardColor,
                onSelected: (value) {
                  if (value == 'edit') _editPost();
                  if (value == 'delete') _deletePost();
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: AppTheme.textColor), SizedBox(width: 8), Text('Düzenle', style: TextStyle(color: AppTheme.textColor))])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: AppTheme.primaryColor), SizedBox(width: 8), Text('Sil', style: TextStyle(color: AppTheme.primaryColor))])),
                ],
              ),
          ],
        ),
        
        body: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: false),
          child: PageView.builder(
            controller: _verticalPageController,
            itemCount: widget.posts.length,
            scrollDirection: Axis.vertical, 
            physics: const ClampingScrollPhysics(), 
            onPageChanged: (index) {
              setState(() {
                _currentPostIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildSinglePostView(widget.posts[index]);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSinglePostView(PostModel post) {
    String displayCaption = _localCaptions[post.id] ?? post.caption ?? "";
    
    // Cihazın üstündeki sistem çubuğu (saat/şarj kısmının) yüksekliği
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Padding(
      // Fotoğrafın tam 'Geri' butonuyla aynı hizada başlaması için
      // sadece sistem çubuğu yüksekliği kadar boşluk bırakıyoruz.
      padding: EdgeInsets.only(top: statusBarHeight + 50.0),
      child: Column(
        children: [
          // Resim Alanı (Genişlik kadar yükseklik - Kare)
          SizedBox(
            height: MediaQuery.of(context).size.width, 
            child: _buildImageCarousel(post),
          ),

          // Alt kısım kaydırılabilir (Açıklama ve Beğeni için)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (displayCaption.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                      child: Text(
                        displayCaption, 
                        textAlign: TextAlign.center, 
                        style: const TextStyle(color: Colors.white70, fontSize: 16) 
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Text(
                      "${post.likeCount} Beğeni", 
                      style: const TextStyle(color: Colors.white54, fontSize: 14)
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(PostModel post) {
    if (post.imageUrls.length <= 1) {
       final url = post.imageUrls.isNotEmpty ? post.imageUrls[0] : '';
       if (url.isEmpty) return const SizedBox();

       return InteractiveViewer(
        child: CachedNetworkImage(
          imageUrl: url,
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
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}