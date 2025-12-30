import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../profile/artist_profile_screen.dart';
import '../profile/customer_profile_screen.dart';

class ReportDetailScreen extends StatelessWidget {
  final String reportId;
  final Map<String, dynamic> reportData;

  const ReportDetailScreen({
    super.key,
    required this.reportId,
    required this.reportData,
  });

  // --- HAZIR MESAJ KALIPLARI (SADECE BURASI EKLENDİ) ---
  static const List<String> warningDrafts = [
    "Gönderiniz topluluk kurallarına aykırı olduğu için silindi.",
    "Profiliniz uygunsuz içerik nedeniyle şikayet edildi. Tekrarı halinde hesabınız kapatılacaktır.",
    "Mesajlarınızda kullandığınız dil taciz içerdiği için uyarıldınız.",
    "Telif hakkı ihlali tespit edildiği için içeriğiniz kaldırıldı.",
  ];

  static const List<String> feedbackDrafts = [
    "Şikayetiniz incelendi ve ilgili kullanıcı kalıcı olarak yasaklandı.",
    "Bildirdiğiniz içerik kurallarımıza aykırı bulundu ve sistemden silindi.",
    "Şikayetiniz doğrultusunda ilgili kullanıcıya resmi uyarı gönderildi.",
    "Geri bildiriminiz için teşekkürler, topluluğumuzu korumamıza yardımcı oldunuz."
  ];

