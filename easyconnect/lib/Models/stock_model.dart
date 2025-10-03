class Stock {
  final int? id;
  final String name;
  final String description;
  final String category;
  final String sku; // Stock Keeping Unit
  final double quantity;
  final double minQuantity; // Seuil minimum
  final double maxQuantity; // Seuil maximum
  final double unitPrice;
  final String unit; // Unité de mesure (pièce, kg, litre, etc.)
  final String? location; // Emplacement dans l'entrepôt
  final String? supplier; // Fournisseur principal
  final String? barcode; // Code-barres
  final String? image; // Image du produit
  final bool isActive;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? comments;
  final List<StockMovement>? movements;

  const Stock({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.sku,
    required this.quantity,
    required this.minQuantity,
    required this.maxQuantity,
    required this.unitPrice,
    required this.unit,
    this.location,
    this.supplier,
    this.barcode,
    this.image,
    this.isActive = true,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
    this.movements,
    this.comments,
  });

  // Méthode utilitaire pour parser les doubles de manière sécurisée
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Méthode utilitaire pour parser les dates de manière sécurisée
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      sku: json['sku'] ?? '',
      quantity: Stock._parseDouble(json['quantity']),
      minQuantity: _parseDouble(json['min_quantity']),
      maxQuantity: _parseDouble(json['max_quantity']),
      unitPrice: _parseDouble(json['unit_price']),
      unit: json['unit'] ?? 'pièce',
      location: json['location'],
      supplier: json['supplier'],
      barcode: json['barcode'],
      image: json['image'],
      isActive: json['is_active'] ?? true,
      status: json['status'] ?? 'pending',
      createdAt: Stock._parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      movements:
          json['movements'] != null
              ? (json['movements'] as List)
                  .map((m) => StockMovement.fromJson(m))
                  .toList()
              : null,
      comments: json['commentaire'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'sku': sku,
      'quantity': quantity,
      'min_quantity': minQuantity,
      'max_quantity': maxQuantity,
      'unit_price': unitPrice,
      'unit': unit,
      'location': location,
      'supplier': supplier,
      'barcode': barcode,
      'image': image,
      'is_active': isActive,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'movements': movements?.map((m) => m.toJson()).toList(),
      'commentaire': comments,
    };
  }

  // Propriétés calculées
  bool get isLowStock => quantity <= minQuantity;
  bool get isOutOfStock => quantity <= 0;
  bool get isOverstocked => quantity >= maxQuantity;

  String get stockStatus {
    if (isOutOfStock) return 'Rupture';
    if (isLowStock) return 'Stock faible';
    if (isOverstocked) return 'Surstock';
    return 'Normal';
  }

  String get stockStatusText {
    switch (stockStatus) {
      case 'Rupture':
        return 'Rupture de stock';
      case 'Stock faible':
        return 'Stock faible';
      case 'Surstock':
        return 'Surstock';
      default:
        return 'Stock normal';
    }
  }

  String get stockStatusIcon {
    switch (stockStatus) {
      case 'Rupture':
        return 'error';
      case 'Stock faible':
        return 'warning';
      case 'Surstock':
        return 'info';
      default:
        return 'check_circle';
    }
  }

  String get stockStatusColor {
    switch (stockStatus) {
      case 'Rupture':
        return 'red';
      case 'Stock faible':
        return 'orange';
      case 'Surstock':
        return 'blue';
      default:
        return 'green';
    }
  }

  // Méthodes pour gérer le statut d'approbation
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  String get approvalStatusText {
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

  String get approvalStatusIcon {
    switch (status) {
      case 'pending':
        return 'pending';
      case 'approved':
        return 'check_circle';
      case 'rejected':
        return 'cancel';
      default:
        return 'help';
    }
  }

  String get approvalStatusColor {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'approved':
        return 'green';
      case 'rejected':
        return 'red';
      default:
        return 'grey';
    }
  }

  double get totalValue => quantity * unitPrice;

  String get formattedQuantity => '${quantity.toStringAsFixed(0)} $unit';
  String get formattedUnitPrice => '${unitPrice.toStringAsFixed(2)} fcfa';
  String get formattedTotalValue => '${totalValue.toStringAsFixed(2)} fcfa';

  get user => null;
}

class StockMovement {
  final int? id;
  final int stockId;
  final String type; // 'in', 'out', 'adjustment', 'transfer'
  final double quantity;
  final String? reason;
  final String? reference; // Référence du mouvement (commande, facture, etc.)
  final String? notes;
  final DateTime createdAt;
  final String? createdBy;

