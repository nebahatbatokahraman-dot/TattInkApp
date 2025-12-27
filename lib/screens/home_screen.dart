import 'post_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math; // Açı hesaplaması için eklendi
import 'dart:ui'; //glass effect//

// --- IMPORTS ---
import '../models/post_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart'; 
import '../utils/constants.dart';
import '../utils/turkey_locations.dart'; 
import '../utils/slide_route.dart';
import '../theme/app_theme.dart';
import '../widgets/login_required_dialog.dart';

// --- EKRANLAR ---
import 'create_post_screen.dart';
import 'chat_screen.dart';
import 'settings/notifications_screen.dart';
import 'profile/artist_profile_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState(); 
}

class HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
      );
    }
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() { });
  }

  // --- KULLANICI KONTROLLERİ ---
  bool _checkUserStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      LoginRequiredDialog.show(context);
      return false;
    }
    if (!user.emailVerified) {
      _showVerificationRequired();
      return false;
    }
    return true;
  }

  void _showVerificationRequired() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text('E-posta Onayı Gerekli', style: TextStyle(color: AppTheme.textColor)),
        content: const Text(
          'Beğeni yapabilmek ve mesaj atabilmek için e-posta onayı gereklidir.',
          style: TextStyle(color: AppTheme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- FİLTRE DEĞİŞKENLERİ ---
  final List<String> _selectedApplications = [];
  final List<String> _selectedStyles = [];
  String? _selectedDistrict;
  String? _selectedCity;
  double _minScore = 0.0;
  String? _sortOption;

  @override

  //HEADER VE GLASS EFFECT//
  Widget build(BuildContext context) {
  // Ayarları buradan kolayca yapabilirsin:
  const double blurAmount = 20.0; // Bulanıklık şiddeti
  const double glassOpacity = 0.10; // Camın rengi (%30 Siyah)
  
  // Header yüksekliği (SafeArea hariç tahmini yükseklik)
  // Post listesini bu kadar aşağı iteceğiz.
  
  const double headerHeight = 0.0; 
  

  return Container(
    // 1. ZEMİN (Atmosferik Arka Plan)
    decoration: const BoxDecoration(
      gradient: AppTheme.atmosphericBackgroundGradient, 
    ),
    child: Scaffold(
      backgroundColor: Colors.transparent, // Scaffold şeffaf
      
      // STACK: Katmanlı Yapı
      body: Stack(
        children: [
          // KATMAN 1: POST AKIŞI (En altta)
          Positioned.fill(
            child: Padding(
              // Header'ın altında kalmasın diye üstten boşluk bırakıyoruz
              padding: EdgeInsets.only(top: headerHeight), 
              child: _buildPostFeed(), 
            ),
          ),

          // KATMAN 2: TEK PARÇA GLASS HEADER (En üstte sabit)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect( // Blur taşmasın
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
                child: Container(
                  width: double.infinity,
                  
                  // DÜZELTİLEN YER BURASI: 
                  // Dışarıdaki 'color' satırını sildim. Sadece decoration içinde kaldı.
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor.withOpacity(0.9),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.1), 
                        width: 0.5
                      ),
                    ),
                  ),
                  
                  // İçerik (SafeArea ile çentik altına alıyoruz)
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 5.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // A) LOGO VE BİLDİRİM
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 40,
                                  child: CachedNetworkImage(
                                    imageUrl: AppConstants.logoUrl,
                                    height: 40,
                                    fit: BoxFit.contain,
                                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                                  ),
                                ),
                                _buildNotificationIcon(),
                              ],
                            ),
                          ),

                          // B) BUTONLAR
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showFilterBottomSheet(context),
                                    icon: const Icon(Icons.tune, size: 18, color: AppTheme.primaryColor),
                                    label: const Text('Filtrele', style: TextStyle(color: AppTheme.primaryColor)),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: AppTheme.backgroundColor.withOpacity(0.3),
                                      side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.8)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showSortBottomSheet(context),
                                    icon: const Icon(Icons.sort, size: 18, color: AppTheme.primaryColor),
                                    label: Text(_getSortButtonLabel(), style: const TextStyle(color: AppTheme.primaryColor)),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: AppTheme.backgroundColor.withOpacity(0.3),
                                      side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.8)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    ),
  );
}

  Widget _buildFloatingActionButton() {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return StreamBuilder(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            return FutureBuilder(
              future: authService.getUserModel(snapshot.data!.uid),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const SizedBox.shrink();
                final user = userSnapshot.data!;
                if ((user.role == AppConstants.roleArtistApproved || user.role == "artist") && user.isApproved) {
                  return FloatingActionButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
                    },
                    child: const Icon(Icons.add),
                  );
                }
                return const SizedBox.shrink();
              },
            );
          },
        );
      },
    );
  }

