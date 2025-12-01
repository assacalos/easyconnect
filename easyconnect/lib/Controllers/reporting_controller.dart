import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/reporting_model.dart';
import 'package:easyconnect/services/reporting_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/roles.dart';

class ReportingController extends GetxController {
  final ReportingService _reportingService = Get.find<ReportingService>();
  final AuthController _authController = Get.find<AuthController>();

  // Observables
  var isLoading = false.obs;
  var reports = <ReportingModel>[].obs;
  var currentReport = Rxn<ReportingModel>();
  var selectedDate = DateTime.now().obs;
  var selectedUserRole = Rxn<String>();
  var startDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  var endDate = DateTime.now().obs;

  // Métriques spécifiques par rôle
  var commercialMetrics = Rxn<CommercialMetrics>();
  var comptableMetrics = Rxn<ComptableMetrics>();
  var technicienMetrics = Rxn<TechnicienMetrics>();
  var rhMetrics = Rxn<RhMetrics>();

  // Formulaires
  final commentsController = TextEditingController();
  final rdvClientController = TextEditingController();
  final rdvDateController = TextEditingController();
  final rdvHeureController = TextEditingController();
  final rdvTypeController = TextEditingController();
  final rdvNotesController = TextEditingController();

  // Contrôleurs pour les notes des métriques
  final noteClientsProspectesController = TextEditingController();
  final noteDevisCreesController = TextEditingController();
  final noteDevisAcceptesController = TextEditingController();
  final noteNouveauxClientsController = TextEditingController();
  final noteAppelsEffectuesController = TextEditingController();
  final noteEmailsEnvoyesController = TextEditingController();
  final noteVisitesRealiseesController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Ne pas charger automatiquement - laisser les pages décider quand charger
    // loadReports(); // Désactivé pour éviter les chargements inutiles
  }

  @override
  void onClose() {
    commentsController.dispose();
    rdvClientController.dispose();
    rdvDateController.dispose();
    rdvHeureController.dispose();
    rdvTypeController.dispose();
    rdvNotesController.dispose();
    super.onClose();
  }

  // Charger les rapports
  Future<void> loadReports() async {
    try {
      isLoading.value = true;

      final userRole = _authController.userAuth.value?.role;
      final userId = _authController.userAuth.value?.id;

      if (userRole == Roles.ADMIN || userRole == Roles.PATRON) {
        // Le patron peut voir tous les rapports
        reports.value = await _reportingService.getAllReports(
          startDate: startDate.value,
          endDate: endDate.value,
          userRole: selectedUserRole.value,
        );
      } else {
        // Les autres utilisateurs voient leurs propres rapports
        final userReports = await _reportingService.getUserReports(
          userId: userId!,
          startDate: startDate.value,
          endDate: endDate.value,
        );

        // Filtrer également par rôle pour s'assurer que l'utilisateur ne voit que les reporting de son propre rôle
        final userRoleName = Roles.getRoleName(userRole);
        reports.value =
            userReports.where((report) {
              // Vérifier que le reporting appartient à l'utilisateur ET correspond à son rôle
              return report.userId == userId &&
                  report.userRole.toLowerCase() == userRoleName.toLowerCase();
            }).toList();
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors du chargement des rapports: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Créer un nouveau rapport
  Future<void> createReport() async {
    try {
      isLoading.value = true;

      final userRole = _authController.userAuth.value?.role;
      final userId = _authController.userAuth.value?.id;

      Map<String, dynamic> metrics = {};

      // Générer les métriques selon le rôle
      switch (userRole) {
        case Roles.COMMERCIAL:
          metrics = _generateCommercialMetrics();
          break;
        case Roles.COMPTABLE:
          metrics = _generateComptableMetrics();
          break;
        case Roles.TECHNICIEN:
          metrics = _generateTechnicienMetrics();
          break;
        case Roles.RH:
          metrics = _generateRhMetrics();
          break;
        default:
          metrics = {};
      }

      await _reportingService.createReport(
        userId: userId!,
        userRole: Roles.getRoleName(userRole),
        reportDate: selectedDate.value,
        metrics: metrics,
        comments: commentsController.text,
      );

      Get.snackbar('Succès', 'Rapport créé avec succès');
      loadReports();
      clearForm();
      // Navigation automatique vers la page de liste des reportings
      Get.offNamed('/reporting');
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la création du rapport: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Soumettre un rapport
  Future<void> submitReport(int reportId) async {
    try {
      isLoading.value = true;

      await _reportingService.submitReport(reportId);
      Get.snackbar('Succès', 'Rapport soumis avec succès');
      loadReports();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la soumission du rapport: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Approuver un rapport (patron seulement)
  Future<void> approveReport(int reportId) async {
    try {
      isLoading.value = true;

      await _reportingService.approveReport(
        reportId,
        comments: commentsController.text,
      );
      Get.snackbar('Succès', 'Rapport approuvé avec succès');
      loadReports();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de l\'approbation du rapport: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Rejeter un rapport (patron seulement)
  Future<void> rejectReport(int reportId, {String? reason}) async {
    try {
      isLoading.value = true;

      await _reportingService.rejectReport(
        reportId,
        comments: reason ?? commentsController.text,
      );
      Get.snackbar('Succès', 'Rapport rejeté avec succès');
      loadReports();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors du rejet du rapport: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Ajouter un RDV (pour commercial)
  void addRdv() {
    if (rdvClientController.text.isEmpty ||
        rdvDateController.text.isEmpty ||
        rdvHeureController.text.isEmpty) {
      Get.snackbar('Erreur', 'Veuillez remplir tous les champs du RDV');
      return;
    }

    final rdv = RdvInfo(
      clientName: rdvClientController.text,
      dateRdv: DateTime.parse(rdvDateController.text),
      heureRdv: rdvHeureController.text,
      typeRdv:
          rdvTypeController.text.isNotEmpty
              ? rdvTypeController.text
              : 'presentiel',
      status: 'planifie',
      notes: rdvNotesController.text,
    );

    // Ajouter le RDV à la liste des RDV du commercial
    final currentMetrics =
        commercialMetrics.value ??
        CommercialMetrics(
          clientsProspectes: 0,
          rdvObtenus: 0,
          rdvList: [],
          devisCrees: 0,
          devisAcceptes: 0,
          nouveauxClients: 0,
          appelsEffectues: 0,
          emailsEnvoyes: 0,
          visitesRealisees: 0,
        );

    final updatedRdvList = List<RdvInfo>.from(currentMetrics.rdvList)..add(rdv);

    commercialMetrics.value = CommercialMetrics(
      clientsProspectes: currentMetrics.clientsProspectes,
      rdvObtenus: updatedRdvList.length,
      rdvList: updatedRdvList,
      devisCrees: currentMetrics.devisCrees,
      devisAcceptes: currentMetrics.devisAcceptes,
      nouveauxClients: currentMetrics.nouveauxClients,
      appelsEffectues: currentMetrics.appelsEffectues,
      emailsEnvoyes: currentMetrics.emailsEnvoyes,
      visitesRealisees: currentMetrics.visitesRealisees,
    );

    // Vider les champs
    rdvClientController.clear();
    rdvDateController.clear();
    rdvHeureController.clear();
    rdvTypeController.clear();
    rdvNotesController.clear();

    Get.snackbar('Succès', 'RDV ajouté avec succès');
  }

  // Générer les métriques commercial
  Map<String, dynamic> _generateCommercialMetrics() {
    final metrics =
        commercialMetrics.value ??
        CommercialMetrics(
          clientsProspectes: 0,
          rdvObtenus: 0,
          rdvList: [],
          devisCrees: 0,
          devisAcceptes: 0,
          nouveauxClients: 0,
          appelsEffectues: 0,
          emailsEnvoyes: 0,
          visitesRealisees: 0,
        );

    return metrics.toJson();
  }

  // Générer les métriques comptable
  Map<String, dynamic> _generateComptableMetrics() {
    final metrics =
        comptableMetrics.value ??
        ComptableMetrics(
          facturesEmises: 0,
          facturesPayees: 0,
          montantFacture: 0,
          montantEncaissement: 0,
          bordereauxTraites: 0,
          bonsCommandeTraites: 0,
          chiffreAffaires: 0,
          clientsFactures: 0,
          relancesEffectuees: 0,
          encaissements: 0,
        );

    return metrics.toJson();
  }

  // Générer les métriques technicien
  Map<String, dynamic> _generateTechnicienMetrics() {
    final metrics =
        technicienMetrics.value ??
        TechnicienMetrics(
          interventionsPlanifiees: 0,
          interventionsRealisees: 0,
          interventionsAnnulees: 0,
          interventionsList: [],
          clientsVisites: 0,
          problemesResolus: 0,
          problemesEnCours: 0,
          tempsTravail: 0,
          deplacements: 0,
        );

    return metrics.toJson();
  }

  // Générer les métriques RH
  Map<String, dynamic> _generateRhMetrics() {
    final metrics =
        rhMetrics.value ??
        RhMetrics(
          employesRecrutes: 0,
          demandesCongeTraitees: 0,
          demandesCongeApprouvees: 0,
          demandesCongeRejetees: 0,
          contratsCrees: 0,
          contratsRenouveles: 0,
          pointagesValides: 0,
          entretiensRealises: 0,
          formationsOrganisees: 0,
          evaluationsEffectuees: 0,
        );

    return metrics.toJson();
  }

  // Mettre à jour les métriques commercial
  void updateCommercialMetrics({
    int? clientsProspectes,
    int? devisCrees,
    int? devisAcceptes,
    int? nouveauxClients,
    int? appelsEffectues,
    int? emailsEnvoyes,
    int? visitesRealisees,
    String? noteClientsProspectes,
    String? noteDevisCrees,
    String? noteDevisAcceptes,
    String? noteNouveauxClients,
    String? noteAppelsEffectues,
    String? noteEmailsEnvoyes,
    String? noteVisitesRealisees,
  }) {
    final current =
        commercialMetrics.value ??
        CommercialMetrics(
          clientsProspectes: 0,
          rdvObtenus: 0,
          rdvList: [],
          devisCrees: 0,
          devisAcceptes: 0,
          nouveauxClients: 0,
          appelsEffectues: 0,
          emailsEnvoyes: 0,
          visitesRealisees: 0,
        );

    commercialMetrics.value = CommercialMetrics(
      clientsProspectes: clientsProspectes ?? current.clientsProspectes,
      rdvObtenus: current.rdvObtenus,
      rdvList: current.rdvList,
      devisCrees: devisCrees ?? current.devisCrees,
      devisAcceptes: devisAcceptes ?? current.devisAcceptes,
      nouveauxClients: nouveauxClients ?? current.nouveauxClients,
      appelsEffectues: appelsEffectues ?? current.appelsEffectues,
      emailsEnvoyes: emailsEnvoyes ?? current.emailsEnvoyes,
      visitesRealisees: visitesRealisees ?? current.visitesRealisees,
      noteClientsProspectes:
          noteClientsProspectes ?? current.noteClientsProspectes,
      noteRdvObtenus: current.noteRdvObtenus,
      noteDevisCrees: noteDevisCrees ?? current.noteDevisCrees,
      noteDevisAcceptes: noteDevisAcceptes ?? current.noteDevisAcceptes,
      noteNouveauxClients: noteNouveauxClients ?? current.noteNouveauxClients,
      noteAppelsEffectues: noteAppelsEffectues ?? current.noteAppelsEffectues,
      noteEmailsEnvoyes: noteEmailsEnvoyes ?? current.noteEmailsEnvoyes,
      noteVisitesRealisees:
          noteVisitesRealisees ?? current.noteVisitesRealisees,
    );
  }

  // Mettre à jour les métriques comptable
  void updateComptableMetrics({
    int? facturesEmises,
    int? facturesPayees,
    double? montantFacture,
    double? montantEncaissement,
    int? bordereauxTraites,
    int? bonsCommandeTraites,
    double? chiffreAffaires,
    int? clientsFactures,
    int? relancesEffectuees,
    double? encaissements,
    String? noteFacturesEmises,
    String? noteFacturesPayees,
    String? noteMontantFacture,
    String? noteMontantEncaissement,
    String? noteBordereauxTraites,
    String? noteBonsCommandeTraites,
    String? noteChiffreAffaires,
    String? noteClientsFactures,
    String? noteRelancesEffectuees,
    String? noteEncaissements,
  }) {
    final current =
        comptableMetrics.value ??
        ComptableMetrics(
          facturesEmises: 0,
          facturesPayees: 0,
          montantFacture: 0,
          montantEncaissement: 0,
          bordereauxTraites: 0,
          bonsCommandeTraites: 0,
          chiffreAffaires: 0,
          clientsFactures: 0,
          relancesEffectuees: 0,
          encaissements: 0,
        );

    comptableMetrics.value = ComptableMetrics(
      facturesEmises: facturesEmises ?? current.facturesEmises,
      facturesPayees: facturesPayees ?? current.facturesPayees,
      montantFacture: montantFacture ?? current.montantFacture,
      montantEncaissement: montantEncaissement ?? current.montantEncaissement,
      bordereauxTraites: bordereauxTraites ?? current.bordereauxTraites,
      bonsCommandeTraites: bonsCommandeTraites ?? current.bonsCommandeTraites,
      chiffreAffaires: chiffreAffaires ?? current.chiffreAffaires,
      clientsFactures: clientsFactures ?? current.clientsFactures,
      relancesEffectuees: relancesEffectuees ?? current.relancesEffectuees,
      encaissements: encaissements ?? current.encaissements,
      noteFacturesEmises: noteFacturesEmises ?? current.noteFacturesEmises,
      noteFacturesPayees: noteFacturesPayees ?? current.noteFacturesPayees,
      noteMontantFacture: noteMontantFacture ?? current.noteMontantFacture,
      noteMontantEncaissement:
          noteMontantEncaissement ?? current.noteMontantEncaissement,
      noteBordereauxTraites:
          noteBordereauxTraites ?? current.noteBordereauxTraites,
      noteBonsCommandeTraites:
          noteBonsCommandeTraites ?? current.noteBonsCommandeTraites,
      noteChiffreAffaires: noteChiffreAffaires ?? current.noteChiffreAffaires,
      noteClientsFactures: noteClientsFactures ?? current.noteClientsFactures,
      noteRelancesEffectuees:
          noteRelancesEffectuees ?? current.noteRelancesEffectuees,
      noteEncaissements: noteEncaissements ?? current.noteEncaissements,
    );
  }

  // Mettre à jour les métriques technicien
  void updateTechnicienMetrics({
    int? interventionsPlanifiees,
    int? interventionsRealisees,
    int? interventionsAnnulees,
    int? clientsVisites,
    int? problemesResolus,
    int? problemesEnCours,
    double? tempsTravail,
    int? deplacements,
    String? notesTechniques,
    String? noteInterventionsPlanifiees,
    String? noteInterventionsRealisees,
    String? noteInterventionsAnnulees,
    String? noteClientsVisites,
    String? noteProblemesResolus,
    String? noteProblemesEnCours,
    String? noteTempsTravail,
    String? noteDeplacements,
  }) {
    final current =
        technicienMetrics.value ??
        TechnicienMetrics(
          interventionsPlanifiees: 0,
          interventionsRealisees: 0,
          interventionsAnnulees: 0,
          interventionsList: [],
          clientsVisites: 0,
          problemesResolus: 0,
          problemesEnCours: 0,
          tempsTravail: 0,
          deplacements: 0,
        );

    technicienMetrics.value = TechnicienMetrics(
      interventionsPlanifiees:
          interventionsPlanifiees ?? current.interventionsPlanifiees,
      interventionsRealisees:
          interventionsRealisees ?? current.interventionsRealisees,
      interventionsAnnulees:
          interventionsAnnulees ?? current.interventionsAnnulees,
      interventionsList: current.interventionsList,
      clientsVisites: clientsVisites ?? current.clientsVisites,
      problemesResolus: problemesResolus ?? current.problemesResolus,
      problemesEnCours: problemesEnCours ?? current.problemesEnCours,
      tempsTravail: tempsTravail ?? current.tempsTravail,
      deplacements: deplacements ?? current.deplacements,
      notesTechniques: notesTechniques ?? current.notesTechniques,
      noteInterventionsPlanifiees:
          noteInterventionsPlanifiees ?? current.noteInterventionsPlanifiees,
      noteInterventionsRealisees:
          noteInterventionsRealisees ?? current.noteInterventionsRealisees,
      noteInterventionsAnnulees:
          noteInterventionsAnnulees ?? current.noteInterventionsAnnulees,
      noteClientsVisites: noteClientsVisites ?? current.noteClientsVisites,
      noteProblemesResolus:
          noteProblemesResolus ?? current.noteProblemesResolus,
      noteProblemesEnCours:
          noteProblemesEnCours ?? current.noteProblemesEnCours,
      noteTempsTravail: noteTempsTravail ?? current.noteTempsTravail,
      noteDeplacements: noteDeplacements ?? current.noteDeplacements,
    );
  }

  // Mettre à jour les métriques RH
  void updateRhMetrics({
    int? employesRecrutes,
    int? demandesCongeTraitees,
    int? demandesCongeApprouvees,
    int? demandesCongeRejetees,
    int? contratsCrees,
    int? contratsRenouveles,
    int? pointagesValides,
    int? entretiensRealises,
    int? formationsOrganisees,
    int? evaluationsEffectuees,
    String? noteEmployesRecrutes,
    String? noteDemandesCongeTraitees,
    String? noteContratsCrees,
    String? notePointagesValides,
    String? noteEntretiensRealises,
    String? noteFormationsOrganisees,
    String? noteEvaluationsEffectuees,
  }) {
    final current =
        rhMetrics.value ??
        RhMetrics(
          employesRecrutes: 0,
          demandesCongeTraitees: 0,
          demandesCongeApprouvees: 0,
          demandesCongeRejetees: 0,
          contratsCrees: 0,
          contratsRenouveles: 0,
          pointagesValides: 0,
          entretiensRealises: 0,
          formationsOrganisees: 0,
          evaluationsEffectuees: 0,
        );

    rhMetrics.value = RhMetrics(
      employesRecrutes: employesRecrutes ?? current.employesRecrutes,
      demandesCongeTraitees:
          demandesCongeTraitees ?? current.demandesCongeTraitees,
      demandesCongeApprouvees:
          demandesCongeApprouvees ?? current.demandesCongeApprouvees,
      demandesCongeRejetees:
          demandesCongeRejetees ?? current.demandesCongeRejetees,
      contratsCrees: contratsCrees ?? current.contratsCrees,
      contratsRenouveles: contratsRenouveles ?? current.contratsRenouveles,
      pointagesValides: pointagesValides ?? current.pointagesValides,
      entretiensRealises: entretiensRealises ?? current.entretiensRealises,
      formationsOrganisees:
          formationsOrganisees ?? current.formationsOrganisees,
      evaluationsEffectuees:
          evaluationsEffectuees ?? current.evaluationsEffectuees,
      noteEmployesRecrutes:
          noteEmployesRecrutes ?? current.noteEmployesRecrutes,
      noteDemandesCongeTraitees:
          noteDemandesCongeTraitees ?? current.noteDemandesCongeTraitees,
      noteContratsCrees: noteContratsCrees ?? current.noteContratsCrees,
      notePointagesValides:
          notePointagesValides ?? current.notePointagesValides,
      noteEntretiensRealises:
          noteEntretiensRealises ?? current.noteEntretiensRealises,
      noteFormationsOrganisees:
          noteFormationsOrganisees ?? current.noteFormationsOrganisees,
      noteEvaluationsEffectuees:
          noteEvaluationsEffectuees ?? current.noteEvaluationsEffectuees,
    );
  }

  // Vider le formulaire
  void clearForm() {
    commentsController.clear();
    rdvClientController.clear();
    rdvDateController.clear();
    rdvHeureController.clear();
    rdvTypeController.clear();
    rdvNotesController.clear();
    commercialMetrics.value = null;
    comptableMetrics.value = null;
    technicienMetrics.value = null;
    rhMetrics.value = null;
  }

  // Changer la période de filtrage
  void updateDateRange(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;
    loadReports();
  }

  // Filtrer par rôle utilisateur
  void filterByUserRole(String? role) {
    selectedUserRole.value = role;
    loadReports();
  }

  // Ajouter ou modifier la note du patron sur un rapport
  Future<void> addPatronNote(int reportId, {String? note}) async {
    try {
      isLoading.value = true;

      await _reportingService.addPatronNote(reportId, note: note);
      Get.snackbar(
        'Succès',
        note != null && note.isNotEmpty
            ? 'Note enregistrée avec succès'
            : 'Note supprimée avec succès',
      );
      loadReports();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de l\'enregistrement de la note: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
