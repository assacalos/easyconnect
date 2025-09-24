import 'package:get/get.dart';

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
    quantite: json['quantite'],
    prixUnitaire: json['prix_unitaire']?.toDouble() ?? 0.0,
    description: json['description'],
  );
}

class Bordereau {
  final int? id;
  final String reference;
  final int clientId;
  final int commercialId;
  final DateTime dateCreation;
  final DateTime? dateValidation;
  final String? notes;
  final List<BordereauItem> items;
  final double? remiseGlobale;
  final double? tva;
  final String? conditions;
  final int status; // 0: brouillon, 1: soumis, 2: validé, 3: rejeté
  final String? commentaireRejet;

  Bordereau({
    this.id,
    required this.reference,
    required this.clientId,
    required this.commercialId,
    required this.dateCreation,
    this.dateValidation,
    this.notes,
    required this.items,
    this.remiseGlobale,
    this.tva = 20.0,
    this.conditions,
    this.status = 0,
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
      case 0:
        return 'Brouillon';
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
    'user_id': commercialId,
    'date_creation': dateCreation.toIso8601String(),
    'date_validation': dateValidation?.toIso8601String(),
    'notes': notes,
    'items': items.map((item) => item.toJson()).toList(),
    'remise_globale': remiseGlobale,
    'tva': tva,
    'conditions': conditions,
    'status': status,
    'commentaire': commentaireRejet,
  };

  factory Bordereau.fromJson(Map<String, dynamic> json) => Bordereau(
    id: json['id'],
    reference: json['reference'],
    clientId: json['client_id'],
    commercialId: json['user_id'],
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
    remiseGlobale: json['remise_globale']?.toDouble(),
    tva: json['tva']?.toDouble(),
    conditions: json['conditions'],
    status: json['status'] ?? 0,
    commentaireRejet: json['commentaire'],
  );
}
