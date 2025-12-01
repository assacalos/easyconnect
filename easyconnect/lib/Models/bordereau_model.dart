class BordereauItem {
  final int? id;
  final String designation;
  final String unite;
  final int quantite;
  final String? description;

  BordereauItem({
    this.id,
    required this.designation,
    required this.unite,
    required this.quantite,
    this.description,
  });

  double get montantTotal => 0.0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'designation': designation,
    'unite': unite,
    'quantite': quantite,
    'description': description,
  };

  factory BordereauItem.fromJson(Map<String, dynamic> json) => BordereauItem(
    id:
        json['id'] != null
            ? (json['id'] is String
                ? int.tryParse(json['id'])
                : json['id'] is int
                ? json['id']
                : null)
            : null,
    designation: json['designation']?.toString() ?? '',
    unite: json['unite']?.toString() ?? 'unité',
    quantite:
        json['quantite'] is String
            ? int.tryParse(json['quantite']) ?? 0
            : (json['quantite'] is int
                ? json['quantite']
                : (json['quantite'] is num ? json['quantite'].toInt() : 0)),
    description: json['description']?.toString(),
  );
}

class Bordereau {
  final int? id;
  final String reference;
  final int clientId;
  final int? devisId; // Référence au devis
  final int commercialId;
  final DateTime dateCreation;
  final DateTime? dateValidation;
  final String? notes;
  final List<BordereauItem> items;
  final int status; // 1: soumis, 2: validé, 3: rejeté
  final String? commentaireRejet;

  Bordereau({
    this.id,
    required this.reference,
    required this.clientId,
    this.devisId,
    required this.commercialId,
    required this.dateCreation,
    this.dateValidation,
    this.notes,
    required this.items,
    this.status = 1,
    this.commentaireRejet,
  });

  double get montantHT => 0.0;

  double get montantTVA => 0.0;
  double get montantTTC => 0.0;

  String get statusText {
    switch (status) {
      case 1:
        return 'En attente';
      case 2:
        return 'Validé';
      case 3:
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'reference': reference,
    'client_id': clientId,
    'devis_id': devisId,
    'user_id': commercialId,
    'date_creation': dateCreation.toIso8601String(),
    'date_validation': dateValidation?.toIso8601String(),
    'notes': notes,
    'items': items.map((item) => item.toJson()).toList(),
    'status': status,
    'commentaire': commentaireRejet,
  };

  factory Bordereau.fromJson(Map<String, dynamic> json) {
    try {
      // Gérer les dates mal formées (ex: "22025-10-20" ou avec espaces)
      DateTime? parseDate(dynamic dateValue) {
        if (dateValue == null) return null;
        if (dateValue is DateTime) return dateValue;
        if (dateValue is String) {
          final trimmed = dateValue.trim();
          if (trimmed.isEmpty || trimmed == 'null' || trimmed == 'NULL')
            return null;
          // Corriger "22025" en "2025"
          final corrected = trimmed.replaceFirst('22025', '2025');
          try {
            return DateTime.parse(corrected);
          } catch (e) {
            return null;
          }
        }
        return null;
      }

      return Bordereau(
        id: _parseInt(json['id']),
        reference: json['reference']?.toString() ?? '',
        clientId:
            _parseInt(
              json['client_id'] ?? json['cliennt_id'] ?? json['clieent_id'],
            ) ??
            0,
        devisId: _parseInt(json['devis_id']),
        commercialId: _parseInt(json['user_id']) ?? 0,
        dateCreation:
            parseDate(
              json['date_creation'] ??
                  json['date_creaation'] ??
                  json['date_creatio'],
            ) ??
            DateTime.now(),
        dateValidation: parseDate(json['date_validation']),
        notes: json['notes']?.toString(),
        items:
            json['items'] != null && json['items'] is List
                ? (json['items'] as List)
                    .map(
                      (item) => BordereauItem.fromJson(
                        item is Map<String, dynamic>
                            ? item
                            : Map<String, dynamic>.from(item),
                      ),
                    )
                    .toList()
                : [],
        status: _parseInt(json['status']) ?? 1,
        commentaireRejet: json['commentaire']?.toString(),
      );
    } catch (e, stackTrace) {
      print('❌ Bordereau.fromJson: Erreur: $e');
      print('❌ Bordereau.fromJson: Stack trace: $stackTrace');
      print('❌ Bordereau.fromJson: JSON: $json');
      rethrow;
    }
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == 'null' || trimmed == 'NULL')
        return null;
      return int.tryParse(trimmed);
    }
    if (value is num) {
      try {
        return value.toInt();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == 'null' || trimmed == 'NULL')
        return null;
      try {
        return double.tryParse(trimmed);
      } catch (e) {
        return null;
      }
    }
    if (value is num) {
      try {
        return value.toDouble();
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
