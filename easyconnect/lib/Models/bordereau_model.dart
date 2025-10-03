class BordereauItem {
  final int? id;
  final String designation;
  final String unite;
  final int quantite;
  final double prixUnitaire;
  final String? description;

  BordereauItem({
    this.id,
    required this.designation,
    required this.unite,
    required this.quantite,
    required this.prixUnitaire,
    this.description,
  });

  double get montantTotal => quantite * prixUnitaire;

  Map<String, dynamic> toJson() => {
    'id': id,
    'designation': designation,
    'unite': unite,
    'quantite': quantite,
    'prix_unitaire': prixUnitaire,
    'description': description,
  };

  factory BordereauItem.fromJson(Map<String, dynamic> json) => BordereauItem(
    id: json['id'],
    designation: json['designation'],
    unite: json['unite'],
    quantite:
        json['quantite'] is String
            ? int.tryParse(json['quantite']) ?? 0
            : json['quantite'],
    prixUnitaire:
        json['prix_unitaire'] is String
            ? double.tryParse(json['prix_unitaire']) ?? 0.0
            : (json['prix_unitaire']?.toDouble() ?? 0.0),
    description: json['description'],
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
  final double? remiseGlobale;
  final double? tva;
  final String? conditions;
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
    this.remiseGlobale,
    this.tva = 20.0,
    this.conditions,
    this.status = 1,
    this.commentaireRejet,
  });

  double get montantHT {
    double total = items.fold(0, (sum, item) => sum + item.montantTotal);
    if (remiseGlobale != null) {
      total = total * (1 - remiseGlobale! / 100);
    }
    return total;
  }

  double get montantTVA => tva != null ? montantHT * (tva! / 100) : 0.0;
  double get montantTTC => montantHT + montantTVA;

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
    'remise_globale': remiseGlobale?.toString(),
    'tva': tva?.toString(),
    'conditions': conditions,
    'status': status,
    'commentaire': commentaireRejet,
  };

  factory Bordereau.fromJson(Map<String, dynamic> json) => Bordereau(
    id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
    reference: json['reference'],
    clientId:
        (json['client_id'] ?? json['cliennt_id'] ?? json['clieent_id'])
                is String
            ? int.tryParse(
              json['client_id'] ?? json['cliennt_id'] ?? json['clieent_id'],
            )
            : (json['client_id'] ?? json['cliennt_id'] ?? json['clieent_id']),
    devisId: json['devis_id'] is String 
        ? int.tryParse(json['devis_id']) 
        : json['devis_id'],
    commercialId:
        json['user_id'] is String
            ? int.tryParse(json['user_id'])
            : json['user_id'],
    dateCreation: DateTime.parse(json['date_creation']),
    dateValidation:
        json['date_validation'] != null
            ? DateTime.parse(json['date_validation'])
            : null,
    notes: json['notes'],
    items:
        (json['items'] as List)
            .map((item) => BordereauItem.fromJson(item))
            .toList(),
    remiseGlobale:
        json['remise_globale'] is String
            ? double.tryParse(json['remise_globale'])
            : json['remise_globale']?.toDouble(),
    tva:
        json['tva'] is String
            ? double.tryParse(json['tva'])
            : json['tva']?.toDouble(),
    conditions: json['conditions'],
    status:
        json['status'] is String
            ? int.tryParse(json['status'])
            : json['status'] ?? 1,
    commentaireRejet: json['commentaire'],
  );
}
