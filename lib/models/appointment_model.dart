import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus {
  pending,
  confirmed,
  cancelled,
  completed,
}

class AppointmentModel {
  final String id;
  final String customerId;
  final String artistId;
  final String? customerName;
  final String? artistName;
  final DateTime appointmentDate;
  final String? notes;
  final String? referenceImageUrl; // Photo from post that customer liked
  final AppointmentStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AppointmentModel({
    required this.id,
    required this.customerId,
    required this.artistId,
    this.customerName,
    this.artistName,
    required this.appointmentDate,
    this.notes,
    this.referenceImageUrl,
    this.status = AppointmentStatus.pending,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'artistId': artistId,
      'customerName': customerName,
      'artistName': artistName,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'notes': notes,
      'referenceImageUrl': referenceImageUrl,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      artistId: map['artistId'] ?? '',
      customerName: map['customerName'],
      artistName: map['artistName'],
      appointmentDate: (map['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'],
      referenceImageUrl: map['referenceImageUrl'],
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel.fromMap({...data, 'id': doc.id});
  }

  AppointmentModel copyWith({
    String? id,
    String? customerId,
    String? artistId,
    String? customerName,
    String? artistName,
    DateTime? appointmentDate,
    String? notes,
    String? referenceImageUrl,
    AppointmentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      artistId: artistId ?? this.artistId,
      customerName: customerName ?? this.customerName,
      artistName: artistName ?? this.artistName,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      notes: notes ?? this.notes,
      referenceImageUrl: referenceImageUrl ?? this.referenceImageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