  const StockMovement({
    this.id,
    required this.stockId,
    required this.type,
    required this.quantity,
    this.reason,
    this.reference,
    this.notes,
    required this.createdAt,
    this.createdBy,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'],
      stockId: json['stock_id'] ?? 0,
      type: json['type'] ?? '',
      quantity: Stock._parseDouble(json['quantity']),
      reason: json['reason'],
      reference: json['reference'],
      notes: json['notes'],
      createdAt: Stock._parseDateTime(json['created_at']),
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stock_id': stockId,
      'type': type,
      'quantity': quantity,
      'reason': reason,
      'reference': reference,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  String get typeText {
    switch (type) {
      case 'in':
        return 'Entrée';
      case 'out':
        return 'Sortie';
      case 'adjustment':
        return 'Ajustement';
      case 'transfer':
        return 'Transfert';
      default:
        return type;
    }
  }

  String get typeIcon {
    switch (type) {
      case 'in':
        return 'add';
      case 'out':
        return 'remove';
      case 'adjustment':
        return 'edit';
      case 'transfer':
        return 'swap_horiz';
      default:
        return 'help';
    }
  }

  String get typeColor {
    switch (type) {
      case 'in':
        return 'green';
      case 'out':
        return 'red';
      case 'adjustment':
        return 'blue';
      case 'transfer':
        return 'orange';
      default:
        return 'grey';
    }
  }
}

class StockCategory {
  final int? id;
  final String name;
  final String description;
  final String? parentCategory;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StockCategory({
    this.id,
    required this.name,
    required this.description,
    this.parentCategory,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StockCategory.fromJson(Map<String, dynamic> json) {
    return StockCategory(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      parentCategory: json['parent_category'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'parent_category': parentCategory,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class StockAlert {
  final int? id;
  final int stockId;
  final String type; // 'low_stock', 'out_of_stock', 'overstock'
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const StockAlert({
    this.id,
    required this.stockId,
    required this.type,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  factory StockAlert.fromJson(Map<String, dynamic> json) {
    return StockAlert(
      id: json['id'],
      stockId: json['stock_id'] ?? 0,
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stock_id': stockId,
      'type': type,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get typeText {
    switch (type) {
      case 'low_stock':
        return 'Stock faible';
      case 'out_of_stock':
        return 'Rupture de stock';
      case 'overstock':
        return 'Surstock';
      default:
        return type;
    }
  }

  String get typeIcon {
    switch (type) {
      case 'low_stock':
        return 'warning';
      case 'out_of_stock':
        return 'error';
      case 'overstock':
        return 'info';
      default:
        return 'help';
    }
  }

  String get typeColor {
    switch (type) {
      case 'low_stock':
        return 'orange';
      case 'out_of_stock':
        return 'red';
      case 'overstock':
        return 'blue';
      default:
        return 'grey';
    }
  }
}

class StockStats {
  final int totalProducts;
  final int activeProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final int overstockedProducts;
  final double totalValue;
  final double averageValue;
  final int totalMovements;
  final int movementsThisMonth;
  final List<StockCategory> topCategories;
  final List<Stock> topProducts;

  const StockStats({
    required this.totalProducts,
    required this.activeProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.overstockedProducts,
    required this.totalValue,
    required this.averageValue,
    required this.totalMovements,
    required this.movementsThisMonth,
    required this.topCategories,
    required this.topProducts,
  });

  factory StockStats.fromJson(Map<String, dynamic> json) {
    return StockStats(
      totalProducts: json['total_products'] ?? 0,
      activeProducts: json['active_products'] ?? 0,
      lowStockProducts: json['low_stock_products'] ?? 0,
      outOfStockProducts: json['out_of_stock_products'] ?? 0,
      overstockedProducts: json['overstocked_products'] ?? 0,
      totalValue: Stock._parseDouble(json['total_value']),
      averageValue: Stock._parseDouble(json['average_value']),
      totalMovements: json['total_movements'] ?? 0,
      movementsThisMonth: json['movements_this_month'] ?? 0,
      topCategories:
          json['top_categories'] != null
              ? (json['top_categories'] as List)
                  .map((c) => StockCategory.fromJson(c))
                  .toList()
              : [],
      topProducts:
          json['top_products'] != null
              ? (json['top_products'] as List)
                  .map((p) => Stock.fromJson(p))
                  .toList()
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_products': totalProducts,
      'active_products': activeProducts,
      'low_stock_products': lowStockProducts,
      'out_of_stock_products': outOfStockProducts,
      'overstocked_products': overstockedProducts,
      'total_value': totalValue,
      'average_value': averageValue,
      'total_movements': totalMovements,
      'movements_this_month': movementsThisMonth,
      'top_categories': topCategories.map((c) => c.toJson()).toList(),
      'top_products': topProducts.map((p) => p.toJson()).toList(),
    };
  }
}
