import 'package:get/get.dart';

class BonCommandeItem {
  final int? id;
  final String designation;
  final String unite;
  final int quantite;
  final double prixUnitaire;
  final String? description;
  final DateTime? dateLivraison;

  BonCommandeItem({
    this.id,
    required this.designation,
    required this.unite,
    required this.quantite,
    required this.prixUnitaire,
    this.description,
    this.dateLivraison,
  });

  double get montantTotal => quantite * prixUnitaire;

  Map<String, dynamic> toJson() => {
    'id': id,
    'designation': designation,
    'unite': unite,
    'quantite': quantite,
    'prix_unitaire': prixUnitaire,
    'description': description,
    'date_livraison': dateLivraison?.toIso8601String(),
  };

  factory BonCommandeItem.fromJson(Map<String, dynamic> json) => BonCommandeItem(
    id: json['id'],
    designation: json['designation'],
    unite: json['unite'],
    quantite: json['quantite'],
    prixUnitaire: json['prix_unitaire']?.toDouble() ?? 0.0,
    description: json['description'],
    dateLivraison: json['date_livraison'] != null 
      ? DateTime.parse(json['date_livraison'])
      : null,
  );
}

class BonCommande {
  final int? id;
  final String reference;
  final int clientId;
  final int commercialId;
  final DateTime dateCreation;
  final DateTime? dateValidation;
  final DateTime? dateLivraisonPrevue;
  final String? adresseLivraison;
  final String? notes;
  final List<BonCommandeItem> items;
  final double? remiseGlobale;
  final double? tva;
  final String? conditions;
  final int status; // 0: brouillon, 1: soumis, 2: validé, 3: rejeté, 4: livré
  final String? commentaireRejet;
  final String? numeroFacture;
  final bool estFacture;
  final bool estLivre;

  BonCommande({
    this.id,
    required this.reference,
    required this.clientId,
    required this.commercialId,
    required this.dateCreation,
    this.dateValidation,
    this.dateLivraisonPrevue,
    this.adresseLivraison,
    this.notes,
    required this.items,
    this.remiseGlobale,
    this.tva = 20.0,
    this.conditions,
    this.status = 0,
    this.commentaireRejet,
    this.numeroFacture,
    this.estFacture = false,
    this.estLivre = false,
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
      case 4:
        return 'Livré';
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
    'date_livraison_prevue': dateLivraisonPrevue?.toIso8601String(),
    'adresse_livraison': adresseLivraison,
    'notes': notes,
    'items': items.map((item) => item.toJson()).toList(),
    'remise_globale': remiseGlobale,
    'tva': tva,
    'conditions': conditions,
    'status': status,
    'commentaire': commentaireRejet,
    'numero_facture': numeroFacture,
    'est_facture': estFacture ? 1 : 0,
    'est_livre': estLivre ? 1 : 0,
  };

  factory BonCommande.fromJson(Map<String, dynamic> json) => BonCommande(
    id: json['id'],
    reference: json['reference'],
    clientId: json['client_id'],
    commercialId: json['user_id'],
    dateCreation: DateTime.parse(json['date_creation']),
    dateValidation: json['date_validation'] != null 
      ? DateTime.parse(json['date_validation'])
      : null,
    dateLivraisonPrevue: json['date_livraison_prevue'] != null 
      ? DateTime.parse(json['date_livraison_prevue'])
      : null,
    adresseLivraison: json['adresse_livraison'],
    notes: json['notes'],
    items: (json['items'] as List)
      .map((item) => BonCommandeItem.fromJson(item))
      .toList(),
    remiseGlobale: json['remise_globale']?.toDouble(),
    tva: json['tva']?.toDouble(),
    conditions: json['conditions'],
    status: json['status'] ?? 0,
    commentaireRejet: json['commentaire'],
    numeroFacture: json['numero_facture'],
    estFacture: json['est_facture'] == 1,
    estLivre: json['est_livre'] == 1,
  );
}
