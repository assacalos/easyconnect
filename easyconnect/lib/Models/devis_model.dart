import 'package:flutter/material.dart';

class DevisItem {
  final int? id;
  final String designation;
  final int quantite;
  final double prixUnitaire;
  final double? remise;

  DevisItem({
    this.id,
    required this.designation,
    required this.quantite,
    required this.prixUnitaire,
    this.remise,
  });

  double get total {
    final sousTotal = quantite * prixUnitaire;
    if (remise != null && remise! > 0) {
      return sousTotal * (1 - remise! / 100);
    }
    return sousTotal;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'designation': designation,
      'quantite': quantite,
      'prix_unitaire': prixUnitaire,
      'remise': remise,
    };
  }

  factory DevisItem.fromJson(Map<String, dynamic> json) {
    return DevisItem(
      id: json['id'],
      designation: json['designation'],
      quantite: json['quantite'],
      prixUnitaire: json['prix_unitaire'].toDouble(),
      remise: json['remise']?.toDouble(),
    );
  }
}

class Devis {
  final int? id;
  final int clientId;
  final String reference;
  final DateTime dateCreation;
  final DateTime? dateValidite;
  final String? notes;
  final int status; // 0: brouillon, 1: envoyé, 2: accepté, 3: refusé
  final List<DevisItem> items;
  final double? remiseGlobale;
  final double? tva;
  final String? conditions;
  final String? commentaire;
  final int commercialId;

  Devis({
    this.id,
    required this.clientId,
    required this.reference,
    required this.dateCreation,
    this.dateValidite,
    this.notes,
    this.status = 0,
    required this.items,
    this.remiseGlobale,
    this.tva,
    this.conditions,
    this.commentaire,
    required this.commercialId,
  });

  double get sousTotal {
    return items.fold(0, (sum, item) => sum + item.total);
  }

  double get remise {
    if (remiseGlobale != null && remiseGlobale! > 0) {
      return sousTotal * (remiseGlobale! / 100);
    }
    return 0;
  }

  double get totalHT {
    return sousTotal - remise;
  }

  double get montantTVA {
    if (tva != null && tva! > 0) {
      return totalHT * (tva! / 100);
    }
    return 0;
  }

  double get totalTTC {
    return totalHT + montantTVA;
  }

  String get statusText {
    switch (status) {
      case 1:
        return "Envoyé";
      case 2:
        return "Accepté";
      case 3:
        return "Refusé";
      default:
        return "Brouillon";
    }
  }

  Color get statusColor {
    switch (status) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 1:
        return Icons.send;
      case 2:
        return Icons.check_circle;
      case 3:
        return Icons.cancel;
      default:
        return Icons.edit;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'reference': reference,
      'date_creation': dateCreation.toIso8601String(),
      'date_validite': dateValidite?.toIso8601String(),
      'notes': notes,
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
      'remise_globale': remiseGlobale,
      'tva': tva,
      'conditions': conditions,
      'commentaire': commentaire,
      'user_id': commercialId,
    };
  }

  factory Devis.fromJson(Map<String, dynamic> json) {
    return Devis(
      id: json['id'],
      clientId: json['client_id'],
      reference: json['reference'],
      dateCreation: DateTime.parse(json['date_creation']),
      dateValidite:
          json['date_validite'] != null
              ? DateTime.parse(json['date_validite'])
              : null,
      notes: json['notes'],
      status: json['status'],
      items:
          (json['items'] as List)
              .map((item) => DevisItem.fromJson(item))
              .toList(),
      remiseGlobale: json['remise_globale']?.toDouble(),
      tva: json['tva']?.toDouble(),
      conditions: json['conditions'],
      commentaire: json['commentaire'],
      commercialId: json['user_id'],
    );
  }
}
