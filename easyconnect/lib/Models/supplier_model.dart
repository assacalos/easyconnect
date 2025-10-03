class Supplier {
  final int? id;
  final String nom;
  final String email;
  final String telephone;
  final String adresse;
  final String ville;
  final String pays;
  final String contactPrincipal;
  final String? description;
  final String statut;
  final double? noteEvaluation;
  final String? commentaires;
  final DateTime createdAt;
  final DateTime updatedAt;

  Supplier({
    this.id,
    required this.nom,
    required this.email,
    required this.telephone,
    required this.adresse,
    required this.ville,
    required this.pays,
    required this.contactPrincipal,
    this.description,
    this.statut = 'pending',
    this.noteEvaluation,
    this.commentaires,
    required this.createdAt,
    required this.updatedAt,
  });

  // Méthodes utilitaires
  bool get isPending => statut == 'pending';
  bool get isApproved => statut == 'approved';
  bool get isRejected => statut == 'rejected';
  bool get isActive => statut == 'active';
  bool get isInactive => statut == 'inactive';

  String get statusText {
    switch (statut) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      case 'active':
        return 'Actif';
      case 'inactive':
        return 'Inactif';
      default:
        return 'Inconnu';
    }
  }

  String get statusColor {
    switch (statut) {
      case 'pending':
        return 'orange';
      case 'approved':
        return 'green';
      case 'rejected':
        return 'red';
      case 'active':
        return 'blue';
      case 'inactive':
        return 'grey';
      default:
        return 'grey';
    }
  }

  // Sérialisation JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'telephone': telephone,
      'adresse': adresse,
      'ville': ville,
      'pays': pays,
      'contact_principal': contactPrincipal,
      'description': description,
      'statut': statut,
      'note_evaluation': noteEvaluation,
      'commentaires': commentaires,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      nom: json['nom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'] ?? '',
      adresse: json['adresse'] ?? '',
      ville: json['ville'] ?? '',
      pays: json['pays'] ?? '',
      contactPrincipal: json['contact_principal'] ?? '',
      description: json['description'],
      statut: json['statut'] ?? 'pending',
      noteEvaluation:
          json['note_evaluation'] != null
              ? (json['note_evaluation'] is String
                  ? double.tryParse(json['note_evaluation'])
                  : json['note_evaluation']?.toDouble())
              : null,
      commentaires: json['commentaires'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  // Méthode de copie
  Supplier copyWith({
    int? id,
    String? nom,
    String? email,
    String? telephone,
    String? adresse,
    String? ville,
    String? pays,
    String? contactPrincipal,
    String? description,
    String? statut,
    double? noteEvaluation,
    String? commentaires,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      ville: ville ?? this.ville,
      pays: pays ?? this.pays,
      contactPrincipal: contactPrincipal ?? this.contactPrincipal,
      description: description ?? this.description,
      statut: statut ?? this.statut,
      noteEvaluation: noteEvaluation ?? this.noteEvaluation,
      commentaires: commentaires ?? this.commentaires,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Classe pour les statistiques
class SupplierStats {
  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final int active;
  final int inactive;
  final double averageRating;

  SupplierStats({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.active,
    required this.inactive,
    required this.averageRating,
  });

  factory SupplierStats.fromJson(Map<String, dynamic> json) {
    return SupplierStats(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      approved: json['approved'] ?? 0,
      rejected: json['rejected'] ?? 0,
      active: json['active'] ?? 0,
      inactive: json['inactive'] ?? 0,
      averageRating:
          json['average_rating'] != null
              ? (json['average_rating'] is String
                  ? double.tryParse(json['average_rating']) ?? 0.0
                  : (json['average_rating']?.toDouble() ?? 0.0))
              : 0.0,
    );
  }
}
