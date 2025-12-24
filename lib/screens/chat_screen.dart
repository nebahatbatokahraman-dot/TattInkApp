import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/message_model.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeChat();
    
    // Sayfa açılır açılmaz görsel varsa tetiği çek
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
      _chatId = MessageModel.generateChatId(senderId, widget.receiverId);
    }
  }

  // HER İHTİMALDE GÖRSELİ GÖNDEREN FONKSİYON
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
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.white),
            title: const Text('Fotoğraf Çek', style: TextStyle(color: Colors.white)),
            onTap: () => _processImage(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.white),
            title: const Text('Galeriden Seç', style: TextStyle(color: Colors.white)),
            onTap: () => _processImage(ImageSource.gallery),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _processImage(ImageSource source) async {
    Navigator.pop(context);
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image == null) return;

    final imageService = ImageService();
    try {
      final imageUrl = await imageService.uploadImage(
        imageBytes: await File(image.path).readAsBytes(),
        path: 'chat_images/$_chatId',
      );
      _sendFinalMessage(content: '📷 Fotoğraf', imagePath: imageUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Resim yüklenemedi: $e")));
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _sendFinalMessage(content: text);
    _messageController.clear();
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
      'imageUrl': imagePath, // Buraya gelen her görseli kaydediyoruz
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.receiverName), 
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
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
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data?.docs ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isMe = data['senderId'] == Provider.of<AuthService>(context, listen: false).currentUser?.uid;
                    return _buildBubble(data, isMe);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> data, bool isMe) {
    const Color customMeColor = Color(0xFF5D4152);

    return Align(
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
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: AppTheme.cardColor.withOpacity(0.5),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_a_photo, color: AppTheme.primaryColor),
              onPressed: _pickAndSendImage,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
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
            IconButton(
              icon: const Icon(Icons.send, color: AppTheme.primaryColor),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}