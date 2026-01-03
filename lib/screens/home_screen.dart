import '../widgets/video_post_player.dart';
import '../app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'dart:ui'; // Glass effect ve ImageFilter için gerekli
import 'dart:async';
import '../services/report_service.dart';
import 'package:url_launcher/url_launcher.dart';

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

class HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  // --- 1. BÖLÜM: DEĞİŞKENLER ---
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  
  // Yasaklı Listesi
  List<String> _blockedUserIds = [];
  StreamSubscription? _blockSubscription;

  // Filtre Değişkenleri
  final List<String> _selectedApplications = [];
  final List<String> _selectedStyles = [];
  String? _selectedDistrict;
  String _nameSearchQuery = "";
  String? _selectedCity;
  double _minScore = 0.0;
  String? _sortOption = AppConstants.sortNewest;

  // Çeviri Kısayolu
  String tr(String key) => AppLocalizations.of(context)?.translate(key) ?? key;

  @override
    void initState() {
      super.initState();
      _fetchBlockedUsers(); // Listeyi çekmeye başla
    }

  // --- 2. BÖLÜM: KEEPALIVE VE SCROLL FONKSİYONU ---
  @override
  bool get wantKeepAlive => true;

  //Sikayet Butonu
  void _showPostOptions(BuildContext context, PostModel post) {
  final currentUser = FirebaseAuth.instance.currentUser;

  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          // ŞİKAYET ET BUTONU
          ListTile(
            leading: const Icon(Icons.flag, color: Colors.redAccent),
            title: Text(AppLocalizations.of(context)!.translate('report_post'), style: const TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(sheetContext); // Menüyü kapat
              ReportService.showReportDialog(
                context: context, // Ana context kullan
                contentId: post.id!,
                contentType: 'post',
                reportedUserId: post.artistId,
              );
            },
          ),
          // ENGELLE BUTONU
          ListTile(
            leading: const Icon(Icons.block, color: Colors.white70),
            title: Text(AppLocalizations.of(context)!.translate('block_artist'), style: const TextStyle(color: Colors.white70)),
            onTap: () async {
              Navigator.pop(sheetContext);
              
              if (currentUser != null) {
                try {
                  await ReportService.blockUser(
                    context: context, // Ana context'i gönderiyoruz
                    currentUserId: currentUser.uid,
                    blockedUserId: post.artistId,
                  );
                } catch (e) {
                  print("Engelleme sırasında hata: $e");
                }
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

// --- AKILLI SCROLL FONKSİYONU ---
  void scrollToTop() {
    if (_scrollController.hasClients) {
      if (_scrollController.offset > 0) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuart,
        );
      } else {
        _refreshIndicatorKey.currentState?.show();
      }
    }
  }

  // --- 3. BÖLÜM: DİĞER FONKSİYONLAR ---

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() { });
  }

  // ENGELLENENLERİ SÜREKLİ DİNLEYEN FONKSİYON
  void _fetchBlockedUsers() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _blockSubscription?.cancel();

    _blockSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('blocked_users')
        .snapshots() 
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              _blockedUserIds = snapshot.docs.map((doc) => doc.id).toList();
            });
          }
        });
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
        title: Text(tr('email_verify_title'), style: const TextStyle(color: AppTheme.textColor)),
        content: Text(
          tr('email_verify_msg'),
          style: const TextStyle(color: AppTheme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('ok'), style: const TextStyle(color: AppTheme.primaryColor)),
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

  // --- 4. BÖLÜM: BUILD METODU ---
  @override
  Widget build(BuildContext context) {
    super.build(context); // KeepAlive için gerekli

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
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                                      label: Text(tr('filter'), style: const TextStyle(color: AppTheme.primaryColor)),
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
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text(tr('no_posts')));

        final filteredPosts = snapshot.data!.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .where((post) {
          
          // ENGEL KONTROLÜ
          if (_blockedUserIds.contains(post.artistId)) {
            return false;
          }

          // Client-side Filtreleme
          if (_selectedDistrict != null) {
            if (!post.locationString.toLowerCase().contains(_selectedDistrict!.toLowerCase())) return false;
          }
          if (_selectedApplications.isNotEmpty) {
            // Anahtar eşleşmesi kontrol ediliyor (Postta anahtar var, seçilende de anahtar var)
            bool match = _selectedApplications.any((app) => (post.application == app || (post.caption?.toLowerCase().contains(app.toLowerCase()) ?? false)));
            if (!match) return false;
          }
          if (_selectedStyles.isNotEmpty) {
             bool match = _selectedStyles.any((style) => (post.styles.contains(style) || (post.caption?.toLowerCase().contains(style.toLowerCase()) ?? false)));
            if (!match) return false;
          }
          return true;
        }).toList();

        if (filteredPosts.isEmpty) {
           return Center(child: Text(tr('no_posts_found')));
        }

        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          color: AppTheme.primaryColor,
          backgroundColor: AppTheme.cardColor,
          edgeOffset: 130,
          child: ListView.builder(
            key: const PageStorageKey('home_post_list'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(), 
            padding: const EdgeInsets.only(top: 140, bottom: 100),
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

  //REKLAM KARTLARI
  Widget _buildStandardAdCard({
    required String title,
    required String subtitle,
    required String content,
    String? imageUrl,
    required VoidCallback onTap,
  }) {
    // --- GÜVENLİK KONTROLÜ ---
    // 1. Null olmamalı
    // 2. Boş olmamalı
    // 3. 'http' ile başlamalı (Gerçek bir link olmalı)
    // 4. O meşhur hatalı yazıyı içermemeli
    bool isValidImage = imageUrl != null &&
                        imageUrl.isNotEmpty &&
                        imageUrl.startsWith('http') &&
                        !imageUrl.contains('Bir resim linki') &&
                        !imageUrl.contains('Bir%20resim');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Sadece geçerliyse resmi göster
          if (isValidImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                // Resim yüklenirken veya hata verirse çökmesin, boş geçsin:
                placeholder: (context, url) => Container(
                  height: 200, 
                  color: AppTheme.cardColor,
                  child: const Center(child: CircularProgressIndicator())
                ),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.campaign, color: AppTheme.primaryColor),
            title: Text(title, style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
            subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            trailing: OutlinedButton(onPressed: onTap, child: Text(tr('get_info'))),
          ),
        ],
      ),
    );
  }

  //BUILD DYNAMIC ADS
  Widget _buildDynamicAds() {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('ads')
              .where('isActive', isEqualTo: true)
              // .orderBy('createdAt', descending: true) 
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
            
            final doc = snapshot.data!.docs.first;
            final adData = doc.data() as Map<String, dynamic>;
            
            // --- Linki Çekiyoruz ---
            String targetLink = adData['link'] ?? ""; 

            // Güvenlik kontrolleri (Resim vs... önceki kodun aynısı)
            String? rawImage = adData['imageUrl'];
            String? safeImageUrl;
            if (rawImage != null && rawImage.startsWith('http') && !rawImage.contains('Bir resim linki')) {
               safeImageUrl = rawImage;
            }

            return _buildStandardAdCard(
              title: adData['title'] ?? "Fırsat",
              subtitle: "Sponsorlu",
              content: adData['content'] ?? "",
              imageUrl: safeImageUrl,
              
              // --- İŞTE SİHİR BURADA: TIKLAMA OLAYI ---
              // --- GÜNCELLENMİŞ VE GÜVENLİ ONTAP ---
              onTap: () async {
                if (targetLink.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link bulunamadı.")));
                  return;
                }

                // Boşlukları temizle
                final String cleanLink = targetLink.trim();

                try {
                  // 1. Eğer Link bir WEB SİTESİ ise (http ile başlıyorsa)
                  if (cleanLink.startsWith('http')) {
                    final Uri url = Uri.parse(cleanLink);
                    
                    // launchUrl fonksiyonunu try-catch içine alıyoruz
                    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                      throw 'Link açılamadı';
                    }
                  } 
                  // 2. Eğer Link bir PROFİL ID'si ise
                  else {
                     Navigator.push(
                       context, 
                       MaterialPageRoute(
                         builder: (context) => ArtistProfileScreen(
                           userId: cleanLink,
                           isOwnProfile: false
                         )
                       )
                     );
                  }
                } catch (e) {
                  // Hata olursa uygulama çökmez, sadece mesaj verir
                  debugPrint("Link açma hatası: $e");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bağlantı açılamadı, link hatalı olabilir.")));
                  }
                }
              },
            );
          },
        ),
      ],
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
        
        // SİLİNMİŞ KULLANICI KONTROLÜ
        if (artistSnapshot.connectionState == ConnectionState.done) {
          if (!artistSnapshot.hasData || !artistSnapshot.data!.exists) {
            return const SizedBox.shrink();
          }
        }

        final bool isPremium = artistSnapshot.hasData && 
                              artistSnapshot.data!.exists &&
                              (artistSnapshot.data!.data() as Map<String, dynamic>?)?['isFeatured'] == true;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: isPremium ? [
              BoxShadow(
                color: AppTheme.cardColor.withOpacity(0.5), 
                blurRadius: 8,
                spreadRadius: 2,
              )
            ] : null,
            border: isPremium ? Border.all(color: AppTheme.primaryColor, width: 0.5) : null, 
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
                        top: 12, left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars, color: AppTheme.textColor, size: 14),
                              const SizedBox(width: 4),
                              Text(tr('featured_badge'), style: const TextStyle(color: AppTheme.textColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    
                    if (!isOwnPost) 
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                            onPressed: () => _showPostOptions(context, post), 
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
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => ArtistProfileScreen(userId: post.artistId, isOwnProfile: false)));
                                },
                                child: Row(
                                  children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.grey[800],
                                        // GÜVENLİ RESİM KONTROLÜ (Hatalı linkleri engeller)
                                        backgroundImage: (post.artistProfileImageUrl != null && 
                                                          post.artistProfileImageUrl!.isNotEmpty && 
                                                          post.artistProfileImageUrl!.startsWith('http') &&
                                                          !post.artistProfileImageUrl!.contains('Bir resim linki')) 
                                                ? CachedNetworkImageProvider(post.artistProfileImageUrl!) 
                                                : null,
                                        child: (post.artistProfileImageUrl == null || 
                                                  post.artistProfileImageUrl!.isEmpty || 
                                                  !post.artistProfileImageUrl!.startsWith('http') ||
                                                  post.artistProfileImageUrl!.contains('Bir resim linki')) 
                                                ? const Icon(Icons.person, size: 20, color: AppTheme.textColor) 
                                                : null,
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
                                    angle: -45 * 3.14159 / 180,
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
                                        right: 9, top: 25,
                                        child: Text("${post.likeCount}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // --- CAPTION (AÇIKLAMA) KISMI ---
                      if (post.caption != null && post.caption!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
                          child: ValueListenableBuilder<bool>(
                            valueListenable: isExpandedNotifier,
                            builder: (context, isExpanded, child) {
                              
                              // DÜZELTME BURADA: Metni alıp etiketleri çeviriyoruz
                              String localizedCaption = _translateCaptionTags(context, post.caption!);

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
                                        // Çevrilmiş metni kullanıyoruz
                                        children: [TextSpan(text: localizedCaption)], 
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

  // --- YENİ YARDIMCI FONKSİYON (HomeScreen sınıfının içine ekle) ---
  // Bu fonksiyon metindeki #app_... ve #style_... etiketlerini bulup Türkçeye çevirir.
  String _translateCaptionTags(BuildContext context, String caption) {
    // Regex: # ile başlayan, ardından app_ veya style_ gelen ve harf/rakam/altçizgi ile devam edenler
    final regex = RegExp(r'#(app_|style_)\w+');

    // Metindeki tüm eşleşmeleri bul ve değiştir
    return caption.replaceAllMapped(regex, (match) {
      String fullTag = match.group(0)!; // Örn: #app_tattoo
      String key = fullTag.substring(1); // Örn: app_tattoo (başındaki # kalktı)

      // Anahtarı AppLocalizations ile çevir
      String? translated = AppLocalizations.of(context)!.translate(key);

      // Eğer çeviri varsa ve anahtardan farklıysa (yani çeviri başarılıysa)
      if (translated != null && translated != key) {
        return "#$translated"; // Örn: #Dövme
      }
      
      // Çeviri yoksa veya hata varsa orijinalini döndür
      return fullTag;
    });
  }

  Widget _buildPostMedia(PostModel post) {
    // 1. Video varsa öncelik videonun
    if (post.videoUrl != null && post.videoUrl!.isNotEmpty) {
      return VideoPostPlayer(videoUrl: post.videoUrl!);
    }

    // 2. Resim listesi boşsa hiçbir şey gösterme
    if (post.imageUrls.isEmpty) return const SizedBox.shrink();

    // --- DÜZELTME BAŞLANGICI ---
    // İlk resim linkini alıp kontrol ediyoruz.
    String firstImage = post.imageUrls[0];

    // Eğer link 'http' ile başlamıyorsa VEYA içinde o hatalı placeholder yazı varsa
    // (Hem normal halini hem de URL encoded halini kontrol ediyoruz garanti olsun diye)
    if (!firstImage.startsWith('http') || 
        firstImage.contains('Bir resim linki') || 
        firstImage.contains('Bir%20resim')) {
       return const SizedBox.shrink();
    }
    // --- DÜZELTME BİTİŞİ ---

    // 3. Tek resim varsa
    if (post.imageUrls.length == 1) {
      return CachedNetworkImage(
        imageUrl: firstImage, // Kontrol edilmiş değişkeni kullanıyoruz
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

    // 4. Çoklu resim varsa (Slider)
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
    if (_sortOption == null) return tr('sort');
    switch (_sortOption) {
      case AppConstants.sortNewest: return tr('newest');
      case AppConstants.sortPopular: return tr('popular');
      case AppConstants.sortArtistScore: return tr('artist_score');
      case AppConstants.sortDistance: return tr('distance');
      case AppConstants.sortCampaigns: return tr('campaigns');
      default: return tr('sort');
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
                    color: AppTheme.backgroundColor.withOpacity(0.8),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                      left: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                      right: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                      bottom: BorderSide.none,
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
                                  _buildSectionTitle(tr('application_type')),
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
                                            label: Text(tr(app)), // DİNAMİK ÇEVİRİ
                                            selected: isSelected,
                                            showCheckmark: false, 
                                            selectedColor: AppTheme.primaryColor.withOpacity(0.5),
                                            backgroundColor: Colors.transparent, 
                                            labelStyle: TextStyle(
                                              color: isSelected ? AppTheme.textColor : Colors.grey[400], 
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              side: BorderSide(
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
                                    _buildSectionTitle(tr('styles')),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Wrap(
                                        spacing: 8, runSpacing: 8, alignment: WrapAlignment.start,
                                        children: relevantStyles.map((style) {
                                          final isSelected = _selectedStyles.contains(style);
                                          return Theme(
                                            data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
                                            child: FilterChip(
                                              label: Text(tr(style)), // DİNAMİK ÇEVİRİ
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
                                    _buildSectionTitle(tr('styles')),
                                    Text(tr('select_application_for_styles'), style: const TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
                                    const SizedBox(height: 24),
                                  ],
                                  

                                  // 3. Bölge ve Akıllı Arama 
                                  _HomeMultiSearchWidget(
                                    initialValue: _nameSearchQuery.isNotEmpty 
                                        ? _nameSearchQuery 
                                        : (_selectedDistrict != null ? "${_selectedDistrict}, ${_selectedCity}" : ""),
                                    
                                    onLocationSelected: (district, city) {
                                      setModalState(() {
                                        _selectedDistrict = district;
                                        _selectedCity = city;
                                        _nameSearchQuery = ""; 
                                      });
                                    },
                                    
                                    onApplicationSelected: (app) {
                                      setModalState(() {
                                        if (!_selectedApplications.contains(app)) {
                                          _selectedApplications.add(app);
                                        }
                                        _nameSearchQuery = "";
                                        _selectedDistrict = null; 
                                      });
                                    },
                                    
                                    onStyleSelected: (style) {
                                      setModalState(() {
                                        if (!_selectedStyles.contains(style)) {
                                          _selectedStyles.add(style);
                                        }
                                        _nameSearchQuery = "";
                                      });
                                    },
                                    
                                    onTextSearch: (text) {
                                      setModalState(() {
                                        _nameSearchQuery = text;
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
                                child: Text(tr('reset'), style: const TextStyle(color: AppTheme.primaryColor, fontSize: 14, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Uygula Butonu
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {}); 
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            minimumSize: const Size(double.infinity, 50), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            tr('show_results'),
                            style: const TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
      AppConstants.sortNewest: tr('newest'),
      AppConstants.sortPopular: tr('popular'),
      AppConstants.sortArtistScore: tr('artist_score'),
      AppConstants.sortDistance: tr('distance'),
      AppConstants.sortCampaigns: tr('campaigns'),
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

// --- DÜZELTİLEN YER: ARAMA WIDGET'I ---

class _HomeMultiSearchWidget extends StatefulWidget {
  final String? initialValue; 
  
  final Function(String?, String?) onLocationSelected; 
  final Function(String) onApplicationSelected;        
  final Function(String) onStyleSelected;              
  final Function(String) onTextSearch;                 

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
  List<Map<String, String>> _suggestions = [];

  // Helper
  String tr(String key) => AppLocalizations.of(context)?.translate(key) ?? key;

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

    // 1. UYGULAMA ARAMA (DÜZELTİLDİ: Çevrilmiş metinlerde arama yapıyoruz)
    for (var appKey in AppConstants.applications) {
      String translatedApp = tr(appKey); // Anahtarı (app_tattoo) al, çevir (Dövme)
      
      if (translatedApp.toLowerCase().contains(lower)) {
        matches.add({
          'type': 'app',
          'title': translatedApp, // Ekranda çevrilmiş hali görünsün
          'key': appKey,          // Ama arkada orijinal anahtarı tutalım
          'subtitle': tr('application_type')
        });
      }
    }

    // 2. STİL ARAMA (DÜZELTİLDİ)
    for (var styleKey in AppConstants.styles) {
      String translatedStyle = tr(styleKey); // Anahtarı al, çevir
      
      if (translatedStyle.toLowerCase().contains(lower)) {
        matches.add({
          'type': 'style',
          'title': translatedStyle, // Ekranda çevrilmiş hali
          'key': styleKey,          // Arkada orijinal anahtar
          'subtitle': tr('styles')
        });
      }
    }

    // 3. KONUM ARAMA (Değişmedi, zaten metin tabanlı)
    TurkeyLocations.citiesWithDistricts.forEach((city, districts) {
      if (city.toLowerCase().contains(lower)) {
        matches.add({
          'type': 'location',
          'title': city,
          'city': city,
          'district': '',
          'subtitle': tr('city')
        });
      }
      for (var district in districts) {
        if (district.toLowerCase().contains(lower)) {
          matches.add({
            'type': 'location',
            'title': '$district, $city',
            'city': city,
            'district': district,
            'subtitle': tr('district')
          });
        }
      }
    });

    // 4. GENEL METİN (Her zaman en sonda)
    matches.add({
      'type': 'text',
      'title': '"$query" ${tr('search_suffix')}', // "ara" suffix'i
      'query': query,
      'subtitle': tr('search_hint_subtitle') // Artist, Açıklama vb.
    });

    setState(() => _suggestions = matches.take(10).toList());
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'location': return Icons.location_on_outlined;
      case 'app': return Icons.category_outlined;
      case 'style': return Icons.brush_outlined;
      case 'text': return Icons.search;
      default: return Icons.search;
    }
  }

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
            hintText: tr('search_hint'), // "Semt, artist..."
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
                  },
                ) 
              : null,
          ),
          onChanged: _updateSuggestions,
        ),
        
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 200),
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
                    
                    switch (item['type']) {
                      case 'location':
                        widget.onLocationSelected(item['district'], item['city']);
                        break;
                      case 'app':
                        // ÖNEMLİ: Ekranda "Dövme" yazsa da arkaya "app_tattoo" (key) gönderiyoruz
                        widget.onApplicationSelected(item['key']!);
                        break;
                      case 'style':
                        // ÖNEMLİ: Arkaya style key gönderiyoruz
                        widget.onStyleSelected(item['key']!);
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