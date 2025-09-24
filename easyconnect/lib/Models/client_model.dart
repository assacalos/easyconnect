import 'dart:ui';

import 'package:flutter/material.dart';

class Client {
  final int? id;
  final String? nom;
  final String? prenom;
  final String? email;
  final String? contact;
  final String? adresse;
  final String? nomEntreprise;
  final String? situationGeographique;
  final int? status; // 0: en attente, 1: validé, 2: rejeté
  final String? commentaire;
  final String? createdAt;
  final String? updatedAt;
  final int? commercialId;

  Client({
    this.id,
    this.nom,
    this.prenom,
    this.email,
    this.contact,
    this.adresse,
    this.nomEntreprise,
    this.situationGeographique,
    this.status = 0,
    this.commentaire,
    this.createdAt,
    this.updatedAt,
    this.commercialId,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      contact: json['contact'],
      adresse: json['adresse'],
      nomEntreprise: json['nom_entreprise'],
      situationGeographique: json['situation_geographique'],
      status: json['status'],
      commentaire: json['commentaire'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      commercialId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'contact': contact,
      'adresse': adresse,
      'nom_entreprise': nomEntreprise,
      'situation_geographique': situationGeographique,
      'status': status,
      'commentaire': commentaire,
      'user_id': commercialId,
    };
  }

  String get statusText {
    switch (status) {
      case 1:
        return "Validé";
      case 2:
        return "Rejeté";
      default:
        return "En attente";
    }
  }

  Color get statusColor {
    switch (status) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 1:
        return Icons.check_circle;
      case 2:
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }
}
