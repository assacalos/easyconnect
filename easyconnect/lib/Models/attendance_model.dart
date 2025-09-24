class AttendanceModel {
  final int id;
  final int userId;
  final String userName;
  final String userRole;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String status; // 'present', 'absent', 'late', 'early_leave'
  final LocationInfo location;
  final String? photoPath;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.checkInTime,
    this.checkOutTime,
    required this.status,
    required this.location,
    this.photoPath,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userRole: json['user_role'],
      checkInTime: DateTime.parse(json['check_in_time']),
      checkOutTime: json['check_out_time'] != null 
          ? DateTime.parse(json['check_out_time']) 
          : null,
      status: json['status'],
      location: LocationInfo.fromJson(json['location']),
      photoPath: json['photo_path'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_role': userRole,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'status': status,
      'location': location.toJson(),
      'photo_path': photoPath,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class LocationInfo {
  final double latitude;
  final double longitude;
  final String? address;
  final double? accuracy;
  final DateTime timestamp;

  LocationInfo({
    required this.latitude,
    required this.longitude,
    this.address,
    this.accuracy,
    required this.timestamp,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      address: json['address'],
      accuracy: json['accuracy']?.toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class AttendanceStats {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final double averageHours;
  final List<AttendanceModel> recentAttendance;
  final Map<String, int> monthlyStats;

  AttendanceStats({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.averageHours,
    required this.recentAttendance,
    required this.monthlyStats,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    return AttendanceStats(
      totalDays: json['total_days'] ?? 0,
      presentDays: json['present_days'] ?? 0,
      absentDays: json['absent_days'] ?? 0,
      lateDays: json['late_days'] ?? 0,
      averageHours: (json['average_hours'] ?? 0).toDouble(),
      recentAttendance: (json['recent_attendance'] as List<dynamic>?)
          ?.map((e) => AttendanceModel.fromJson(e))
          .toList() ?? [],
      monthlyStats: Map<String, int>.from(json['monthly_stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_days': totalDays,
      'present_days': presentDays,
      'absent_days': absentDays,
      'late_days': lateDays,
      'average_hours': averageHours,
      'recent_attendance': recentAttendance.map((e) => e.toJson()).toList(),
      'monthly_stats': monthlyStats,
    };
  }
}

class AttendanceSettings {
  final double allowedRadius; // Rayon autorisé en mètres
  final String workStartTime; // Heure de début (format HH:mm)
  final String workEndTime; // Heure de fin (format HH:mm)
  final int lateThresholdMinutes; // Seuil de retard en minutes
  final bool requirePhoto; // Photo obligatoire
  final bool requireLocation; // Géolocalisation obligatoire
  final List<String> allowedLocations; // Lieux autorisés

  AttendanceSettings({
    required this.allowedRadius,
    required this.workStartTime,
    required this.workEndTime,
    required this.lateThresholdMinutes,
    required this.requirePhoto,
    required this.requireLocation,
    required this.allowedLocations,
  });

  factory AttendanceSettings.fromJson(Map<String, dynamic> json) {
    return AttendanceSettings(
      allowedRadius: (json['allowed_radius'] ?? 100).toDouble(),
      workStartTime: json['work_start_time'] ?? '08:00',
      workEndTime: json['work_end_time'] ?? '17:00',
      lateThresholdMinutes: json['late_threshold_minutes'] ?? 15,
      requirePhoto: json['require_photo'] ?? true,
      requireLocation: json['require_location'] ?? true,
      allowedLocations: List<String>.from(json['allowed_locations'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowed_radius': allowedRadius,
      'work_start_time': workStartTime,
      'work_end_time': workEndTime,
      'late_threshold_minutes': lateThresholdMinutes,
      'require_photo': requirePhoto,
      'require_location': requireLocation,
      'allowed_locations': allowedLocations,
    };
  }
}
