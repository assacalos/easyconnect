import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/reporting_model.dart';
import 'package:easyconnect/services/reporting_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/logger.dart';

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

  // Métadonnées de pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPreviousPage = false.obs;
  final RxInt perPage = 15.obs;

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
  Future<void> loadReports({int page = 1, bool forceRefresh = false}) async {
    print('🚀 [REPORTING_CONTROLLER] ===== loadReports APPELÉ =====');
    print('🚀 [REPORTING_CONTROLLER] page: $page, forceRefresh: $forceRefresh');
    print(
      '🚀 [REPORTING_CONTROLLER] Liste actuelle: ${reports.length} reportings',
    );

    try {
      isLoading.value = true;
      print('🚀 [REPORTING_CONTROLLER] isLoading mis à true');

      final userRole = _authController.userAuth.value?.role;
      final userId = _authController.userAuth.value?.id;
      print('🔍 [REPORTING_CONTROLLER] userRole: $userRole, userId: $userId');
      print(
        '🔍 [REPORTING_CONTROLLER] startDate: ${startDate.value}, endDate: ${endDate.value}',
      );
      print(
        '🔍 [REPORTING_CONTROLLER] selectedUserRole: ${selectedUserRole.value}',
      );

      try {
        // Utiliser la méthode paginée
        print('📡 [REPORTING_CONTROLLER] Appel de getReportsPaginated...');
        final paginatedResponse = await _reportingService.getReportsPaginated(
          startDate: startDate.value,
          endDate: endDate.value,
          userRole: selectedUserRole.value,
          userId:
              (userRole == Roles.ADMIN || userRole == Roles.PATRON)
                  ? null
                  : userId,
          page: page,
          perPage: perPage.value,
        );

        print(
          '✅ [REPORTING_CONTROLLER] Réponse paginée reçue: ${paginatedResponse.data.length} reportings',
        );
        print(
          '✅ [REPORTING_CONTROLLER] Meta: total=${paginatedResponse.meta.total}, lastPage=${paginatedResponse.meta.lastPage}',
        );

        // Mettre à jour les métadonnées de pagination
        totalPages.value = paginatedResponse.meta.lastPage;
        totalItems.value = paginatedResponse.meta.total;
        hasNextPage.value = paginatedResponse.hasNextPage;
        hasPreviousPage.value = paginatedResponse.hasPreviousPage;
        currentPage.value = paginatedResponse.meta.currentPage;

        // Filtrer les reportings pour s'assurer que l'utilisateur ne voit que ses propres reportings
        // (sauf pour ADMIN et PATRON qui peuvent voir tous les reportings)
        List<ReportingModel> filteredData = paginatedResponse.data;
        print(
          '🔍 [REPORTING_CONTROLLER] AVANT filtrage: ${filteredData.length} reportings',
        );

        if (userRole != Roles.ADMIN &&
            userRole != Roles.PATRON &&
            userId != null) {
          filteredData =
              paginatedResponse.data.where((report) {
                final matches = report.userId == userId;
                print(
                  '🔍 [REPORTING_CONTROLLER] Filtrage - report.userId=${report.userId}, userId=$userId, matches=$matches',
                );
                return matches;
              }).toList();

          print(
            '🔍 [REPORTING_CONTROLLER] APRÈS filtrage: ${filteredData.length} reportings',
          );
          AppLogger.info(
            'Filtrage des reportings: ${paginatedResponse.data.length} -> ${filteredData.length} (userId: $userId)',
            tag: 'REPORTING_CONTROLLER',
          );
        }

        // Mettre à jour la liste
        if (page == 1) {
          print(
            '📝 [REPORTING_CONTROLLER] AVANT assignation: ${reports.length} reportings',
          );
          reports.value = filteredData;
          print(
            '📝 [REPORTING_CONTROLLER] APRÈS assignation: ${reports.length} reportings',
          );

          if (reports.isNotEmpty) {
            print(
              '📝 [REPORTING_CONTROLLER] Premier reporting: id=${reports.first.id}, userId=${reports.first.userId}, role=${reports.first.userRole}',
            );
          } else {
            print(
              '⚠️ [REPORTING_CONTROLLER] ATTENTION: La liste est vide après assignation!',
            );
          }
        } else {
          reports.addAll(filteredData);
          print(
            '📝 [REPORTING_CONTROLLER] Reportings ajoutés (page $page): ${reports.length} reportings au total',
          );
        }
      } catch (e, stackTrace) {
        print('❌ [REPORTING_CONTROLLER] Erreur dans getReportsPaginated: $e');
        print('❌ [REPORTING_CONTROLLER] Stack trace: $stackTrace');

        // En cas d'erreur, essayer la méthode non-paginée en fallback
        try {
          print('🔄 [REPORTING_CONTROLLER] Tentative avec méthode fallback...');
          if (userRole == Roles.ADMIN || userRole == Roles.PATRON) {
            print('🔄 [REPORTING_CONTROLLER] Appel de getAllReports...');
            final allReports = await _reportingService.getAllReports(
              startDate: startDate.value,
              endDate: endDate.value,
              userRole: selectedUserRole.value,
            );
            print(
              '🔄 [REPORTING_CONTROLLER] getAllReports retourné: ${allReports.length} reportings',
            );
            if (page == 1) {
              reports.value = allReports;
              print(
                '🔄 [REPORTING_CONTROLLER] Liste mise à jour avec getAllReports: ${reports.length} reportings',
              );
            } else {
              reports.addAll(allReports);
            }
          } else {
            print(
              '🔄 [REPORTING_CONTROLLER] Appel de getUserReports pour userId=$userId...',
            );
            final userReports = await _reportingService.getUserReports(
              userId: userId!,
              startDate: startDate.value,
              endDate: endDate.value,
            );
            print(
              '🔄 [REPORTING_CONTROLLER] getUserReports retourné: ${userReports.length} reportings',
            );
            // Ne filtrer que par userId, pas par rôle (le userId est déjà unique)
            // Le backend devrait déjà retourner les reportings du bon utilisateur
            print(
              '🔄 [REPORTING_CONTROLLER] Filtrage uniquement par userId: $userId',
            );

            final filteredReports =
                userReports.where((report) {
                  final matches = report.userId == userId;
                  print(
                    '🔄 [REPORTING_CONTROLLER] Fallback filtrage - report.userId=${report.userId}, userId=$userId, report.userRole="${report.userRole}", matches=$matches',
                  );
                  return matches;
                }).toList();
            print(
              '🔄 [REPORTING_CONTROLLER] Après filtrage fallback: ${filteredReports.length} reportings',
            );
            if (page == 1) {
              reports.value = filteredReports;
              print(
                '🔄 [REPORTING_CONTROLLER] Liste mise à jour avec getUserReports: ${reports.length} reportings',
              );
            } else {
              reports.addAll(filteredReports);
            }
          }
        } catch (fallbackError, fallbackStackTrace) {
          print(
            '❌ [REPORTING_CONTROLLER] Erreur dans le fallback: $fallbackError',
          );
          print(
            '❌ [REPORTING_CONTROLLER] Stack trace fallback: $fallbackStackTrace',
          );
          rethrow;
        }
      }
    } catch (e, stackTrace) {
      print('❌ [REPORTING_CONTROLLER] ERREUR FINALE dans loadReports: $e');
      print('❌ [REPORTING_CONTROLLER] Stack trace: $stackTrace');
      Get.snackbar('Erreur', 'Erreur lors du chargement des rapports: $e');
    } finally {
      isLoading.value = false;
      print(
        '✅ [REPORTING_CONTROLLER] loadReports terminé. Liste finale: ${reports.length} reportings',
      );
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

      final response = await _reportingService.createReport(
        userId: userId!,
        userRole: Roles.getRoleName(userRole),
        reportDate: selectedDate.value,
        metrics: metrics,
        comments: commentsController.text,
      );

      // Extraire le reporting créé de la réponse
      ReportingModel? createdReport;
      try {
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null) {
          // Construire le nom d'utilisateur
          final user = _authController.userAuth.value;
          final userName =
              user != null
                  ? '${user.prenom ?? ''} ${user.nom ?? ''}'.trim()
                  : '';

          // Construire un ReportingModel à partir de la réponse
          createdReport = ReportingModel(
            id:
                data['id'] is int
                    ? data['id'] as int
                    : (data['id'] is String
                        ? int.tryParse(data['id'] as String) ??
                            DateTime.now().millisecondsSinceEpoch
                        : DateTime.now().millisecondsSinceEpoch),
            userId:
                data['user_id'] is int
                    ? data['user_id'] as int
                    : (data['user_id'] is String
                        ? int.tryParse(data['user_id'] as String) ?? userId
                        : userId),
            userName: data['user_name'] as String? ?? userName,
            userRole:
                data['user_role'] as String? ?? Roles.getRoleName(userRole),
            reportDate: selectedDate.value,
            metrics:
                data['metrics'] is Map
                    ? Map<String, dynamic>.from(data['metrics'] as Map)
                    : metrics,
            status: data['status'] as String? ?? 'submitted',
            comments: data['comments'] as String? ?? commentsController.text,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      } catch (e) {
        print(
          '⚠️ [REPORTING_CONTROLLER] Erreur lors de la création du ReportingModel: $e',
        );
      }

      // Mise à jour optimiste : ajouter le reporting à la liste immédiatement
      if (createdReport != null) {
        print(
          '✅ [REPORTING_CONTROLLER] Ajout optimiste du reporting à la liste',
        );
        reports.insert(0, createdReport);
      }

      isLoading.value = false;
      clearForm();

      Get.snackbar('Succès', 'Rapport créé avec succès');

      // Navigation automatique vers la page de liste des reportings
      Get.offNamed('/reporting');

      // Recharger les reportings en arrière-plan pour synchroniser avec le serveur
      Future.microtask(() async {
        await Future.delayed(const Duration(milliseconds: 500));
        await loadReports(forceRefresh: true);

        // Si le reporting créé n'est pas dans la liste après le refresh, le ré-ajouter
        if (createdReport != null) {
          final exists = reports.any((r) => r.id == createdReport!.id);
          if (!exists) {
            print(
              '🔄 [REPORTING_CONTROLLER] Ré-ajout du reporting après refresh',
            );
            reports.insert(0, createdReport);
          }
        }
      });
    } catch (e) {
      String errorMessage = 'Erreur lors de la création du rapport';
      if (e.toString().contains('Erreur de format') ||
          e.toString().contains('format')) {
        errorMessage =
            'Erreur de format des données. Veuillez vérifier que tous les champs sont correctement remplis.';
      } else if (e.toString().isNotEmpty) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      Get.snackbar(
        'Erreur',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
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
    bool actionSuccess = false;
    try {
      isLoading.value = true;

      final result = await _reportingService.approveReport(
        reportId,
        comments: commentsController.text,
      );

      // Vérifier si l'action a réussi
      final isSuccess =
          result['success'] == true ||
          result['success'] == 1 ||
          result['success'] == 'true';

      if (isSuccess) {
        actionSuccess = true;
        Get.snackbar('Succès', 'Rapport approuvé avec succès');

        // Rafraîchir les données en arrière-plan (non-bloquant)
        loadReports().catchError((e) {
          // Ignorer silencieusement les erreurs de refresh
        });
      } else {
        throw Exception(result['message'] ?? 'Erreur lors de l\'approbation');
      }
    } catch (e) {
      // Ne pas afficher d'erreur si l'action principale a réussi
      if (actionSuccess) {
        // L'action a réussi, ignorer les erreurs de parsing/refresh
        return;
      }

      // Vérifier si c'est une erreur critique (authentification)
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('forbidden')) {
        Get.snackbar('Erreur', 'Erreur d\'authentification: $e');
      } else {
        // Pour les autres erreurs, vérifier si c'est un problème de parsing
        if (errorStr.contains('format') ||
            errorStr.contains('json') ||
            errorStr.contains('type') ||
            errorStr.contains('cast') ||
            errorStr.contains('null')) {
          // Probablement un problème de parsing après un succès
          // Ne rien afficher
        } else {
          Get.snackbar('Erreur', 'Erreur lors de l\'approbation: $e');
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Rejeter un rapport (patron seulement)
  Future<void> rejectReport(int reportId, {String? reason}) async {
    bool actionSuccess = false;
    try {
      isLoading.value = true;

      final result = await _reportingService.rejectReport(
        reportId,
        comments: reason ?? commentsController.text,
      );

      // Vérifier si l'action a réussi
      final isSuccess =
          result['success'] == true ||
          result['success'] == 1 ||
          result['success'] == 'true';

      if (isSuccess) {
        actionSuccess = true;
        Get.snackbar('Succès', 'Rapport rejeté avec succès');

        // Rafraîchir les données en arrière-plan (non-bloquant)
        loadReports().catchError((e) {
          // Ignorer silencieusement les erreurs de refresh
        });
      } else {
        throw Exception(result['message'] ?? 'Erreur lors du rejet');
      }
    } catch (e) {
      // Ne pas afficher d'erreur si l'action principale a réussi
      if (actionSuccess) {
        // L'action a réussi, ignorer les erreurs de parsing/refresh
        return;
      }

      // Vérifier si c'est une erreur critique (authentification)
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('forbidden')) {
        Get.snackbar('Erreur', 'Erreur d\'authentification: $e');
      } else {
        // Pour les autres erreurs, vérifier si c'est un problème de parsing
        if (errorStr.contains('format') ||
            errorStr.contains('json') ||
            errorStr.contains('type') ||
            errorStr.contains('cast') ||
            errorStr.contains('null')) {
          // Probablement un problème de parsing après un succès
          // Ne rien afficher
        } else {
          Get.snackbar('Erreur', 'Erreur lors du rejet: $e');
        }
      }
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
    bool actionSuccess = false;
    try {
      isLoading.value = true;

      final result = await _reportingService.addPatronNote(
        reportId,
        note: note,
      );

      // Vérifier si l'action a réussi
      final isSuccess =
          result['success'] == true ||
          result['success'] == 1 ||
          result['success'] == 'true';

      if (isSuccess) {
        actionSuccess = true;
        Get.snackbar(
          'Succès',
          note != null && note.isNotEmpty
              ? 'Note enregistrée avec succès'
              : 'Note supprimée avec succès',
        );

        // Rafraîchir les données en arrière-plan (non-bloquant)
        loadReports().catchError((e) {
          // Ignorer silencieusement les erreurs de refresh
        });
      } else {
        throw Exception(
          result['message'] ?? 'Erreur lors de l\'enregistrement de la note',
        );
      }
    } catch (e) {
      // Ne pas afficher d'erreur si l'action principale a réussi
      if (actionSuccess) {
        // L'action a réussi, ignorer les erreurs de parsing/refresh
        return;
      }

      // Vérifier si c'est une erreur critique (authentification)
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('forbidden')) {
        Get.snackbar('Erreur', 'Erreur d\'authentification: $e');
      } else {
        // Pour les autres erreurs, vérifier si c'est un problème de parsing
        if (errorStr.contains('format') ||
            errorStr.contains('json') ||
            errorStr.contains('type') ||
            errorStr.contains('cast') ||
            errorStr.contains('null')) {
          // Probablement un problème de parsing après un succès
          // Ne rien afficher
        } else {
          Get.snackbar(
            'Erreur',
            'Erreur lors de l\'enregistrement de la note: $e',
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }
}
