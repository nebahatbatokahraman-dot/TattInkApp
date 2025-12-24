import 'package:cloud_firestore/cloud_firestore.dart';

enum ApprovalStatus {
  pending,
  approved,
  rejected,
}

class ArtistApprovalModel {
  final String id;
  final String userId;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String studioAddress;
  final String? district;
  final String? city;
  final String instagramUsername;
  final String documentUrl; // Tax document or work permit
  final List<String> portfolioImages;
  final bool isApprovedArtist; // true for approved artist registration, false for unapproved
  final ApprovalStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy; // Admin user ID

  ArtistApprovalModel({
    required this.id,
    required this.userId,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.studioAddress,
    this.district,
    this.city,
    required this.instagramUsername,
    required this.documentUrl,
    this.portfolioImages = const [],
    this.isApprovedArtist = false,
    this.status = ApprovalStatus.pending,
    this.rejectionReason,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'studioAddress': studioAddress,
      'district': district,
      'city': city,
      'instagramUsername': instagramUsername,
      'documentUrl': documentUrl,
      'portfolioImages': portfolioImages,
      'isApprovedArtist': isApprovedArtist,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
    };
  }

  factory ArtistApprovalModel.fromMap(Map<String, dynamic> map) {
    return ArtistApprovalModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      studioAddress: map['studioAddress'] ?? '',
      district: map['district'],
      city: map['city'],
      instagramUsername: map['instagramUsername'] ?? '',
      documentUrl: map['documentUrl'] ?? '',
      portfolioImages: List<String>.from(map['portfolioImages'] ?? []),
      isApprovedArtist: map['isApprovedArtist'] ?? false,
      status: ApprovalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      rejectionReason: map['rejectionReason'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: map['reviewedBy'],
    );
  }

  factory ArtistApprovalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ArtistApprovalModel.fromMap({...data, 'id': doc.id});
  }

  ArtistApprovalModel copyWith({
    String? id,
    String? userId,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? studioAddress,
    String? district,
    String? city,
    String? instagramUsername,
    String? documentUrl,
    List<String>? portfolioImages,
    bool? isApprovedArtist,
    ApprovalStatus? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return ArtistApprovalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      studioAddress: studioAddress ?? this.studioAddress,
      district: district ?? this.district,
      city: city ?? this.city,
      instagramUsername: instagramUsername ?? this.instagramUsername,
      documentUrl: documentUrl ?? this.documentUrl,
      portfolioImages: portfolioImages ?? this.portfolioImages,
      isApprovedArtist: isApprovedArtist ?? this.isApprovedArtist,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }
}

