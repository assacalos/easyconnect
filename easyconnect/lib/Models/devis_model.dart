import 'package:flutter/material.dart';

class DevisItem {
  final int? id;
  final String designation;
  final int quantite;
  final double prixUnitaire;

  DevisItem({
    this.id,
    required this.designation,
    required this.quantite,
    required this.prixUnitaire,
  });

  double get total {
    return quantite * prixUnitaire;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'designation': designation,
      'quantite': quantite,
      'prix_unitaire': prixUnitaire,
    };
  }

  factory DevisItem.fromJson(Map<String, dynamic> json) {
    return DevisItem(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      designation: json['designation'],
      quantite:
          json['quantite'] is String
              ? int.tryParse(json['quantite']) ?? 0
              : json['quantite'],
      prixUnitaire: _parseDouble(json['prix_unitaire']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0.0;
  }
}

class Devis {
  final int? id;
  final int clientId;
  final String reference;
  final DateTime dateCreation;
  final DateTime? dateValidite;
  final String? notes;
  final int status; // 1: envoyé, 2: accepté, 3: refusé
  final List<DevisItem> items;
  final double? remiseGlobale;
  final double? tva;
  final String? conditions;
  final String? commentaire;
  final int commercialId;
  final String? submittedBy; // Nom de l'utilisateur qui a soumis
  final String? rejectionComment; // Commentaire de rejet du patron
  final DateTime? submittedAt; // Date de soumission
  final DateTime? validatedAt; // Date de validation

  Devis({
    this.id,
    required this.clientId,
    required this.reference,
    required this.dateCreation,
    this.dateValidite,
    this.notes,
    this.status = 1,
    required this.items,
    this.remiseGlobale,
    this.tva,
    this.conditions,
    this.commentaire,
    required this.commercialId,
    this.submittedBy,
    this.rejectionComment,
    this.submittedAt,
    this.validatedAt,
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
        return "En attente";
      case 2:
        return "Validé";
      case 3:
        return "Rejeté";
      default:
        return "Inconnu";
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
        return Icons.access_time;
      case 2:
        return Icons.check_circle;
      case 3:
        return Icons.cancel;
      default:
        return Icons.help;
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
      'submitted_by': submittedBy,
      'rejection_comment': rejectionComment,
      'submitted_at': submittedAt?.toIso8601String(),
      'validated_at': validatedAt?.toIso8601String(),
    };
  }

  factory Devis.fromJson(Map<String, dynamic> json) {
    return Devis(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      clientId:
          (json['client_id'] ?? json['cliennt_id'] ?? json['clieent_id'])
                  is String
              ? int.tryParse(
                json['client_id'] ?? json['cliennt_id'] ?? json['clieent_id'],
              )
              : (json['client_id'] ?? json['cliennt_id'] ?? json['clieent_id']),
      reference: json['reference'],
      dateCreation: DateTime.parse(json['date_creation']),
      dateValidite:
          json['date_validite'] != null
              ? DateTime.parse(json['date_validite'])
              : null,
      notes: json['notes'],
      status:
          json['status'] is String
              ? int.tryParse(json['status']) ?? 0
              : json['status'],
      items:
          (json['items'] as List)
              .map((item) => DevisItem.fromJson(item))
              .toList(),
      remiseGlobale:
          json['remise_globale'] != null
              ? _parseDouble(json['remise_globale'])
              : null,
      tva: json['tva'] != null ? _parseDouble(json['tva']) : null,
      conditions: json['conditions'],
      commentaire: json['commentaire'],
      commercialId: json['user_id'],
      submittedBy: json['submitted_by'],
      rejectionComment: json['rejection_comment'],
      submittedAt:
          json['submitted_at'] != null
              ? DateTime.parse(json['submitted_at'])
              : null,
      validatedAt:
          json['validated_at'] != null
              ? DateTime.parse(json['validated_at'])
              : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0.0;
  }
}
