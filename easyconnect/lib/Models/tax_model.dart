class Tax {
  final int? id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final String status;
  final String? description;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tax({
    this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.status = 'pending',
    this.description,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  // Méthodes utilitaires
  bool get isPending => status == 'pending';
  bool get isValidated => status == 'validated';
  bool get isRejected => status == 'rejected';

  String get statusText {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'validated':
        return 'Validé';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  String get statusColor {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'validated':
        return 'green';
      case 'rejected':
        return 'red';
      default:
        return 'grey';
    }
  }

  // Sérialisation JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'description': description,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Tax.fromJson(Map<String, dynamic> json) {
    return Tax(
      id: json['id'],
      name: json['name'] ?? '',
      amount:
          json['amount'] != null
              ? (json['amount'] is String
                  ? double.tryParse(json['amount']) ?? 0.0
                  : (json['amount']?.toDouble() ?? 0.0))
              : 0.0,
      dueDate: DateTime.parse(
        json['due_date'] ?? DateTime.now().toIso8601String(),
      ),
      status: json['status'] ?? 'pending',
      description: json['description'],
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  get user => null;

  // Méthode de copie
  Tax copyWith({
    int? id,
    String? name,
    double? amount,
    DateTime? dueDate,
    String? status,
    String? description,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tax(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      description: description ?? this.description,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Classe pour les statistiques des taxes
class TaxStats {
  final int total;
  final int pending;
  final int validated;
  final int rejected;
  final double totalAmount;
  final double pendingAmount;
  final double validatedAmount;
  final double rejectedAmount;

  TaxStats({
    required this.total,
    required this.pending,
    required this.validated,
    required this.rejected,
    required this.totalAmount,
    required this.pendingAmount,
    required this.validatedAmount,
    required this.rejectedAmount,
  });

  factory TaxStats.fromJson(Map<String, dynamic> json) {
    return TaxStats(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      validated: json['validated'] ?? 0,
      rejected: json['rejected'] ?? 0,
      totalAmount:
          json['total_amount'] != null
              ? (json['total_amount'] is String
                  ? double.tryParse(json['total_amount']) ?? 0.0
                  : (json['total_amount']?.toDouble() ?? 0.0))
              : 0.0,
      pendingAmount:
          json['pending_amount'] != null
              ? (json['pending_amount'] is String
                  ? double.tryParse(json['pending_amount']) ?? 0.0
                  : (json['pending_amount']?.toDouble() ?? 0.0))
              : 0.0,
      validatedAmount:
          json['validated_amount'] != null
              ? (json['validated_amount'] is String
                  ? double.tryParse(json['validated_amount']) ?? 0.0
                  : (json['validated_amount']?.toDouble() ?? 0.0))
              : 0.0,
      rejectedAmount:
          json['rejected_amount'] != null
              ? (json['rejected_amount'] is String
                  ? double.tryParse(json['rejected_amount']) ?? 0.0
                  : (json['rejected_amount']?.toDouble() ?? 0.0))
              : 0.0,
    );
  }
}
