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

  // --- KRİTİK DÜZELTME BURADA YAPILDI ---
  void _initializeChat() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final senderId = authService.currentUser?.uid;
    if (senderId != null) {
      // MessageModel.generateChatId yerine kendi yazdığımız alfabetik sıralayan fonksiyonu kullanıyoruz.
      // Bu sayede Ahmet -> Mehmet ile Mehmet -> Ahmet aynı odayı görür.
      _chatId = getChatRoomId(senderId, widget.receiverId);
    }
  }
  // --------------------------------------

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

  // --- MODERN DOSYA SEÇİCİ MENÜSÜ ---
  Future<void> _pickAndSendImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Şeffaf zemin (köşeler için)
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor.withOpacity(0.75), // Koyu yarı saydam zemin
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(
            top: BorderSide(color: AppTheme.primaryLightColor.withOpacity(0.1), width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gri Tutamaç
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Yan Yana Butonlar
            Row(
              children: [
                // 1. KAMERA (Turuncu/Sarı Tonlar)
                Expanded(
                  child: _buildAttachmentOption(
                    icon: Icons.camera_alt_rounded,
                    label: "Fotoğraf Çek",
                    color: AppTheme.primaryColor, // Amber/Sarı
                    onTap: () => _processImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16), // Boşluk
                
                // 2. GALERİ (Mavi/Cyan Tonlar)
                Expanded(
                  child: _buildAttachmentOption(
                    icon: Icons.photo_library_rounded,
                    label: "Galeriden Seç",
                    color: AppTheme.primaryColor, // Açık Mavi
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
    Navigator.pop(context); // Menüyü kapat
    FocusScope.of(context).unfocus(); // Klavyeyi kapat

    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
      if (image == null) return;

      // YÜKLEME GÖSTERGESİNİ BAŞLAT
      setState(() => _isAnalyzing = true);

      final imageService = ImageService();
      // Dosya çakışmasını önlemek için zaman damgası
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
      // İşlem bitince göstergeyi durdur
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _messageController.clear();
    
    // AI analizi göstergesi
    setState(() => _isAnalyzing = true);
    
    try {
      final tempFilteredText = ChatModerationService.filterMessage(text);
      final String finalFilteredText = await GeminiService.filterMessage(tempFilteredText);
      
      if (finalFilteredText == "[YASAKLI İÇERİK]") {
        _showModerationWarning("Mesajınız topluluk kurallarına aykırı olduğu için engellendi.");
      } else {
        await _sendFinalMessage(content: finalFilteredText);
      }
      
    } catch (e) {
      print('Hata: $e');
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

  Future<void> _sendFinalMessage({required String content, String? imagePath}) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final senderId = authService.currentUser?.uid;
    final sender = await authService.getUserModel(senderId ?? '');

    if (senderId == null || _chatId == null) return;

    // 1. MESAJI KAYDET (Eski kodun aynısı)
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
    });
    
    // --- 2. YENİ EKLENEN KISIM: SOHBET ÖZETİNİ GÜNCELLE ---
    // Bu kısım sayesinde MessagesScreen'deki liste güncellenecek
    final chatRef = FirebaseFirestore.instance.collection(AppConstants.collectionChats).doc(_chatId);
    
    // Mesaj metin mi resim mi?
    String previewText = content;
    if (imagePath != null) {
      previewText = "📷 Fotoğraf";
    }

    // --- 3. YENİ: BİLDİRİM OLUŞTUR ---
    // Bu kısım sayesinde "Bildirimler" ekranına veri düşecek.
    await FirebaseFirestore.instance.collection(AppConstants.collectionNotifications).add({
      'type': 'message',
      'senderId': senderId,
      'senderName': sender?.fullName ?? 'Kullanıcı',
      'senderAvatar': sender?.profileImageUrl,
      'receiverId': widget.receiverId, // Mesajı alan kişi
      'relatedId': _chatId, // Tıklayınca hangi sohbete gideceği
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // ---------------------------------


    await chatRef.set({
      'users': [senderId, widget.receiverId], // Sohbetin kimler arasında olduğunu kaydet
      'lastMessage': previewText,             // Son mesaj içeriği
      'lastMessageTime': FieldValue.serverTimestamp(), // Son mesaj zamanı
      'updatedAt': FieldValue.serverTimestamp(),       // Sıralama için
    }, SetOptions(merge: true)); // Varsa güncelle, yoksa oluştur
    // -----------------------------------------------------

    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. ADIM: Gradient Arka Plan (Performans ve Şıklık için)
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.atmosphericBackgroundGradient, 
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Şeffaf, gradient görünsün
        
        appBar: AppBar(
          title: Text(widget.receiverName), 
          centerTitle: true,
          backgroundColor: Colors.transparent, // Şeffaf
          elevation: 0,
          scrolledUnderElevation: 0, // Kaydırma sırasındaki renk değişimini engeller
          iconTheme: const IconThemeData(color: AppTheme.primaryColor),
          titleTextStyle: const TextStyle(color: AppTheme.textColor, fontSize: 18, fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> data, bool isMe) {
    const Color customMeColor = AppTheme.backgroundSecondaryColor;

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
              style: const TextStyle(color: AppTheme.textColor, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      // Input alanı hafif şeffaf olsun ki arkadaki gradient hissedilsin
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

  // --- HELPER METHOD: Sohbet ID'sini Alfabetik Oluşturur ---
  String getChatRoomId(String user1, String user2) {
    if (user1.toLowerCase().compareTo(user2.toLowerCase()) > 0) {
      return '${user2}_$user1';
    } else {
      return '${user1}_$user2';
    }
  }

  // --- MODERN DOSYA SEÇİM KUTUCUKLARI ---
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
        height: 120, // Kutunun yüksekliği
        decoration: BoxDecoration(
          color: AppTheme.cardColor, // Koyu zemin
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.2), // Çerçeve
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1), // Glow efekti
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