import 'package:tattink_app/screens/profile/artist_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth eklendi
import '../models/post_model.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/turkey_locations.dart';
import '../utils/slide_route.dart';
import '../theme/app_theme.dart';
import '../widgets/login_required_dialog.dart';
import 'create_post_screen.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';

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
    if (mounted) {
      setState(() { });
    }
  }

  // --- YENİ: KULLANICI DOĞRULAMA KONTROLÜ ---
  // Bu fonksiyon; giriş yapılmamışsa login diyaloğunu, 
  // e-posta onaylanmamışsa onay diyaloğunu gösterir.
  bool _checkUserStatus() {
    final user = FirebaseAuth.instance.currentUser;
    
    // 1. Giriş Kontrolü
    if (user == null) {
      _showLoginRequired();
      return false;
    }
    
    // 2. E-posta Onay Kontrolü
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
          'Mesaj atma, beğenme ve randevu talebi gibi özellikleri kullanabilmek için e-posta adresinizi onaylamanız gerekmektedir.',
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 50,
                    child: CachedNetworkImage(
                      imageUrl: AppConstants.logoUrl,
                      height: 50,
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) => const SizedBox(
                        height: 50, width: 50,
                        child: Icon(Icons.image_not_supported, size: 30),
                      ),
                    ),
                  ),
                  _buildNotificationIcon(),
                ],
              ),
            ),
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
                if (user.role == AppConstants.roleArtistApproved && user.isApproved) {
                  return FloatingActionButton(
                    onPressed: () {
                      // Artist paylaşım yaparken de onaylı olmalı mı?
                      // İsterseniz buraya da _checkUserStatus() ekleyebilirsiniz.
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
          return true;
        }).toList();

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppTheme.primaryColor,
          backgroundColor: const Color(0xFF252525),
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(), 
            itemCount: filteredPosts.length,
            itemBuilder: (context, index) {
              final post = filteredPosts[index];
              return _buildPostCard(post);
            },
          ),
        );
      },
    );
  }

  void _openFullScreenPost(PostModel post) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 3.0,
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrls[0],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuart)),
          child: child,
        );
      },
    );
  }

  Widget _buildPostCard(PostModel post) {
    final ValueNotifier<bool> isExpandedNotifier = ValueNotifier<bool>(false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openFullScreenPost(post),
            child: _buildPostMedia(post),
          ),
          Container(
            color: const Color(0xFF252525),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    ArtistProfileScreen(userId: post.artistId),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeOutQuart;
                                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                  return SlideTransition(position: animation.drive(tween), child: child);
                                },
                                transitionDuration: const Duration(milliseconds: 400),
                              ),
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
                                      Text(post.artistUsername!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
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
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 40, width: 40,
                                child: IconButton(
                                  onPressed: () => _handleMessagePost(post),
                                  padding: EdgeInsets.zero,
                                  icon: Transform.rotate(angle: -0.8, child: const Icon(Icons.send_rounded, size: 26, color: Color(0xFF8A4F77))),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildLikeButton(post),
                              if (post.likeCount > 0)
                                Text(
                                  post.likeCount.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[400],
                                    fontSize: 10,
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
                    padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 12.0),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: isExpandedNotifier,
                      builder: (context, isExpanded, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => isExpandedNotifier.value = !isExpandedNotifier.value,
                              child: Text(post.caption!, maxLines: isExpanded ? null : 2, overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Colors.white)),
                            ),
                            const SizedBox(height: 4),
                            if (!isExpanded && post.caption!.length > 60)
                              GestureDetector(
                                onTap: () => isExpandedNotifier.value = true,
                                child: const Text("Devamını oku...", style: TextStyle(color: Color(0xFF8A4F77), fontWeight: FontWeight.bold, fontSize: 12)),
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
    return AspectRatio(
      aspectRatio: 0.8,
      child: post.imageUrls.length == 1
          ? CachedNetworkImage(
              imageUrl: post.imageUrls[0],
              width: double.infinity, height: double.infinity, fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.black12, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            )
          : PageView.builder(
              itemCount: post.imageUrls.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: post.imageUrls[index],
                  width: double.infinity, height: double.infinity, fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.black12, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                );
              },
            ),
    );
  }

  Widget _buildLikeButton(PostModel post) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.collectionLikes)
          .doc('${post.id}_${Provider.of<AuthService>(context).currentUser?.uid ?? ''}')
          .snapshots(),
      builder: (context, snapshot) {
        final isLiked = snapshot.hasData && snapshot.data!.exists;
        return SizedBox(
          height: 40, width: 40, 
          child: GestureDetector(
            onTap: () => _handleLike(post, isLiked),
            child: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? const Color(0xFF944B79) : Colors.white, size: 28),
          ),
        );
      },
    );
  }

  Future<void> _handleLike(PostModel post, bool isLiked) async {
    // GÜNCELLENDİ: Durum kontrolü yapılıyor
    if (!_checkUserStatus()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    // userId kontrolü zaten _checkUserStatus içinde yapılıyor ama güvenli kod için kalabilir.
    if (userId == null) return;

    final likeDocRef = FirebaseFirestore.instance.collection(AppConstants.collectionLikes).doc('${post.id}_$userId');
    final postRef = FirebaseFirestore.instance.collection(AppConstants.collectionPosts).doc(post.id);
    final artistRef = FirebaseFirestore.instance.collection(AppConstants.collectionUsers).doc(post.artistId);

    if (isLiked) {
      await likeDocRef.delete();
      await postRef.update({'likeCount': FieldValue.increment(-1), 'likedBy': FieldValue.arrayRemove([userId])});
      await artistRef.update({'totalLikes': FieldValue.increment(-1)});
    } else {
      await likeDocRef.set({'postId': post.id, 'userId': userId, 'createdAt': FieldValue.serverTimestamp()});
      await postRef.update({'likeCount': FieldValue.increment(1), 'likedBy': FieldValue.arrayUnion([userId])});
      await artistRef.update({'totalLikes': FieldValue.increment(1)});
    }
  }

  void _handleMessagePost(PostModel post) {
    // GÜNCELLENDİ: Durum kontrolü yapılıyor
    if (!_checkUserStatus()) return;

    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(receiverId: post.artistId, receiverName: post.artistUsername ?? 'Artist', referenceImageUrl: post.imageUrls.isNotEmpty ? post.imageUrls[0] : null)));
  }

  String _getSortButtonLabel() {
    if (_sortOption == null) return 'Sırala';
    switch (_sortOption) {
      case AppConstants.sortNewest: return 'En Yeniler';
      case AppConstants.sortPopular: return 'En Popüler';
      case AppConstants.sortDistance: return 'En Yakın';
      case AppConstants.sortCampaigns: return 'Kampanyalar';
      default: return 'Sırala';
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: const Color(0xFF161616), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => StatefulBuilder(builder: (context, setModalState) => SizedBox(height: MediaQuery.of(context).size.height * 0.75, child: Column(children: [Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))), const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text('Filtrele', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFEBEBEB))))), Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFilterSection('Uygulama', ['Dövme', 'Piercing', 'Geçici Dövme', 'Rasta', 'Makyaj', 'Kına'], _selectedApplications, (value) { setModalState(() { _selectedApplications.contains(value) ? _selectedApplications.remove(value) : _selectedApplications.add(value); }); }), const SizedBox(height: 16), _buildFilterSection('Stil', ['Minimal', 'Old School', 'Dot Work', 'Realist', 'Tribal', 'Blackwork', 'Watercolor', 'Trash Polka', 'Fine Line', 'Traditional'], _selectedStyles, (value) { setModalState(() { _selectedStyles.contains(value) ? _selectedStyles.remove(value) : _selectedStyles.add(value); }); }), const SizedBox(height: 16), _buildDistrictSearch(setModalState), const SizedBox(height: 16), _buildScoreSlider(setModalState), const SizedBox(height: 16)]))), Padding(padding: const EdgeInsets.all(16.0), child: SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () { setState(() {}); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Uygula', style: TextStyle(color: Color(0xFFEBEBEB), fontSize: 16, fontWeight: FontWeight.bold)))))]))));
  }

  Widget _buildFilterSection(String title, List<String> options, List<String> selected, Function(String) onToggle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEBEBEB))), const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, children: options.map((option) { final isSelected = selected.contains(option); return GestureDetector(onTap: () => onToggle(option), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: isSelected ? AppTheme.primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? AppTheme.primaryColor : const Color(0xFFEBEBEB), width: 1)), child: Text(option, style: const TextStyle(color: Color(0xFFEBEBEB), fontSize: 14)))); }).toList())]);
  }

  Widget _buildDistrictSearch(StateSetter setModalState) {
    return _DistrictSearchWidget(selectedDistrict: _selectedDistrict, selectedCity: _selectedCity, onDistrictSelected: (district, city) { setModalState(() { _selectedDistrict = district; _selectedCity = city; }); });
  }

  Widget _buildNotificationIcon() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    if (userId == null) return IconButton(icon: const Icon(Icons.notifications_outlined, color: AppTheme.primaryColor, size: 28), onPressed: () {});
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(AppConstants.collectionNotifications).where('userId', isEqualTo: userId).where('isRead', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Stack(clipBehavior: Clip.none, children: [IconButton(icon: const Icon(Icons.notifications_outlined, color: AppTheme.primaryColor, size: 28), onPressed: () { Navigator.push(context, SlideRoute(page: const NotificationsScreen())); }), if (unreadCount > 0) Positioned(right: 6, top: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle), constraints: const BoxConstraints(minWidth: 18, minHeight: 18), child: Center(child: Text(unreadCount > 99 ? '99+' : unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w300))))),]);
      },
    );
  }

  Widget _buildScoreSlider(StateSetter setModalState) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Minimum Artist Puanı: ${_minScore.toStringAsFixed(1)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEBEBEB))), Slider(value: _minScore, min: 0.0, max: 5.0, divisions: 10, label: _minScore.toStringAsFixed(1), activeColor: AppTheme.primaryColor, inactiveColor: Colors.grey[700], onChanged: (value) { setModalState(() { _minScore = value; }); }),]);
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF161616), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => SizedBox(height: MediaQuery.of(context).size.height * 0.4, child: Column(children: [Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))), const Padding(padding: EdgeInsets.all(16.0), child: Text('Sırala', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFEBEBEB)))), Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16.0), children: [_buildSortOption('En Yeniler', Icons.refresh, AppConstants.sortNewest), _buildSortOption('En Popüler', Icons.local_fire_department, AppConstants.sortPopular), _buildSortOption('En Yakın', Icons.near_me, AppConstants.sortDistance), _buildSortOption('Kampanyalar', Icons.campaign, AppConstants.sortCampaigns)]))])));
  }

  Widget _buildSortOption(String label, IconData icon, String value) {
    final isSelected = _sortOption == value;
    return ListTile(leading: Icon(icon, color: const Color(0xFFEBEBEB)), title: Text(label, style: const TextStyle(color: Color(0xFFEBEBEB))), trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryColor) : null, onTap: () { setState(() { _sortOption = value; }); Navigator.pop(context); });
  }

  void _showLoginRequired() { LoginRequiredDialog.show(context); }
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