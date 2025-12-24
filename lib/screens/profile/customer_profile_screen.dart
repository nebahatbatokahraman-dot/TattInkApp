import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../models/message_model.dart';
import '../../utils/constants.dart';
import '../../theme/app_theme.dart';
import '../../utils/slide_route.dart';
import '../appointments_screen.dart';
import '../chat_screen.dart'; 
import '../messages_screen.dart'; 
import '../profile/artist_profile_screen.dart';
import '../settings/customer_settings_screen.dart'; 
import '../settings/customer_edit_profile_screen.dart'; 

class CustomerProfileScreen extends StatefulWidget {
  final String userId;
  const CustomerProfileScreen({super.key, required this.userId});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- BEĞENİ / FAVORİ İŞLEMİ ---
  Future<void> _handleLike(PostModel post, bool isCurrentlyLiked) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    if (userId == null) return;

    final likeDocRef = FirebaseFirestore.instance
        .collection(AppConstants.collectionLikes)
        .doc('${post.id}_$userId');

    final postRef = FirebaseFirestore.instance
        .collection(AppConstants.collectionPosts)
        .doc(post.id);

    final artistRef = FirebaseFirestore.instance
        .collection(AppConstants.collectionUsers)
        .doc(post.artistId);

    if (isCurrentlyLiked) {
      await likeDocRef.delete();
      await postRef.update({
        'likeCount': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([userId]),
      });
      await artistRef.update({'totalLikes': FieldValue.increment(-1)});
    } else {
      await likeDocRef.set({
        'postId': post.id,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await postRef.update({
        'likeCount': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([userId]),
      });
      await artistRef.update({'totalLikes': FieldValue.increment(1)});
    }
  }

  // --- TAM EKRAN GÖRÜNÜMÜ ---
  void _openFullScreenPost(PostModel post) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) {
        final currentUserId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;

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
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: post.artistProfileImageUrl != null 
                            ? NetworkImage(post.artistProfileImageUrl!) 
                            : null,
                        child: post.artistProfileImageUrl == null ? const Icon(Icons.person) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(post.artistUsername ?? 'Sanatçı', 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(post.locationString, 
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection(AppConstants.collectionLikes)
                            .doc('${post.id}_$currentUserId')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final isLiked = snapshot.hasData && snapshot.data!.exists;
                          return IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? const Color(0xFF944B79) : Colors.white,
                            ),
                            onPressed: () => _handleLike(post, isLiked),
                          );
                        }
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(context, SlideRoute(page: ArtistProfileScreen(userId: post.artistId)));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                        child: const Text('Profili Gör', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
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
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuart)),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Giriş yapın')));

    return Scaffold(
      body: StreamBuilder<UserModel?>(
        stream: Provider.of<AuthService>(context).getUserModelStream(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final userModel = snapshot.data!;

          return SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildProfileInfo(userModel),
                _buildAppointmentsBtn(),
                const SizedBox(height: 20),
                _buildTabs(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGridTab(AppConstants.collectionLikes), // Favoriler
                      _buildListTab(), // Takip
                      _buildMessagesList(user.uid), // Mesajlar
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CachedNetworkImage(imageUrl: AppConstants.logoUrl, height: 40),
          IconButton(
            icon: const Icon(Icons.settings, color: AppTheme.primaryColor),
            // DÜZELTİLDİ: Artık direkt edit sayfasına değil, Ayarlar menüsüne gidiyor
            onPressed: () => Navigator.push(context, SlideRoute(page: const CustomerSettingsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(UserModel user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
                child: user.profileImageUrl == null ? const Icon(Icons.person, size: 40) : null,
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  // Profil fotosundaki kalem ikonu direkt düzenlemeye gitmeye devam edebilir
                  onTap: () => Navigator.push(context, SlideRoute(page: const CustomerEditProfileScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(user.locationString, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsBtn() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity, height: 45,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          onPressed: () => showModalBottomSheet(
            context: context, isScrollControlled: true,
            builder: (context) => SizedBox(height: MediaQuery.of(context).size.height * 0.7, child: const AppointmentsScreen()),
          ),
          child: const Text('RANDEVULARIM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _tabItem(Icons.favorite, 'Favoriler', 0),
        _tabItem(Icons.person, 'Takip', 1),
        _tabItem(Icons.message, 'Mesajlar', 2),
      ],
    );
  }

  Widget _tabItem(IconData icon, String label, int index) {
    bool sel = _tabController.index == index;
    Color color = sel ? AppTheme.primaryColor : Colors.grey;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
            const SizedBox(height: 4),
            AnimatedContainer(duration: const Duration(milliseconds: 200), width: sel ? 30 : 0, height: 2, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildGridTab(String collection) {
    final uid = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).where('userId', isEqualTo: uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return _empty(Icons.favorite_border, 'Boş');
        final ids = snap.data!.docs.map((d) => d['postId'] as String).toList();
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection(AppConstants.collectionPosts).where(FieldPath.documentId, whereIn: ids).snapshots(),
          builder: (context, pSnap) {
            if (!pSnap.hasData) return const Center(child: CircularProgressIndicator());
            final posts = pSnap.data!.docs.map((d) => PostModel.fromFirestore(d)).toList();
            return GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
              itemCount: posts.length,
              itemBuilder: (c, i) => GestureDetector(
                onTap: () => _openFullScreenPost(posts[i]),
                child: CachedNetworkImage(imageUrl: posts[i].imageUrls[0], fit: BoxFit.cover),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListTab() {
    final uid = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(AppConstants.collectionFollows).where('followerId', isEqualTo: uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return _empty(Icons.person_add, 'Takip yok');
        final ids = snap.data!.docs.map((d) => d['followingId'] as String).toList();
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection(AppConstants.collectionUsers).where(FieldPath.documentId, whereIn: ids).snapshots(),
          builder: (context, uSnap) {
            if (!uSnap.hasData) return const Center(child: CircularProgressIndicator());
            final users = uSnap.data!.docs.map((d) => UserModel.fromFirestore(d)).toList();
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (c, i) => ListTile(
                leading: CircleAvatar(backgroundImage: users[i].profileImageUrl != null ? NetworkImage(users[i].profileImageUrl!) : null),
                title: Text(users[i].fullName, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.push(context, SlideRoute(page: ArtistProfileScreen(userId: users[i].uid))), 
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessagesList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(AppConstants.collectionMessages).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return _empty(Icons.mail_outline, 'Mesaj yok');
        final chats = <String, MessageModel>{};
        for (var d in snap.data!.docs) {
          final m = MessageModel.fromFirestore(d);
          if ((m.senderId == uid || m.receiverId == uid) && !chats.containsKey(m.chatId)) chats[m.chatId] = m;
        }
        final list = chats.values.toList();
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (c, i) {
            final m = list[i];
            final otherId = m.senderId == uid ? m.receiverId : m.senderId;
            final name = m.senderId == uid ? "Sanatçı" : (m.senderName ?? "Kullanıcı");
            return ListTile(
              leading: CircleAvatar(backgroundImage: m.senderImageUrl != null && m.senderId != uid ? NetworkImage(m.senderImageUrl!) : null, child: m.senderImageUrl == null ? const Icon(Icons.person) : null),
              title: Text(name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(m.content, maxLines: 1, style: const TextStyle(color: Colors.grey)),
              onTap: () => Navigator.push(context, SlideRoute(page: ChatScreen(receiverId: otherId, receiverName: name))),
            );
          },
        );
      },
    );
  }

  Widget _empty(IconData icon, String txt) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 40, color: Colors.grey), Text(txt, style: const TextStyle(color: Colors.grey))]));
}