import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/reporting_model.dart';
import 'package:easyconnect/services/reporting_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/notification_helper.dart';

class ReportingController extends GetxController {
  final ReportingService _reportingService = Get.find<ReportingService>();
  final AuthController _authController = Get.find<AuthController>();

  // Observables
  var isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  var reports = <ReportingModel>[].obs;
  var currentReport = Rxn<ReportingModel>(); // rapport en cours d'édition
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
  final RxInt perPage = 10.obs;
  final ScrollController scrollController = ScrollController();

  // Clé de formulaire pour la validation
  final formKey = GlobalKey<FormState>();

  // Nouveaux champs du formulaire
  var nature = ''.obs;
  final nomSocieteController = TextEditingController();
  final contactSocieteController = TextEditingController();
  final nomPersonneController = TextEditingController();
  final contactPersonneController = TextEditingController();
  var moyenContact = ''.obs;
  final produitDemarcheController = TextEditingController();
  final commentaireController = TextEditingController();
  var typeRelance = ''.obs;
  var relanceDateHeure = Rxn<DateTime>();

  // Anciens champs (conservés pour compatibilité)
  final commentsController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Ne pas charger automatiquement - laisser les pages décider quand charger
    // loadReports(); // Désactivé pour éviter les chargements inutiles
  }

  @override
  void onClose() {
    scrollController.dispose();
    nomSocieteController.dispose();
    contactSocieteController.dispose();
    nomPersonneController.dispose();
    contactPersonneController.dispose();
    produitDemarcheController.dispose();
    commentaireController.dispose();
    commentsController.dispose();
    super.onClose();
  }

  bool _isLoadingReportsInProgress = false;

  /// Charge les rapports : Hive d'abord (affichage immédiat), puis API dans la même méthode.
  Future<void> loadReports({int page = 1, bool forceRefresh = false}) async {
    if (_isLoadingReportsInProgress) return;
    _isLoadingReportsInProgress = true;
    final userRole = _authController.userAuth.value?.role;
    final userId = _authController.userAuth.value?.id;

    if (page == 1) {
      isLoading.value = true;
      final hiveList = ReportingService.getCachedReporting();
      if (hiveList.isNotEmpty && !forceRefresh) {
        reports.assignAll(hiveList);
        isLoading.value = false;
      } else {
        reports.value = [];
      }
    } else {
      isLoadingMore.value = true;
    }

    try {
      final paginatedResponse = await _reportingService.getReportsPaginated(
        startDate: startDate.value,
        endDate: endDate.value,
        userRole: selectedUserRole.value,
        userId: (userRole == Roles.ADMIN || userRole == Roles.PATRON) ? null : userId,
        page: page,
        perPage: perPage.value,
      );

      List<ReportingModel> filteredData = paginatedResponse.data;
      if (userRole != Roles.ADMIN && userRole != Roles.PATRON && userId != null) {
        filteredData = paginatedResponse.data.where((report) => report.userId == userId).toList();
      }

      if (page == 1) {
        reports.assignAll(filteredData);
        ReportingService.saveCachedReporting(filteredData);
      } else {
        reports.addAll(filteredData);
      }

      totalPages.value = paginatedResponse.meta.lastPage;
      totalItems.value = paginatedResponse.meta.total;
      hasNextPage.value = paginatedResponse.hasNextPage;
      hasPreviousPage.value = paginatedResponse.hasPreviousPage;
      currentPage.value = paginatedResponse.meta.currentPage;
    } catch (e) {
      try {
        if (page == 1 && (userRole == Roles.ADMIN || userRole == Roles.PATRON)) {
          final allReports = await _reportingService.getAllReports(
            startDate: startDate.value,
            endDate: endDate.value,
            userRole: selectedUserRole.value,
          );
          reports.assignAll(allReports);
          totalItems.value = allReports.length;
          totalPages.value = 1;
          if (allReports.isNotEmpty) ReportingService.saveCachedReporting(allReports);
        } else if (page == 1 && userId != null) {
          final userReports = await _reportingService.getUserReports(
            userId: userId,
            startDate: startDate.value,
            endDate: endDate.value,
          );
          final filtered = userReports.where((r) => r.userId == userId).toList();
          reports.assignAll(filtered);
          totalItems.value = filtered.length;
          totalPages.value = 1;
          if (filtered.isNotEmpty) ReportingService.saveCachedReporting(filtered);
        } else {
          throw e;
        }
      } catch (_) {
        if (reports.isEmpty) {
          final fallback = ReportingService.getCachedReporting();
          if (fallback.isNotEmpty) {
            reports.assignAll(fallback);
          } else {
            Get.snackbar('Erreur', 'Erreur lors du chargement des rapports', snackPosition: SnackPosition.BOTTOM);
          }
        }
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
      _isLoadingReportsInProgress = false;
    }
  }

  void loadMore() {
    if (hasNextPage.value && !isLoading.value && !isLoadingMore.value) {
      loadNextPage();
    }
  }

  /// Charger la page suivante
  void loadNextPage() {
    if (hasNextPage.value && !isLoading.value && !isLoadingMore.value) {
      loadReports(page: currentPage.value + 1);
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage.value && !isLoading.value && !isLoadingMore.value) {
      loadReports(page: currentPage.value - 1);
    }
  }

  // Créer un nouveau rapport
  Future<void> createReport() async {
    // Valider le formulaire
    if (formKey.currentState?.validate() != true) {
      Get.snackbar('Erreur', 'Veuillez remplir tous les champs obligatoires');
      return;
    }

    try {
      isLoading.value = true;

      final userRole = _authController.userAuth.value?.role;
      final userId = _authController.userAuth.value?.id;

      final response = await _reportingService.createReport(
        userId: userId!,
        userRole: Roles.getRoleName(userRole),
        reportDate: selectedDate.value,
        nature: nature.value,
        nomSociete: nomSocieteController.text,
        contactSociete: contactSocieteController.text,
        nomPersonne: nomPersonneController.text,
        contactPersonne: contactPersonneController.text,
        moyenContact: moyenContact.value,
        produitDemarche: produitDemarcheController.text,
        commentaire: commentaireController.text,
        typeRelance: typeRelance.value.isEmpty ? null : typeRelance.value,
        relanceDateHeure: relanceDateHeure.value,
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
            status: data['status'] as String? ?? 'submitted',
            nature: data['nature'] as String? ?? nature.value,
            nomSociete: data['nom_societe'] as String? ?? nomSocieteController.text,
            contactSociete: data['contact_societe'] as String? ?? contactSocieteController.text,
            nomPersonne: data['nom_personne'] as String? ?? nomPersonneController.text,
            contactPersonne: data['contact_personne'] as String? ?? contactPersonneController.text,
            moyenContact: data['moyen_contact'] as String? ?? moyenContact.value,
            produitDemarche: data['produit_demarche'] as String? ?? produitDemarcheController.text,
            commentaire: data['commentaire'] as String? ?? commentaireController.text,
            typeRelance: data['type_relance'] as String? ?? (typeRelance.value.isEmpty ? null : typeRelance.value),
            relanceDateHeure: relanceDateHeure.value,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      } catch (e) {
        print(
          '⚠️ [REPORTING_CONTROLLER] Erreur lors de la création du ReportingModel: $e',
        );
      }

      // Mise à jour optimiste : ajouter le reporting à la liste et persister le cache
      if (createdReport != null) {
        reports.insert(0, createdReport);
        ReportingService.saveCachedReporting(reports.toList());
      }

      isLoading.value = false;
      clearForm();

      Get.snackbar('Succès', 'Rapport créé avec succès');

      // Navigation automatique vers la page de liste des reportings
      Get.offNamed('/reporting');
      // Pas de loadReports(forceRefresh: true) pour ne pas écraser l'insertion
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

      // Notifier le patron de la soumission
      final report = reports.firstWhereOrNull((r) => r.id == reportId);
      if (report != null) {
        // Inclure le nom de l'utilisateur dans le message
        final userName =
            report.userName.isNotEmpty
                ? report.userName
                : 'Utilisateur #${report.userId}';
        final entityDisplayName = NotificationHelper.getEntityDisplayName(
          'report',
          report,
        );

        NotificationHelper.notifySubmission(
          entityType: 'report',
          entityName: 'Reporting de $userName - $entityDisplayName',
          entityId: reportId.toString(),
          route: NotificationHelper.getEntityRoute(
            'report',
            reportId.toString(),
          ),
        );
      }

      Get.snackbar('Succès', 'Rapport soumis avec succès');
      loadReports();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la soumission du rapport: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Approuver un rapport (patron seulement). [patronNote] optionnel avant validation.
  Future<void> approveReport(int reportId, {String? patronNote}) async {
    bool actionSuccess = false;
    try {
      isLoading.value = true;

      final result = await _reportingService.approveReport(
        reportId,
        patronNote: patronNote ?? (commentsController.text.trim().isEmpty ? null : commentsController.text.trim()),
      );

      // Vérifier si l'action a réussi
      final isSuccess =
          result['success'] == true ||
          result['success'] == 1 ||
          result['success'] == 'true';

      if (isSuccess) {
        actionSuccess = true;

        // Notifier l'utilisateur concerné de la validation
        final report = reports.firstWhereOrNull((r) => r.id == reportId);
        if (report != null) {
          NotificationHelper.notifyValidation(
            entityType: 'report',
            entityName: NotificationHelper.getEntityDisplayName(
              'report',
              report,
            ),
            entityId: reportId.toString(),
            route: NotificationHelper.getEntityRoute(
              'report',
              reportId.toString(),
            ),
            entity: report,
          );
        }

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

        // Notifier l'utilisateur concerné du rejet
        final report = reports.firstWhereOrNull((r) => r.id == reportId);
        if (report != null) {
          NotificationHelper.notifyRejection(
            entityType: 'report',
            entityName: NotificationHelper.getEntityDisplayName(
              'report',
              report,
            ),
            entityId: reportId.toString(),
            reason: reason,
            route: NotificationHelper.getEntityRoute(
              'report',
              reportId.toString(),
            ),
            entity: report,
          );
        }

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

  // Méthodes obsolètes - conservées pour compatibilité mais non utilisées dans le nouveau système
  // Ces méthodes peuvent être supprimées si elles ne sont plus nécessaires

  // Vider le formulaire
  void clearForm() {
    currentReport.value = null;
    nature.value = '';
    nomSocieteController.clear();
    contactSocieteController.clear();
    nomPersonneController.clear();
    contactPersonneController.clear();
    moyenContact.value = '';
    produitDemarcheController.clear();
    commentaireController.clear();
    typeRelance.value = '';
    relanceDateHeure.value = null;
    commentsController.clear();
  }

  /// Remplir le formulaire pour éditer un rapport (soumis uniquement, backend canBeEdited)
  void loadReportForEdit(ReportingModel report) {
    currentReport.value = report;
    selectedDate.value = report.reportDate;
    nature.value = report.nature ?? '';
    nomSocieteController.text = report.nomSociete ?? '';
    contactSocieteController.text = report.contactSociete ?? '';
    nomPersonneController.text = report.nomPersonne ?? '';
    contactPersonneController.text = report.contactPersonne ?? '';
    moyenContact.value = report.moyenContact ?? '';
    produitDemarcheController.text = report.produitDemarche ?? '';
    commentaireController.text = report.commentaire ?? '';
    typeRelance.value = report.typeRelance ?? '';
    relanceDateHeure.value = report.relanceDateHeure;
    commentsController.text = report.commentaire ?? '';
  }

  /// Mettre à jour un rapport existant (statut submitted uniquement côté backend)
  Future<void> updateReport() async {
    final report = currentReport.value;
    if (report == null) return;
    if (formKey.currentState?.validate() != true) {
      Get.snackbar('Erreur', 'Veuillez remplir tous les champs obligatoires');
      return;
    }
    try {
      isLoading.value = true;
      await _reportingService.updateReport(
        reportId: report.id,
        nature: nature.value.isEmpty ? null : nature.value,
        nomSociete: nomSocieteController.text.trim().isEmpty ? null : nomSocieteController.text.trim(),
        contactSociete: contactSocieteController.text.trim().isEmpty ? null : contactSocieteController.text.trim(),
        nomPersonne: nomPersonneController.text.trim().isEmpty ? null : nomPersonneController.text.trim(),
        contactPersonne: contactPersonneController.text.trim().isEmpty ? null : contactPersonneController.text.trim(),
        moyenContact: moyenContact.value.isEmpty ? null : moyenContact.value,
        produitDemarche: produitDemarcheController.text.trim().isEmpty ? null : produitDemarcheController.text.trim(),
        commentaire: commentaireController.text.trim().isEmpty ? null : commentaireController.text.trim(),
        typeRelance: typeRelance.value.isEmpty ? null : typeRelance.value,
        relanceDateHeure: relanceDateHeure.value,
      );
      clearForm();
      Get.snackbar('Succès', 'Rapport mis à jour avec succès');
      Get.offNamed('/reporting');
      loadReports(forceRefresh: true);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
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
