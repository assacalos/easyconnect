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

  // Formulaires
  final commentsController = TextEditingController();
  final rdvClientController = TextEditingController();
  final rdvDateController = TextEditingController();
  final rdvHeureController = TextEditingController();
  final rdvTypeController = TextEditingController();
  final rdvNotesController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadReports();
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
        reports.value = await _reportingService.getUserReports(
          userId: userId!,
          startDate: startDate.value,
          endDate: endDate.value,
        );
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
      typeRdv: rdvTypeController.text.isNotEmpty ? rdvTypeController.text : 'presentiel',
      status: 'planifie',
      notes: rdvNotesController.text,
    );

    // Ajouter le RDV à la liste des RDV du commercial
    final currentMetrics = commercialMetrics.value ?? CommercialMetrics(
      clientsProspectes: 0,
      rdvObtenus: 0,
      rdvList: [],
      devisCrees: 0,
      devisAcceptes: 0,
      chiffreAffaires: 0,
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
      chiffreAffaires: currentMetrics.chiffreAffaires,
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
    final metrics = commercialMetrics.value ?? CommercialMetrics(
      clientsProspectes: 0,
      rdvObtenus: 0,
      rdvList: [],
      devisCrees: 0,
      devisAcceptes: 0,
      chiffreAffaires: 0,
      nouveauxClients: 0,
      appelsEffectues: 0,
      emailsEnvoyes: 0,
      visitesRealisees: 0,
    );
    
    return metrics.toJson();
  }

  // Générer les métriques comptable
  Map<String, dynamic> _generateComptableMetrics() {
    final metrics = comptableMetrics.value ?? ComptableMetrics(
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
    final metrics = technicienMetrics.value ?? TechnicienMetrics(
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

  // Mettre à jour les métriques commercial
  void updateCommercialMetrics({
    int? clientsProspectes,
    int? devisCrees,
    int? devisAcceptes,
    double? chiffreAffaires,
    int? nouveauxClients,
    int? appelsEffectues,
    int? emailsEnvoyes,
    int? visitesRealisees,
  }) {
    final current = commercialMetrics.value ?? CommercialMetrics(
      clientsProspectes: 0,
      rdvObtenus: 0,
      rdvList: [],
      devisCrees: 0,
      devisAcceptes: 0,
      chiffreAffaires: 0,
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
      chiffreAffaires: chiffreAffaires ?? current.chiffreAffaires,
      nouveauxClients: nouveauxClients ?? current.nouveauxClients,
      appelsEffectues: appelsEffectues ?? current.appelsEffectues,
      emailsEnvoyes: emailsEnvoyes ?? current.emailsEnvoyes,
      visitesRealisees: visitesRealisees ?? current.visitesRealisees,
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
  }) {
    final current = comptableMetrics.value ?? ComptableMetrics(
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
  }) {
    final current = technicienMetrics.value ?? TechnicienMetrics(
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
      interventionsPlanifiees: interventionsPlanifiees ?? current.interventionsPlanifiees,
      interventionsRealisees: interventionsRealisees ?? current.interventionsRealisees,
      interventionsAnnulees: interventionsAnnulees ?? current.interventionsAnnulees,
      interventionsList: current.interventionsList,
      clientsVisites: clientsVisites ?? current.clientsVisites,
      problemesResolus: problemesResolus ?? current.problemesResolus,
      problemesEnCours: problemesEnCours ?? current.problemesEnCours,
      tempsTravail: tempsTravail ?? current.tempsTravail,
      deplacements: deplacements ?? current.deplacements,
      notesTechniques: notesTechniques ?? current.notesTechniques,
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
}
