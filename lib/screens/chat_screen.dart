import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

// --- IMPORTS ---
import '../services/auth_service.dart';
import '../services/image_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? referenceImageUrl; // Eğer bir post üzerinden gelindiyse

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeChatId();
    
    // Sayfa açıldıktan sonra eğer referans resim varsa otomatik gönder
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

  // --- KRİTİK: ID OLUŞTURMA ---
  // ID'leri alfabetik sıralayıp birleştiriyoruz.
  // Böylece Ali-Veli sohbeti her iki taraf için de aynı ID'ye sahip oluyor.
  void _initializeChatId() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final List<String> ids = [currentUserId, widget.receiverId];
    ids.sort(); // Alfabetik sırala
    _chatId = ids.join("_"); // Birleştir
  }

  // Referans resmi (Post fotosu) gönderme
  Future<void> _autoSendReferenceImage() async {
    if (widget.referenceImageUrl != null && _chatId != null) {
      // Kullanıcıya sormadan direkt gönderiyor, istersen onay kutusu ekleyebilirsin.
      await _sendFinalMessage(
        content: "Bu gönderi hakkında konuşmak istiyorum.",
        imagePath: widget.referenceImageUrl, // Upload etmeye gerek yok, zaten URL var
      );
    }
  }

  // Galeriden/Kameradan resim seçip gönderme
  Future<void> _pickAndSendImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF252525),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.white),
            title: const Text('Fotoğraf Çek', style: TextStyle(color: Colors.white)),
            onTap: () { Navigator.pop(context); _processImage(ImageSource.camera); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.white),
            title: const Text('Galeriden Seç', style: TextStyle(color: Colors.white)),
            onTap: () { Navigator.pop(context); _processImage(ImageSource.gallery); },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _processImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image == null) return;

    setState(() => _isLoading = true);
    final imageService = ImageService();
    try {
      final imageUrl = await imageService.uploadImage(
        imageBytes: await File(image.path).readAsBytes(),
        path: 'chat_images/$_chatId',
      );
      await _sendFinalMessage(content: '📷 Fotoğraf', imagePath: imageUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Resim yüklenemedi: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await _sendFinalMessage(content: text);
  }

  // --- ANA MESAJ GÖNDERME FONKSİYONU ---
  Future<void> _sendFinalMessage({required String content, String? imagePath}) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final senderId = authService.currentUser?.uid;
    
    // Gönderen bilgilerini çek (Bildirimde adının görünmesi için)
    final sender = await authService.getUserModel(senderId ?? '');

    if (senderId == null || _chatId == null) return;

    // 1. MESAJI KAYDET (chats -> ID -> messages)
    final messageRef = FirebaseFirestore.instance
        .collection(AppConstants.collectionChats)
        .doc(_chatId)
        .collection(AppConstants.collectionMessages) // 'messages'
        .doc();
    
    final newMessageData = {
      'id': messageRef.id,
      'chatId': _chatId!,
      'senderId': senderId,
      'receiverId': widget.receiverId,
      'content': content,
      'imageUrl': imagePath, // Varsa resim URL'si
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await messageRef.set(newMessageData);

    // 2. SOHBET ÖZETİNİ GÜNCELLE (Inbox Listesi İçin)
    await FirebaseFirestore.instance
        .collection(AppConstants.collectionChats)
        .doc(_chatId)
        .set({
      'users': [senderId, widget.receiverId], 
      'lastMessage': imagePath != null ? '📷 Fotoğraf' : content,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. BİLDİRİM GÖNDER
    if (sender != null) {
      // Username null ise 'Kullanıcı' yazsın diye önlem aldık
      final senderName = sender.fullName.isNotEmpty ? sender.fullName : (sender.username ?? 'Müşteri');
      
      await NotificationService.sendMessageNotification(
        senderId,
        senderName,
        sender.profileImageUrl,
        widget.receiverId,
        _chatId! 
      );
    }
    
    // Listeyi aşağı kaydır
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, 
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeOut
      );
    }
  }

  // --- OKUNDU OLARAK İŞARETLEME ---
  Future<void> _markMessagesAsRead() async {
     final currentUserId = FirebaseAuth.instance.currentUser?.uid;
     if (currentUserId == null || _chatId == null) return;

     // Sadece karşı tarafın attığı ve okunmamış mesajları bul
     final query = await FirebaseFirestore.instance
         .collection(AppConstants.collectionChats)
         .doc(_chatId)
         .collection(AppConstants.collectionMessages)
         .where('receiverId', isEqualTo: currentUserId)
         .where('isRead', isEqualTo: false)
         .get();

     if (query.docs.isNotEmpty) {
       final batch = FirebaseFirestore.instance.batch();
       for (var doc in query.docs) {
         batch.update(doc.reference, {'isRead': true});
       }
       await batch.commit();
     }
  }

  @override
  Widget build(BuildContext context) {
    if (_chatId == null) return const SizedBox();

    return Scaffold(
      backgroundColor: const Color(0xFF161616),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // --- CANLI İSİM GÖSTERİMİ ---
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection(AppConstants.collectionUsers)
              .doc(widget.receiverId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text(widget.receiverName, style: const TextStyle(color: Colors.white, fontSize: 16));
            }
            final data = snapshot.data!.data() as Map<String, dynamic>;
            // Ad Soyad > Kullanıcı Adı > Stüdyo Adı
            final displayName = data['fullName'] ?? data['username'] ?? data['studioName'] ?? widget.receiverName;
            return Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 16));
          },
        ),
      ),
      body: Column(
        children: [
          // --- MESAJ LİSTESİ ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.collectionChats) // Ana: chats
                  .doc(_chatId)                             // Doc: ID
                  .collection(AppConstants.collectionMessages) // Alt: messages
                  .orderBy('createdAt', descending: true) // En yeni en altta (reverse)
                  .snapshots(),
              builder: (context, snapshot) {
                // Veri geldikçe okundu yap
                if (snapshot.hasData) _markMessagesAsRead();
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                }
                
                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(child: Text("Hadi bir merhaba de! 👋", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Klavye açılınca mantıklı olan budur
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isMe = data['senderId'] == FirebaseAuth.instance.currentUser?.uid;
                    return _buildMessageBubble(data, isMe);
                  },
                );
              },
            ),
          ),

          // --- GİRİŞ ALANI ---
          if (_isLoading) const LinearProgressIndicator(color: AppTheme.primaryColor, backgroundColor: Colors.transparent),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            color: const Color(0xFF252525),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_a_photo, color: Colors.grey),
                    onPressed: _pickAndSendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Mesaj yaz...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF333333),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _handleSendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final String content = msg['content'] ?? '';
    final String? imageUrl = msg['imageUrl'];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : const Color(0xFF333333),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    placeholder: (c, u) => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.white))),
                    errorWidget: (c, u, e) => const Icon(Icons.error, color: Colors.white),
                  ),
                ),
              ),
            if (content.isNotEmpty)
              Text(
                content,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
          ],
        ),
      ),
    );
  }
}