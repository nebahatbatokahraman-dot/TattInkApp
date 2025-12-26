import 'post_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math; // Açı hesaplaması için eklendi

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
        backgroundColor: const Color(0xFF161616),
        title: const Text('E-posta Onayı Gerekli', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Beğeni yapabilmek ve mesaj atabilmek için e-posta onayı gereklidir.',
          style: TextStyle(color: Colors.white70),
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER (Logo ve Bildirim)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 40,
                    child: CachedNetworkImage(
                      imageUrl: AppConstants.logoUrl,
                      height: 40,
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) => const SizedBox(
                        height: 40, width: 40,
                        child: Icon(Icons.image_not_supported, size: 30),
                      ),
                    ),
                  ),
                  _buildNotificationIcon(),
                ],
              ),
            ),

            // 2. FİLTRE VE SIRALAMA BUTONLARI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showFilterBottomSheet(context),
                      icon: const Icon(Icons.tune),
                      label: const Text('Filtrele'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showSortBottomSheet(context),
                      icon: const Icon(Icons.sort),
                      label: Text(_getSortButtonLabel()),
                    ),
                  ),
                ],
              ),
            ),

            // 3. POST AKIŞI
            Expanded(child: _buildPostFeed()),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
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
  
  if (_sortOption == AppConstants.sortPopular) {
    query = query.orderBy('likeCount', descending: true);
  } else {
    query = query.orderBy('createdAt', descending: true);
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
        backgroundColor: const Color(0xFF252525),
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(), 
          itemCount: filteredPosts.length + (filteredPosts.length ~/ 3),
          itemBuilder: (context, index) {
            // Her 4. sırada (index 3, 7, 11...) reklam kartı göster
            if (index % 4 == 3) {
              return _buildAdPostCard(); 
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
Widget _buildAdPostCard() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF212121),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. ÜST KISIM: REKLAM GÖRSELİ
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Container(
            height: 300,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A2A2A), Color(0xFF161616)],
              ),
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 70),
            ),
          ),
        ),
        
        // 2. ALT KISIM: PROFİL VE YAZI ALANI
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: const Icon(Icons.stars, color: AppTheme.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TattInk Premium",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        "Sponsorlu",
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text("Bilgi Al", style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "Kendi stüdyonu şimdi öne çıkar! Profilini binlerce sanatseverle buluştur ve randevularını hemen artır.",
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medya
          GestureDetector(
            onTap: () => _openFullScreenPost(post),
            child: _buildPostMedia(post),
          ),
          
          // Alt Bilgiler
          Container(
            color: const Color(0xFF252525),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Artist Bilgileri (Alt Sol)
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
                                    ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (post.artistUsername != null)
                                      Text(post.artistUsername!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14), overflow: TextOverflow.ellipsis),
                                    if (post.locationString.isNotEmpty)
                                      Text(post.locationString, style: TextStyle(fontSize: 11, color: Colors.grey[400]), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Mesaj ve Like (Alt Sağ)
                     Row(
                        children: [
                          // Mesaj Butonu
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
                          // Beğeni Butonu ve Sayacı Stack İçinde
                          Stack(
                            clipBehavior: Clip.none, // Sayının buton dışına taşmasına izin verir
                            children: [
                              _buildLikeButton(post),
                              if (post.likeCount > 0)
                                Positioned(
                                  right: 9, // Butonun sağından dışarı taşır
                                  top: 25,   // Senin padding'ine göre aşağıda konumlandırır
                                  child: Text(
                                    "${post.likeCount}",
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
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
                                  style: const TextStyle(fontSize: 13, color: Colors.white),
                                  children: [
                                  
                                    TextSpan(text: post.caption!),
                                  ]
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (!isExpanded && post.caption!.length > 60)
                                  GestureDetector(
                                    onTap: () => isExpandedNotifier.value = true,
                                    child: const Padding(
                                      padding: EdgeInsets.only(top: 4.0),
                                      child: Text("daha fazla...", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                                
                            
                              ],
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
    );
  }




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
          color: const Color(0xFF202020), 
          child: const Center(child: CircularProgressIndicator())
        ),
        errorWidget: (context, url, error) => Container(
          height: 300, 
          color: const Color(0xFF202020), 
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
            color: isLiked ? const Color(0xFF944B79) : AppTheme.primaryColor, 
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
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: const Color(0xFF161616), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => StatefulBuilder(builder: (context, setModalState) => SizedBox(height: MediaQuery.of(context).size.height * 0.75, child: Column(children: [Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))), Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0), child: Stack(alignment: Alignment.center, children: [const Center(child: Text('Filtrele', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFEBEBEB)))), Positioned(right: 0, child: TextButton(onPressed: () { setModalState(() { _selectedApplications.clear(); _selectedStyles.clear(); _selectedDistrict = null; _selectedCity = null; _minScore = 0.0; }); }, child: const Text('Sıfırla', style: TextStyle(color: Colors.redAccent))))])), Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFilterSection('Uygulama', AppConstants.applications, _selectedApplications, (value) { setModalState(() { _selectedApplications.contains(value) ? _selectedApplications.remove(value) : _selectedApplications.add(value); }); }), const SizedBox(height: 16), _buildFilterSection('Stil', AppConstants.styles, _selectedStyles, (value) { setModalState(() { _selectedStyles.contains(value) ? _selectedStyles.remove(value) : _selectedStyles.add(value); }); }), const SizedBox(height: 16), _buildDistrictSearch(setModalState), const SizedBox(height: 16)]))), Padding(padding: const EdgeInsets.all(16.0), child: SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () { setState(() {}); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor), child: const Text('Uygula', style: TextStyle(color: Color(0xFFEBEBEB), fontSize: 16, fontWeight: FontWeight.bold)))))]))));
  }

  Widget _buildFilterSection(String title, List<String> options, List<String> selected, Function(String) onToggle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEBEBEB))), const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, children: options.map((option) { final isSelected = selected.contains(option); return GestureDetector(onTap: () => onToggle(option), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: isSelected ? AppTheme.primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? AppTheme.primaryColor : const Color(0xFFEBEBEB), width: 1)), child: Text(option, style: const TextStyle(color: Color(0xFFEBEBEB), fontSize: 14)))); }).toList())]);
  }

  Widget _buildDistrictSearch(StateSetter setModalState) {
    return _DistrictSearchWidget(selectedDistrict: _selectedDistrict, selectedCity: _selectedCity, onDistrictSelected: (district, city) { setModalState(() { _selectedDistrict = district; _selectedCity = city; }); });
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF161616), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => SizedBox(height: MediaQuery.of(context).size.height * 0.3, child: Column(children: [Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))), const Padding(padding: EdgeInsets.all(16.0), child: Text('Sırala', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFEBEBEB)))), Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16.0), children: [_buildSortOption('En Yeniler', Icons.refresh, AppConstants.sortNewest), _buildSortOption('En Popüler', Icons.local_fire_department, AppConstants.sortPopular)]))])));
  }

  Widget _buildSortOption(String label, IconData icon, String value) {
    final isSelected = _sortOption == value;
    return ListTile(leading: Icon(icon, color: const Color(0xFFEBEBEB)), title: Text(label, style: const TextStyle(color: Color(0xFFEBEBEB))), trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryColor) : null, onTap: () { setState(() { _sortOption = value; }); Navigator.pop(context); });
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
                      style: const TextStyle(color: Colors.white, fontSize: 10)
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Bölge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEBEBEB))), const SizedBox(height: 8), TextField(controller: _searchController, style: const TextStyle(color: Color(0xFFEBEBEB)), decoration: InputDecoration(hintText: 'Semt ara', hintStyle: const TextStyle(color: Color(0xFFEBEBEB)), prefixIcon: const Icon(Icons.search, color: Color(0xFFEBEBEB)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), onChanged: _updateFilteredDistricts), if (_filteredDistricts.isNotEmpty) Container(margin: const EdgeInsets.only(top: 8), constraints: const BoxConstraints(maxHeight: 150), decoration: BoxDecoration(color: const Color(0xFF323232), borderRadius: BorderRadius.circular(8)), child: ListView.builder(shrinkWrap: true, itemCount: _filteredDistricts.length, itemBuilder: (context, index) { final item = _filteredDistricts[index]; return ListTile(title: Text('${item['district']}, ${item['city']}', style: const TextStyle(color: Color(0xFFEBEBEB))), onTap: () { _searchController.text = '${item['district']}, ${item['city']}'; widget.onDistrictSelected(item['district'], item['city']); setState(() { _filteredDistricts = []; }); }); })),]);
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
                  placeholder: (context, url) => Container(color: const Color(0xFF202020)),
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
                          : Colors.white.withOpacity(0.5),
                    ),
                  );
                }).toList(),
              ),
            ),
          
          // --- FOTOĞRAF SAYISI GÖSTERGESİ (Sağ Üst Köşe - Opsiyonel) ---
          if (widget.imageUrls.length > 1)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${_currentIndex + 1}/${widget.imageUrls.length}",
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}