class TechnicianReminder {
  final int? id;
  final int userId;
  final String title;
  final String? notes;
  final int? clientId;
  final String? companyName;
  final DateTime dueDate;
  final int remindDaysBefore; // 1, 2 ou 3
  final String status; // pending, done, cancelled
  final DateTime? reminderSentAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? companyDisplay;

  TechnicianReminder({
    this.id,
    required this.userId,
    required this.title,
    this.notes,
    this.clientId,
    this.companyName,
    required this.dueDate,
    this.remindDaysBefore = 1,
    this.status = 'pending',
    this.reminderSentAt,
    required this.createdAt,
    required this.updatedAt,
    this.companyDisplay,
  });

  factory TechnicianReminder.fromJson(Map<String, dynamic> json) {
    return TechnicianReminder(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      userId: _int(json['user_id']) ?? 0,
      title: json['title']?.toString() ?? '',
      notes: json['notes']?.toString(),
      clientId: _int(json['client_id']),
      companyName: json['company_name']?.toString(),
      dueDate: DateTime.tryParse(json['due_date']?.toString() ?? '') ?? DateTime.now(),
      remindDaysBefore: _int(json['remind_days_before']) ?? 1,
      status: json['status']?.toString() ?? 'pending',
      reminderSentAt: json['reminder_sent_at'] != null
          ? DateTime.tryParse(json['reminder_sent_at'].toString())
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      companyDisplay: _companyDisplay(json),
    );
  }

  static int? _int(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static String? _companyDisplay(Map<String, dynamic> json) {
    if (json['client'] is Map<String, dynamic>) {
      final c = json['client'] as Map<String, dynamic>;
      return c['nom_entreprise']?.toString() ?? c['nom']?.toString();
    }
    return json['company_name']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'notes': notes,
      'client_id': clientId,
      'company_name': companyName,
      'due_date': dueDate.toIso8601String().split('T').first,
      'remind_days_before': remindDaysBefore,
      'status': status,
      'reminder_sent_at': reminderSentAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get remindDaysLabel {
    switch (remindDaysBefore) {
      case 1:
        return '1 jour avant';
      case 2:
        return '2 jours avant';
      case 3:
        return '3 jours avant';
      default:
        return '$remindDaysBefore jour(s) avant';
    }
  }

  bool get isPending => status == 'pending';
  bool get isDone => status == 'done';
}
