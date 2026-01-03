import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import '../theme/app_theme.dart';
import 'create_post_screen.dart';
import '../widgets/video_post_player.dart';
import '../services/report_service.dart'; 

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

  // --- SİLME İŞLEMİ ---
  Future<void> _deletePost() async { 
    final post = currentPost;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text("Gönderiyi Sil", style: TextStyle(color: AppTheme.textColor)),
        content: const Text("Bu gönderiyi silmek istediğine emin misin?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Sil", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      // Postu sil
      batch.delete(FirebaseFirestore.instance.collection('posts').doc(post.id));
      // Artist istatistiklerini güncelle
      batch.update(FirebaseFirestore.instance.collection('users').doc(post.artistId), {
        'totalPosts': FieldValue.increment(-1), 
        'totalLikes': FieldValue.increment(-post.likeCount)
      });
      
      await batch.commit();
      
      if (mounted) {
        Navigator.pop(context, true); // Ekranı kapat ve yenilemesi için true döndür
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  // --- DÜZENLEME İŞLEMİ ---
  Future<void> _editPost() async { 
    final updatedPost = await Navigator.push(context, MaterialPageRoute(builder: (context) => CreatePostScreen(post: currentPost, isEditing: true)));
    if (updatedPost != null && updatedPost is PostModel) {
      setState(() {
        widget.posts[_currentPostIndex] = updatedPost;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Görsele tam odak
      extendBodyBehindAppBar: true,
      
      // Üst Bar (Geri ve Seçenekler)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
          child: const BackButton(color: Colors.white),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
            child: Theme(
              data: Theme.of(context).copyWith(cardColor: AppTheme.cardColor, iconTheme: const IconThemeData(color: Colors.white)),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'edit') _editPost();
                  if (value == 'delete') _deletePost();
                  if (value == 'report') {
                    ReportService.showReportDialog(context: context, contentId: currentPost.id, contentType: 'post', reportedUserId: currentPost.artistId);
                  }
                },
                itemBuilder: (context) => widget.isOwner 
                  ? [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: AppTheme.textColor, size: 20), SizedBox(width: 8), Text('Düzenle', style: TextStyle(color: AppTheme.textColor))])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.redAccent, size: 20), SizedBox(width: 8), Text('Sil', style: TextStyle(color: Colors.redAccent))])),
                    ]
                  : [
                      const PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.flag, color: Colors.redAccent, size: 20), SizedBox(width: 8), Text('Şikayet Et', style: TextStyle(color: Colors.redAccent))])),
                    ],
              ),
            ),
          ),
        ],
      ),
      
      // Ana İçerik (Dikey Kaydırma)
      body: PageView.builder(
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
          // Stack kullanmaya gerek kalmadı, direkt ortalayıp gösteriyoruz
          return Center(
            child: _buildMixedMediaCarousel(widget.posts[index]),
          );
        },
      ),
    );
  }

  // Medya Gösterici (Carousel)
  Widget _buildMixedMediaCarousel(PostModel post) {
    List<Map<String, String>> mediaItems = [];
    
    // Video var mı?
    if (post.videoUrl != null && post.videoUrl!.isNotEmpty) {
      mediaItems.add({'type': 'video', 'url': post.videoUrl!});
    }
    // Resimler var mı?
    for (var imgUrl in post.imageUrls) {
      mediaItems.add({'type': 'image', 'url': imgUrl});
    }

    if (mediaItems.isEmpty) return const SizedBox();
    
    return _HorizontalMediaSlider(mediaItems: mediaItems);
  }
}

// Yatay Medya Kaydırıcı (Zoom Destekli)
class _HorizontalMediaSlider extends StatefulWidget {
  final List<Map<String, String>> mediaItems;
  const _HorizontalMediaSlider({required this.mediaItems});
  
  @override
  State<_HorizontalMediaSlider> createState() => _HorizontalMediaSliderState();
}

class _HorizontalMediaSliderState extends State<_HorizontalMediaSlider> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PageView.builder(
          scrollDirection: Axis.horizontal, 
          itemCount: widget.mediaItems.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) {
            final item = widget.mediaItems[index];
            
            if (item['type'] == 'video') {
              // Videoda zoom yok, direkt player
              return Center(child: VideoPostPlayer(videoUrl: item['url']!));
            } else {
              // Resimde Sınırsız Zoom ve Gezinme (InteractiveViewer)
              return InteractiveViewer(
                minScale: 1.0, 
                maxScale: 4.0, 
                clipBehavior: Clip.none, // Resim çerçeveden taşabilir
                child: CachedNetworkImage(
                  imageUrl: item['url']!,
                  fit: BoxFit.contain, // Orijinal oranı koru, ekrana sığdır
                  placeholder: (c, u) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                  errorWidget: (c, u, e) => const Icon(Icons.error, color: Colors.white),
                ),
              );
            }
          },
        ),
        
        // Medya Sayısı Göstergesi (Noktalar) - Sadece birden fazla medya varsa görünür
        if (widget.mediaItems.length > 1) 
          Positioned(
            bottom: 40, 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: widget.mediaItems.asMap().entries.map((entry) {
                return Container(
                  width: 6.0, 
                  height: 6.0, 
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    color: _currentIndex == entry.key ? Colors.white : Colors.white.withOpacity(0.3)
                  )
                );
              }).toList()
            )
          ),
      ],
    );
  }
}