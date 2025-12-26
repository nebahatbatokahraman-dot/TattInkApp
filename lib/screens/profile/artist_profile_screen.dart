import '../create_appointment_screen.dart'; // <--- SENİN DOSYA ADIN
import '../post_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

// --- SERVICE & MODEL IMPORTS ---
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

// --- YENİ: STÜDYO FOTOĞRAFI YÜKLEME ---
  Future<void> _uploadStudioImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;

      // Yükleme animasyonu gösterilebilir, şimdilik basit tutuyoruz
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yükleniyor...')));

      final imageService = ImageService();
      // Resmi sıkıştırıp byte'a çeviriyoruz (senin image service yapına göre)
      final File file = File(image.path);
      final optimizedImageBytes = await imageService.optimizeImage(file); 
      
      // Storage'a yükle
      final imageUrl = await imageService.uploadImage(
        imageBytes: optimizedImageBytes,
        path: 'studio_images/${widget.userId}/${DateTime.now().millisecondsSinceEpoch}',
      );

      // Firestore'a dizi olarak ekle (arrayUnion)
      await FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(widget.userId)
          .update({
        'studioImageUrls': FieldValue.arrayUnion([imageUrl]),
      });

      // Ekrana yansıması için kullanıcıyı yeniden yükle
      await _loadUser();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fotoğraf eklendi!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // --- YENİ: STÜDYO FOTOĞRAFI SİLME ---
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fotoğraf silindi.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  // Silme onayı için dialog
  void _confirmDeleteStudioImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Text("Fotoğrafı Sil", style: TextStyle(color: Colors.white)),
        content: const Text("Bu stüdyo fotoğrafını kaldırmak istiyor musunuz?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteStudioImage(imageUrl);
            }, 
            child: const Text("Sil", style: TextStyle(color: Colors.red))
          ),
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

  // --- KULLANICI DURUM KONTROLÜ ---
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
        backgroundColor: const Color(0xFF161616),
        title: const Text('E-posta Onayı Gerekli', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Takip etme, mesaj atma ve randevu alma işlemleri için e-posta adresinizi onaylamanız gerekmektedir.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam', style: TextStyle(color: AppTheme.primaryColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.currentUser?.sendEmailVerification();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Doğrulama e-postası tekrar gönderildi.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Tekrar Gönder'),
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
            widget.userId 
          );
        }
      }
      
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşlem başarısız: $e')),
      );
    }
  }

  Future<void> _uploadCoverPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final imageService = ImageService();
      final optimizedImage = await imageService.optimizeImage(File(image.path));

      if (_user!.coverImageUrl != null) {
        await imageService.deleteImage(_user!.coverImageUrl!);
      }

      final coverImageUrl = await imageService.uploadImage(
        imageBytes: optimizedImage,
        path: AppConstants.storageCoverImages,
      );

      await FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(widget.userId)
          .update({
        'coverImageUrl': coverImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kapak fotoğrafı güncellendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
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
        if (!userSnapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF161616),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!userSnapshot.data!.exists) {
           return const Scaffold(
            backgroundColor: Color(0xFF161616),
            body: Center(child: Text("Kullanıcı bulunamadı", style: TextStyle(color: Colors.white))),
          );
        }

        final userData = userSnapshot.data!;
        _user = UserModel.fromFirestore(userData);

        final currentUserId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
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

    return SafeArea(
      top: false,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // --- KAPAK FOTOĞRAFI ---
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        image: _user!.coverImageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(_user!.coverImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                    ),

                    // --- GERİ BUTONU ---
                    if (canPop && !isOwnProfile)
                      Positioned(
                        top: 40,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                          ),
                        ),
                      ),

                    // --- AYARLAR BUTONU ---
                    if (isOwnProfile)
                      Positioned(
                        top: 40,
                        right: 16,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              SlideRoute(page: const ArtistSettingsScreen()), 
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.settings, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    
                    // --- KAPAK FOTO DÜZENLEME ---
                    if (isOwnProfile)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _uploadCoverPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, size: 20, color: Colors.white),
                          ),
                        ),
                      ),
                    
                    // --- PROFİL FOTO & BİLGİLER ---
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
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    width: 4,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Container(
                                    width: 130,
                                    height: 130,
                                    color: const Color(0xFF757575),
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
                                            color: Colors.white,
                                            shadows: [Shadow(offset: Offset(0, 1), blurRadius: 3, color: Colors.black)]
                                          ),
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
                                      style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                                    ),
                                  if (_user!.locationString.isNotEmpty)
                                    Text(
                                      _user!.locationString,
                                      style: TextStyle(fontSize: 11, color: Colors.grey[300]),
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
                const SizedBox(height: 80), 
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Dövme', _user!.tattooCount.toString()),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection(AppConstants.collectionFollows)
                            .where('followingId', isEqualTo: widget.userId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final followerCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return _buildStatItem('Takipçi', followerCount.toString());
                        },
                      ),
                      _buildStatItem('Beğeni', (_user!.totalLikes ?? 0).toString()),
                    ],
                  ),
                ),
                if (isOwnProfile)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(child: _buildActionButton(Icons.calendar_today, 'Randevular', _handleAppointments)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildActionButton(Icons.message, 'Mesajlar', _handleMessages)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildActionButton(Icons.camera_alt, 'Paylaş', _handleCreatePost)),
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
                  const Tab(text: 'Portfolyo'),
                  if (isOwnProfile) const Tab(text: 'Favoriler'),
                  const Tab(text: 'Hakkında'),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true, 
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPortfolioTab(),
                if (isOwnProfile) _buildFavoritesTab(),
                _buildAboutTab(isOwnProfile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- GÜNCELLENEN BUTON ALANI ---
  Widget _buildFollowAndMessageButtons(BuildContext context) {
    if (_user == null) {
      return const SizedBox.shrink(); 
    }
    
    final userRole = _user!.role.toLowerCase();
    final bool isTargetArtist = userRole.contains('artist');

    return Column(
      children: [
        // 1. SATIR: TAKİP VE MESAJ
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
                    child: const Text('Takibi Bırak', style: TextStyle(color: Colors.white, fontSize: 12)),
                  )
                : OutlinedButton(
                    onPressed: _toggleFollow,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Takip Et', style: TextStyle(color: AppTheme.primaryColor)),
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
                child: const Text('Mesaj', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
        
        // 2. SATIR: RANDEVU AL (Sadece profiline bakılan kişi Artist ise)
        if (isTargetArtist) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton( // <-- BURADA DEĞİŞİKLİK YAPILDI
              onPressed: () {
                if (!_checkUserStatus()) return;
                
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, 
                  useSafeArea: true,       
                  showDragHandle: true,
                  backgroundColor: const Color(0xFF161616),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => CreateAppointmentScreen(
                    artistId: widget.userId,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryColor, width: 2.0), // Kenarlık Rengi
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.transparent, // İçi boş
              ),
              child: const Text(
                'Randevu Al', 
                style: TextStyle(
                  color: AppTheme.primaryColor, // Yazı Rengi
                  fontWeight: FontWeight.bold
                ),
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
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Henüz paylaşım yok', style: TextStyle(color: Colors.white70)));

        final posts = snapshot.data!.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList();

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(
                      posts: posts,
                      initialIndex: index,
                      isOwner: widget.isOwnProfile, 
                    ),
                  ),
                );
              },
              child: CachedNetworkImage( 
                imageUrl: post.imageUrls.isNotEmpty ? post.imageUrls[0] : '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[900]),
                errorWidget: (context, url, error) => const Icon(Icons.error),
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
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Henüz favori yok', style: TextStyle(color: Colors.white70)));
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
              itemBuilder: (context, index) {
                final post = posts[index];
                return GestureDetector(
                  onTap: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(
                          posts: posts,
                          initialIndex: index,
                          isOwner: false
                        ),
                      ),
                    );
                  },
                  child: Image.network(post.imageUrls.isNotEmpty ? post.imageUrls[0] : '', fit: BoxFit.cover)
                );
              },
            );
          },
        );
      },
    );
  }

