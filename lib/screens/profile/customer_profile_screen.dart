import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../../services/report_service.dart'; 
import '../../services/auth_service.dart';
import '../../services/image_service.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../models/message_model.dart';
import '../../utils/constants.dart';
import '../../theme/app_theme.dart';
import '../../utils/slide_route.dart';
import '../../app_localizations.dart';
import '../appointments_screen.dart';
import '../chat_screen.dart'; 
import '../messages_screen.dart'; 
import '../profile/artist_profile_screen.dart';
import '../settings/customer_settings_screen.dart'; 
import '../settings/customer_edit_profile_screen.dart'; 
import '../admin/admin_dashboard.dart';

class CustomerProfileScreen extends StatefulWidget {
  final String userId;
  const CustomerProfileScreen({super.key, required this.userId});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isUploadingCover = false;

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

  Future<void> _pickAndUploadCover() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image == null) return;

    setState(() => _isUploadingCover = true);
    try {
      final imageService = ImageService();
      final imageUrl = await imageService.uploadImage(
        imageBytes: await File(image.path).readAsBytes(),
        path: 'covers/${widget.userId}',
      );

      await FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(widget.userId)
          .update({'coverImageUrl': imageUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.translate('cover_photo_updated')), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.translate('error_generic')}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

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
                bottom: MediaQuery.of(context).padding.bottom + 2,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
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
                            Text(post.artistUsername ?? 'Artist', 
                              style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
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
                              color: isLiked ? const Color(0xFF944B79) : AppTheme.textColor,
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
                        child: Text(AppLocalizations.of(context)!.translate('view_profile'), style: TextStyle(color: AppTheme.textColor, fontSize: 12)),
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
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
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
    final currentUserId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    final bool isMe = currentUserId == widget.userId;

    return Scaffold(
      // StreamBuilder'ı DocumentSnapshot dinleyecek şekilde güncelledik
      // Çünkü exists kontrolü yapmak için DocumentSnapshot'a ihtiyacımız var.
      // (AuthService'deki getUserModelStream muhtemelen UserModel dönüyor, bu yüzden direkt Firestore çağırıyoruz)
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(widget.userId)
          .snapshots(),
        builder: (context, snapshot) {
          
          // 1. YÜKLENİYORSA
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. KULLANICI BULUNAMADIYSA (SİLİNMİŞSE) - İŞTE GÜNCELLEME BURASI
          if (!snapshot.data!.exists) {
            return Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off_outlined, size: 80, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.translate('user_not_found'),
                      style: TextStyle(color: AppTheme.textColor, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.translate('user_not_found_msg'),
                      style: TextStyle(color: AppTheme.textColor.withOpacity(0.6), fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. KULLANICI VARSA (NORMAL AKIŞ)
          final userModel = UserModel.fromFirestore(snapshot.data!);

          return NestedScrollView(
            physics: const NeverScrollableScrollPhysics(), 
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Stack(
                    clipBehavior: Clip.none, 
                    alignment: Alignment.topCenter,
                    children: [
                      // --- ALT KATMAN ---
                      Column(
                        children: [
                          // Kapak Alanı
                          Container(
                            height: 160,
                            width: double.infinity,
                            decoration: const BoxDecoration(color: AppTheme.backgroundColor),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                userModel.coverImageUrl != null && userModel.coverImageUrl!.isNotEmpty
                                    ? CachedNetworkImage(imageUrl: userModel.coverImageUrl!, fit: BoxFit.cover)
                                    : Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [AppTheme.primaryColor.withOpacity(0.8), AppTheme.backgroundColor],
                                          ),
                                        ),
                                      ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                                    ),
                                  ),
                                ),
                                
                                if (isMe)
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: _isUploadingCover ? null : _pickAndUploadCover,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.black54,
                                        radius: 18,
                                        child: _isUploadingCover 
                                          ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                                          : const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: MediaQuery.of(context).padding.top,
                                  left: 0, right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (!isMe) IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)) else const SizedBox(),
                                      if (isMe) IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () => Navigator.push(context, SlideRoute(page: const CustomerSettingsScreen()))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 70), 
                          
                          if (isMe && userModel.role == 'admin') _buildAdminButton(),
                          if (isMe) _buildAppointmentsBtn(),
                          _buildTabs(),
                        ],
                      ),

                      // --- ÜST KATMAN: PROFİL FOTOSU VE BİLGİLERİ ---
                      Positioned(
                        top: 125, 
                        left: 16,
                        child: _buildProfileInfo(userModel, isMe),
                      ),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildGridTab(AppConstants.collectionLikes),
                _buildListTab(),
                _buildMessagesList(widget.userId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboard())),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
          child: Row(children: [const Icon(Icons.admin_panel_settings, color: Colors.redAccent), const SizedBox(width: 12), Text(AppLocalizations.of(context)!.translate('admin_panel'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)), const Spacer(), const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.redAccent)]),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(UserModel user, bool isMe) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Stack(
        clipBehavior: Clip.none, 
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              border: Border.all(color: AppTheme.backgroundColor, width: 4)
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: AppTheme.cardColor,
              backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
              child: user.profileImageUrl == null ? const Icon(Icons.person, size: 40) : null,
            ),
          ),
          if (isMe)
            Positioned(
              bottom: 0, 
              right: 0, 
              child: Material(
                color: Colors.transparent,
                child: InkWell( 
                  onTap: () {
                    Navigator.push(
                      context, 
                      SlideRoute(page: const CustomerEditProfileScreen())
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor, 
                      shape: BoxShape.circle
                    ),
                    child: const Icon(Icons.edit, size: 16, color: AppTheme.textColor),
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(width: 16),
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
            Text(user.locationString, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      
      // ŞİKAYET ET / ENGELLE BUTONU (BAŞKA PROFİLSE GÖZÜKÜR)
      if (FirebaseAuth.instance.currentUser?.uid != widget.userId)
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                showModalBottomSheet(
                  context: context, 
                  backgroundColor: AppTheme.cardColor,
                  builder: (sheetContext) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
                        ),
                        ListTile(
                          leading: const Icon(Icons.flag, color: Colors.redAccent),
                          title: Text(AppLocalizations.of(context)!.translate('report_user'), style: TextStyle(color: Colors.white)),
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
                          title: Text(AppLocalizations.of(context)!.translate('block_user'), style: TextStyle(color: Colors.white70)),
                          onTap: () {
                            Navigator.pop(sheetContext); 
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              ReportService.blockUser(
                                context: context,
                                currentUserId: user.uid,
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
              },
            ),
          ),
        ),
    ],
  );
}

  Widget _buildAppointmentsBtn() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: SizedBox(
        width: double.infinity, height: 45,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, elevation: 0, barrierColor: Colors.black.withOpacity(0.5), builder: (context) => SizedBox(height: MediaQuery.of(context).size.height * 0.65, child: const AppointmentsScreen())),
          child: Text(AppLocalizations.of(context)!.translate('my_appointments'), style: TextStyle(color: AppTheme.textDarkColor, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _tabItem(Icons.favorite, AppLocalizations.of(context)!.translate('favorites_tab'), 0),
        _tabItem(Icons.person, AppLocalizations.of(context)!.translate('following_tab'), 1),
        _tabItem(Icons.message, AppLocalizations.of(context)!.translate('messages_tab'), 2)
      ],
    );
  }

  Widget _tabItem(IconData icon, String label, int index) {
    bool sel = _tabController.index == index;
    Color color = sel ? AppTheme.primaryColor : Colors.grey;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: Container(color: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 8), child: Column(children: [Icon(icon, color: color, size: 26), Text(label, style: TextStyle(color: color, fontSize: 11)), const SizedBox(height: 4), AnimatedContainer(duration: const Duration(milliseconds: 200), width: sel ? 33 : 0, height: 2, color: AppTheme.primaryColor)])),
    );
  }

  Widget _buildGridTab(String collection) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).where('userId', isEqualTo: widget.userId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return _empty(Icons.favorite_border, 'Empty');
        final ids = snap.data!.docs.map((d) => d['postId'] as String).toList();
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection(AppConstants.collectionPosts).where(FieldPath.documentId, whereIn: ids).snapshots(),
          builder: (context, pSnap) {
            if (!pSnap.hasData) return const Center(child: CircularProgressIndicator());
            final posts = pSnap.data!.docs.map((d) => PostModel.fromFirestore(d)).toList();
            return GridView.builder(padding: const EdgeInsets.all(2), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2), itemCount: posts.length, itemBuilder: (c, i) => GestureDetector(onTap: () => _openFullScreenPost(posts[i]), child: CachedNetworkImage(imageUrl: posts[i].imageUrls[0], fit: BoxFit.cover)));
          },
        );
      },
    );
  }

  Widget _buildListTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(AppConstants.collectionFollows).where('followerId', isEqualTo: widget.userId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return _empty(Icons.person_add, 'No following');
        final ids = snap.data!.docs.map((d) => d['followingId'] as String).toList();
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection(AppConstants.collectionUsers).where(FieldPath.documentId, whereIn: ids).snapshots(),
          builder: (context, uSnap) {
            if (!uSnap.hasData) return const Center(child: CircularProgressIndicator());
            final users = uSnap.data!.docs.map((d) => UserModel.fromFirestore(d)).toList();
            
            return ListView.builder(
              itemCount: users.length, 
              itemBuilder: (c, i) => Theme(
                data: Theme.of(context).copyWith(
                  splashColor: AppTheme.cardColor, 
                  highlightColor: Colors.transparent,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: users[i].profileImageUrl != null 
                        ? NetworkImage(users[i].profileImageUrl!) 
                        : null
                  ), 
                  title: Text(
                    users[i].fullName, 
                    style: const TextStyle(color: AppTheme.textColor)
                  ), 
                  onTap: () => Navigator.push(
                    context, 
                    SlideRoute(page: ArtistProfileScreen(userId: users[i].uid))
                  )
                ),
              )
            );
          },
        );
      },
    );
  }

  // --- SOHBETİ VERİTABANINDAN (KİŞİYE ÖZEL) SİLME ---