Widget _buildPostFeed() {
  Query query = FirebaseFirestore.instance.collection(AppConstants.collectionPosts);
  
  // Şimdi sıralama mantığını güvenle ekleyebiliriz
  if (_sortOption == AppConstants.sortPopular) {
    query = query
        .orderBy('isFeatured', descending: true) // Önce Premiumlar
        .orderBy('likeCount', descending: true);
  } else {
    query = query
        .orderBy('isFeatured', descending: true) // Önce Premiumlar
        .orderBy('createdAt', descending: true);
  }


  return StreamBuilder<QuerySnapshot>(
    stream: query.snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Henüz paylaşım yok'));

      final filteredPosts = snapshot.data!.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .where((post) {
        if (_selectedDistrict != null) {
          if (!post.locationString.toLowerCase().contains(_selectedDistrict!.toLowerCase())) return false;
        }
        if (_selectedApplications.isNotEmpty) {
          bool match = _selectedApplications.any((app) => (post.caption?.toLowerCase().contains(app.toLowerCase()) ?? false));
          if (!match) return false;
        }
        if (_selectedStyles.isNotEmpty) {
           bool match = _selectedStyles.any((style) => (post.caption?.toLowerCase().contains(style.toLowerCase()) ?? false));
          if (!match) return false;
        }
        return true;
      }).toList();

      return RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.primaryColor,
        backgroundColor: AppTheme.cardColor,
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(), 
          padding: const EdgeInsets.only(top: 170, bottom: 100),
          itemCount: filteredPosts.length + (filteredPosts.length ~/ 3),
          itemBuilder: (context, index) {
            // Her 4. sırada (index 3, 7, 11...) reklam kartı göster
            if (index % 4 == 3) {
              return _buildDynamicAds(); // ARTIK DİNAMİK OLANI ÇAĞIRIYORUZ
            }

            final postIndex = index - (index ~/ 4);
            if (postIndex >= filteredPosts.length) return const SizedBox.shrink();

            final post = filteredPosts[postIndex];
            return _buildPostCard(post);
          },
        ),
      );
    },
  );
}

//REKLAM KARTI//
Widget _buildAdPostCard({
  required String title,
  required String subtitle,
  required String content,
  String? imageUrl,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Container(
            height: 250,
            width: double.infinity,
            decoration: const BoxDecoration(color: AppTheme.textColor),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 50),
                  )
                : const Center(child: Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 70)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.cardColor,
                    child: Icon(Icons.stars, color: AppTheme.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {}, // İstersen buraya link verebilirsin
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                    child: const Text("Bilgi Al", style: TextStyle(color: AppTheme.textColor, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(content, style: const TextStyle(color: AppTheme.textColor, fontSize: 13, height: 1.4)),
            ],
          ),
        ),
      ],
    ),
  );
}


//DINAMIK REKLAM KARTI//
Widget _buildDynamicAds() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('ads') // Firestore'daki koleksiyon adın
        .where('isActive', isEqualTo: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        // Eğer Firebase'de reklam yoksa, senin eski sabit reklamını gösterelim ki boş kalmasın
        return _buildAdPostCard(
          title: "TattInk Premium",
          subtitle: "Sponsorlu",
          content: "Kendi stüdyonu şimdi öne çıkar! Profilini binlerce sanatseverle buluştur.",
          imageUrl: null,
        );
      }

      final adDocs = snapshot.data!.docs;
      // Rastgele bir reklam seçmek için (veya listelemek için)
      final adData = adDocs[math.Random().nextInt(adDocs.length)];

      return _buildAdPostCard(
        title: adData['title'] ?? "TattInk",
        subtitle: adData['subtitle'] ?? "Sponsorlu",
        content: adData['content'] ?? "",
        imageUrl: adData['imageUrl'],
      );
    },
  );
}



