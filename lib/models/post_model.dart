import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String artistId;
  final String? artistUsername;
  final String? artistProfileImageUrl;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final String? caption;
  final int likeCount;
  final List<String> likedBy;
  final String locationString;
  final String? city;
  final String? district;
  final Timestamp createdAt;
  final bool isFeatured; // Premium/Öne çıkan post mu?
  final double artistScore; // Sıralama için

  // --- YENİ EKLENEN ALANLAR ---
  final String? application; // Örn: Dövme, Piercing
  final List<String> styles; // Örn: [Realistik, Minimal]

  PostModel({
    required this.id,
    required this.artistId,
    this.artistUsername,
    this.artistProfileImageUrl,
    required this.imageUrls,
    this.videoUrls = const [],
    this.caption,
    this.likeCount = 0,
    this.likedBy = const [],
    this.locationString = '',
    this.city,
    this.district,
    required this.createdAt,
    this.isFeatured = false,
    this.artistScore = 0.0,
    // Yeni alanları constructor'a ekledik
    this.application, 
    this.styles = const [],
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PostModel(
      id: data['id'] ?? doc.id,
      artistId: data['artistId'] ?? '',
      artistUsername: data['artistUsername'],
      artistProfileImageUrl: data['artistProfileImageUrl'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      videoUrls: List<String>.from(data['videoUrls'] ?? []),
      caption: data['caption'],
      likeCount: data['likeCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      locationString: data['locationString'] ?? '',
      city: data['city'],
      district: data['district'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isFeatured: data['isFeatured'] ?? false,
      artistScore: (data['artistScore'] ?? 0).toDouble(),
      
      // --- YENİ ALANLARI VERİTABANINDAN OKUYORUZ ---
      application: data['application'], 
      styles: List<String>.from(data['styles'] ?? []), 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'artistId': artistId,
      'artistUsername': artistUsername,
      'artistProfileImageUrl': artistProfileImageUrl,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'caption': caption,
      'likeCount': likeCount,
      'likedBy': likedBy,
      'locationString': locationString,
      'city': city,
      'district': district,
      'createdAt': createdAt,
      'isFeatured': isFeatured,
      'artistScore': artistScore,
      
      // --- YENİ ALANLARI HARİTAYA EKLİYORUZ ---
      'application': application,
      'styles': styles,
    };
  }
}