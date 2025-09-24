class InvoiceModel {
  final int id;
  final String invoiceNumber;
  final int clientId;
  final String clientName;
  final String clientEmail;
  final String clientAddress;
  final int commercialId;
  final String commercialName;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final String status; // 'draft', 'sent', 'paid', 'overdue', 'cancelled'
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double totalAmount;
  final String currency;
  final String? notes;
  final String? terms;
  final List<InvoiceItem> items;
  final PaymentInfo? paymentInfo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? sentAt;
  final DateTime? paidAt;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.clientAddress,
    required this.commercialId,
    required this.commercialName,
    required this.invoiceDate,
    required this.dueDate,
    required this.status,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.totalAmount,
    required this.currency,
    this.notes,
    this.terms,
    required this.items,
    this.paymentInfo,
    required this.createdAt,
    required this.updatedAt,
    this.sentAt,
    this.paidAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'],
      invoiceNumber: json['invoice_number'],
      clientId: json['client_id'],
      clientName: json['client_name'],
      clientEmail: json['client_email'],
      clientAddress: json['client_address'],
      commercialId: json['commercial_id'],
      commercialName: json['commercial_name'],
      invoiceDate: DateTime.parse(json['invoice_date']),
      dueDate: DateTime.parse(json['due_date']),
      status: json['status'],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxRate: (json['tax_rate'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'EUR',
      notes: json['notes'],
      terms: json['terms'],
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => InvoiceItem.fromJson(item))
          .toList() ?? [],
      paymentInfo: json['payment_info'] != null 
          ? PaymentInfo.fromJson(json['payment_info']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'client_id': clientId,
      'client_name': clientName,
      'client_email': clientEmail,
      'client_address': clientAddress,
      'commercial_id': commercialId,
      'commercial_name': commercialName,
      'invoice_date': invoiceDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'currency': currency,
      'notes': notes,
      'terms': terms,
      'items': items.map((item) => item.toJson()).toList(),
      'payment_info': paymentInfo?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
    };
  }
}

class InvoiceItem {
  final int id;
  final String description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? unit;

  InvoiceItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.unit,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] ?? 0,
      description: json['description'],
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'unit': unit,
    };
  }
}

class PaymentInfo {
  final String method; // 'bank_transfer', 'check', 'cash', 'card'
  final String? reference;
  final DateTime? paymentDate;
  final double amount;
  final String? notes;

  PaymentInfo({
    required this.method,
    this.reference,
    this.paymentDate,
    required this.amount,
    this.notes,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      method: json['method'],
      reference: json['reference'],
      paymentDate: json['payment_date'] != null 
          ? DateTime.parse(json['payment_date']) 
          : null,
      amount: (json['amount'] ?? 0).toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'reference': reference,
      'payment_date': paymentDate?.toIso8601String(),
      'amount': amount,
      'notes': notes,
    };
  }
}

class InvoiceStats {
  final int totalInvoices;
  final int draftInvoices;
  final int sentInvoices;
  final int paidInvoices;
  final int overdueInvoices;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final double overdueAmount;
  final List<InvoiceModel> recentInvoices;
  final Map<String, double> monthlyStats;

  InvoiceStats({
    required this.totalInvoices,
    required this.draftInvoices,
    required this.sentInvoices,
    required this.paidInvoices,
    required this.overdueInvoices,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.overdueAmount,
    required this.recentInvoices,
    required this.monthlyStats,
  });

  factory InvoiceStats.fromJson(Map<String, dynamic> json) {
    return InvoiceStats(
      totalInvoices: json['total_invoices'] ?? 0,
      draftInvoices: json['draft_invoices'] ?? 0,
      sentInvoices: json['sent_invoices'] ?? 0,
      paidInvoices: json['paid_invoices'] ?? 0,
      overdueInvoices: json['overdue_invoices'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      pendingAmount: (json['pending_amount'] ?? 0).toDouble(),
      overdueAmount: (json['overdue_amount'] ?? 0).toDouble(),
      recentInvoices: (json['recent_invoices'] as List<dynamic>?)
          ?.map((invoice) => InvoiceModel.fromJson(invoice))
          .toList() ?? [],
      monthlyStats: Map<String, double>.from(json['monthly_stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_invoices': totalInvoices,
      'draft_invoices': draftInvoices,
      'sent_invoices': sentInvoices,
      'paid_invoices': paidInvoices,
      'overdue_invoices': overdueInvoices,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'pending_amount': pendingAmount,
      'overdue_amount': overdueAmount,
      'recent_invoices': recentInvoices.map((invoice) => invoice.toJson()).toList(),
      'monthly_stats': monthlyStats,
    };
  }
}

class InvoiceTemplate {
  final int id;
  final String name;
  final String description;
  final String template;
  final bool isDefault;
  final DateTime createdAt;

  InvoiceTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.template,
    required this.isDefault,
    required this.createdAt,
  });

  factory InvoiceTemplate.fromJson(Map<String, dynamic> json) {
    return InvoiceTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
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
      'template': template,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
