import 'dart:convert';

class BonCommande {
  final int? id;
  final int clientId;
  final int commercialId;
  final List<String> fichiers; // Chemins/URLs des fichiers scannés
  final int status; // 1: soumis, 2: validé, 3: rejeté, 4: livré

  BonCommande({
    this.id,
    required this.clientId,
    required this.commercialId,
    this.fichiers = const [],
    this.status = 1,
  });

  String get statusText {
    switch (status) {
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
    'client_id': clientId,
    'user_id': commercialId,
    'fichiers': fichiers,
    'status': status,
  };

  /// Méthode pour créer un JSON uniquement avec les champs nécessaires à la création
  Map<String, dynamic> toJsonForCreate() => {
    'client_id': clientId,
    'user_id': commercialId,
    'fichiers': fichiers,
    'status': status,
  };

  factory BonCommande.fromJson(Map<String, dynamic> json) {
    // Parser les fichiers (peuvent être une liste ou une chaîne JSON)
    List<String> fichiersList = [];
    if (json['fichiers'] != null) {
      if (json['fichiers'] is List) {
        fichiersList =
            (json['fichiers'] as List).map((f) => f.toString()).toList();
      } else if (json['fichiers'] is String) {
        try {
          final parsed = jsonDecode(json['fichiers']);
          if (parsed is List) {
            fichiersList = parsed.map((f) => f.toString()).toList();
          }
        } catch (e) {
          // Si ce n'est pas du JSON valide, traiter comme une chaîne simple
          fichiersList = [json['fichiers']];
        }
      }
    }

    return BonCommande(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      clientId:
          (json['client_id'] ?? json['cliennt_id'] ?? json['clieent_id'])
                  is String
              ? int.tryParse(
                json['client_id'] ?? json['cliennt_id'] ?? json['clieent_id'],
              )
              : (json['client_id'] ?? json['cliennt_id'] ?? json['clieent_id']),
      commercialId:
          json['user_id'] is String
              ? int.tryParse(json['user_id'])
              : json['user_id'],
      fichiers: fichiersList,
      status: _parseStatus(json['status']),
    );
  }

  static int _parseStatus(dynamic status) {
    if (status == null) return 0;
    if (status is int) return status;
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'en_attente':
        case 'en attente':
          return 1;
        case 'valide':
        case 'validé':
        case 'accepte':
        case 'accepté':
          return 2;
        case 'rejete':
        case 'rejeté':
        case 'refuse':
        case 'refusé':
          return 3;
        case 'livre':
        case 'livré':
          return 4;
        case 'en_cours':
        case 'en cours':
          return 2; // En cours = validé
        default:
          return 0;
      }
    }
    return 0;
  }
}