  // --- FOTOĞRAFI TAM EKRAN GÖSTERME ---
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black, 
            foregroundColor: Colors.white,
            leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl, 
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white, size: 50),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentType = reportData['contentType'] ?? 'Genel';
    final reason = reportData['reason'] ?? 'Belirsiz';
    final reportedUserId = reportData['reportedUserId'] ?? '';
    final reporterId = reportData['reporterId'] ?? '';
    final contentId = reportData['contentId'] ?? '';
    
    Color typeColor;
    String typeTitle;

    if (contentType == 'chat') {
      typeColor = Colors.blueAccent;
      typeTitle = "MESAJ ŞİKAYETİ";
    } else if (contentType == 'post') {
      typeColor = Colors.orangeAccent;
      typeTitle = "GÖNDERİ ŞİKAYETİ";
    } else {
      typeColor = Colors.purpleAccent;
      typeTitle = "PROFİL ŞİKAYETİ";
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Şikayet Detayı"),
        backgroundColor: AppTheme.cardColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: _buildActionButtons(context, reportedUserId, reporterId, contentId, contentType),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ŞİKAYET KONUSU",
              style: TextStyle(color: typeColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 5),
            Text(
              typeTitle,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold,
            ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              "ŞİKAYET GEREKÇESİ",
              style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                reason,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(color: Colors.white10),
            const SizedBox(height: 20),

            if (contentType == 'chat') ...[
              const Text("DELİL OLARAK ALINAN MESAJLAR", style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildChatEvidence(context, reportedUserId),
            ],

            if (contentType == 'post') ...[
              const Text("ŞİKAYET EDİLEN İÇERİK", style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () => _inspectPost(context, contentId),
                icon: const Icon(Icons.image_search),
                label: const Text("İÇERİĞİ GÖRÜNTÜLE"),
              ),
            ],

            if (contentType == 'user' || contentType == 'profil') ...[
              const Text("İLGİLİ PROFİLLER", style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                onPressed: () => _navigateToProfile(context, reportedUserId),
                icon: const Icon(Icons.person),
                label: const Text("ŞİKAYET EDİLEN PROFİL"),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white24), minimumSize: const Size(double.infinity, 50)),
                onPressed: () => _navigateToProfile(context, reporterId),
                icon: const Icon(Icons.record_voice_over),
                label: const Text("ŞİKAYET EDEN KİŞİ"),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- AKSİYON BUTONLARI PANELİ ---
  Widget _buildActionButtons(BuildContext context, String reportedUserId, String reporterId, String contentId, String contentType) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 30),
      color: AppTheme.cardColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                  onPressed: () => _ignoreReport(context),
                  child: const Text("YOKSAY"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  onPressed: () => _showNotificationDialog(context, reportedUserId, "Uyarı Gönder", warningDrafts),
                  child: const Text("UYAR"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                  onPressed: () => _showNotificationDialog(context, reporterId, "Geri Bildirim", feedbackDrafts),
                  child: const Text("GERİ"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: () => _handleMainAction(context, reportedUserId, contentId, contentType),
                  child: Text(contentType == 'post' ? "İÇERİĞİ SİL" : "KULLANICIYI BANLA"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- BİLDİRİM GÖNDERME DİALOGU (YANDAN LİSTELİ TASLAKLAR EKLENDİ) ---
  void _showNotificationDialog(BuildContext context, String targetUserId, String title, List<String> drafts) {
    final TextEditingController _msgController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Hazır Taslaklar:", style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 10),
                // Taslak Seçici Alanı
                Container(
                  height: 100,
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: drafts.length,
                    itemBuilder: (context, index) => ListTile(
                      dense: true,
                      title: Text(drafts[index], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      onTap: () {
                        setState(() { _msgController.text = drafts[index]; });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _msgController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Mesajınızı buraya yazın veya yukarıdan seçin...",
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                    fillColor: Colors.black26,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İPTAL")),
            ElevatedButton(
              onPressed: () async {
                if (_msgController.text.trim().isEmpty) return;
                await FirebaseFirestore.instance.collection('notifications').add({
                  'receiverId': targetUserId,
                  'title': 'Tattink Admin Mesajı',
                  'message': _msgController.text.trim(),
                  'type': 'admin_message',
                  'createdAt': FieldValue.serverTimestamp(),
                  'isRead': false,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mesaj başarıyla iletildi.")));
              },
              child: const Text("GÖNDER"),
            ),
          ],
        ),
      ),
    );
  }

  // --- ANA AKSİYON (SİLME / BANLAMA) ---
  void _handleMainAction(BuildContext context, String userId, String contentId, String contentType) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text("Emin misiniz?", style: TextStyle(color: Colors.white)),
        content: Text(contentType == 'post' ? "Bu gönderi kalıcı olarak silinecek." : "Bu kullanıcı sisteme bir daha giremeyecek.", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İPTAL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); 
              if (contentType == 'post') {
                 await FirebaseFirestore.instance.collection('posts').doc(contentId).delete();
              } else {
                 await FirebaseFirestore.instance.collection('users').doc(userId).update({'isBanned': true});
              }
              await _ignoreReport(context); 
            },
            child: const Text("ONAYLA"),
          ),
        ],
      ),
    );
  }

  Widget _buildChatEvidence(BuildContext context, String reportedUserId) {
    List<dynamic> evidence = List.from(reportData['evidenceMessages'] ?? []);
    evidence.sort((a, b) {
      Timestamp t1 = a['timestamp'] ?? Timestamp.now();
      Timestamp t2 = b['timestamp'] ?? Timestamp.now();
      return t1.compareTo(t2);
    });

    if (evidence.isEmpty) return const Text("Mesaj kanıtı mevcut değil.", style: TextStyle(color: Colors.white54));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: evidence.length,
      itemBuilder: (context, index) {
        final m = evidence[index];
        bool isReported = m['senderId'] == reportedUserId;
        final String? msg = m['message'] ?? m['text'];
        final String? img = m['imageUrl'] ?? m['image'];
        bool isImage = (img != null && img.isNotEmpty) || (msg != null && msg.startsWith('http'));

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isReported ? Colors.redAccent.withOpacity(0.08) : Colors.blueAccent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isReported ? Colors.redAccent.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isReported ? "ŞÜPHELİ" : "DİĞER", style: TextStyle(color: isReported ? Colors.redAccent : Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (isImage)
                GestureDetector(
                  onTap: () => _showFullScreenImage(context, img ?? msg!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(img ?? msg!, height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, e, s) => const Icon(Icons.broken_image, color: Colors.white24)),
                  ),
                )
              else
                Text(msg ?? 'Mesaj içeriği boş', style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        );
      },
    );
  }

  void _inspectPost(BuildContext context, String contentId) async {
    if (contentId.isEmpty) return;
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    try {
      DocumentSnapshot? doc;
      doc = await FirebaseFirestore.instance.collection('posts').doc(contentId).get();
      if (!doc.exists) doc = await FirebaseFirestore.instance.collection('portfolio').doc(contentId).get();
      if (!doc.exists) doc = await FirebaseFirestore.instance.collection('portfolio_images').doc(contentId).get();
      
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      if (!doc.exists) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İçerik bulunamadı.")));
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      String? mediaUrl = data['imageUrl'] ?? data['videoUrl'] ?? (data['imageUrls'] != null && (data['imageUrls'] as List).isNotEmpty ? data['imageUrls'][0] : null);
      String caption = data['caption'] ?? data['description'] ?? data['text'] ?? 'Açıklama metni bulunamadı.';

      Future.delayed(const Duration(milliseconds: 100), () {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (mediaUrl != null) ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(mediaUrl, fit: BoxFit.cover)),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                    child: Text(caption, style: const TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.center),
                  ),
                ],
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("KAPAT"))],
            ),
          );
        }
      });
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _ignoreReport(BuildContext context) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();
    if (context.mounted) Navigator.pop(context);
  }

  void _navigateToProfile(BuildContext context, String userId) async {
    if (userId.isEmpty) return;
    showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator()));
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (context.mounted) Navigator.pop(context);

    if (context.mounted && userDoc.exists) {
      final role = userDoc.data()?['role'];
      Widget profilePage = role == 'artist' ? ArtistProfileScreen(userId: userId) : CustomerProfileScreen(userId: userId);
      Navigator.push(context, MaterialPageRoute(fullscreenDialog: true, builder: (context) => profilePage));
    }
  }
}