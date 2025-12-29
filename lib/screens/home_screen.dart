import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'dart:ui'; // Glass effect ve ImageFilter için gerekli

// --- IMPORTS ---
import '../models/post_model.dart';
import '../models/user_model.dart'; // UserModel için
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
import 'post_detail_screen.dart'; // PostDetailScreen importu
import 'settings/notifications_screen.dart';
import 'profile/artist_profile_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState(); 
}

class HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  // --- FİLTRE DEĞİŞKENLERİ ---
  final List<String> _selectedApplications = [];
  final List<String> _selectedStyles = [];
  String? _selectedDistrict;
  String _nameSearchQuery = "";
  String? _selectedCity;
  double _minScore = 0.0;
  String? _sortOption = AppConstants.sortNewest; // Varsayılan: En Yeniler

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

  @override
  Widget build(BuildContext context) {
    const double blurAmount = 10.0;
    const double headerHeight = 0.0; 

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.atmosphericBackgroundGradient, 
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        
        body: Stack(
          children: [
            // KATMAN 1: POST AKIŞI
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: headerHeight), 
                child: _buildPostFeed(), 
              ),
            ),

            // KATMAN 2: GLASS HEADER
            Positioned(
              top: 0, left: 0, right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor.withOpacity(0.9),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.1), 
                          width: 0.5
                        ),
                      ),
                    ),
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

  // --- POST LİSTELEME ---
  Widget _buildPostFeed() {
    Query query = FirebaseFirestore.instance.collection(AppConstants.collectionPosts);
    
    // Sıralama Mantığı
    if (_sortOption == AppConstants.sortPopular) {
      query = query
          .orderBy('isFeatured', descending: true)
          .orderBy('likeCount', descending: true);
    } else {
      query = query
          .orderBy('isFeatured', descending: true)
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
          // Client-side Filtreleme
          if (_selectedDistrict != null) {
            if (!post.locationString.toLowerCase().contains(_selectedDistrict!.toLowerCase())) return false;
          }
          if (_selectedApplications.isNotEmpty) {
            bool match = _selectedApplications.any((app) => (post.application == app || (post.caption?.toLowerCase().contains(app.toLowerCase()) ?? false)));
            if (!match) return false;
          }
          if (_selectedStyles.isNotEmpty) {
             bool match = _selectedStyles.any((style) => (post.styles.contains(style) || (post.caption?.toLowerCase().contains(style.toLowerCase()) ?? false)));
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
              if (index % 4 == 3) {
                return _buildDynamicAds();
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

  // --- REKLAM KARTLARI ---
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
                      onPressed: () {},
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

  Widget _buildDynamicAds() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ads')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildAdPostCard(
            title: "TattInk Premium",
            subtitle: "Sponsorlu",
            content: "Kendi stüdyonu şimdi öne çıkar! Profilini binlerce sanatseverle buluştur.",
            imageUrl: null,
          );
        }

        final adDocs = snapshot.data!.docs;
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

  // --- POST DETAYLARI ---
  void _openFullScreenPost(PostModel post) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isOwner = (currentUserId != null && currentUserId == post.artistId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(
          posts: [post],     
          initialIndex: 0,   
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
  }

  Widget _buildPostMedia(PostModel post) {
    if (post.imageUrls.isEmpty) return const SizedBox.shrink();

    if (post.imageUrls.length == 1) {
      return CachedNetworkImage(
        imageUrl: post.imageUrls[0],
        width: double.infinity,
        fit: BoxFit.cover,
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

    return HomePostSlider(
      imageUrls: post.imageUrls,
      onTap: () => _openFullScreenPost(post),
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

  Future<void> _handleLike(PostModel post, bool isLiked) async {
    if (!_checkUserStatus()) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    
    if (userId == null) return;

    final likeDocRef = FirebaseFirestore.instance.collection(AppConstants.collectionLikes).doc('${post.id}_$userId');
    final postRef = FirebaseFirestore.instance.collection(AppConstants.collectionPosts).doc(post.id);
    final artistRef = FirebaseFirestore.instance.collection(AppConstants.collectionUsers).doc(post.artistId);

    if (isLiked) {
      await likeDocRef.delete();
      await postRef.update({'likeCount': FieldValue.increment(-1)});
      await artistRef.update({'totalLikes': FieldValue.increment(-1)});
    } else {
      await likeDocRef.set({'postId': post.id, 'userId': userId, 'createdAt': FieldValue.serverTimestamp()});
      await postRef.update({'likeCount': FieldValue.increment(1)});
      await artistRef.update({'totalLikes': FieldValue.increment(1)});
      
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
      case AppConstants.sortPopular: return 'Popüler';
      case AppConstants.sortArtistScore: return 'Artist Puanı';
      case AppConstants.sortDistance: return 'Mesafe';
      case AppConstants.sortCampaigns: return 'Kampanya';
      default: return 'Sırala';
    }
  }

  // --- YENİ FİLTRE VE SIRALAMA FONKSİYONLARI ---
  
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Akıllı stil hesaplama (return'den önce)
            Set<String> dynamicStylesSet = {};
            if (_selectedApplications.isNotEmpty) {
              for (var app in _selectedApplications) {
                if (AppConstants.applicationStylesMap.containsKey(app)) {
                  dynamicStylesSet.addAll(AppConstants.applicationStylesMap[app]!);
                }
              }
            }
            List<String> relevantStyles = dynamicStylesSet.toList()..sort();

            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor.withOpacity(0.85),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 10),
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),


                      Expanded(
                        child: Stack(
                          children: [
                            SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. Uygulama
                                  // 1. BÖLÜM: UYGULAMA TÜRÜ
                                  _buildSectionTitle('Uygulama'),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.start,
                                      children: AppConstants.applications.map((app) {
                                        final isSelected = _selectedApplications.contains(app);
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            splashColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                          ),
                                          child: FilterChip(
                                            label: Text(app),
                                            selected: isSelected,
                                            showCheckmark: false, // Tik işareti kapalı
                                            
                                            // --- RENK AYARLARI ---
                                            // Seçili olduğunda içi dolu (Primary Renk)
                                            selectedColor: AppTheme.primaryColor, 
                                            // Seçili DEĞİLKEN içi şeffaf (Outlined görünümü sağlayan kısım)
                                            backgroundColor: Colors.transparent, 
                                            
                                            // Yazı Rengi
                                            labelStyle: TextStyle(
                                              // Seçiliyse Beyaz, Değilse Gri
                                              color: isSelected ? AppTheme.textColor : Colors.grey[400], 
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            ),
                                            
                                            // --- KENARLIK (BORDER) AYARLARI ---
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              side: BorderSide(
                                                // Seçiliyse Primary Rengi, Değilse Gri Çizgi (Outlined Effect)
                                                color: isSelected ? AppTheme.primaryColor : Colors.grey[700]!, 
                                                width: 1,
                                              ),
                                            ),
                                            
                                            onSelected: (selected) {
                                              setModalState(() {
                                                if (selected) {
                                                  _selectedApplications.add(app);
                                                } else {
                                                  _selectedApplications.remove(app);
                                                  // İstersen: _selectedStyles.clear();
                                                }
                                              });
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // 2. Stiller
                                  if (_selectedApplications.isNotEmpty && relevantStyles.isNotEmpty) ...[
                                    _buildSectionTitle('Stiller'),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Wrap(
                                        spacing: 8, runSpacing: 8, alignment: WrapAlignment.start,
                                        children: relevantStyles.map((style) {
                                          final isSelected = _selectedStyles.contains(style);
                                          return Theme(
                                            data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
                                            child: FilterChip(
                                              label: Text(style),
                                              selected: isSelected,
                                              showCheckmark: false,
                                              selectedColor: AppTheme.primaryColor.withOpacity(0.3),
                                              backgroundColor: AppTheme.cardColor.withOpacity(0.6),
                                              labelStyle: TextStyle(color: isSelected ? AppTheme.textColor : Colors.grey[400], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.grey[800]!)),
                                              onSelected: (selected) {
                                                setModalState(() {
                                                  selected ? _selectedStyles.add(style) : _selectedStyles.remove(style);
                                                });
                                              },
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ] else if (_selectedApplications.isEmpty) ...[
                                    _buildSectionTitle('Stiller'),
                                    const Text("Stilleri görmek için uygulama seçiniz.", style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
                                    const SizedBox(height: 24),
                                  ],
                                  

                                  // 3. Bölge ve Akıllı Arama (Eski DistrictSearchWidget yerine bunu kullanın)
                                  _HomeMultiSearchWidget(
                                    initialValue: _nameSearchQuery.isNotEmpty 
                                        ? _nameSearchQuery 
                                        : (_selectedDistrict != null ? "${_selectedDistrict}, ${_selectedCity}" : ""),
                                    
                                    // A) KONUM SEÇİLİRSE
                                    onLocationSelected: (district, city) {
                                      setModalState(() {
                                        _selectedDistrict = district;
                                        _selectedCity = city;
                                        _nameSearchQuery = ""; // Metin aramasını temizle
                                      });
                                    },
                                    
                                    // B) UYGULAMA SEÇİLİRSE (Örn: Dövme)
                                    onApplicationSelected: (app) {
                                      setModalState(() {
                                        if (!_selectedApplications.contains(app)) {
                                          _selectedApplications.add(app);
                                        }
                                        _nameSearchQuery = "";
                                        _selectedDistrict = null; // Tercihe bağlı: Konumu sıfırlayabilirsin
                                      });
                                    },
                                    
                                    // C) STİL SEÇİLİRSE (Örn: Realistik)
                                    onStyleSelected: (style) {
                                      setModalState(() {
                                        if (!_selectedStyles.contains(style)) {
                                          _selectedStyles.add(style);
                                        }
                                        _nameSearchQuery = "";
                                      });
                                    },
                                    
                                    // D) DÜZ METİN / ARTİST ADI ARANIRSA
                                    onTextSearch: (text) {
                                      setModalState(() {
                                        _nameSearchQuery = text;
                                        // Diğer filtreleri sıfırlamak istersen buraya ekle
                                        // _selectedDistrict = null;
                                      });
                                    },
                                  ),


                                  const SizedBox(height: 80),
                                ],
                              ),
                            ),
                            
                            // Sıfırla
                            Positioned(
                              top: -2, right: 8,
                              child: TextButton(
                                onPressed: () {
                                  setModalState(() {
                                    _selectedApplications.clear();
                                    _selectedStyles.clear();
                                    _selectedDistrict = null;
                                    _selectedCity = null;
                                  });
                                },
                                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, overlayColor: Colors.transparent),
                                child: const Text('Sıfırla', style: TextStyle(color: AppTheme.primaryColor, fontSize: 14, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Uygula Butonu
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))), color: AppTheme.backgroundColor.withOpacity(0.5)),
                        child: SizedBox(
                          width: double.infinity, height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {}); // Ana ekranı güncelle
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                            child: const Text('Sonuçları Göster', style: TextStyle(color: AppTheme.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    final Map<String, String> sortOptions = {
      AppConstants.sortNewest: 'En Yeniler',
      AppConstants.sortPopular: 'Popüler',
      AppConstants.sortArtistScore: 'Artist Puanı',
      AppConstants.sortDistance: 'Mesafe',
      AppConstants.sortCampaigns: 'Kampanyalar',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor.withOpacity(0.85),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 10),
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
                  ),
                  
                  
                  ...sortOptions.entries.map((entry) {
                    final isSelected = _sortOption == entry.key;
                    return Theme(
                      data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
                      child: ListTile(
                        title: Text(entry.value, style: TextStyle(color: isSelected ? AppTheme.primaryColor : AppTheme.textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                        onTap: () {
                          setState(() {
                            _sortOption = entry.key;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        )
      ),
    );
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
                Navigator.push(context, SlideRoute(page: const NotificationsSettingsScreen())); 
              }
            ), 
            if (unreadCount > 0) 
              Positioned(
                right: 6, top: 6, 
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

// --- YARDIMCI WIDGETLAR ---

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
  @override
Widget build(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Başlık ve boşluk silindi
      TextField(
        controller: _searchController,
        style: const TextStyle(color: AppTheme.textColor),
        decoration: InputDecoration(
          hintText: 'Semt ara',
          hintStyle: const TextStyle(color: AppTheme.textColor),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: _updateFilteredDistricts,
      ),
      if (_filteredDistricts.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 8),
          constraints: const BoxConstraints(maxHeight: 150),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _filteredDistricts.length,
            itemBuilder: (context, index) {
              final item = _filteredDistricts[index];
              return ListTile(
                title: Text('${item['district']}, ${item['city']}',
                    style: const TextStyle(color: AppTheme.textColor)),
                onTap: () {
                  _searchController.text = '${item['district']}, ${item['city']}';
                  widget.onDistrictSelected(item['district'], item['city']);
                  setState(() {
                    _filteredDistricts = [];
                  });
                },
              );
            },
          ),
        ),
    ],
  );
}
}

class HomePostSlider extends StatefulWidget {
  final List<String> imageUrls;
  final VoidCallback onTap; 

  const HomePostSlider({super.key, required this.imageUrls, required this.onTap});

  @override
  State<HomePostSlider> createState() => _HomePostSliderState();
}

class _HomePostSliderState extends State<HomePostSlider> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
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
                onTap: widget.onTap, 
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrls[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: AppTheme.backgroundColor),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              );
            },
          ),
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

// --- ÇOK FONKSİYONLU AKILLI ARAMA WIDGET'I ---

class _HomeMultiSearchWidget extends StatefulWidget {
  // Seçili değerleri başlangıçta göstermek için
  final String? initialValue; 
  
  // Seçim yapıldığında ana ekrana ne seçildiğini bildiren fonksiyonlar
  final Function(String?, String?) onLocationSelected; // İl/İlçe seçilirse
  final Function(String) onApplicationSelected;        // Uygulama seçilirse (Dövme vb.)
  final Function(String) onStyleSelected;              // Stil seçilirse (Realistik vb.)
  final Function(String) onTextSearch;                 // Artist adı veya düz metin aranırsa

  const _HomeMultiSearchWidget({
    this.initialValue,
    required this.onLocationSelected,
    required this.onApplicationSelected,
    required this.onStyleSelected,
    required this.onTextSearch,
  });

  @override
  State<_HomeMultiSearchWidget> createState() => _HomeMultiSearchWidgetState();
}

class _HomeMultiSearchWidgetState extends State<_HomeMultiSearchWidget> {
  late TextEditingController _controller;
  
  // Önerileri tutacak liste. 
  // type: 'location', 'app', 'style', 'text'
  List<Map<String, String>> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateSuggestions(String query) {
    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    List<Map<String, String>> matches = [];
    String lower = query.toLowerCase();

    // 1. UYGULAMA ARAMA (Örn: Dövme, Piercing)
    for (var app in AppConstants.applications) {
      if (app.toLowerCase().contains(lower)) {
        matches.add({
          'type': 'app',
          'title': app,
          'subtitle': 'Uygulama Türü'
        });
      }
    }

    // 2. STİL ARAMA (Örn: Realistik, Minimal)
    for (var style in AppConstants.styles) {
      if (style.toLowerCase().contains(lower)) {
        matches.add({
          'type': 'style',
          'title': style,
          'subtitle': 'Stil'
        });
      }
    }

    // 3. KONUM ARAMA (Örn: Kadıköy, İstanbul)
    TurkeyLocations.citiesWithDistricts.forEach((city, districts) {
      if (city.toLowerCase().contains(lower)) {
        matches.add({
          'type': 'location',
          'title': city,
          'city': city,
          'district': '',
          'subtitle': 'Şehir'
        });
      }
      for (var district in districts) {
        if (district.toLowerCase().contains(lower)) {
          matches.add({
            'type': 'location',
            'title': '$district, $city',
            'city': city,
            'district': district,
            'subtitle': 'Bölge'
          });
        }
      }
    });

    // 4. GENEL METİN / ARTİST ARAMA (Her zaman en sonda göster)
    matches.add({
      'type': 'text',
      'title': '"$query" ara',
      'query': query,
      'subtitle': 'Artist, Açıklama veya Etiket'
    });

    // Sonuçları sınırla (Performans için)
    setState(() => _suggestions = matches.take(10).toList());
  }

  // Tipine göre ikon belirle
  IconData _getIconForType(String type) {
    switch (type) {
      case 'location': return Icons.location_on_outlined;
      case 'app': return Icons.category_outlined;
      case 'style': return Icons.brush_outlined;
      case 'text': return Icons.search;
      default: return Icons.search;
    }
  }

  // Tipine göre renk belirle
  Color _getColorForType(String type) {
    switch (type) {
      case 'location': return Colors.redAccent;
      case 'app': return Colors.blueAccent;
      case 'style': return Colors.purpleAccent;
      case 'text': return AppTheme.primaryColor;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          style: const TextStyle(color: AppTheme.textColor),
          decoration: InputDecoration(
            hintText: 'Semt, artist, stil veya uygulama...',
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: AppTheme.textColor),
            filled: true,
            fillColor: AppTheme.cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            suffixIcon: _controller.text.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () {
                    _controller.clear();
                    setState(() => _suggestions = []);
                    // Sıfırlama isteği gönderilebilir
                  },
                ) 
              : null,
          ),
          onChanged: _updateSuggestions,
        ),
        
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 200), // Listeyi biraz uzattık
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                
                return ListTile(
                  dense: true,
                  leading: Icon(
                    _getIconForType(item['type']!), 
                    size: 20, 
                    color: _getColorForType(item['type']!)
                  ),
                  title: Text(
                    item['title']!, 
                    style: const TextStyle(color: AppTheme.textColor, fontSize: 14)
                  ),
                  subtitle: Text(
                    item['subtitle']!, 
                    style: TextStyle(color: Colors.grey[500], fontSize: 10)
                  ),
                  onTap: () {
                    _controller.text = item['title']!;
                    setState(() => _suggestions = []);
                    
                    // Seçilen tipe göre ilgili fonksiyonu çalıştır
                    switch (item['type']) {
                      case 'location':
                        widget.onLocationSelected(item['district'], item['city']);
                        break;
                      case 'app':
                        widget.onApplicationSelected(item['title']!);
                        break;
                      case 'style':
                        widget.onStyleSelected(item['title']!);
                        break;
                      case 'text':
                        widget.onTextSearch(item['query']!);
                        break;
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}