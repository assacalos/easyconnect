import 'package:flutter/material.dart';
import 'package:easyconnect/router/app_router.dart' show rootGoRouter;
import 'package:easyconnect/Models/reporting_model.dart';
import 'package:easyconnect/services/reporting_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/error_helper.dart';

ReportingModel? _firstWhereReportById(List<ReportingModel> list, int id) {
  try {
    return list.firstWhere((r) => r.id == id);
  } catch (_) {
    return null;
  }
}

class ReportingController {
  static final ReportingController _instance = ReportingController._();
  static ReportingController get to => _instance;
  factory ReportingController() => _instance;
  ReportingController._();

  final ReportingService _reportingService = ReportingService.to;
  final AuthController _authController = AuthController.to;

  bool isLoading = false;
  bool isLoadingMore = false;
  final List<ReportingModel> reports = [];
  ReportingModel? currentReport;
  DateTime selectedDate = DateTime.now();
  String? selectedUserRole;
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();

  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  int perPage = 10;
  final ScrollController scrollController = ScrollController();
  final formKey = GlobalKey<FormState>();

  String nature = '';
  final nomSocieteController = TextEditingController();
  final contactSocieteController = TextEditingController();
  final nomPersonneController = TextEditingController();
  final contactPersonneController = TextEditingController();
  String moyenContact = '';
  final produitDemarcheController = TextEditingController();
  final commentaireController = TextEditingController();
  String typeRelance = '';
  DateTime? relanceDateHeure;
  final commentsController = TextEditingController();

  void dispose() {
    scrollController.dispose();
    nomSocieteController.dispose();
    contactSocieteController.dispose();
    nomPersonneController.dispose();
    contactPersonneController.dispose();
    produitDemarcheController.dispose();
    commentaireController.dispose();
    commentsController.dispose();
  }

  bool _isLoadingReportsInProgress = false;

  /// Charge les rapports : Hive d'abord (affichage immédiat), puis API dans la même méthode.
  Future<void> loadReports({int page = 1, bool forceRefresh = false}) async {
    if (_isLoadingReportsInProgress) return;
    _isLoadingReportsInProgress = true;
    final userRole = _authController.userAuth?.role;
    final userId = _authController.userAuth?.id;

    if (page == 1) {
      isLoading = true;
      final hiveList = ReportingService.getCachedReporting();
      if (hiveList.isNotEmpty && !forceRefresh) {
        reports.clear();
        reports.addAll(hiveList);
        isLoading = false;
      } else {
        reports.clear();
      }
    } else {
      isLoadingMore = true;
    }

    try {
      final paginatedResponse = await _reportingService.getReportsPaginated(
        startDate: startDate,
        endDate: endDate,
        userRole: selectedUserRole,
        userId: (userRole == Roles.ADMIN || userRole == Roles.PATRON) ? null : userId,
        page: page,
        perPage: perPage,
      );

      List<ReportingModel> filteredData = paginatedResponse.data;
      if (userRole != Roles.ADMIN && userRole != Roles.PATRON && userId != null) {
        filteredData = paginatedResponse.data.where((report) => report.userId == userId).toList();
      }

      if (page == 1) {
        reports.clear();
        reports.addAll(filteredData);
        ReportingService.saveCachedReporting(reports.toList());
      } else {
        reports.addAll(filteredData);
      }

      totalPages = paginatedResponse.meta.lastPage;
      totalItems = paginatedResponse.meta.total;
      hasNextPage = paginatedResponse.hasNextPage;
      hasPreviousPage = paginatedResponse.hasPreviousPage;
      currentPage = paginatedResponse.meta.currentPage;
    } catch (e) {
      try {
        if (page == 1 && (userRole == Roles.ADMIN || userRole == Roles.PATRON)) {
          final allReports = await _reportingService.getAllReports(
            startDate: startDate,
            endDate: endDate,
            userRole: selectedUserRole,
          );
          reports.clear();
          reports.addAll(allReports);
          totalItems = allReports.length;
          totalPages = 1;
          if (allReports.isNotEmpty) ReportingService.saveCachedReporting(allReports);
        } else if (page == 1 && userId != null) {
          final userReports = await _reportingService.getUserReports(
            userId: userId,
            startDate: startDate,
            endDate: endDate,
          );
          final filtered = userReports.where((r) => r.userId == userId).toList();
          reports.clear();
          reports.addAll(filtered);
          totalItems = filtered.length;
          totalPages = 1;
          if (filtered.isNotEmpty) ReportingService.saveCachedReporting(filtered);
        } else {
          throw e;
        }
      } catch (_) {
        if (reports.isEmpty) {
          final fallback = ReportingService.getCachedReporting();
          if (fallback.isNotEmpty) {
            reports.clear();
            reports.addAll(fallback);
          } else {
            errorHelperShowSnackbar?.call('Erreur', 'Erreur lors du chargement des rapports');
          }
        }
      }
    } finally {
      isLoading = false;
      isLoadingMore = false;
      _isLoadingReportsInProgress = false;
    }
  }

