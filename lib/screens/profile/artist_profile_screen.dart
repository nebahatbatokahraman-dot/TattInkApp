import '../../widgets/payment_webview.dart';
import '../create_appointment_screen.dart';
import '../post_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:tattink_app/screens/create_appointment_screen.dart';
import 'dart:ui';

// --- LOCALIZATION IMPORT (Bunu eklememiz şart) ---
import '../../app_localizations.dart'; 

// --- SERVICE & MODEL IMPORTS ---
import '../../services/report_service.dart';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';
import '../../services/notification_service.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../utils/constants.dart';
import '../../utils/slide_route.dart';
import '../../theme/app_theme.dart';

// --- WIDGET & SCREEN IMPORTS ---
import '../../widgets/login_required_dialog.dart';
import '../chat_screen.dart';
import '../appointments_screen.dart';
import '../create_post_screen.dart';
import '../messages_screen.dart';

// --- AYAR SAYFALARI ---
import '../settings/artist_settings_screen.dart';
import '../settings/artist_edit_profile_screen.dart';

class ArtistProfileScreen extends StatefulWidget {
  final String userId;
  final bool isOwnProfile;

  const ArtistProfileScreen({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
  });

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserModel? _user;
  UserModel? _currentUserModel;
  bool _isFollowing = false;
  final ImagePicker _picker = ImagePicker();

  // --- CAROUSEL INDEX TAKİBİ ---
  int _currentStudioImageIndex = 0;

  // --- ÇEVİRİ YARDIMCISI (Kodu şişirmemek için) ---
  String tr(String key) {
    return AppLocalizations.of(context)?.translate(key) ?? key;
  }