void _openFullScreenPost(PostModel post) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isOwner = (currentUserId != null && currentUserId == post.artistId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(
          posts: [post],     // <-- TEK POSTU KÖŞELİ PARANTEZLE LİSTE YAPTIK
          initialIndex: 0,   // <-- LİSTE TEK ELEMANLI OLDUĞU İÇİN INDEX 0
          isOwner: isOwner 
        ),
      ),
    );
  }

Widget _buildPostCard(PostModel post) {
    final ValueNotifier<bool> isExpandedNotifier = ValueNotifier<bool>(false);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isOwnPost = currentUserId == post.artistId;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(post.artistId).get(),
      builder: (context, artistSnapshot) {
        final bool isPremium = artistSnapshot.hasData && 
                              (artistSnapshot.data?.data() as Map<String, dynamic>?)?['isFeatured'] == true;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: isPremium ? [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.6), 
                blurRadius: 7,
                spreadRadius: 1,
              )
            ] : null,

            // 🔥 ÇERÇEVE (Border) - Hata veren satırın düzeltilmiş hali
            border: isPremium ? Border.all(color: AppTheme.primaryColor, width: 1.2) : null, 
          ),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            elevation: isPremium ? 0 : 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _openFullScreenPost(post),
                      child: _buildPostMedia(post),
                    ),
                    if (isPremium)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stars, color: AppTheme.textColor, size: 14),
                              SizedBox(width: 4),
                              Text("ÖNE ÇIKAN", style: TextStyle(color: AppTheme.textColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                Container(
                  color: AppTheme.cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: isOwnPost ? null : () {
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(
                                      builder: (context) => ArtistProfileScreen(
                                        userId: post.artistId,
                                        isOwnProfile: false,
                                      )
                                    )
                                  );
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.grey[800],
                                      backgroundImage: post.artistProfileImageUrl != null && post.artistProfileImageUrl!.isNotEmpty
                                          ? CachedNetworkImageProvider(post.artistProfileImageUrl!) : null,
                                      child: post.artistProfileImageUrl == null || post.artistProfileImageUrl!.isEmpty
                                          ? const Icon(Icons.person, size: 20, color: AppTheme.textColor) : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (post.artistUsername != null)
                                            Text(post.artistUsername!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor, fontSize: 14), overflow: TextOverflow.ellipsis),
                                          if (post.locationString.isNotEmpty)
                                            Text(post.locationString, style: TextStyle(fontSize: 11, color: Colors.grey[400]), overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, -2),
                                  child: Transform.rotate(
                                    angle: -45 * math.pi / 180,
                                    child: IconButton(
                                      onPressed: () => _handleMessagePost(post),
                                      icon: const Icon(Icons.send_rounded, color: AppTheme.primaryColor, size: 24),
                                    ),
                                  ),
                                ),
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _buildLikeButton(post),
                                    if (post.likeCount > 0)
                                      Positioned(
                                        right: 9,
                                        top: 25,
                                        child: Text("${post.likeCount}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (post.caption != null && post.caption!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
                          child: ValueListenableBuilder<bool>(
                            valueListenable: isExpandedNotifier,
                            builder: (context, isExpanded, child) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => isExpandedNotifier.value = !isExpandedNotifier.value,
                                    child: RichText(
                                      maxLines: isExpanded ? null : 1,
                                      overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                      text: TextSpan(
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textColor),
                                        children: [TextSpan(text: post.caption!)],
                                      ),
                                    ),
                                  ),
                                  if (!isExpanded && post.caption!.length > 60)
                                    GestureDetector(
                                      onTap: () => isExpandedNotifier.value = true,
                                      child: const Padding(
                                        padding: EdgeInsets.only(top: 4.0),
                                        child: Text("daha fazla...", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  } // <--- METOD BURADA BİTİYOR




Widget _buildPostMedia(PostModel post) {
    if (post.imageUrls.isEmpty) return const SizedBox.shrink();

    // Eğer sadece 1 resim varsa Slider çalıştırmaya gerek yok, direkt resmi göster (Performans için)
    if (post.imageUrls.length == 1) {
      return CachedNetworkImage(
        imageUrl: post.imageUrls[0],
        width: double.infinity,
        fit: BoxFit.cover, // BoxFit.fitWidth yerine cover daha şık durabilir
        placeholder: (context, url) => Container(
          height: 300, 
          color: AppTheme.backgroundColor, 
          child: const Center(child: CircularProgressIndicator())
        ),
        errorWidget: (context, url, error) => Container(
          height: 300, 
          color: AppTheme.backgroundColor, 
          child: const Icon(Icons.broken_image, color: Colors.grey)
        ),
      );
    }

    // Birden fazla resim varsa Slider Widget'ı çağır
    return HomePostSlider(
      imageUrls: post.imageUrls,
      onTap: () => _openFullScreenPost(post), // Tıklayınca yine detaya gitsin
    );
  }

  Widget _buildLikeButton(PostModel post) {
    final userId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection(AppConstants.collectionLikes).doc('${post.id}_${userId ?? ""}').snapshots(),
      builder: (context, snapshot) {
        final isLiked = snapshot.hasData && snapshot.data!.exists;
        return GestureDetector(
          onTap: () => _handleLike(post, isLiked),
          child: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border, 
            color: isLiked ? AppTheme.primaryColor : AppTheme.primaryColor, 
            size: 26
          ),
        );
      },
    );
  }

  // --- GÜNCELLENEN BEĞENİ FONKSİYONU ---
  Future<void> _handleLike(PostModel post, bool isLiked) async {
    if (!_checkUserStatus()) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    
    if (userId == null) return;

    final likeDocRef = FirebaseFirestore.instance.collection(AppConstants.collectionLikes).doc('${post.id}_$userId');
    final postRef = FirebaseFirestore.instance.collection(AppConstants.collectionPosts).doc(post.id);
    
    // Artistin puanını tutan referans
    final artistRef = FirebaseFirestore.instance.collection(AppConstants.collectionUsers).doc(post.artistId);

    if (isLiked) {
      // 1. Beğeniyi Kaldır
      await likeDocRef.delete();
      // 2. Postun beğeni sayısını azalt
      await postRef.update({'likeCount': FieldValue.increment(-1)});
      // 3. ARTİSTİN TOTAL LIKES PUANINI AZALT
      await artistRef.update({'totalLikes': FieldValue.increment(-1)});
    } else {
      // 1. Beğeni Ekle
      await likeDocRef.set({'postId': post.id, 'userId': userId, 'createdAt': FieldValue.serverTimestamp()});
      // 2. Postun beğeni sayısını artır
      await postRef.update({'likeCount': FieldValue.increment(1)});
      // 3. ARTİSTİN TOTAL LIKES PUANINI ARTIR
      await artistRef.update({'totalLikes': FieldValue.increment(1)});
      
      // 4. Bildirim Gönder
      final currentUserData = await authService.getUserModel(userId);
      if (currentUserData != null) {
        await NotificationService.sendLikeNotification(userId, currentUserData.fullName, currentUserData.profileImageUrl, post.artistId, post.id);
      }
    }
  }

  void _handleMessagePost(PostModel post) {
    if (!_checkUserStatus()) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(receiverId: post.artistId, receiverName: post.artistUsername ?? 'Artist', referenceImageUrl: post.imageUrls.isNotEmpty ? post.imageUrls[0] : null)));
  }

  String _getSortButtonLabel() {
    if (_sortOption == null) return 'Sırala';
    switch (_sortOption) {
      case AppConstants.sortNewest: return 'En Yeniler';
      case AppConstants.sortPopular: return 'En Popüler';
      default: return 'Sırala';
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent, // 1. ÖNEMLİ: Burası şeffaf olmalı
  builder: (context) => ClipRRect( // 2. Bulanıklığı köşelere göre kırpıyoruz
    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // 3. Buzlu camın bulanıklık şiddeti
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          // 4. Rengin kendisi biraz şeffaf olmalı ki arkası görünsün
          // AppTheme.backgroundColor yerine dark bir renk veya temanın şeffaf hali:
          color: AppTheme.backgroundColor.withOpacity(0.8), 
          // İsteğe bağlı: Cam hissini artırmak için ince bir kenarlık
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
          ),
        ),
        child: Column(
          children: [
            // --- Gri Çubuk ---
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // --- İÇERİK (Stack ve diğer kodlar aynı) ---
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatefulBuilder( // StatefulBuilder'ı buraya taşıdım
                          builder: (context, setModalState) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFilterSection(
                                  'Uygulama',
                                  AppConstants.applications,
                                  _selectedApplications,
                                  (value) {
                                    setModalState(() {
                                      _selectedApplications.contains(value)
                                          ? _selectedApplications.remove(value)
                                          : _selectedApplications.add(value);
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildFilterSection(
                                  'Stil',
                                  AppConstants.styles,
                                  _selectedStyles,
                                  (value) {
                                    setModalState(() {
                                      _selectedStyles.contains(value)
                                          ? _selectedStyles.remove(value)
                                          : _selectedStyles.add(value);
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildDistrictSearch(setModalState),
                                const SizedBox(height: 16),
                              ],
                            );
                          }
                        ),
                      ],
                    ),
                  ),

                  // SIFIRLA BUTONU (Konumu aynı)
                  Positioned(
                    top: -2,
                    right: 8,
                    child: StatefulBuilder( // Sıfırlama işlemi için state lazım
                      builder: (context, setModalState) => TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedApplications.clear();
                            _selectedStyles.clear();
                            _selectedDistrict = null;
                            _selectedCity = null;
                            _minScore = 0.0;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Sıfırla',
                          style: TextStyle(color: AppTheme.textColor, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- UYGULA BUTONU (Padding düzeltilmiş hali) ---
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 40.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text(
                    'Uygula',
                    style: TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _buildFilterSection(String title, List<String> options, List<String> selected, Function(String) onToggle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor)), const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, children: options.map((option) { final isSelected = selected.contains(option); return GestureDetector(onTap: () => onToggle(option), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: isSelected ? AppTheme.primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.primaryLightColor, width: 1)), child: Text(option, style: const TextStyle(color: AppTheme.textColor, fontSize: 14)))); }).toList())]);
  }

  Widget _buildDistrictSearch(StateSetter setModalState) {
    return _DistrictSearchWidget(selectedDistrict: _selectedDistrict, selectedCity: _selectedCity, onDistrictSelected: (district, city) { setModalState(() { _selectedDistrict = district; _selectedCity = city; }); });
  }

  void _showSortBottomSheet(BuildContext context) {
showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent, // 1. Arka plan şeffaf
  builder: (context) => ClipRRect( // 2. Köşeleri yuvarla
    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    child: BackdropFilter( // 3. Bulanıklık Efekti
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.3,
        decoration: BoxDecoration(
          // 4. Arka plan rengini yarı şeffaf yap
          color: AppTheme.backgroundColor.withOpacity(0.8),
          // İsteğe bağlı: Üst kısma ince bir parlaklık çizgisi (Cam hissi için)
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
        ),
        child: Column(
          children: [
            // --- Gri Çubuk (Tutamaç) ---
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // --- Seçenekler Listesi ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  _buildSortOption('En Yeni En Üstte', Icons.refresh, AppConstants.sortNewest),
                  _buildSortOption('En Popüler En Üstte', Icons.local_fire_department, AppConstants.sortPopular),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);  
}

  Widget _buildSortOption(String label, IconData icon, String value) {
    final isSelected = _sortOption == value;
    return ListTile(leading: Icon(icon, color: AppTheme.primaryColor), title: Text(label, style: const TextStyle(color: AppTheme.primaryColor)), trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryColor) : null, onTap: () { setState(() { _sortOption = value; }); Navigator.pop(context); });
  }

  Widget _buildNotificationIcon() {
    final userId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    if (userId == null) return IconButton(icon: const Icon(Icons.notifications_outlined, color: AppTheme.primaryColor, size: 28), onPressed: () {});
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.collectionNotifications)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        
        return Stack(
          clipBehavior: Clip.none, 
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppTheme.primaryColor, size: 28), 
              onPressed: () { 
                Navigator.push(
                  context, 
                  SlideRoute(page: NotificationsSettingsScreen())
                ); 
              }
            ), 
            if (unreadCount > 0) 
              Positioned(
                right: 6, 
                top: 6, 
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), 
                  decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle), 
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18), 
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(), 
                      style: const TextStyle(color: AppTheme.textColor, fontSize: 10)
                    )
                  )
                )
              ),
          ],
        );
      },
    );
  }
}

