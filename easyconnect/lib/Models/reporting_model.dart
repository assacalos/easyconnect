class ReportingModel {
  final int id;
  final int userId;
  final String userName;
  final String userRole;
  final DateTime reportDate;
  final Map<String, dynamic> metrics;
  final String status; // 'draft', 'submitted', 'approved'
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final String? comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportingModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.reportDate,
    required this.metrics,
    required this.status,
    this.submittedAt,
    this.approvedAt,
    this.comments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReportingModel.fromJson(Map<String, dynamic> json) {
    return ReportingModel(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userRole: json['user_role'],
      reportDate: DateTime.parse(json['report_date']),
      metrics: Map<String, dynamic>.from(json['metrics']),
      status: json['status'],
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at']) : null,
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      comments: json['comments'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_role': userRole,
      'report_date': reportDate.toIso8601String(),
      'metrics': metrics,
      'status': status,
      'submitted_at': submittedAt?.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'comments': comments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// Métriques spécifiques pour chaque rôle
class CommercialMetrics {
  final int clientsProspectes;
  final int rdvObtenus;
  final List<RdvInfo> rdvList;
  final int devisCrees;
  final int devisAcceptes;
  final double chiffreAffaires;
  final int nouveauxClients;
  final int appelsEffectues;
  final int emailsEnvoyes;
  final int visitesRealisees;

  CommercialMetrics({
    required this.clientsProspectes,
    required this.rdvObtenus,
    required this.rdvList,
    required this.devisCrees,
    required this.devisAcceptes,
    required this.chiffreAffaires,
    required this.nouveauxClients,
    required this.appelsEffectues,
    required this.emailsEnvoyes,
    required this.visitesRealisees,
  });

  factory CommercialMetrics.fromJson(Map<String, dynamic> json) {
    return CommercialMetrics(
      clientsProspectes: json['clients_prospectes'] ?? 0,
      rdvObtenus: json['rdv_obtenus'] ?? 0,
      rdvList: (json['rdv_list'] as List<dynamic>?)
          ?.map((e) => RdvInfo.fromJson(e))
          .toList() ?? [],
      devisCrees: json['devis_crees'] ?? 0,
      devisAcceptes: json['devis_acceptes'] ?? 0,
      chiffreAffaires: (json['chiffre_affaires'] ?? 0).toDouble(),
      nouveauxClients: json['nouveaux_clients'] ?? 0,
      appelsEffectues: json['appels_effectues'] ?? 0,
      emailsEnvoyes: json['emails_envoyes'] ?? 0,
      visitesRealisees: json['visites_realisees'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clients_prospectes': clientsProspectes,
      'rdv_obtenus': rdvObtenus,
      'rdv_list': rdvList.map((e) => e.toJson()).toList(),
      'devis_crees': devisCrees,
      'devis_acceptes': devisAcceptes,
      'chiffre_affaires': chiffreAffaires,
      'nouveaux_clients': nouveauxClients,
      'appels_effectues': appelsEffectues,
      'emails_envoyes': emailsEnvoyes,
      'visites_realisees': visitesRealisees,
    };
  }
}

class RdvInfo {
  final String clientName;
  final DateTime dateRdv;
  final String heureRdv;
  final String typeRdv; // 'presentiel', 'telephone', 'video'
  final String status; // 'planifie', 'realise', 'annule'
  final String? notes;

  RdvInfo({
    required this.clientName,
    required this.dateRdv,
    required this.heureRdv,
    required this.typeRdv,
    required this.status,
    this.notes,
  });

  factory RdvInfo.fromJson(Map<String, dynamic> json) {
    return RdvInfo(
      clientName: json['client_name'],
      dateRdv: DateTime.parse(json['date_rdv']),
      heureRdv: json['heure_rdv'],
      typeRdv: json['type_rdv'],
      status: json['status'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_name': clientName,
      'date_rdv': dateRdv.toIso8601String(),
      'heure_rdv': heureRdv,
      'type_rdv': typeRdv,
      'status': status,
      'notes': notes,
    };
  }
}

class ComptableMetrics {
  final int facturesEmises;
  final int facturesPayees;
  final double montantFacture;
  final double montantEncaissement;
  final int bordereauxTraites;
  final int bonsCommandeTraites;
  final double chiffreAffaires;
  final int clientsFactures;
  final int relancesEffectuees;
  final double encaissements;

  ComptableMetrics({
    required this.facturesEmises,
    required this.facturesPayees,
    required this.montantFacture,
    required this.montantEncaissement,
    required this.bordereauxTraites,
    required this.bonsCommandeTraites,
    required this.chiffreAffaires,
    required this.clientsFactures,
    required this.relancesEffectuees,
    required this.encaissements,
  });

  factory ComptableMetrics.fromJson(Map<String, dynamic> json) {
    return ComptableMetrics(
      facturesEmises: json['factures_emises'] ?? 0,
      facturesPayees: json['factures_payees'] ?? 0,
      montantFacture: (json['montant_facture'] ?? 0).toDouble(),
      montantEncaissement: (json['montant_encaissement'] ?? 0).toDouble(),
      bordereauxTraites: json['bordereaux_traites'] ?? 0,
      bonsCommandeTraites: json['bons_commande_traites'] ?? 0,
      chiffreAffaires: (json['chiffre_affaires'] ?? 0).toDouble(),
      clientsFactures: json['clients_factures'] ?? 0,
      relancesEffectuees: json['relances_effectuees'] ?? 0,
      encaissements: (json['encaissements'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'factures_emises': facturesEmises,
      'factures_payees': facturesPayees,
      'montant_facture': montantFacture,
      'montant_encaissement': montantEncaissement,
      'bordereaux_traites': bordereauxTraites,
      'bons_commande_traites': bonsCommandeTraites,
      'chiffre_affaires': chiffreAffaires,
      'clients_factures': clientsFactures,
      'relances_effectuees': relancesEffectuees,
      'encaissements': encaissements,
    };
  }
}

class TechnicienMetrics {
  final int interventionsPlanifiees;
  final int interventionsRealisees;
  final int interventionsAnnulees;
  final List<InterventionInfo> interventionsList;
  final int clientsVisites;
  final int problemesResolus;
  final int problemesEnCours;
  final double tempsTravail;
  final int deplacements;
  final String? notesTechniques;

  TechnicienMetrics({
    required this.interventionsPlanifiees,
    required this.interventionsRealisees,
    required this.interventionsAnnulees,
    required this.interventionsList,
    required this.clientsVisites,
    required this.problemesResolus,
    required this.problemesEnCours,
    required this.tempsTravail,
    required this.deplacements,
    this.notesTechniques,
  });

  factory TechnicienMetrics.fromJson(Map<String, dynamic> json) {
    return TechnicienMetrics(
      interventionsPlanifiees: json['interventions_planifiees'] ?? 0,
      interventionsRealisees: json['interventions_realisees'] ?? 0,
      interventionsAnnulees: json['interventions_annulees'] ?? 0,
      interventionsList: (json['interventions_list'] as List<dynamic>?)
          ?.map((e) => InterventionInfo.fromJson(e))
          .toList() ?? [],
      clientsVisites: json['clients_visites'] ?? 0,
      problemesResolus: json['problemes_resolus'] ?? 0,
      problemesEnCours: json['problemes_en_cours'] ?? 0,
      tempsTravail: (json['temps_travail'] ?? 0).toDouble(),
      deplacements: json['deplacements'] ?? 0,
      notesTechniques: json['notes_techniques'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interventions_planifiees': interventionsPlanifiees,
      'interventions_realisees': interventionsRealisees,
      'interventions_annulees': interventionsAnnulees,
      'interventions_list': interventionsList.map((e) => e.toJson()).toList(),
      'clients_visites': clientsVisites,
      'problemes_resolus': problemesResolus,
      'problemes_en_cours': problemesEnCours,
      'temps_travail': tempsTravail,
      'deplacements': deplacements,
      'notes_techniques': notesTechniques,
    };
  }
}

class InterventionInfo {
  final String clientName;
  final DateTime dateIntervention;
  final String heureDebut;
  final String heureFin;
  final String typeIntervention;
  final String status;
  final String? description;
  final String? resultat;

  InterventionInfo({
    required this.clientName,
    required this.dateIntervention,
    required this.heureDebut,
    required this.heureFin,
    required this.typeIntervention,
    required this.status,
    this.description,
    this.resultat,
  });

  factory InterventionInfo.fromJson(Map<String, dynamic> json) {
    return InterventionInfo(
      clientName: json['client_name'],
      dateIntervention: DateTime.parse(json['date_intervention']),
      heureDebut: json['heure_debut'],
      heureFin: json['heure_fin'],
      typeIntervention: json['type_intervention'],
      status: json['status'],
      description: json['description'],
      resultat: json['resultat'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_name': clientName,
      'date_intervention': dateIntervention.toIso8601String(),
      'heure_debut': heureDebut,
      'heure_fin': heureFin,
      'type_intervention': typeIntervention,
      'status': status,
      'description': description,
      'resultat': resultat,
    };
  }
}