  // --- STÜDYO FOTOĞRAFI YÜKLEME ---
  Future<void> _uploadStudioImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('loading'))));

      final imageService = ImageService();
      final File file = File(image.path);
      final optimizedImageBytes = await imageService.optimizeImage(file);

      final imageUrl = await imageService.uploadImage(
        imageBytes: optimizedImageBytes,
        path: 'studio_images/${widget.userId}/${DateTime.now().millisecondsSinceEpoch}',
      );

      await FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(widget.userId)
          .update({
        'studioImageUrls': FieldValue.arrayUnion([imageUrl]),
      });

      await _loadUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('photo_added')), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('error_prefix')}: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // --- STÜDYO FOTOĞRAFI SİLME ---
  Future<void> _deleteStudioImage(String imageUrl) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(widget.userId)
          .update({
        'studioImageUrls': FieldValue.arrayRemove([imageUrl]),
      });

      await _loadUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('photo_deleted'))));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('error_prefix')}: $e')));
    }
  }

  void _confirmDeleteStudioImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(tr('delete_photo_title'), style: const TextStyle(color: AppTheme.textColor)),
        content: Text(tr('delete_studio_photo_confirm'), style: const TextStyle(color: AppTheme.textColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'), style: const TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _deleteStudioImage(imageUrl);
              },
              child: Text(tr('delete'), style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.isOwnProfile ? 3 : 2, vsync: this);
    _loadUser();
    _loadCurrentUser();
    _checkFollowing();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.currentUser?.sendEmailVerification();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('verify_email_sent'))),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: Text(tr('resend')),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCurrentUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final uid = authService.currentUser?.uid;
    if (uid != null) {
      final userModel = await authService.getUserModel(uid);
      if (mounted) {
        setState(() {
          _currentUserModel = userModel;
        });
      }
    }
  }

  Future<void> _loadUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (widget.userId.isEmpty) return;

    final userModel = await authService.getUserModel(widget.userId);
    if (mounted) {
      setState(() {
        _user = userModel;
      });
    }
  }

  Future<void> _checkFollowing() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;

    if (currentUserId == null || currentUserId == widget.userId) {
      return;
    }

    final followDoc = await FirebaseFirestore.instance
        .collection(AppConstants.collectionFollows)
        .doc('${currentUserId}_${widget.userId}')
        .get();

    if (mounted) {
      setState(() {
        _isFollowing = followDoc.exists;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (!_checkUserStatus()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;

    if (currentUserId == null) return;

    final followDocRef = FirebaseFirestore.instance
        .collection(AppConstants.collectionFollows)
        .doc('${currentUserId}_${widget.userId}');

    try {
      if (_isFollowing) {
        await followDocRef.delete();
      } else {
        await followDocRef.set({
          'followerId': currentUserId,
          'followingId': widget.userId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        final currentUserModel = await authService.getUserModel(currentUserId);

        if (currentUserModel != null) {
          await NotificationService.sendFollowNotification(
              currentUserId,
              currentUserModel.fullName,
              currentUserModel.profileImageUrl,
              widget.userId);
        }
      }

      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr('operation_failed')}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(widget.userId)
          .snapshots(),
      builder: (context, userSnapshot) {
        // 1. YÜKLENİYORSA
        if (!userSnapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. KULLANICI BULUNAMADIYSA (SİLİNMİŞSE)
        if (!userSnapshot.data!.exists) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            // İŞTE ÇÖZÜM: Buraya şeffaf bir AppBar ve Geri Butonu koyuyoruz
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(), // Geri gönder
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, size: 80, color: Colors.white.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    tr('user_not_found'),
                    style: const TextStyle(color: AppTheme.textColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('user_not_found_msg'),
                    style: TextStyle(color: AppTheme.textColor.withOpacity(0.6), fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        // 3. KULLANICI VARSA (NORMAL AKIŞ)
        final userData = userSnapshot.data!;
        _user = UserModel.fromFirestore(userData);

        final authService = Provider.of<AuthService>(context, listen: false); // safe call
        final currentUserId = authService.currentUser?.uid;
        final isOwnProfile = widget.isOwnProfile || currentUserId == widget.userId;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: _buildBody(context, isOwnProfile),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, bool isOwnProfile) {
    bool canPop = Navigator.canPop(context);
    final bool isTargetArtist = _user?.role.toLowerCase().contains('artist') ?? false;

    // 1. ANA YAPIYI STACK YAPTIK (Sabit butonlar için)
    return Stack(
      children: [
        // KATMAN 1: KAYDIRILABİLİR İÇERİK (EN ALTTA)
        CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // --- CAROUSEL (Mevcut Kodun) ---
                      SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: (_user!.studioImageUrls.isNotEmpty)
                            ? cs.CarouselSlider.builder(
                                itemCount: _user!.studioImageUrls.length,
                                options: cs.CarouselOptions(
                                  height: 220,
                                  viewportFraction: 1.0,
                                  autoPlay: true,
                                  autoPlayInterval: const Duration(seconds: 5),
                                  onPageChanged: (index, reason) => setState(() => _currentStudioImageIndex = index),
                                ),
                                itemBuilder: (context, index, realIndex) {
                                  final imageUrl = _user!.studioImageUrls[index];
                                  return GestureDetector(
                                    onLongPress: isOwnProfile ? () => _confirmDeleteStudioImage(imageUrl) : null,
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(color: Colors.grey[900]),
                                      errorWidget: (context, url, error) => const Icon(Icons.error),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[800],
                                child: (_user!.coverImageUrl != null)
                                    ? CachedNetworkImage(imageUrl: _user!.coverImageUrl!, fit: BoxFit.cover)
                                    : const Center(child: Icon(Icons.image, color: AppTheme.textColor, size: 50)),
                              ),
                      ),

                      // --- NOKTA GÖSTERGELERİ ---
                      if (_user!.studioImageUrls.length > 1)
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: AnimatedSmoothIndicator(
                              activeIndex: _currentStudioImageIndex,
                              count: _user!.studioImageUrls.length,
                              effect: const ScrollingDotsEffect(
                                dotHeight: 6,
                                dotWidth: 6,
                                activeDotColor: AppTheme.primaryColor,
                                dotColor: AppTheme.textColor,
                              ),
                            ),
                          ),
                        ),
                      
                      // ⚠️ DİKKAT: SABİT BUTONLARI BURADAN SİLDİK VE AŞAĞIYA (STACK'İN EN DIŞINA) TAŞIDIK.
                      
                      // --- FOTOĞRAF EKLEME BUTONU (Bu görselle beraber kaysın diye burada bıraktık) ---
                      if (isOwnProfile)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: AppTheme.backgroundSecondaryColor,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (context) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 8),
                                      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2))),
                                      ListTile(
                                        leading: const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primaryColor),
                                        title: Text(tr('add_photo_gallery'), style: const TextStyle(color: AppTheme.textColor)),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _uploadStudioImage();
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.no_photography_outlined, color: Colors.redAccent),
                                        title: Text(tr('remove_photo_gallery'), style: const TextStyle(color: AppTheme.textColor)),
                                        subtitle: Text(tr('remove_photo_hint'), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                        onTap: () {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(tr('remove_photo_hint')),
                                              backgroundColor: Colors.blueGrey,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_a_photo, size: 20, color: AppTheme.textColor),
                            ),
                          ),
                        ),

                      // --- PROFİL FOTO & BİLGİLER (Bu da kaymalı) ---
                      Positioned(
                        left: 16,
                        bottom: -85,
                        right: 16,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.cardLightColor,
                                      width: 4,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Container(
                                      width: 130,
                                      height: 130,
                                      color: AppTheme.cardColor,
                                      child: _user!.profileImageUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl: _user!.profileImageUrl!,
                                              fit: BoxFit.cover,
                                              errorWidget: (context, url, error) => const Icon(Icons.person, size: 50),
                                            )
                                          : const Icon(Icons.person, size: 60),
                                    ),
                                  ),
                                ),
                                if (_user!.isApproved)
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).scaffoldBackgroundColor,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(
                                        Icons.verified,
                                        color: Colors.blue,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 25),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _user!.fullName.isNotEmpty ? _user!.fullName : (_user!.studioName ?? ''),
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textColor,
                                                shadows: [Shadow(offset: Offset(0, 1), blurRadius: 3, color: Colors.black)]),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (_user!.isApproved)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 4.0),
                                            child: Icon(Icons.verified, color: Colors.blue, size: 18),
                                          ),
                                      ],
                                    ),
                                    if (_user!.studioName != null && _user!.studioName!.isNotEmpty)
                                      Text(
                                        _user!.studioName!,
                                        style: TextStyle(fontSize: 14, color: AppTheme.primaryLightColor.withOpacity(0.8)),
                                      ),
                                    if (_user!.locationString.isNotEmpty)
                                      Text(
                                        _user!.locationString,
                                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Alt kısımdaki boşluk ve diğer istatistikler
                  const SizedBox(height: 90), // Profil fotosu taştığı için boşluk
                  
                  // İstatistikler
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(tr('tattoo_count'), _user!.tattooCount.toString()),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection(AppConstants.collectionFollows)
                              .where('followingId', isEqualTo: widget.userId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            final followerCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                            return _buildStatItem(tr('followers'), followerCount.toString());
                          },
                        ),
                        _buildStatItem(tr('likes'), (_user!.totalLikes ?? 0).toString()),
                      ],
                    ),
                  ),

                  // Aksiyon Butonları (Kaymalı)
                  if (isOwnProfile)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(child: _buildActionButton(Icons.calendar_today, tr('btn_appointments'), _handleAppointments)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildActionButton(Icons.message, tr('btn_messages'), _handleMessages)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildActionButton(Icons.camera_alt, tr('btn_share'), _handleCreatePost)),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildFollowAndMessageButtons(context),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            
            // TAB BAR (Sticky Header)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: const Color(0xFF757575),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  tabs: [
                    Tab(text: isTargetArtist ? tr('tab_portfolio') : tr('tab_favorites')),
                    if (isOwnProfile) Tab(text: tr('tab_favorites')),
                    Tab(text: tr('tab_about')),
                  ],
                ),
              ),
            ),
            
            // TAB İÇERİKLERİ
            SliverFillRemaining(
              hasScrollBody: true,
              child: TabBarView(
                controller: _tabController,
                children: [
                  isTargetArtist ? _buildPortfolioTab() : _buildFavoritesTab(),
                  if (isOwnProfile) _buildFavoritesTab(),
                  _buildAboutTab(isOwnProfile),
                ],
              ),
            ),
          ],
        ),

        // 🔥 KATMAN 2: SABİT GERİ BUTONU (Scroll'dan etkilenmez)
        if (canPop && !isOwnProfile)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white10),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
            ),
          ),

        // 🔥 KATMAN 3: SABİT SAĞ ÜST AKSİYONLAR (Ayarlar, Öne Çıkar, Şikayet Et)
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ÖNE ÇIKAR BUTONU (Sadece kendi profiliyse)
              if (isOwnProfile) ...[
                InkWell(
                  onTap: () => _showPromoteBottomSheet(context, _user?.fullName),
                  child: _user?.isFeatured == true
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(tr('featured_badge'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_graph, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(tr('promote_btn'), style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                ),
                const SizedBox(width: 8),
              ],

              // AYARLAR veya ŞİKAYET MENÜSÜ
              GestureDetector(
                onTap: () {
                  if (isOwnProfile) {
                    Navigator.push(context, SlideRoute(page: const ArtistSettingsScreen()));
                  } else {
                    // ŞİKAYET MENÜSÜ AÇ
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppTheme.cardColor,
                      builder: (sheetContext) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
                            ListTile(
                              leading: const Icon(Icons.flag, color: Colors.redAccent),
                              title: Text(tr('report_user'), style: const TextStyle(color: Colors.white)),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                ReportService.showReportDialog(
                                  context: context,
                                  contentId: widget.userId,
                                  contentType: 'user',
                                  reportedUserId: widget.userId,
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.block, color: Colors.white70),
                              title: Text(tr('block_user'), style: const TextStyle(color: Colors.white70)),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                final currentUser = FirebaseAuth.instance.currentUser;
                                if (currentUser != null) {
                                  ReportService.blockUser(
                                    context: context,
                                    currentUserId: currentUser.uid,
                                    blockedUserId: widget.userId,
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Icon(
                    isOwnProfile ? Icons.settings : Icons.more_vert,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- HELPER WIDGETS (ARTIK BURADALAR - DOĞRU YER) ---

  Widget _buildFollowAndMessageButtons(BuildContext context) {
    if (_user == null) {
      return const SizedBox.shrink();
    }

    final userRole = _user!.role.toLowerCase();
    final bool isTargetArtist = userRole.contains('artist');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _isFollowing
                  ? ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(tr('unfollow'),
                          style: const TextStyle(
                            color: AppTheme.backgroundColor,
                          )),
                    )
                  : OutlinedButton(
                      onPressed: _toggleFollow,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(tr('follow'), style: const TextStyle(color: AppTheme.primaryColor)),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (!_checkUserStatus()) return;
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(receiverId: widget.userId, receiverName: _user!.fullName)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(tr('message'), style: const TextStyle(color: AppTheme.backgroundColor)),
              ),
            ),
          ],
        ),
        if (isTargetArtist) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                if (!_checkUserStatus()) return;

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  // --- GLASS EFEKTİ İÇİN KRİTİK AYARLAR ---
                  backgroundColor: Colors.transparent, // Arka plan tamamen şeffaf olmalı
                  elevation: 0, 
                  useSafeArea: true,
                  // showDragHandle: true, // Bunu kapatıyoruz çünkü CreateAppointmentScreen içinde kendi tutamacımızı yaptık
                  // ---------------------------------------
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => CreateAppointmentScreen(
                    artistId: widget.userId,
                    // Eğer post üzerinden geliyorsa referenceImageUrl: post.imageUrl ekleyebilirsin
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryColor, width: 2.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.transparent,
              ),
              child: Text(
                tr('book_appointment'),
                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 18, color: AppTheme.backgroundColor),
      label: Text(label, style: const TextStyle(color: AppTheme.backgroundColor, fontSize: 12)),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildPortfolioTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.collectionPosts)
          .where('artistId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text(tr('no_posts'), style: const TextStyle(color: AppTheme.textColor)));

        final posts = snapshot.data!.docs.map((doc) => PostModel.fromFirestore(doc)).toList();

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];

            return GestureDetector(
              // --- 1. TIKLAMA ÖZELLİĞİ (AYNEN KALIYOR) ---
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(
                      posts: posts, // Tüm listeyi gönderiyoruz ki sağa sola kayabilsin
                      initialIndex: index, // Tıklanan videodan başlasın
                      isOwner: widget.isOwnProfile,
                    ),
                  ),
                );
              },

              // --- 2. GÖRÜNÜM KISMI (BURAYI GÜNCELLİYORUZ) ---
              child: (post.videoUrl != null && post.videoUrl!.isNotEmpty)
                  
                  // A) Eğer Video ise: Siyah Kutu + Play İkonu Göster
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        border: Border.all(color: Colors.white24, width: 0.5),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.play_circle_filled, color: Colors.white.withOpacity(0.8), size: 32),
                          const Positioned(
                            top: 4, right: 4,
                            child: Icon(Icons.videocam, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    )
                  
                  // B) Eğer Resim ise: Eskisi gibi resmi yükle
                  : CachedNetworkImage(
                      imageUrl: post.imageUrls.isNotEmpty ? post.imageUrls[0] : '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[900]),
                      // Hata olursa (örn: link bozuksa) gri kutu göster, patlamasın
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[900], 
                        child: const Icon(Icons.image_not_supported, color: Colors.white24),
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(AppConstants.collectionLikes).where('userId', isEqualTo: widget.userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text(tr('no_favorites'), style: const TextStyle(color: AppTheme.textColor)));
        final likedPostIds = snapshot.data!.docs.map((doc) => doc['postId'] as String).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection(AppConstants.collectionPosts).where(FieldPath.documentId, whereIn: likedPostIds).snapshots(),
          builder: (context, postSnapshot) {
            if (!postSnapshot.hasData || postSnapshot.data!.docs.isEmpty) return const SizedBox();

            final posts = postSnapshot.data!.docs.map((doc) => PostModel.fromFirestore(doc)).toList();

            return GridView.builder(
              padding: const EdgeInsets.all(2),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
              itemCount: posts.length,
              // Favoriler sayfasındaki GridView.builder'ın içine bunu yapıştır:
          itemBuilder: (context, index) {
            final post = posts[index]; // Favoriler listesindeki post

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(
                      posts: posts,
                      initialIndex: index,
                      
                      // DİKKAT: Favorilerdeki postlar başkasınındır.
                      // Bu yüzden burayı 'false' yapıyoruz.
                      isOwner: false, 
                    ),
                  ),
                );
              },
              
              // --- GÖRÜNÜM KISMI (PROFİLDEKİYLE AYNI) ---
              child: (post.videoUrl != null && post.videoUrl!.isNotEmpty)
                  
                  // A) Video ise: Siyah Kutu + Play İkonu
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        border: Border.all(color: Colors.white24, width: 0.5),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.play_circle_filled, color: Colors.white.withOpacity(0.8), size: 32),
                          const Positioned(
                            top: 4, right: 4,
                            child: Icon(Icons.videocam, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    )
                  
                  // B) Resim ise: Resmi Göster
                  : CachedNetworkImage(
                      imageUrl: post.imageUrls.isNotEmpty ? post.imageUrls[0] : '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[900]),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[900], 
                        child: const Icon(Icons.image_not_supported, color: Colors.white24),
                      ),
                    ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAboutTab(bool isOwnProfile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('biography'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
              if (isOwnProfile)
                IconButton(
                  icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ArtistEditProfileScreen())).then((_) => _loadUser());
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _user!.biography != null && _user!.biography!.isNotEmpty ? _user!.biography! : tr('no_biography'),
            style: const TextStyle(fontSize: 14, color: AppTheme.textColor, height: 1.4),
          ),
          
          // --- DÜZELTME 1: UYGULAMALAR ---
          if (_user!.applications.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(tr('applications'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              // BURASI DEĞİŞTİ: app -> tr(app)
              children: _user!.applications.map((app) => _buildAboutTag(tr(app), Colors.blueGrey.withOpacity(0.2))).toList(),
            ),
          ],

          // --- DÜZELTME 2: STİLLER ---
          if (_user!.applicationStyles.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(tr('specialty_styles'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              // BURASI DEĞİŞTİ: style -> tr(style)
              children: _user!.applicationStyles.map((style) => _buildAboutTag(tr(style), AppTheme.backgroundSecondaryColor.withOpacity(1))).toList(),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAboutTag(String text, Color bgColor) {
    return Container(
      // Kutu rengi ve kenarlık YOK
      padding: const EdgeInsets.only(right: 16, bottom: 8), 
      decoration: const BoxDecoration(), 
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Küçük Renkli Nokta
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor, // Veya neon bir renk
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.6),
                  blurRadius: 4, 
                  spreadRadius: 1
                )
              ]
            ),
          ),
          const SizedBox(width: 8),
          // Yazı
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.textColor, // Hafif gri
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAppointments() {
    if (!_checkUserStatus()) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AppointmentsScreen()));
  }

  void _handleMessages() {
    Navigator.push(
      context,
      SlideRoute(page: const MessagesScreen()),
    );
  }

  void _handleCreatePost() => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));

  // --- ÖNE ÇIKAR BOTTOM SHEET ---
  // --- 1. ÖNE ÇIKAR BOTTOMSHEET ---

void _showPromoteBottomSheet(BuildContext context, String? name) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent, // Cam efekti için şeffaf olmalı
    isScrollControlled: true,
    builder: (context) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Buzlu cam şiddeti
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor.withOpacity(0.65), // Camın koyuluk tonu
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                left: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                right: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                bottom: BorderSide.none, // Alt kenarı tamamen devre dışı bıraktık
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Üstteki Tutamaç Çizgisi
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20, top: 5),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // --- VIP DURUM PANELİ ---
                  if (_user?.isFeatured == true && _user?.featuredEndDate != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppTheme.textColor.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            tr('promote_package_active'),
                            style: const TextStyle(color: AppTheme.primaryLightColor, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${tr('time_remaining')}: ${_calculateRemainingTime(_user?.featuredEndDate)}",
                            style: const TextStyle(color: AppTheme.textColor, fontSize: 13),
                          ),
                          Text(
                            "${tr('ends_at')}: ${_user!.featuredEndDate!.day}.${_user!.featuredEndDate!.month}.${_user!.featuredEndDate!.year} - ${_user!.featuredEndDate!.hour}:${_user!.featuredEndDate!.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],

                  Text(
                    tr('extend_package'),
                    style: const TextStyle(color: AppTheme.textColor, fontSize: 13),
                  ),
                  const SizedBox(height: 15),

                  _buildPricingCard(
                    title: tr('promote_test_title'),
                    price: "₺10",
                    description: tr('promote_test_desc'),
                    icon: Icons.timer,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentWebView(
                            url: "https://www.shopier.com/SizinOzelLinkiniz", 
                            onPaymentComplete: () {
                              _handlePayment(6); 
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  _buildPricingCard(
                    title: tr('promote_daily_title'),
                    price: "₺49",
                    description: tr('promote_daily_desc'),
                    icon: Icons.wb_sunny,
                    onTap: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentWebView(
                            url: "https://www.shopier.com/SizinOzelLinkiniz2", 
                            onPaymentComplete: () => _handlePayment(24),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildPricingCard(
                    title: tr('promote_weekly_title'),
                    price: "₺199",
                    description: tr('promote_weekly_desc'),
                    icon: Icons.flash_on,
                    onTap: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentWebView(
                            url: "https://www.shopier.com/SizinOzelLinkiniz3", 
                            onPaymentComplete: () => _handlePayment(168),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.security, color: Colors.grey, size: 14),
                      const SizedBox(width: 10),
                      Text(
                        tr('ssl_secure'),
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.credit_card, color: Colors.grey, size: 14),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(tr('cancel'), style: const TextStyle(color: AppTheme.textGreyColor)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

// --- GÜNCELLENMİŞ CAM EFEKTLİ PRICING CARD ---
Widget _buildPricingCard({
  required String title,
  required String price,
  required String description,
  required IconData icon,
  Color iconColor = AppTheme.primaryColor,
  bool isHighlight = false,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10.0),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          // Kartların içi de biraz şeffaf olsun ki cam efekti katmanlı dursun
          color: isHighlight 
              ? AppTheme.primaryColor.withOpacity(0.15) 
              : AppTheme.cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: isHighlight 
                  ? AppTheme.primaryColor 
                  : AppTheme.textColor.withOpacity(0.1), 
              width: isHighlight ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 22),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(description, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                ],
              ),
            ),
            Text(price, style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    ),
  );
}

// --- 3. ÜST ÜSTE EKLEYEN ÖDEME MANTIĞI ---
Future<void> _handlePayment(int hours) async {
  try {
    final String? uid = _user?.uid;
    if (uid != null) {
      // Başlangıç noktasını belirliyoruz: Şu an mı yoksa mevcut bitiş tarihi mi?
      DateTime baseDate = DateTime.now();

      // Eğer kullanıcı zaten öne çıkarılmışsa ve süresi henüz bitmemişse
      if (_user?.isFeatured == true && _user?.featuredEndDate != null) {
        if (_user!.featuredEndDate!.isAfter(baseDate)) {
          // Yeni süreyi mevcut bitiş tarihinin üzerine ekle
          baseDate = _user!.featuredEndDate!;
        }
      }

      final DateTime expiryDate = baseDate.add(Duration(hours: hours));

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isFeatured': true,
        'featuredEndDate': Timestamp.fromDate(expiryDate),
      });

      if (mounted) {
        setState(() {
          _user?.isFeatured = true;
          _user?.featuredEndDate = expiryDate; // Lokal modeli güncelle
        });

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${tr('payment_success')} ${expiryDate.day}.${expiryDate.month} ${expiryDate.hour}:${expiryDate.minute.toString().padLeft(2, '0')}",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  } catch (e) {
    debugPrint("Hata: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('operation_failed')), backgroundColor: Colors.red),
      );
    }
  }
}

  Widget _buildPackageItem(String title, String price, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 28),
          const SizedBox(width: 15),
          Text(title, style: const TextStyle(color: AppTheme.textColor, fontSize: 17)),
          const Spacer(),
          Text(price, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
// Grid içindeki her bir kareyi çizen fonksiyon
  Widget _buildGridPostItem(PostModel post) {
    
    // --- 1. VİDEO VARSA ---
    if (post.videoUrl != null && post.videoUrl!.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          // Tıklayınca detay sayfasına (PostDetailScreen) gitmeli
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                posts: [post], // Sadece bu postu gönderiyoruz
                initialIndex: 0,
                isOwner: true, // Profil sahibi kendi profilindeyse true
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black87, // Koyu arka plan
            border: Border.all(color: Colors.white10), // Hafif çerçeve
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ortaya Büyük Play İkonu
              Icon(Icons.play_circle_fill, color: Colors.white.withOpacity(0.8), size: 40),
              
              // Sağ Üste Küçük Kamera İkonu (Video olduğunu belli etmek için)
              const Positioned(
                top: 8, 
                right: 8,
                child: Icon(Icons.videocam, color: Colors.white, size: 20),
              ),
              
              // Alta "Video" yazısı (Opsiyonel)
              Positioned(
                bottom: 10,
                child: Text(
                  "VİDEO", 
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6), 
                    fontSize: 10, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5
                  )
                ),
              ),
            ],
          ),
        ),
      );
    }

    // --- 2. RESİM VARSA (Eski Kodun) ---
    if (post.imageUrls.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          // Detay sayfasına git
           Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                posts: [post], 
                initialIndex: 0,
                isOwner: true,
              ),
            ),
          );
        },
        child: CachedNetworkImage(
          imageUrl: post.imageUrls[0],
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.grey[900]),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      );
    }

    // --- 3. HİÇBİRİ YOKSA ---
    return Container(color: Colors.grey[900]);
  }


} // 🔥 _ArtistProfileScreenState BURADA BİTİYOR


  // Bu fonksiyon, tarihler arasındaki farkı hesaplayıp kullanıcıya güzel bir yazı döner
  String _calculateRemainingTime(DateTime? endDate) {
    if (endDate == null) return "Öne Çıkarıldı"; // Bunu çevirmeye gerek yok (statik değil, dinamik akışta null check)
    
    final now = DateTime.now();
    final diff = endDate.difference(now);

    // Eğer süre dolmuşsa
    if (diff.isNegative) {
      return "Süre Doldu"; // Bunu aşağıda tr ile değiştireceğiz, bu helper fonksiyon dışında.
    }
    
    // 1 saatten fazla varsa "X sa Y dk" formatı
    if (diff.inHours > 0) {
      return "${diff.inHours}sa ${diff.inMinutes.remainder(60)}dk";
    } 
    // 1 saatten azsa sadece "X dk kaldı" formatı
    else {
      return "${diff.inMinutes}dk kaldı";
    }
  }

// --- DIŞARI ALINAN SINIF (DOĞRU YER) ---
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;

  
}