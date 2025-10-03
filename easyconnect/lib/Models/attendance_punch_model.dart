import 'dart:math';
import 'package:get/get.dart';

class AttendancePunchModel {
  final int? id;
  final int userId;
  final String type; // 'check_in' ou 'check_out'
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String? address;
  final double? accuracy;
  final String? photoPath;
  final String? notes;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final int? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  final String? userName;
  final String? approverName;

  AttendancePunchModel({
    this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.address,
    this.accuracy,
    this.photoPath,
    this.notes,
    required this.status,
    this.rejectionReason,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.approverName,
  });

  factory AttendancePunchModel.fromJson(Map<String, dynamic> json) {
    return AttendancePunchModel(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      timestamp: DateTime.parse(json['timestamp']),
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      address: json['address'],
      accuracy: double.tryParse(json['accuracy']?.toString() ?? '0'),
      photoPath: json['photo_path'],
      notes: json['notes'],
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejection_reason'],
      approvedBy: json['approved_by'],
      approvedAt:
          json['approved_at'] != null
              ? DateTime.parse(json['approved_at'])
              : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      userName: json['user']?['name'] ?? json['user']?['nom'],
      approverName: json['approver']?['name'] ?? json['approver']?['nom'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'accuracy': accuracy,
      'photo_path': photoPath,
      'notes': notes,
      'status': status,
      'rejection_reason': rejectionReason,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Getters pour l'affichage
  String get typeLabel {
    switch (type) {
      case 'check_in':
        return 'Arrivée';
      case 'check_out':
        return 'Départ';
      default:
        return 'Inconnu';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  String get statusColor {
    switch (status) {
      case 'pending':
        return '#FFA500'; // Orange
      case 'approved':
        return '#28A745'; // Vert
      case 'rejected':
        return '#DC3545'; // Rouge
      default:
        return '#6C757D'; // Gris
    }
  }

  String get typeColor {
    switch (type) {
      case 'check_in':
        return '#007BFF'; // Bleu
      case 'check_out':
        return '#6F42C1'; // Violet
      default:
        return '#6C757D'; // Gris
    }
  }

  String get photoUrl {
    if (photoPath != null) {
      return 'http://10.0.2.2:8000/storage/$photoPath';
    }
    return '';
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isCheckIn => type == 'check_in';
  bool get isCheckOut => type == 'check_out';

  // Méthodes de validation
  bool get canBeApproved => isPending;
  bool get canBeRejected => isPending;

  // Formatage des dates
  String get formattedTimestamp {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} à ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // Distance depuis une position donnée
  double distanceFrom(double lat, double lng) {
    const double earthRadius = 6371000; // Rayon de la Terre en mètres

    final double lat1Rad = latitude * (3.14159265359 / 180);
    final double lat2Rad = lat * (3.14159265359 / 180);
    final double deltaLatRad = (lat - latitude) * (3.14159265359 / 180);
    final double deltaLngRad = (lng - longitude) * (3.14159265359 / 180);

    final double a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  // Vérifier si le pointage est récent (moins de 24h)
  bool get isRecent {
    return DateTime.now().difference(timestamp).inHours < 24;
  }

  // Vérifier si le pointage est aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  AttendancePunchModel copyWith({
    int? id,
    int? userId,
    String? type,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    String? address,
    double? accuracy,
    String? photoPath,
    String? notes,
    String? status,
    String? rejectionReason,
    int? approvedBy,
    DateTime? approvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? approverName,
  }) {
    return AttendancePunchModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      accuracy: accuracy ?? this.accuracy,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      approverName: approverName ?? this.approverName,
    );
  }
}
