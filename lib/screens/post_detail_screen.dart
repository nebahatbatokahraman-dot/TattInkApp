import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import '../theme/app_theme.dart';
import 'create_post_screen.dart';
import '../widgets/video_post_player.dart'; // Video oynatıcın burada

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
  final Map<String, String> _localCaptions = {}; // Düzenleme sonrası anlık güncelleme için

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
        content: const Text("Bu gönderiyi silmek istediğine emin misin? Bu işlem geri alınamaz.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sil", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      DocumentReference postRef = FirebaseFirestore.instance.collection('posts').doc(post.id);
      batch.delete(postRef);

      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(post.artistId);
      batch.update(userRef, {
        'totalPosts': FieldValue.increment(-1), 
        'totalLikes': FieldValue.increment(-post.likeCount), 
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gönderi silindi.")));
        Navigator.pop(context, true);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata oluştu: $e")));
      }
    }
  }

  // --- DÜZENLEME İŞLEMİ ---
  Future<void> _editPost() async { 
    final updatedPost = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(
          post: currentPost, 
          isEditing: true
        ),
      ),
    );

    if (updatedPost != null && updatedPost is PostModel) {
      setState(() {
        _localCaptions[updatedPost.id] = updatedPost.caption ?? "";
        widget.posts[_currentPostIndex] = updatedPost;
      });
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gönderi güncellendi"), backgroundColor: Colors.green),
        );
      }
    }
  }

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
          backgroundColor: AppTheme.cardColor.withOpacity(0.8),
          scrolledUnderElevation: 0,
          elevation: 0,
          leading: const BackButton(color: Colors.white), 
          centerTitle: true,
          actions: [
            if (widget.isOwner)
              Theme(
                data: Theme.of(context).copyWith(
                  cardColor: AppTheme.cardColor,
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'edit') _editPost();
                    if (value == 'delete') _deletePost();
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'edit', 
                      child: Row(children: [Icon(Icons.edit, color: AppTheme.textColor, size: 20), SizedBox(width: 8), Text('Düzenle', style: TextStyle(color: AppTheme.textColor))])
                    ),
                    const PopupMenuItem(
                      value: 'delete', 
                      child: Row(children: [Icon(Icons.delete, color: Colors.redAccent, size: 20), SizedBox(width: 8), Text('Sil', style: TextStyle(color: Colors.redAccent))])
                    ),
                  ],
                ),
              ),
          ],
        ),
        
        // 3. ÖZELLİK: Vertical Scroll (Aşağı/Yukarı kaydırarak post değiştirme)
        body: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: false),
          child: PageView.builder(
            controller: _verticalPageController,
            itemCount: widget.posts.length,
            scrollDirection: Axis.vertical, // Dikey kaydırma
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
    // 1. Ekran Yüksekliğini Al
    final double screenHeight = MediaQuery.of(context).size.height;
    
    // 2. Çentik/Dynamic Island Yüksekliği
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    // 3. AppBar Standart Yüksekliği (Flutter'da genelde 56.0'dır)
    const double appBarHeight = kToolbarHeight; 

    // 4. HESAPLAMA: 
    // Status Bar + AppBar + Ekranın %2'si kadar nefes payı
    // (0.02 yerine daha çok boşluk istersen 0.05 yapabilirsin)
    final double topPadding = statusBarHeight + appBarHeight + (screenHeight * 0.02);

    return Padding(
      // Buraya hesapladığımız değeri veriyoruz
      padding: EdgeInsets.only(top: topPadding),
    
      child: Column(
        children: [
          // GÖRSEL/MEDYA ALANI
          // 1. ve 2. ÖZELLİK: Çoklu medya ve Video/Foto karışık
          SizedBox(
            height: MediaQuery.of(context).size.width, // Kare veya 4:5 oran
            child: _buildMixedMediaCarousel(post),
          ),

          // Alt kısım (Açıklama ve Beğeni)
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

  // Medya Listesini Hazırlayan Fonksiyon
  Widget _buildMixedMediaCarousel(PostModel post) {
    // Tüm medyaları tek bir listede topluyoruz
    List<Map<String, String>> mediaItems = [];

    // 1. Varsa videoyu ekle
    if (post.videoUrl != null && post.videoUrl!.isNotEmpty) {
      mediaItems.add({
        'type': 'video',
        'url': post.videoUrl!,
      });
    }

    // 2. Resimleri ekle
    for (var imgUrl in post.imageUrls) {
      mediaItems.add({
        'type': 'image',
        'url': imgUrl,
      });
    }

    // Eğer liste boşsa (hata durumu)
    if (mediaItems.isEmpty) return const SizedBox();

    // Medya Slider Widget'ını Çağır
    return _HorizontalMediaSlider(mediaItems: mediaItems);
  }
}

// --- YENİ SLIDER WIDGET'I (VİDEO VE FOTO DESTEKLİ) ---
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
      alignment: Alignment.bottomCenter,
      children: [
        PageView.builder(
          scrollDirection: Axis.horizontal, 
          itemCount: widget.mediaItems.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final item = widget.mediaItems[index];
            final type = item['type'];
            final url = item['url']!;

            // TÜR KONTROLÜ
            if (type == 'video') {
              // Video ise Player'ı döndür (Zoom özelliği yok)
              return Container(
                color: Colors.black,
                child: Center(
                  child: VideoPostPlayer(videoUrl: url),
                ),
              );
            } else {
              // Resim ise Zoom özellikli Image döndür
              return InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (c, u) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                  errorWidget: (c, u, e) => const Icon(Icons.error, color: Colors.white),
                ),
              );
            }
          },
        ),
        
        // NOKTA GÖSTERGESİ (Sadece 1'den fazla medya varsa)
        if (widget.mediaItems.length > 1) 
          Positioned(
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.mediaItems.asMap().entries.map((entry) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == entry.key
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