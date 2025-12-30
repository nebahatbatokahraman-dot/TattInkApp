import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String artistId;
  final String? artistUsername;
  final String? artistProfileImageUrl;
  final List<String> imageUrls;
  
  // --- VİDEO İÇİN GEREKLİ ALANLAR ---
  final List<String> videoUrls; // (Yedek) İlerde çoklu video istersen diye kalsın
  final String? videoUrl;       // (AKTİF) Şu an kullandığımız tekil video alanı

  final String? caption;
  final int likeCount;
  final List<String> likedBy;
  final String locationString;
  final String? city;
  final String? district;
  final Timestamp createdAt;
  final bool isFeatured; 
  final double artistScore; 

  // --- UYGULAMA TÜRÜ VE STİLLER ---
  final String? application; 
  final List<String> styles; 

  PostModel({
    required this.id,
    required this.artistId,
    this.artistUsername,
    this.artistProfileImageUrl,
    required this.imageUrls,
    this.videoUrls = const [], // Varsayılan boş liste
    this.videoUrl,             // Varsayılan null
    this.caption,
    this.likeCount = 0,
    this.likedBy = const [],
    this.locationString = '',
    this.city,
    this.district,
    required this.createdAt,
    this.isFeatured = false,
    this.artistScore = 0.0,
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
      
      // --- VİDEO VERİLERİNİ OKUMA ---
      videoUrls: List<String>.from(data['videoUrls'] ?? []),
      videoUrl: data['videoUrl'], // Veritabanından string olarak oku
      
      caption: data['caption'],
      likeCount: data['likeCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      locationString: data['locationString'] ?? '',
      city: data['city'],
      district: data['district'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isFeatured: data['isFeatured'] ?? false,
      artistScore: (data['artistScore'] ?? 0).toDouble(),
      
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
      
      // --- VİDEO VERİLERİNİ YAZMA ---
      'videoUrls': videoUrls,
      'videoUrl': videoUrl,
      
      'caption': caption,
      'likeCount': likeCount,
      'likedBy': likedBy,
      'locationString': locationString,
      'city': city,
      'district': district,
      'createdAt': createdAt,
      'isFeatured': isFeatured,
      'artistScore': artistScore,
      'application': application,
      'styles': styles,
    };
  }

  // CopyWith metodu
  PostModel copyWith({
    String? id,
    String? artistId,
    String? artistUsername,
    String? artistProfileImageUrl,
    List<String>? imageUrls,
    List<String>? videoUrls,
    String? videoUrl, // <-- Eklendi
    String? caption,
    int? likeCount,
    List<String>? likedBy,
    String? locationString,
    String? city,
    String? district,
    Timestamp? createdAt,
    bool? isFeatured,
    double? artistScore,
    String? application,
    List<String>? styles,
  }) {
    return PostModel(
      id: id ?? this.id,
      artistId: artistId ?? this.artistId,
      artistUsername: artistUsername ?? this.artistUsername,
      artistProfileImageUrl: artistProfileImageUrl ?? this.artistProfileImageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      videoUrl: videoUrl ?? this.videoUrl, // <-- Eklendi
      caption: caption ?? this.caption,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
      locationString: locationString ?? this.locationString,
      city: city ?? this.city,
      district: district ?? this.district,
      createdAt: createdAt ?? this.createdAt,
      isFeatured: isFeatured ?? this.isFeatured,
      artistScore: artistScore ?? this.artistScore,
      application: application ?? this.application,
      styles: styles ?? this.styles,
    );
  }
}