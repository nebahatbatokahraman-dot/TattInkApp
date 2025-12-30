import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String role; // customer, artist_approved, artist_unapproved, admin
  final bool emailVerified;
  final bool isApproved; // For artists
  final String? studioName;
  final String? studioAddress;
  final String? district;
  final String? city;
  
  // --- ÖNE ÇIKARMA ALANLARI ---
  bool? isFeatured; 
  DateTime? featuredUntil;
  
  // --- HARİTA VE ADRES İÇİN GEREKLİ ALANLAR ---
  final String? address;   // Açık adres
  final double? latitude;  // Enlem
  final double? longitude; // Boylam

  final String? instagramUsername;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final List<String> portfolioImages;
  final List<String> studioImageUrls;
  final List<String> services; 
  final List<String> applications; 
  final List<String> applicationStyles; 
  final String? documentUrl;
  final String? biography;
  final int tattooCount;
  final int totalLikes;
  final int followerCount;
  final int score;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    this.username,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    required this.role,
    this.emailVerified = false,
    this.isApproved = false,
    this.studioName,
    this.studioAddress,
    this.district,
    this.city,
    this.isFeatured, 
    this.featuredUntil,
    this.address,
    this.latitude,
    this.longitude,
    this.instagramUsername,
    this.profileImageUrl,
    this.coverImageUrl,
    this.portfolioImages = const [],
    this.studioImageUrls = const [],
    this.services = const [],
    this.applications = const [], 
    this.applicationStyles = const [], 
    this.documentUrl,
    this.biography,
    this.tattooCount = 0,
    this.totalLikes = 0,
    this.followerCount = 0,
    this.score = 0,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'role': role,
      'emailVerified': emailVerified,
      'isApproved': isApproved,
      'studioName': studioName,
      'studioAddress': studioAddress,
      'district': district,
      'city': city,
      'isFeatured': isFeatured,
      'featuredUntil': featuredUntil != null ? Timestamp.fromDate(featuredUntil!) : null,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'instagramUsername': instagramUsername,
      'profileImageUrl': profileImageUrl,
      'coverImageUrl': coverImageUrl,
      'portfolioImages': portfolioImages,
      'studioImageUrls': studioImageUrls,
      'services': services,
      'applications': applications,
      'applicationStyles': applicationStyles,
      'documentUrl': documentUrl,
      'biography': biography,
      'tattooCount': tattooCount,
      'totalLikes': totalLikes,
      'followerCount': followerCount,
      'score': score,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      username: map['username'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      phoneNumber: map['phoneNumber'],
      role: map['role'] ?? 'customer',
      emailVerified: map['emailVerified'] ?? false,
      isApproved: map['isApproved'] ?? false,
      studioName: map['studioName'],
      studioAddress: map['studioAddress'],
      district: map['district'],
      city: map['city'],
      isFeatured: map['isFeatured'] ?? false,
      featuredUntil: map['featuredUntil'] != null 
          ? (map['featuredUntil'] as Timestamp).toDate() 
          : null,
      address: map['address'], 
      latitude: (map['latitude'] as num?)?.toDouble(), 
      longitude: (map['longitude'] as num?)?.toDouble(),
      instagramUsername: map['instagramUsername'],
      profileImageUrl: map['profileImageUrl'],
      coverImageUrl: map['coverImageUrl'],
      portfolioImages: List<String>.from(map['portfolioImages'] ?? []),
      studioImageUrls: List<String>.from(map['studioImageUrls'] ?? []),
      services: List<String>.from(map['services'] ?? []),
      applications: List<String>.from(map['applications'] ?? []),
      applicationStyles: List<String>.from(map['applicationStyles'] ?? []),
      documentUrl: map['documentUrl'],
      biography: map['biography'],
      tattooCount: map['tattooCount'] ?? 0,
      totalLikes: map['totalLikes'] ?? 0,
      followerCount: map['followerCount'] ?? 0,
      score: map['score'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? role,
    bool? emailVerified,
    bool? isApproved,
    String? studioName,
    String? studioAddress,
    String? district,
    String? city,
    bool? isFeatured,
    DateTime? featuredUntil,
    String? address,
    double? latitude,
    double? longitude,
    String? instagramUsername,
    String? profileImageUrl,
    String? coverImageUrl,
    List<String>? portfolioImages,
    List<String>? studioImageUrls,
    List<String>? services,
    List<String>? applications,
    List<String>? applicationStyles,
    String? documentUrl,
    String? biography,
    int? tattooCount,
    int? totalLikes,
    int? followerCount,
    int? score,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      emailVerified: emailVerified ?? this.emailVerified,
      isApproved: isApproved ?? this.isApproved,
      studioName: studioName ?? this.studioName,
      studioAddress: studioAddress ?? this.studioAddress,
      district: district ?? this.district,
      city: city ?? this.city,
      isFeatured: isFeatured ?? this.isFeatured,
      featuredUntil: featuredUntil ?? this.featuredUntil,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      instagramUsername: instagramUsername ?? this.instagramUsername,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      portfolioImages: portfolioImages ?? this.portfolioImages,
      studioImageUrls: studioImageUrls ?? this.studioImageUrls,
      services: services ?? this.services,
      applications: applications ?? this.applications,
      applicationStyles: applicationStyles ?? this.applicationStyles,
      documentUrl: documentUrl ?? this.documentUrl,
      biography: biography ?? this.biography,
      tattooCount: tattooCount ?? this.tattooCount,
      totalLikes: totalLikes ?? this.totalLikes,
      followerCount: followerCount ?? this.followerCount,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (username != null) {
      return username!;
    }
    return email;
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