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
  final List<String> likedBy; // User IDs who liked
  final String? district;
  final String? city;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PostModel({
    required this.id,
    required this.artistId,
    this.artistUsername,
    this.artistProfileImageUrl,
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.caption,
    this.likeCount = 0,
    this.likedBy = const [],
    this.district,
    this.city,
    required this.createdAt,
    this.updatedAt,
  });

  bool get hasImages => imageUrls.isNotEmpty;
  bool get hasVideos => videoUrls.isNotEmpty;
  bool get isCarousel => (imageUrls.length + videoUrls.length) > 1;

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
      'district': district,
      'city': city,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] ?? '',
      artistId: map['artistId'] ?? '',
      artistUsername: map['artistUsername'],
      artistProfileImageUrl: map['artistProfileImageUrl'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      videoUrls: List<String>.from(map['videoUrls'] ?? []),
      caption: map['caption'],
      likeCount: map['likeCount'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      district: map['district'],
      city: map['city'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel.fromMap({...data, 'id': doc.id});
  }

  PostModel copyWith({
    String? id,
    String? artistId,
    String? artistUsername,
    String? artistProfileImageUrl,
    List<String>? imageUrls,
    List<String>? videoUrls,
    String? caption,
    int? likeCount,
    List<String>? likedBy,
    String? district,
    String? city,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      artistId: artistId ?? this.artistId,
      artistUsername: artistUsername ?? this.artistUsername,
      artistProfileImageUrl: artistProfileImageUrl ?? this.artistProfileImageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      caption: caption ?? this.caption,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
      district: district ?? this.district,
      city: city ?? this.city,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get locationString {
    if (district != null && city != null) {
      return '$district, $city';
    } else if (city != null) {
      return city!;
    }
    return '';
  }
}