  void loadMore() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadNextPage();
    }
  }

  void loadNextPage() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadReports(page: currentPage + 1);
    }
  }

  void loadPreviousPage() {
    if (hasPreviousPage && !isLoading && !isLoadingMore) {
      loadReports(page: currentPage - 1);
    }
  }

  // Créer un nouveau rapport
  Future<void> createReport() async {
    // Valider le formulaire
    if (formKey.currentState?.validate() != true) {
      errorHelperShowSnackbar?.call('Erreur', 'Veuillez remplir tous les champs obligatoires');
      return;
    }

    try {
      isLoading = true;

      final userRole = _authController.userAuth?.role;
      final userId = _authController.userAuth?.id;

      final response = await _reportingService.createReport(
        userId: userId!,
        userRole: Roles.getRoleName(userRole),
        reportDate: selectedDate,
        nature: nature,
        nomSociete: nomSocieteController.text,
        contactSociete: contactSocieteController.text,
        nomPersonne: nomPersonneController.text,
        contactPersonne: contactPersonneController.text,
        moyenContact: moyenContact,
        produitDemarche: produitDemarcheController.text,
        commentaire: commentaireController.text,
        typeRelance: typeRelance.isEmpty ? null : typeRelance,
        relanceDateHeure: relanceDateHeure,
      );

      ReportingModel? createdReport;
      try {
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null) {
          final user = _authController.userAuth;
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
            reportDate: selectedDate,
            status: data['status'] as String? ?? 'submitted',
            nature: data['nature'] as String? ?? nature,
            nomSociete: data['nom_societe'] as String? ?? nomSocieteController.text,
            contactSociete: data['contact_societe'] as String? ?? contactSocieteController.text,
            nomPersonne: data['nom_personne'] as String? ?? nomPersonneController.text,
            contactPersonne: data['contact_personne'] as String? ?? contactPersonneController.text,
            moyenContact: data['moyen_contact'] as String? ?? moyenContact,
            produitDemarche: data['produit_demarche'] as String? ?? produitDemarcheController.text,
            commentaire: data['commentaire'] as String? ?? commentaireController.text,
            typeRelance: data['type_relance'] as String? ?? (typeRelance.isEmpty ? null : typeRelance),
            relanceDateHeure: relanceDateHeure,
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

      isLoading = false;
      clearForm();

      ErrorHelper.showSuccess('Rapport créé avec succès');

      // Navigation automatique vers la page de liste des reportings
      rootGoRouter?.go('/reporting');
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
      errorHelperShowSnackbar?.call(
        'Erreur',
        errorMessage,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading = false;
    }
  }

  // Soumettre un rapport
  Future<void> submitReport(int reportId) async {
    try {
      isLoading = true;

      await _reportingService.submitReport(reportId);

      // Notifier le patron de la soumission
      final report = _firstWhereReportById(reports, reportId);
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

      ErrorHelper.showSuccess('Rapport soumis avec succès');
      loadReports();
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', 'Erreur lors de la soumission du rapport: $e');
    } finally {
      isLoading = false;
    }
  }

  // Approuver un rapport (patron seulement). [patronNote] optionnel avant validation.
  Future<void> approveReport(int reportId, {String? patronNote}) async {
    bool actionSuccess = false;
    try {
      isLoading = true;

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
        final report = _firstWhereReportById(reports, reportId);
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

        ErrorHelper.showSuccess('Rapport approuvé avec succès');

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
        errorHelperShowSnackbar?.call('Erreur', 'Erreur d\'authentification: $e');
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
          errorHelperShowSnackbar?.call('Erreur', 'Erreur lors de l\'approbation: $e');
        }
      }
    } finally {
      isLoading = false;
    }
  }

  // Rejeter un rapport (patron seulement)
  Future<void> rejectReport(int reportId, {String? reason}) async {
    bool actionSuccess = false;
    try {
      isLoading = true;

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
        final report = _firstWhereReportById(reports, reportId);
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

        ErrorHelper.showSuccess('Rapport rejeté avec succès');

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
        errorHelperShowSnackbar?.call('Erreur', 'Erreur d\'authentification: $e');
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
          errorHelperShowSnackbar?.call('Erreur', 'Erreur lors du rejet: $e');
        }
      }
    } finally {
      isLoading = false;
    }
  }

  // Méthodes obsolètes

  // Vider le formulaire
  void clearForm() {
    currentReport = null;
    nature = '';
    nomSocieteController.clear();
    contactSocieteController.clear();
    nomPersonneController.clear();
    contactPersonneController.clear();
    moyenContact = '';
    produitDemarcheController.clear();
    commentaireController.clear();
    typeRelance = '';
    relanceDateHeure = null;
    commentsController.clear();
  }

  /// Remplir le formulaire pour éditer un rapport (soumis uniquement, backend canBeEdited)
  void loadReportForEdit(ReportingModel report) {
    currentReport = report;
    selectedDate = report.reportDate;
    nature = report.nature ?? '';
    nomSocieteController.text = report.nomSociete ?? '';
    contactSocieteController.text = report.contactSociete ?? '';
    nomPersonneController.text = report.nomPersonne ?? '';
    contactPersonneController.text = report.contactPersonne ?? '';
    moyenContact = report.moyenContact ?? '';
    produitDemarcheController.text = report.produitDemarche ?? '';
    commentaireController.text = report.commentaire ?? '';
    typeRelance = report.typeRelance ?? '';
    relanceDateHeure = report.relanceDateHeure;
    commentsController.text = report.commentaire ?? '';
  }

  /// Mettre à jour un rapport existant (statut submitted uniquement côté backend)
  Future<void> updateReport() async {
    final report = currentReport;
    if (report == null) return;
    if (formKey.currentState?.validate() != true) {
      errorHelperShowSnackbar?.call('Erreur', 'Veuillez remplir tous les champs obligatoires');
      return;
    }
    try {
      isLoading = true;
      await _reportingService.updateReport(
        reportId: report.id,
        nature: nature.isEmpty ? null : nature,
        nomSociete: nomSocieteController.text.trim().isEmpty ? null : nomSocieteController.text.trim(),
        contactSociete: contactSocieteController.text.trim().isEmpty ? null : contactSocieteController.text.trim(),
        nomPersonne: nomPersonneController.text.trim().isEmpty ? null : nomPersonneController.text.trim(),
        contactPersonne: contactPersonneController.text.trim().isEmpty ? null : contactPersonneController.text.trim(),
        moyenContact: moyenContact.isEmpty ? null : moyenContact,
        produitDemarche: produitDemarcheController.text.trim().isEmpty ? null : produitDemarcheController.text.trim(),
        commentaire: commentaireController.text.trim().isEmpty ? null : commentaireController.text.trim(),
        typeRelance: typeRelance.isEmpty ? null : typeRelance,
        relanceDateHeure: relanceDateHeure,
      );
      clearForm();
      ErrorHelper.showSuccess('Rapport mis à jour avec succès');
      rootGoRouter?.go('/reporting');
      loadReports(forceRefresh: true);
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isLoading = false;
    }
  }

  void updateDateRange(DateTime start, DateTime end) {
    startDate = start;
    endDate = end;
    loadReports();
  }

  void filterByUserRole(String? role) {
    selectedUserRole = role;
    loadReports();
  }

  Future<void> addPatronNote(int reportId, {String? note}) async {
    bool actionSuccess = false;
    try {
      isLoading = true;

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
        ErrorHelper.showSuccess(
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
        errorHelperShowSnackbar?.call('Erreur', 'Erreur d\'authentification: $e');
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
          errorHelperShowSnackbar?.call(
            'Erreur',
            'Erreur lors de l\'enregistrement de la note: $e',
          );
        }
      }
    } finally {
      isLoading = false;
    }
  }
}
