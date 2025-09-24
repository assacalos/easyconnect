class PaymentModel {
  final int id;
  final String paymentNumber;
  final String type; // 'one_time', 'monthly'
  final int clientId;
  final String clientName;
  final String clientEmail;
  final String clientAddress;
  final int comptableId;
  final String comptableName;
  final DateTime paymentDate;
  final DateTime? dueDate;
  final String status; // 'draft', 'submitted', 'approved', 'rejected', 'paid', 'overdue'
  final double amount;
  final String currency;
  final String paymentMethod; // 'bank_transfer', 'check', 'cash', 'card', 'direct_debit'
  final String? description;
  final String? notes;
  final String? reference;
  final PaymentSchedule? schedule; // Pour les paiements mensuels
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? paidAt;

  PaymentModel({
    required this.id,
    required this.paymentNumber,
    required this.type,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.clientAddress,
    required this.comptableId,
    required this.comptableName,
    required this.paymentDate,
    this.dueDate,
    required this.status,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    this.description,
    this.notes,
    this.reference,
    this.schedule,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
    this.approvedAt,
    this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      paymentNumber: json['payment_number'],
      type: json['type'],
      clientId: json['client_id'],
      clientName: json['client_name'],
      clientEmail: json['client_email'],
      clientAddress: json['client_address'],
      comptableId: json['comptable_id'],
      comptableName: json['comptable_name'],
      paymentDate: DateTime.parse(json['payment_date']),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      status: json['status'],
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'EUR',
      paymentMethod: json['payment_method'],
      description: json['description'],
      notes: json['notes'],
      reference: json['reference'],
      schedule: json['schedule'] != null ? PaymentSchedule.fromJson(json['schedule']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at']) : null,
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_number': paymentNumber,
      'type': type,
      'client_id': clientId,
      'client_name': clientName,
      'client_email': clientEmail,
      'client_address': clientAddress,
      'comptable_id': comptableId,
      'comptable_name': comptableName,
      'payment_date': paymentDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'status': status,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      'description': description,
      'notes': notes,
      'reference': reference,
      'schedule': schedule?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
    };
  }
}

class PaymentSchedule {
  final int id;
  final DateTime startDate;
  final DateTime endDate;
  final int frequency; // Nombre de jours entre les paiements
  final int totalInstallments;
  final int paidInstallments;
  final double installmentAmount;
  final String status; // 'active', 'paused', 'completed', 'cancelled'
  final DateTime? nextPaymentDate;
  final List<PaymentInstallment> installments;

  PaymentSchedule({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.frequency,
    required this.totalInstallments,
    required this.paidInstallments,
    required this.installmentAmount,
    required this.status,
    this.nextPaymentDate,
    required this.installments,
  });

  factory PaymentSchedule.fromJson(Map<String, dynamic> json) {
    return PaymentSchedule(
      id: json['id'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      frequency: json['frequency'],
      totalInstallments: json['total_installments'],
      paidInstallments: json['paid_installments'],
      installmentAmount: (json['installment_amount'] ?? 0).toDouble(),
      status: json['status'],
      nextPaymentDate: json['next_payment_date'] != null 
          ? DateTime.parse(json['next_payment_date']) 
          : null,
      installments: (json['installments'] as List<dynamic>?)
          ?.map((installment) => PaymentInstallment.fromJson(installment))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'frequency': frequency,
      'total_installments': totalInstallments,
      'paid_installments': paidInstallments,
      'installment_amount': installmentAmount,
      'status': status,
      'next_payment_date': nextPaymentDate?.toIso8601String(),
      'installments': installments.map((installment) => installment.toJson()).toList(),
    };
  }
}

class PaymentInstallment {
  final int id;
  final int installmentNumber;
  final DateTime dueDate;
  final double amount;
  final String status; // 'pending', 'paid', 'overdue'
  final DateTime? paidDate;
  final String? notes;

  PaymentInstallment({
    required this.id,
    required this.installmentNumber,
    required this.dueDate,
    required this.amount,
    required this.status,
    this.paidDate,
    this.notes,
  });

  factory PaymentInstallment.fromJson(Map<String, dynamic> json) {
    return PaymentInstallment(
      id: json['id'],
      installmentNumber: json['installment_number'],
      dueDate: DateTime.parse(json['due_date']),
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'],
      paidDate: json['paid_date'] != null ? DateTime.parse(json['paid_date']) : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'installment_number': installmentNumber,
      'due_date': dueDate.toIso8601String(),
      'amount': amount,
      'status': status,
      'paid_date': paidDate?.toIso8601String(),
      'notes': notes,
    };
  }
}

class PaymentStats {
  final int totalPayments;
  final int oneTimePayments;
  final int monthlyPayments;
  final int pendingPayments;
  final int approvedPayments;
  final int paidPayments;
  final int overduePayments;
  final double totalAmount;
  final double pendingAmount;
  final double paidAmount;
  final double overdueAmount;
  final List<PaymentModel> recentPayments;
  final Map<String, double> monthlyStats;
  final Map<String, int> paymentMethodStats;

  PaymentStats({
    required this.totalPayments,
    required this.oneTimePayments,
    required this.monthlyPayments,
    required this.pendingPayments,
    required this.approvedPayments,
    required this.paidPayments,
    required this.overduePayments,
    required this.totalAmount,
    required this.pendingAmount,
    required this.paidAmount,
    required this.overdueAmount,
    required this.recentPayments,
    required this.monthlyStats,
    required this.paymentMethodStats,
  });

  factory PaymentStats.fromJson(Map<String, dynamic> json) {
    return PaymentStats(
      totalPayments: json['total_payments'] ?? 0,
      oneTimePayments: json['one_time_payments'] ?? 0,
      monthlyPayments: json['monthly_payments'] ?? 0,
      pendingPayments: json['pending_payments'] ?? 0,
      approvedPayments: json['approved_payments'] ?? 0,
      paidPayments: json['paid_payments'] ?? 0,
      overduePayments: json['overdue_payments'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      pendingAmount: (json['pending_amount'] ?? 0).toDouble(),
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      overdueAmount: (json['overdue_amount'] ?? 0).toDouble(),
      recentPayments: (json['recent_payments'] as List<dynamic>?)
          ?.map((payment) => PaymentModel.fromJson(payment))
          .toList() ?? [],
      monthlyStats: Map<String, double>.from(json['monthly_stats'] ?? {}),
      paymentMethodStats: Map<String, int>.from(json['payment_method_stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_payments': totalPayments,
      'one_time_payments': oneTimePayments,
      'monthly_payments': monthlyPayments,
      'pending_payments': pendingPayments,
      'approved_payments': approvedPayments,
      'paid_payments': paidPayments,
      'overdue_payments': overduePayments,
      'total_amount': totalAmount,
      'pending_amount': pendingAmount,
      'paid_amount': paidAmount,
      'overdue_amount': overdueAmount,
      'recent_payments': recentPayments.map((payment) => payment.toJson()).toList(),
      'monthly_stats': monthlyStats,
      'payment_method_stats': paymentMethodStats,
    };
  }
}

class PaymentTemplate {
  final int id;
  final String name;
  final String description;
  final String type; // 'one_time', 'monthly'
  final double defaultAmount;
  final String defaultPaymentMethod;
  final int? defaultFrequency; // Pour les paiements mensuels
  final String template;
  final bool isDefault;
  final DateTime createdAt;

  PaymentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.defaultAmount,
    required this.defaultPaymentMethod,
    this.defaultFrequency,
    required this.template,
    required this.isDefault,
    required this.createdAt,
  });

  factory PaymentTemplate.fromJson(Map<String, dynamic> json) {
    return PaymentTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: json['type'],
      defaultAmount: (json['default_amount'] ?? 0).toDouble(),
      defaultPaymentMethod: json['default_payment_method'],
      defaultFrequency: json['default_frequency'],
      template: json['template'],
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'default_amount': defaultAmount,
      'default_payment_method': defaultPaymentMethod,
      'default_frequency': defaultFrequency,
      'template': template,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