class _DistrictSearchWidget extends StatefulWidget {
  final String? selectedDistrict;
  final String? selectedCity;
  final Function(String?, String?) onDistrictSelected;
  const _DistrictSearchWidget({required this.selectedDistrict, required this.selectedCity, required this.onDistrictSelected});
  @override State<_DistrictSearchWidget> createState() => _DistrictSearchWidgetState();
}

class _DistrictSearchWidgetState extends State<_DistrictSearchWidget> {
  late TextEditingController _searchController;
  List<Map<String, String>> _filteredDistricts = [];
  @override void initState() { super.initState(); _searchController = TextEditingController(text: widget.selectedDistrict != null && widget.selectedCity != null ? '${widget.selectedDistrict}, ${widget.selectedCity}' : ''); }
  @override void dispose() { _searchController.dispose(); super.dispose(); }
  void _updateFilteredDistricts(String query) {
    setState(() {
      if (query.isEmpty) { _filteredDistricts = []; widget.onDistrictSelected(null, null); }
      else { _filteredDistricts = []; for (var city in TurkeyLocations.citiesWithDistricts.keys) { for (var district in TurkeyLocations.citiesWithDistricts[city]!) { if (district.toLowerCase().contains(query.toLowerCase()) || city.toLowerCase().contains(query.toLowerCase())) { _filteredDistricts.add({'district': district, 'city': city}); } } } }
    });
  }
  @override Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Bölge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor)), const SizedBox(height: 8), TextField(controller: _searchController, style: const TextStyle(color: AppTheme.textColor), decoration: InputDecoration(hintText: 'Semt ara', hintStyle: const TextStyle(color: AppTheme.textColor), prefixIcon: const Icon(Icons.search, color: AppTheme.textColor), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), onChanged: _updateFilteredDistricts), if (_filteredDistricts.isNotEmpty) Container(margin: const EdgeInsets.only(top: 8), constraints: const BoxConstraints(maxHeight: 150), decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(8)), child: ListView.builder(shrinkWrap: true, itemCount: _filteredDistricts.length, itemBuilder: (context, index) { final item = _filteredDistricts[index]; return ListTile(title: Text('${item['district']}, ${item['city']}', style: const TextStyle(color: AppTheme.textColor)), onTap: () { _searchController.text = '${item['district']}, ${item['city']}'; widget.onDistrictSelected(item['district'], item['city']); setState(() { _filteredDistricts = []; }); }); })),]);
  }
}
// --- BU SINIFI HOME SCREEN DOSYASININ EN ALTINA EKLE ---

class HomePostSlider extends StatefulWidget {
  final List<String> imageUrls;
  final VoidCallback onTap; // Tıklanınca ne olacağını dışarıdan alacağız

  const HomePostSlider({super.key, required this.imageUrls, required this.onTap});

  @override
  State<HomePostSlider> createState() => _HomePostSliderState();
}

class _HomePostSliderState extends State<HomePostSlider> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Kare format (Instagram stili) için AspectRatio 1 yaptık. 
    // İstersen 4/5 yapabilirsin.
    return AspectRatio(
      aspectRatio: 1, 
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: widget.onTap, // Resme tıklayınca detay sayfasına git
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrls[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: AppTheme.backgroundColor),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              );
            },
          ),
          
          // --- NOKTA İŞARETÇİLERİ (Sadece 1'den fazla resim varsa göster) ---
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.imageUrls.asMap().entries.map((entry) {
                  return Container(
                    width: 6.0,
                    height: 6.0,
                    margin: const EdgeInsets.symmetric(horizontal: 3.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == entry.key
                          ? AppTheme.primaryColor
                          : AppTheme.textColor.withOpacity(0.5),
                    ),
                  );
                }).toList(),
              ),
            ),
          
        
        ],
      ),
    );
  }
}