Widget _buildAboutTab(bool isOwnProfile) {
    // Modelden gelen gerçek liste (Eğer null ise boş liste)
    final studioImages = _user!.studioImageUrls;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- BİYOGRAFİ ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Biyografi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
            _user!.biography != null && _user!.biography!.isNotEmpty ? _user!.biography! : 'Henüz bir biyografi eklenmemiş.',
            style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
          ),
          
          // --- STÜDYO & ATMOSFER (VERİTABANI ENTEGRASYONLU) ---
          // Eğer liste boşsa VE kendi profili değilse bu başlığı hiç gösterme.
          if (studioImages.isNotEmpty || isOwnProfile) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Stüdyo & Atmosfer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                if (isOwnProfile) // Sadece bilgi amaçlı (opsiyonel)
                   Padding(
                     padding: const EdgeInsets.only(left: 8.0),
                     child: Text("(${studioImages.length})", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                   ),
              ],
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              height: 100, 
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                // Eğer kendi profili ise, listeye "+ Ekle" butonu için +1 ekliyoruz
                itemCount: studioImages.length + (isOwnProfile ? 1 : 0),
                itemBuilder: (context, index) {
                  
                  // 1. Durum: Kendi profili ve ilk eleman -> EKLE BUTONU
                  if (isOwnProfile && index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: InkWell(
                        onTap: _uploadStudioImage,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 80, // Ekle butonu biraz daha dar olabilir
                          decoration: BoxDecoration(
                            color: const Color(0xFF252525),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: AppTheme.primaryColor),
                              SizedBox(height: 4),
                              Text("Ekle", style: TextStyle(color: Colors.white70, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // 2. Durum: Fotoğraflar
                  // Eğer +1 eklediysek, gerçek resim indexi 1 eksik olmalı
                  final int imageIndex = isOwnProfile ? index - 1 : index;
                  final String imageUrl = studioImages[imageIndex];

                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      // Kendi profili ise silmek için uzun basabilir
                      onLongPress: isOwnProfile ? () => _confirmDeleteStudioImage(imageUrl) : null,
                      onTap: () {
                        // Tıklanınca tam ekran açılabilir (İstersen buraya kod ekleyebiliriz)
                      },
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              height: 100,
                              width: 140,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.grey[900]),
                              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.grey),
                            ),
                          ),
                          // Kendi profili ise sağ üstte küçük silme ikonu da koyabiliriz (kullanıcı dostu)
                          if (isOwnProfile)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _confirmDeleteStudioImage(imageUrl),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // --- UYGULAMALAR (TAGLER) ---
          if (_user!.applications.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Uygulamalar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _user!.applications.map((app) => _buildAboutTag(app, Colors.blueGrey.withOpacity(0.2))).toList(),
            ),
          ],
          
          // --- STİLLER (TAGLER) ---
          if (_user!.applicationStyles.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Uzmanlık Stilleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _user!.applicationStyles.map((style) => _buildAboutTag(style, AppTheme.primaryColor.withOpacity(0.15))).toList(),
            ),
          ],
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAboutTag(String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
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
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverAppBarDelegate(this.tabBar);
  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: tabBar);
  }
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}