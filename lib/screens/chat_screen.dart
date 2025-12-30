import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/message_model.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';
import '../services/chat_moderation_service.dart';
import '../services/gemini_service.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/report_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? referenceImageUrl;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.referenceImageUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  String? _chatId;
  bool _isAnalyzing = false; // Yükleme ve AI analizi çarkı

  @override
  void initState() {
    super.initState();
    
    // API Key ayarı (Prod ortamında .env dosyasından çekmek daha güvenlidir)
    GeminiService.setApiKey('AIzaSyBmCmTgJo922h6M7JfclA4hZQKOfAqLEyE');
    
    _initializeChat();
    
    if (widget.referenceImageUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoSendReferenceImage();
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeChat() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final senderId = authService.currentUser?.uid;
    if (senderId != null) {
      _chatId = getChatRoomId(senderId, widget.receiverId);
    }
  }

  Future<void> _autoSendReferenceImage() async {
    if (widget.referenceImageUrl != null && _chatId != null) {
      await _sendFinalMessage(
        content: "Bu gönderi hakkında bilgi almak istiyorum.",
        imagePath: widget.referenceImageUrl,
      );
    }
  }

  Future<void> _markMessagesAsRead() async {
    final currentUserId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    if (currentUserId != null && _chatId != null) {
      final unreadQuery = await FirebaseFirestore.instance
          .collection(AppConstants.collectionMessages)
          .where('chatId', isEqualTo: _chatId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadQuery.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in unreadQuery.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, 
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor.withOpacity(0.75), 
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(
            top: BorderSide(color: AppTheme.primaryLightColor.withOpacity(0.1), width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildAttachmentOption(
                    icon: Icons.camera_alt_rounded,
                    label: "Fotoğraf Çek",
                    color: AppTheme.primaryColor, 
                    onTap: () => _processImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAttachmentOption(
                    icon: Icons.photo_library_rounded,
                    label: "Galeriden Seç",
                    color: AppTheme.primaryColor, 
                    onTap: () => _processImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _processImage(ImageSource source) async {
    Navigator.pop(context); 
    FocusScope.of(context).unfocus(); 

    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
      if (image == null) return;

      setState(() => _isAnalyzing = true);

      final imageService = ImageService();
      final String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      
      final imageUrl = await imageService.uploadImage(
        imageBytes: await File(image.path).readAsBytes(),
        path: 'chat_images/$_chatId/$fileName',
      );
      
      await _sendFinalMessage(content: '📷 Fotoğraf', imagePath: imageUrl);

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Resim yüklenemedi: $e")));
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _messageController.clear();
    setState(() => _isAnalyzing = true);
    
    try {
      final tempFilteredText = ChatModerationService.filterMessage(text);
      final String finalFilteredText = tempFilteredText;

      final isViolating = ChatModerationService.isMessageViolating(finalFilteredText);
      final isTooLong = ChatModerationService.isMessageTooLong(finalFilteredText);
      final isTooShort = ChatModerationService.isMessageTooShort(finalFilteredText);

      if (isViolating || isTooLong || isTooShort) {
        _showModerationWarning("Mesajınız topluluk kurallarına aykırı olduğu için engellendi.");
      } else {
        await _sendFinalMessage(content: finalFilteredText);
      }

    } catch (e) {
      await _sendFinalMessage(content: text);
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showModerationWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  // --- YENİ EKLENEN SİLME FONKSİYONU ---
  Future<void> _deleteMessageForMe(String messageId) async {
    final currentUserId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    if (currentUserId != null) {
      await FirebaseFirestore.instance
          .collection(AppConstants.collectionMessages)
          .doc(messageId)
          .update({
        'deletedBy': FieldValue.arrayUnion([currentUserId])
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mesaj benden silindi"), duration: Duration(seconds: 1))
        );
      }
    }
  }

  Future<void> _sendFinalMessage({required String content, String? imagePath}) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final senderId = authService.currentUser?.uid;
    final sender = await authService.getUserModel(senderId ?? '');

    if (senderId == null || _chatId == null) return;

    final messageRef = FirebaseFirestore.instance.collection(AppConstants.collectionMessages).doc();
    
    await messageRef.set({
      'id': messageRef.id,
      'chatId': _chatId!,
      'senderId': senderId,
      'receiverId': widget.receiverId,
      'senderName': sender?.fullName ?? 'Kullanıcı',
      'senderImageUrl': sender?.profileImageUrl,
      'content': content,
      'imageUrl': imagePath,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'deletedBy': [], // Silenleri tutacak boş liste eklendi
    });
    
    final chatRef = FirebaseFirestore.instance.collection(AppConstants.collectionChats).doc(_chatId);
    
    String previewText = content;
    if (imagePath != null) {
      previewText = "📷 Fotoğraf";
    }

    await FirebaseFirestore.instance.collection(AppConstants.collectionNotifications).add({
      'type': 'message',
      'senderId': senderId,
      'senderName': sender?.fullName ?? 'Kullanıcı',
      'senderAvatar': sender?.profileImageUrl,
      'receiverId': widget.receiverId, 
      'relatedId': _chatId, 
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await chatRef.set({
      'users': [senderId, widget.receiverId], 
      'lastMessage': previewText,             
      'lastMessageTime': FieldValue.serverTimestamp(), 
      'updatedAt': FieldValue.serverTimestamp(),       
    }, SetOptions(merge: true)); 

    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.atmosphericBackgroundGradient, 
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, 
        appBar: AppBar(
          title: Text(widget.receiverName),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: AppTheme.primaryColor),
          titleTextStyle: const TextStyle(
            color: AppTheme.textColor, 
            fontSize: 18, 
            fontWeight: FontWeight.bold
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.primaryColor),
              onSelected: (value) async { 
                if (value == 'report') {
                  if (_chatId != null && _chatId!.isNotEmpty) {
                    final messagesSnapshot = await FirebaseFirestore.instance
                        .collection(AppConstants.collectionMessages)
                        .where('chatId', isEqualTo: _chatId)
                        .orderBy('createdAt', descending: true)
                        .limit(20)
                        .get();

                    List<Map<String, dynamic>> evidenceWithTimestamps = [];
                    
                    for (var doc in messagesSnapshot.docs) {
                      final mData = doc.data();
                      // Eğer raporlayan kişi mesajı kendinden sildiyse bile admin görebilmeli, o yüzden deletedBy kontrolü yapmıyoruz
                      evidenceWithTimestamps.add({
                        'message': mData['content'],
                        'senderId': mData['senderId'],
                        'timestamp': mData['createdAt'], 
                        'imageUrl': mData['imageUrl'],   
                      });
                    }

                    if (context.mounted) {
                      ReportService.showReportDialog(
                        context: context,
                        contentId: _chatId!,
                        contentType: 'chat',
                        reportedUserId: widget.receiverId,
                        evidenceMessages: evidenceWithTimestamps, 
                      );
                    }
                  } else {
                    ReportService.showReportDialog(
                      context: context,
                      contentId: widget.receiverId,
                      contentType: 'user', 
                      reportedUserId: widget.receiverId,
                    );
                  }
                } else if (value == 'block') {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser != null) {
                    ReportService.blockUser(
                      context: context,
                      currentUserId: currentUser.uid,
                      blockedUserId: widget.receiverId,
                    );
                  }
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, color: Colors.redAccent, size: 20),
                      SizedBox(width: 10),
                      Text("Şikayet Et", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block, color: Colors.white70, size: 20),
                      SizedBox(width: 10),
                      Text("Engelle", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(AppConstants.collectionMessages)
                    .where('chatId', isEqualTo: _chatId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) _markMessagesAsRead();
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                  }
                  
                  // --- MESAJLARI FİLTRELEME (deletedBy kontrolü) ---
                  final allDocs = snapshot.data?.docs ?? [];
                  final visibleDocs = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final List deletedBy = data['deletedBy'] ?? [];
                    return !deletedBy.contains(currentUserId);
                  }).toList();

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    itemCount: visibleDocs.length,
                    itemBuilder: (context, index) {
                      final data = visibleDocs[index].data() as Map<String, dynamic>;
                      final String messageId = visibleDocs[index].id;
                      final bool isMe = data['senderId'] == currentUserId;
                      return _buildBubble(data, isMe, messageId);
                    },
                  );
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> data, bool isMe, String messageId) {
    const Color customMeColor = AppTheme.backgroundSecondaryColor;

    return GestureDetector(
      // --- MESAJIN ÜSTÜNE UZUN BASINCA SİLME MENÜSÜ ---
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text("Benden sil", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessageForMe(messageId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy, color: Colors.white70),
                  title: const Text("Kopyala", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    // Kopyalama fonksiyonu eklenebilir
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isMe ? customMeColor : AppTheme.cardColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['imageUrl'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: data['imageUrl'],
                      placeholder: (context, url) => const SizedBox(
                        height: 100, 
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2))
                      ),
                    ),
                  ),
                ),
              Text(
                data['content'] ?? '',
                style: const TextStyle(color: AppTheme.textColor, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: AppTheme.cardColor.withOpacity(0.3),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_a_photo, color: AppTheme.primaryLightColor),
              onPressed: _pickAndSendImage,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(color: AppTheme.textColor),
                decoration: InputDecoration(
                  hintText: 'Mesaj yazın...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: AppTheme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 4),
            _isAnalyzing
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.textColor,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.primaryLightColor),
                    onPressed: _sendMessage,
                  ),
          ],
        ),
      ),
    );
  }

  String getChatRoomId(String user1, String user2) {
    if (user1.toLowerCase().compareTo(user2.toLowerCase()) > 0) {
      return '${user2}_$user1';
    } else {
      return '${user1}_$user2';
    }
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 120, 
        decoration: BoxDecoration(
          color: AppTheme.cardColor, 
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.2), 
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1), 
              blurRadius: 12,
              spreadRadius: 0.5,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}