Future<void> _deleteChatFromProfile(String chatId, String currentUserId) async {
  try {
    final batch = FirebaseFirestore.instance.batch();
    final chatRef = FirebaseFirestore.instance.collection(AppConstants.collectionChats).doc(chatId);
    batch.update(chatRef, {
      'users': FieldValue.arrayRemove([currentUserId])
    });

    final messagesSnapshot = await FirebaseFirestore.instance
        .collection(AppConstants.collectionMessages)
        .where('chatId', isEqualTo: chatId)
        .get();

    for (var doc in messagesSnapshot.docs) {
      batch.update(doc.reference, {
        'deletedBy': FieldValue.arrayUnion([currentUserId])
      });
    }

    await batch.commit();
  } catch (e) {
    debugPrint("Profil mesaj silme hatası: $e");
  }
}

// --- MESAJ LİSTESİ ---
Widget _buildMessagesList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(AppConstants.collectionMessages).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return _empty(Icons.mail_outline, 'No messages');
        
        final chats = <String, MessageModel>{};
        for (var d in snap.data!.docs) {
          final data = d.data() as Map<String, dynamic>;
          final m = MessageModel.fromFirestore(d);
          
          final List deletedBy = data['deletedBy'] ?? [];
          if ((m.senderId == uid || m.receiverId == uid) && 
              !chats.containsKey(m.chatId) && 
              !deletedBy.contains(uid)) {
            chats[m.chatId] = m;
          }
        }
        
        final list = chats.values.toList();
        
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: list.length,
          itemBuilder: (c, i) {
            final m = list[i];
            final otherId = m.senderId == uid ? m.receiverId : m.senderId;
            
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection(AppConstants.collectionUsers).doc(otherId).snapshots(),
              builder: (context, userSnap) {
                String displayName = "Loading...";
                String? displayImage;
                if (userSnap.hasData && userSnap.data!.exists) {
                  final userData = userSnap.data!.data() as Map<String, dynamic>;
                  displayName = userData['fullName'] ?? userData['username'] ?? "User";
                  displayImage = userData['profileImageUrl'];
                }

                return Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: AppTheme.cardColor, 
                    highlightColor: Colors.transparent,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: displayImage != null ? NetworkImage(displayImage) : null, 
                      child: displayImage == null ? const Icon(Icons.person) : null
                    ),
                    title: Text(displayName, style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
                    subtitle: Text(m.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                    trailing: Text(DateFormat('HH:mm').format(m.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    onTap: () => Navigator.push(context, SlideRoute(page: ChatScreen(receiverId: otherId, receiverName: displayName))),
                    
                    onLongPress: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor.withOpacity(0.95),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))),
                              Text("${AppLocalizations.of(context)!.translate('delete_chat_title')} $displayName?", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20),
                              ListTile(
                                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                                title: Text(AppLocalizations.of(context)!.translate('delete_chat_for_me'), style: TextStyle(color: Colors.redAccent)),
                                onTap: () {
                                  Navigator.pop(context);
                                  _deleteChatFromProfile(m.chatId, uid);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.close, color: Colors.grey),
                                title: Text(AppLocalizations.of(context)!.translate('cancel'), style: TextStyle(color: Colors.white70)),
                                onTap: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
            );
          },
        );
      },
    );
  }

  Widget _empty(IconData icon, String txt) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 40, color: Colors.grey), Text(txt, style: const TextStyle(color: Colors.grey))]));
}