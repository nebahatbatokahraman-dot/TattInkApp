import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/artist_approval_model.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ArtistDetailScreen extends StatefulWidget {
  final ArtistApprovalModel approval;

  const ArtistDetailScreen({super.key, required this.approval});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  String? _selectedRejectionReason;
  final TextEditingController _customReasonController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }


Future<void> _approveArtist() async {
  setState(() {
    _isProcessing = true;
  });

  try {
    final authService = Provider.of<AuthService>(context, listen: false);
    final adminId = authService.currentUser?.uid;

    // Batch (Toplu İşlem) başlatıyoruz
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // 1. İşlem: User dokümanını güncellemek için referans al
    DocumentReference userRef = FirebaseFirestore.instance
        .collection(AppConstants.collectionUsers)
        .doc(widget.approval.userId);

    // Batch'e ekle
    batch.update(userRef, {
      'isApproved': true,
      'role': widget.approval.isApprovedArtist
          ? AppConstants.roleArtistApproved
          : AppConstants.roleArtistUnapproved,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. İşlem: Onay (Approval) dokümanını güncellemek için referans al
    DocumentReference approvalRef = FirebaseFirestore.instance
        .collection(AppConstants.collectionArtistApprovals)
        .doc(widget.approval.id);

    // Batch'e ekle
    batch.update(approvalRef, {
      'status': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminId,
    });

    // TÜM İŞLEMLERİ TEK SEFERDE GÖNDER (COMMIT)
    await batch.commit();

    // --- Başarılı Oldu ---

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Artist başarıyla onaylandı ve yetkileri verildi.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Listeye geri dön
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Onay sırasında hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}

  Future<void> _rejectArtist() async {
    if (_selectedRejectionReason == null ||
        (_selectedRejectionReason == 'Diğer' &&
            _customReasonController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen red sebebi seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final adminId = authService.currentUser?.uid;

      final rejectionReason = _selectedRejectionReason == 'Diğer'
          ? _customReasonController.text.trim()
          : _selectedRejectionReason!;

      // Update approval document
      await FirebaseFirestore.instance
          .collection(AppConstants.collectionArtistApprovals)
          .doc(widget.approval.id)
          .update({
        'status': 'rejected',
        'rejectionReason': rejectionReason,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminId,
      });

      // Send rejection email (via Cloud Function)
      // This would be handled by Cloud Functions

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Artist reddedildi'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Red sırasında hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showRejectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Red Sebebi Seç'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...AppConstants.rejectionReasons.map((reason) {
                    return RadioListTile<String>(
                      title: Text(reason),
                      value: reason,
                      groupValue: _selectedRejectionReason,
                      onChanged: (value) {
                        setState(() {
                          _selectedRejectionReason = value;
                        });
                      },
                    );
                  }),
                  if (_selectedRejectionReason == 'Diğer')
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _customReasonController,
                        decoration: const InputDecoration(
                          labelText: 'Özel Sebep',
                          hintText: 'Red sebebini yazın...',
                        ),
                        maxLines: 3,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectArtist();
            },
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Detayı'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Sanatçı Avatarı/Görseli
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Text(
                            widget.approval.firstName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Sanatçı Ad Soyad ve Tip
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.approval.firstName} ${widget.approval.lastName}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.approval.isApprovedArtist ? 'Onaylı Artist' : 'Onaysız Artist',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(),
                    ),
                    const Text(
                      'Temel Bilgiler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Kullanıcı Adı', widget.approval.username),
                    _buildInfoRow('Email', widget.approval.email),
                    _buildInfoRow('Telefon', widget.approval.phoneNumber),
                    _buildInfoRow('Adres', widget.approval.studioAddress),
                    if (widget.approval.district != null)
                      _buildInfoRow('Semt', widget.approval.district!),
                    if (widget.approval.city != null)
                      _buildInfoRow('Şehir', widget.approval.city!),
                    _buildInfoRow('Instagram', widget.approval.instagramUsername),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Document
            if (widget.approval.documentUrl.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Belge',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          final url = Uri.parse(widget.approval.documentUrl);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.description),
                              SizedBox(width: 8),
                              Text('Belgeyi Görüntüle'),
                              Spacer(),
                              Icon(Icons.open_in_new),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Portfolio
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Portfolyo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: widget.approval.portfolioImages.length,
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: widget.approval.portfolioImages[index],
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : _showRejectionDialog,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Reddet'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _approveArtist,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Onayla'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}