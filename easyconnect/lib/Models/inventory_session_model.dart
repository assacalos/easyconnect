/// Session d'inventaire physique (date, dépôt, statut en_cours / cloture).
class InventorySession {
  final int id;
  final String date;
  final String? depot;
  final String status;
  final int? createdBy;
  final int? closedBy;
  final String? closedAt;
  final String? createdAt;
  final String? updatedAt;
  final List<InventorySessionItem> items;

  const InventorySession({
    required this.id,
    required this.date,
    this.depot,
    required this.status,
    this.createdBy,
    this.closedBy,
    this.closedAt,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  factory InventorySession.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'];
    return InventorySession(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      date: json['date']?.toString() ?? '',
      depot: json['depot']?.toString(),
      status: json['status']?.toString() ?? 'en_cours',
      createdBy: json['created_by'] != null ? int.tryParse(json['created_by'].toString()) : null,
      closedBy: json['closed_by'] != null ? int.tryParse(json['closed_by'].toString()) : null,
      closedAt: json['closed_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      items: itemsList is List
          ? (itemsList).map((e) => InventorySessionItem.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'depot': depot,
      'status': status,
      'created_by': createdBy,
      'closed_by': closedBy,
      'closed_at': closedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  bool get isInProgress => status == 'en_cours';
  bool get isClosed => status == 'cloture';

  String get statusText {
    switch (status) {
      case 'en_cours':
        return 'En cours';
      case 'cloture':
        return 'Clôturé';
      default:
        return status;
    }
  }

  int get variancesCount => items.where((e) => e.hasVariance).length;
}

/// Ligne d'une session : article (référence stock) avec quantité théorique et comptée.
class InventorySessionItem {
  final int id;
  final int inventorySessionId;
  final int stockId;
  final double quantityTheoretical;
  final double? quantityCounted;
  final InventoryItemStock? stock;

  const InventorySessionItem({
    required this.id,
    required this.inventorySessionId,
    required this.stockId,
    required this.quantityTheoretical,
    this.quantityCounted,
    this.stock,
  });

  factory InventorySessionItem.fromJson(Map<String, dynamic> json) {
    final stockData = json['stock'];
    return InventorySessionItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      inventorySessionId: int.tryParse(json['inventory_session_id']?.toString() ?? '0') ?? 0,
      stockId: int.tryParse(json['stock_id']?.toString() ?? '0') ?? 0,
      quantityTheoretical: _parseDouble(json['quantity_theoretical']),
      quantityCounted: json['quantity_counted'] != null ? _parseDouble(json['quantity_counted']) : null,
      stock: stockData is Map ? InventoryItemStock.fromJson(Map<String, dynamic>.from(stockData)) : null,
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventory_session_id': inventorySessionId,
      'stock_id': stockId,
      'quantity_theoretical': quantityTheoretical,
      'quantity_counted': quantityCounted,
      'stock': stock?.toJson(),
    };
  }

  /// Écart = compté - théorique (null si pas encore compté)
  double? get quantityVariance {
    if (quantityCounted == null) return null;
    return quantityCounted! - quantityTheoretical;
  }

  bool get hasVariance {
    final v = quantityVariance;
    return v != null && v != 0;
  }
}

/// Infos stock allégées pour une ligne d'inventaire
class InventoryItemStock {
  final int id;
  final String name;
  final String sku;
  final String category;
  final String unit;

  const InventoryItemStock({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    this.unit = 'pièce',
  });

  factory InventoryItemStock.fromJson(Map<String, dynamic> json) {
    return InventoryItemStock(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'pièce',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sku': sku,
        'category': category,
        'unit': unit,
      };
}
