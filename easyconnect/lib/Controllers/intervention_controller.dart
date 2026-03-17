import 'package:flutter/material.dart';
import 'package:easyconnect/Models/intervention_model.dart';
import 'package:easyconnect/services/intervention_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/Controllers/technicien_dashboard_controller.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/error_helper.dart';

class InterventionController {
  static final InterventionController _instance = InterventionController._();
  static InterventionController get to => _instance;
  factory InterventionController() => _instance;
  InterventionController._();

  final InterventionService _interventionService = InterventionService();
  final ClientService _clientService = ClientService();

  // Variables
  final List<Intervention> interventions = [];
  final List<Intervention> pendingInterventions = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  InterventionStats? interventionStats;

  // Variables pour le formulaire
  String searchQuery = '';
  String selectedStatus = 'all';
  String selectedType = 'all';
  String selectedPriority = 'all';
  Intervention? selectedIntervention;
  String? _currentStatusFilter;

  // Métadonnées de pagination
  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  int perPage = 15;
  final ScrollController scrollController = ScrollController();

  // Contrôleurs de formulaire
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController clientNameController = TextEditingController();
  final TextEditingController clientPhoneController = TextEditingController();
  final TextEditingController clientEmailController = TextEditingController();
  final TextEditingController equipmentController = TextEditingController();
  final TextEditingController problemController = TextEditingController();
  final TextEditingController solutionController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController completionNotesController =
      TextEditingController();
  final TextEditingController costController = TextEditingController();
  final TextEditingController estimatedDurationController =
      TextEditingController();
  final TextEditingController actualDurationController =
      TextEditingController();

  // Variables de sélection
  String selectedTypeForm = 'external';
  String selectedPriorityForm = 'medium';
  DateTime? selectedScheduledDate;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  final List<String> selectedAttachments = [];

  // Variables pour la gestion des clients validés
  final List<Client> availableClients = [];
  bool isLoadingClients = false;
  Client? selectedClient;

  bool _initialized = false;
  void ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadInterventions();
      loadInterventionStats();
      loadPendingInterventions();
    });
  }

  void dispose() {
    scrollController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    clientNameController.dispose();
    clientPhoneController.dispose();
    clientEmailController.dispose();
    equipmentController.dispose();
    problemController.dispose();
    solutionController.dispose();
    notesController.dispose();
    completionNotesController.dispose();
    costController.dispose();
    estimatedDurationController.dispose();
    actualDurationController.dispose();
  }

  // Charger toutes les interventions
  Future<void> loadInterventions({String? statusFilter, int page = 1}) async {
    try {
      _currentStatusFilter =
          statusFilter ??
          (selectedStatus == 'all' ? null : selectedStatus);

      if (page == 1) {
        final hiveList = InterventionService.getCachedInterventions();
        if (hiveList.isNotEmpty) {
          interventions.clear();
          interventions.addAll(hiveList);
          isLoading = false;
          Future.microtask(() => _refreshInterventionsFromApi());
          return;
        }
        isLoading = true;
      }
      if (page > 1) {
        isLoadingMore = true;
      }

      try {
        final paginatedResponse = await _interventionService
            .getInterventionsPaginated(
              status: _currentStatusFilter,
              type: selectedType == 'all' ? null : selectedType,
              priority:
                  selectedPriority == 'all'
                      ? null
                      : selectedPriority,
              search: searchQuery.isNotEmpty ? searchQuery : null,
              page: page,
              perPage: perPage,
            );

        // Mettre à jour les métadonnées de pagination
        totalPages = paginatedResponse.meta.lastPage;
        totalItems = paginatedResponse.meta.total;
        hasNextPage = paginatedResponse.hasNextPage;
        hasPreviousPage = paginatedResponse.hasPreviousPage;
        currentPage = paginatedResponse.meta.currentPage;

        // Mettre à jour la liste
        if (page == 1) {
          interventions.clear();
          interventions.addAll(paginatedResponse.data);
        } else {
          // Pour les pages suivantes, ajouter les données
          interventions.addAll(paginatedResponse.data);
        }
      } catch (e) {
        // En cas d'erreur, essayer la méthode non-paginée en fallback
        final loadedInterventions = await _interventionService.getInterventions(
          status: _currentStatusFilter,
          type: selectedType == 'all' ? null : selectedType,
          priority:
              selectedPriority == 'all' ? null : selectedPriority,
          search: searchQuery.isEmpty ? null : searchQuery,
        );
        if (page == 1) {
          interventions.clear();
          interventions.addAll(loadedInterventions);
        } else {
          interventions.addAll(loadedInterventions);
        }
      }
    } catch (e) {
      // Ne pas afficher d'erreur - les erreurs sont gérées silencieusement
      // Les erreurs d'authentification sont déjà gérées par AuthErrorHandler
    } finally {
      isLoading = false;
      isLoadingMore = false;
    }
  }

  /// Rafraîchit les interventions depuis l'API (page 1) et met à jour la liste si le filtre est inchangé.
  Future<void> _refreshInterventionsFromApi() async {
    try {
      if (_currentStatusFilter != (selectedStatus == 'all' ? null : selectedStatus)) return;
      final paginatedResponse = await _interventionService.getInterventionsPaginated(
        status: _currentStatusFilter,
        type: selectedType == 'all' ? null : selectedType,
        priority: selectedPriority == 'all' ? null : selectedPriority,
        search: searchQuery.isNotEmpty ? searchQuery : null,
        page: 1,
        perPage: perPage,
      );
      if (_currentStatusFilter != (selectedStatus == 'all' ? null : selectedStatus)) return;
      interventions.clear();
      interventions.addAll(paginatedResponse.data);
      totalPages = paginatedResponse.meta.lastPage;
      totalItems = paginatedResponse.meta.total;
      hasNextPage = paginatedResponse.hasNextPage;
      hasPreviousPage = paginatedResponse.hasPreviousPage;
      currentPage = 1;
      loadInterventionStats().catchError((_) {});
    } catch (_) {}
  }

  /// Chargement de la page suivante au scroll.
  void loadMore() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadNextPage();
    }
  }

  /// Charger la page suivante
  void loadNextPage() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadInterventions(
        statusFilter: _currentStatusFilter,
        page: currentPage + 1,
      );
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage && !isLoading) {
      loadInterventions(
        statusFilter: _currentStatusFilter,
        page: currentPage - 1,
      );
    }
  }

  // Charger les interventions en attente
  Future<void> loadPendingInterventions() async {
    try {
      final pending = await _interventionService.getPendingInterventions();
      pendingInterventions.clear();
      pendingInterventions.addAll(pending);
    } catch (e) {}
  }

  // Charger les statistiques
  Future<void> loadInterventionStats() async {
    try {
      final stats = await _interventionService.getInterventionStats();
      interventionStats = stats;
    } catch (e) {}
  }

  // Créer une intervention
  Future<bool> createIntervention() async {
    if (isLoading) return false;
    try {
      isLoading = true;

      final intervention = Intervention(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        type: selectedTypeForm,
        priority: selectedPriorityForm,
        scheduledDate:
            selectedScheduledDate ??
            DateTime.now().add(const Duration(days: 1)),
        location:
            locationController.text.trim().isEmpty
                ? null
                : locationController.text.trim(),
        clientId: selectedClient?.id,
        clientName:
            clientNameController.text.trim().isEmpty
                ? null
                : clientNameController.text.trim(),
        clientPhone:
            clientPhoneController.text.trim().isEmpty
                ? null
                : clientPhoneController.text.trim(),
        clientEmail:
            clientEmailController.text.trim().isEmpty
                ? null
                : clientEmailController.text.trim(),
        equipment:
            equipmentController.text.trim().isEmpty
                ? null
                : equipmentController.text.trim(),
        problemDescription:
            problemController.text.trim().isEmpty
                ? null
                : problemController.text.trim(),
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
        estimatedDuration: double.tryParse(estimatedDurationController.text),
        cost: double.tryParse(costController.text),
        attachments: selectedAttachments.isEmpty ? null : selectedAttachments,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final createdIntervention = await _interventionService.createIntervention(
        intervention,
      );

      // Invalider le cache
      CacheHelper.clearByPrefix('interventions_');

      // Ajouter l'intervention à la liste localement (mise à jour optimiste)
      if (createdIntervention.id != null) {
        interventions.add(createdIntervention);
        pendingInterventions.add(createdIntervention);

        // Notifier le patron de la soumission
        NotificationHelper.notifySubmission(
          entityType: 'intervention',
          entityName: NotificationHelper.getEntityDisplayName(
            'intervention',
            createdIntervention,
          ),
          entityId: createdIntervention.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'intervention',
            createdIntervention.id.toString(),
          ),
        );
      }

      await loadInterventions();
      await loadInterventionStats();
      _notifyDashboard();

      errorHelperShowSnackbar?.call(
        'Succès',
        'Intervention créée avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      clearForm();
      return true;
    } catch (e) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        // Probablement une erreur de parsing après un succès
        return false;
      }

      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de créer l\'intervention: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return false;
    } finally {
      isLoading = false;
    }
  }

  // Mettre à jour une intervention
  Future<bool> updateIntervention(Intervention intervention) async {
    if (isLoading) return false;
    try {
      isLoading = true;

      final updatedIntervention = Intervention(
        id: intervention.id,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        type: selectedTypeForm,
        priority: selectedPriorityForm,
        status: intervention.status,
        scheduledDate:
            selectedScheduledDate ?? intervention.scheduledDate,
        startDate: selectedStartDate ?? intervention.startDate,
        endDate: selectedEndDate ?? intervention.endDate,
        location:
            locationController.text.trim().isEmpty
                ? null
                : locationController.text.trim(),
        clientId: selectedClient?.id ?? intervention.clientId,
        clientName:
            clientNameController.text.trim().isEmpty
                ? null
                : clientNameController.text.trim(),
        clientPhone:
            clientPhoneController.text.trim().isEmpty
                ? null
                : clientPhoneController.text.trim(),
        clientEmail:
            clientEmailController.text.trim().isEmpty
                ? null
                : clientEmailController.text.trim(),
        equipment:
            equipmentController.text.trim().isEmpty
                ? null
                : equipmentController.text.trim(),
        problemDescription:
            problemController.text.trim().isEmpty
                ? null
                : problemController.text.trim(),
        solution:
            solutionController.text.trim().isEmpty
                ? null
                : solutionController.text.trim(),
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
        completionNotes:
            completionNotesController.text.trim().isEmpty
                ? null
                : completionNotesController.text.trim(),
        estimatedDuration: double.tryParse(estimatedDurationController.text),
        actualDuration: double.tryParse(actualDurationController.text),
        cost: double.tryParse(costController.text),
        attachments: selectedAttachments.isEmpty ? null : selectedAttachments,
        createdAt: intervention.createdAt,
        updatedAt: DateTime.now(),
        createdBy: intervention.createdBy,
        approvedBy: intervention.approvedBy,
        approvedAt: intervention.approvedAt,
        rejectionReason: intervention.rejectionReason,
      );

      await _interventionService.updateIntervention(updatedIntervention);
      await loadInterventions();
      await loadInterventionStats();
      _notifyDashboard();

      errorHelperShowSnackbar?.call(
        'Succès',
        'Intervention mise à jour avec succès',
      );

      clearForm();
      return true;
    } catch (e) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        // Probablement une erreur de parsing après un succès
        return false;
      }

      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de mettre à jour l\'intervention',
      );
      return false;
    } finally {
      isLoading = false;
    }
  }

  // Approuver une intervention
  Future<void> approveIntervention(Intervention intervention) async {
    try {
      // Mise à jour optimiste de l'UI
      final interventionIndex = interventions.indexWhere(
        (i) => i.id == intervention.id,
      );
      final pendingIndex = pendingInterventions.indexWhere(
        (i) => i.id == intervention.id,
      );

      if (interventionIndex != -1 || pendingIndex != -1) {
        final updatedIntervention = Intervention(
          id: intervention.id,
          title: intervention.title,
          description: intervention.description,
          type: intervention.type,
          status: 'approved', // Approuvée
          priority: intervention.priority,
          scheduledDate: intervention.scheduledDate,
          startDate: intervention.startDate,
          endDate: intervention.endDate,
          location: intervention.location,
          clientId: intervention.clientId,
          clientName: intervention.clientName,
          clientPhone: intervention.clientPhone,
          clientEmail: intervention.clientEmail,
          equipment: intervention.equipment,
          problemDescription: intervention.problemDescription,
          solution: intervention.solution,
          notes:
              notesController.text.trim().isEmpty
                  ? intervention.notes
                  : notesController.text.trim(),
          attachments: intervention.attachments,
          estimatedDuration: intervention.estimatedDuration,
          actualDuration: intervention.actualDuration,
          cost: intervention.cost,
          createdAt: intervention.createdAt,
          updatedAt: DateTime.now(),
          createdBy: intervention.createdBy,
          approvedBy: intervention.approvedBy,
          approvedAt: DateTime.now().toIso8601String(),
          rejectionReason: intervention.rejectionReason,
          completionNotes: intervention.completionNotes,
        );

        if (interventionIndex != -1) {
          interventions[interventionIndex] = updatedIntervention;
        }
        if (pendingIndex != -1) {
          pendingInterventions.removeAt(pendingIndex);
        }
      }

      // Invalider le cache avant l'appel API
      CacheHelper.clearByPrefix('interventions_');

      // Appel API en arrière-plan
      final success = await _interventionService.approveIntervention(
        intervention.id!,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
      );

      if (success) {
        // Rafraîchir les compteurs du dashboard patron
        DashboardRefreshHelper.refreshPatronCounter('intervention');

        // Notifier l'utilisateur concerné de la validation
        NotificationHelper.notifyValidation(
          entityType: 'intervention',
          entityName: NotificationHelper.getEntityDisplayName(
            'intervention',
            intervention,
          ),
          entityId: intervention.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'intervention',
            intervention.id.toString(),
          ),
          entity: intervention,
        );

        _notifyDashboard();

        errorHelperShowSnackbar?.call(
          'Succès',
          'Intervention approuvée',
        );

        // Recharger les données en arrière-plan avec le filtre actuel
        // pour synchroniser avec le serveur (mais garder la mise à jour optimiste)
        Future.delayed(const Duration(milliseconds: 500), () {
          loadInterventions(
            statusFilter: _currentStatusFilter,
          ).catchError((e) {});
          loadInterventionStats().catchError((e) {});
          loadPendingInterventions().catchError((e) {});
        });
      } else {
        // En cas d'échec, recharger pour restaurer l'état
        await loadInterventions(statusFilter: _currentStatusFilter);
        await loadPendingInterventions();
        // Ne pas afficher d'erreur si la validation a peut-être réussi côté serveur
        errorHelperShowSnackbar?.call(
          'Attention',
          'La validation peut avoir réussi. Veuillez vérifier.',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      // Vérifier si l'erreur est survenue après un succès
      final errorStr = e.toString().toLowerCase();

      // Ne pas afficher d'erreur pour les erreurs de parsing ou de rechargement
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        // Probablement une erreur de parsing après un succès
        loadInterventions(
          statusFilter: _currentStatusFilter,
        ).catchError((e) {});
        loadPendingInterventions().catchError((e) {});
        return;
      }

      // Pour les autres erreurs, vérifier si c'est une erreur d'authentification
      if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('forbidden')) {
        // Erreur d'authentification - afficher
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Erreur d\'authentification. Veuillez vous reconnecter.',
        );
      } else {
        // Autre erreur - recharger pour vérifier l'état
        loadInterventions(
          statusFilter: _currentStatusFilter,
        ).catchError((e) {});
        loadPendingInterventions().catchError((e) {});
        // Ne pas afficher d'erreur car l'action peut avoir réussi
      }
    }
  }

  // Rejeter une intervention
  Future<void> rejectIntervention(
    Intervention intervention,
    String reason,
  ) async {
    try {
      // Invalider le cache avant l'appel API
      CacheHelper.clearByPrefix('interventions_');

      // Mise à jour optimiste de l'UI - mettre à jour immédiatement
      final interventionIndex = interventions.indexWhere(
        (i) => i.id == intervention.id,
      );
      final pendingIndex = pendingInterventions.indexWhere(
        (i) => i.id == intervention.id,
      );

      if (interventionIndex != -1 || pendingIndex != -1) {
        final originalIntervention =
            interventionIndex != -1
                ? interventions[interventionIndex]
                : pendingInterventions[pendingIndex];
        final updatedIntervention = Intervention(
          id: originalIntervention.id,
          title: originalIntervention.title,
          description: originalIntervention.description,
          type: originalIntervention.type,
          status: 'rejected', // Rejetée
          priority: originalIntervention.priority,
          scheduledDate: originalIntervention.scheduledDate,
          startDate: originalIntervention.startDate,
          endDate: originalIntervention.endDate,
          location: originalIntervention.location,
          clientId: originalIntervention.clientId,
          clientName: originalIntervention.clientName,
          clientPhone: originalIntervention.clientPhone,
          clientEmail: originalIntervention.clientEmail,
          equipment: originalIntervention.equipment,
          problemDescription: originalIntervention.problemDescription,
          solution: originalIntervention.solution,
          notes: originalIntervention.notes,
          attachments: originalIntervention.attachments,
          estimatedDuration: originalIntervention.estimatedDuration,
          actualDuration: originalIntervention.actualDuration,
          cost: originalIntervention.cost,
          createdAt: originalIntervention.createdAt,
          updatedAt: originalIntervention.updatedAt,
          createdBy: originalIntervention.createdBy,
          approvedBy: originalIntervention.approvedBy,
          approvedAt: originalIntervention.approvedAt,
          rejectionReason: reason,
          completionNotes: originalIntervention.completionNotes,
        );

        if (interventionIndex != -1) {
          interventions[interventionIndex] = updatedIntervention;
        }
        if (pendingIndex != -1) {
          pendingInterventions.removeAt(pendingIndex);
        }
      }

      // Appel API en arrière-plan
      final success = await _interventionService.rejectIntervention(
        intervention.id!,
        reason: reason,
      );

      if (success) {
        // Rafraîchir les compteurs du dashboard patron
        DashboardRefreshHelper.refreshPatronCounter('intervention');

        // Notifier l'utilisateur concerné du rejet
        NotificationHelper.notifyRejection(
          entityType: 'intervention',
          entityName: NotificationHelper.getEntityDisplayName(
            'intervention',
            intervention,
          ),
          entityId: intervention.id.toString(),
          reason: reason,
          route: NotificationHelper.getEntityRoute(
            'intervention',
            intervention.id.toString(),
          ),
          entity: intervention,
        );

        _notifyDashboard();

        errorHelperShowSnackbar?.call(
          'Succès',
          'Intervention rejetée',
        );

        // Recharger les données en arrière-plan avec le filtre actuel
        // pour synchroniser avec le serveur (mais garder la mise à jour optimiste)
        Future.delayed(const Duration(milliseconds: 500), () {
          loadInterventions(
            statusFilter: _currentStatusFilter,
          ).catchError((e) {});
          loadInterventionStats().catchError((e) {});
          loadPendingInterventions().catchError((e) {});
        });
      } else {
        // En cas d'échec, recharger pour restaurer l'état
        await loadInterventions(statusFilter: _currentStatusFilter);
        await loadPendingInterventions();
        throw Exception('Erreur lors du rejet');
      }
    } catch (e) {
      // Vérifier si l'erreur est survenue après un succès
      final errorStr = e.toString().toLowerCase();

      // Ne pas afficher d'erreur pour les erreurs de parsing ou de rechargement
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        // Probablement une erreur de parsing après un succès
        loadInterventions(
          statusFilter: _currentStatusFilter,
        ).catchError((e) {});
        loadPendingInterventions().catchError((e) {});
        return;
      }

      // Pour les autres erreurs, vérifier si c'est une erreur d'authentification
      if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('forbidden')) {
        // Erreur d'authentification - afficher
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Erreur d\'authentification. Veuillez vous reconnecter.',
        );
      } else {
        // Autre erreur - recharger pour vérifier l'état
        loadInterventions(
          statusFilter: _currentStatusFilter,
        ).catchError((e) {});
        loadPendingInterventions().catchError((e) {});
        // Ne pas afficher d'erreur car l'action peut avoir réussi
      }
    }
  }

  // Démarrer une intervention
  Future<void> startIntervention(Intervention intervention) async {
    try {
      isLoading = true;

      final success = await _interventionService.startIntervention(
        intervention.id!,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
      );

      if (success) {
        await loadInterventions();
        await loadInterventionStats();
        _notifyDashboard();

        errorHelperShowSnackbar?.call(
          'Succès',
          'Intervention démarrée',
        );
      } else {
        throw Exception('Erreur lors du démarrage');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de démarrer l\'intervention',
      );
    } finally {
      isLoading = false;
    }
  }

  // Terminer une intervention
  Future<void> completeIntervention(Intervention intervention) async {
    try {
      isLoading = true;

      final success = await _interventionService.completeIntervention(
        intervention.id!,
        solution: solutionController.text.trim(),
        completionNotes:
            completionNotesController.text.trim().isEmpty
                ? null
                : completionNotesController.text.trim(),
        actualDuration: double.tryParse(actualDurationController.text),
        cost: double.tryParse(costController.text),
      );

      if (success) {
        await loadInterventions();
        await loadInterventionStats();
        _notifyDashboard();

        errorHelperShowSnackbar?.call(
          'Succès',
          'Intervention terminée',
        );
      } else {
        throw Exception('Erreur lors de la finalisation');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de terminer l\'intervention',
      );
    } finally {
      isLoading = false;
    }
  }

  // Supprimer une intervention
  Future<void> deleteIntervention(Intervention intervention) async {
    try {
      isLoading = true;

      final success = await _interventionService.deleteIntervention(
        intervention.id!,
      );
      if (success) {
        interventions.removeWhere((i) => i.id == intervention.id);
        await loadInterventionStats();

        errorHelperShowSnackbar?.call(
          'Succès',
          'Intervention supprimée avec succès',
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de supprimer l\'intervention',
      );
    } finally {
      isLoading = false;
    }
  }

  // Remplir le formulaire avec les données d'une intervention
  void fillForm(Intervention intervention) {
    titleController.text = intervention.title;
    descriptionController.text = intervention.description;
    selectedTypeForm = intervention.type;
    selectedPriorityForm = intervention.priority;
    selectedScheduledDate = intervention.scheduledDate;
    selectedStartDate = intervention.startDate;
    selectedEndDate = intervention.endDate;
    locationController.text = intervention.location ?? '';
    // Si l'intervention a un clientId, charger le client
    if (intervention.clientId != null) {
      // On pourrait charger le client ici si nécessaire
      // Pour l'instant, on garde juste les informations textuelles
    }
    clientNameController.text = intervention.clientName ?? '';
    clientPhoneController.text = intervention.clientPhone ?? '';
    clientEmailController.text = intervention.clientEmail ?? '';
    equipmentController.text = intervention.equipment ?? '';
    problemController.text = intervention.problemDescription ?? '';
    solutionController.text = intervention.solution ?? '';
    notesController.text = intervention.notes ?? '';
    completionNotesController.text = intervention.completionNotes ?? '';
    costController.text = intervention.cost?.toString() ?? '';
    estimatedDurationController.text =
        intervention.estimatedDuration?.toString() ?? '';
    actualDurationController.text =
        intervention.actualDuration?.toString() ?? '';
    selectedAttachments.clear();
    selectedAttachments.addAll(intervention.attachments ?? []);
    selectedIntervention = intervention;
  }

  void _notifyDashboard() {
    try {
      TechnicienDashboardController.to.refreshPendingEntities();
    } catch (e) {}
  }

  // Vider le formulaire
  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    selectedTypeForm = 'external';
    selectedPriorityForm = 'medium';
    selectedScheduledDate = null;
    selectedStartDate = null;
    selectedEndDate = null;
    locationController.clear();
    clientNameController.clear();
    clientPhoneController.clear();
    clientEmailController.clear();
    equipmentController.clear();
    problemController.clear();
    solutionController.clear();
    notesController.clear();
    completionNotesController.clear();
    costController.clear();
    estimatedDurationController.clear();
    actualDurationController.clear();
    selectedAttachments.clear();
    selectedIntervention = null;
    clearSelectedClient();
  }

  // Rechercher
  void searchInterventions(String query) {
    searchQuery = query;
    loadInterventions();
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    selectedStatus = status;
    loadInterventions();
  }

  // Filtrer par type
  void filterByType(String type) {
    selectedType = type;
    loadInterventions();
  }

  // Filtrer par priorité
  void filterByPriority(String priority) {
    selectedPriority = priority;
    loadInterventions();
  }

  // Sélectionner le type
  void selectType(String type) {
    selectedTypeForm = type;
  }

  // Sélectionner la priorité
  void selectPriority(String priority) {
    selectedPriorityForm = priority;
  }

  // Sélectionner la date programmée
  void selectScheduledDate(DateTime date) {
    selectedScheduledDate = date;
  }

  // Sélectionner la date de début
  void selectStartDate(DateTime date) {
    selectedStartDate = date;
  }

  // Sélectionner la date de fin
  void selectEndDate(DateTime date) {
    selectedEndDate = date;
  }

  // Obtenir les types d'intervention
  List<Map<String, dynamic>> get interventionTypes => [
    {
      'value': 'external',
      'label': 'Externe',
      'icon': Icons.location_on,
      'color': Colors.blue,
    },
    {
      'value': 'on_site',
      'label': 'Sur place',
      'icon': Icons.home,
      'color': Colors.green,
    },
  ];

  // Obtenir les priorités
  List<Map<String, dynamic>> get priorities => [
    {'value': 'low', 'label': 'Faible', 'color': Colors.green},
    {'value': 'medium', 'label': 'Moyenne', 'color': Colors.blue},
    {'value': 'high', 'label': 'Élevée', 'color': Colors.orange},
    {'value': 'urgent', 'label': 'Urgente', 'color': Colors.red},
  ];

  // Obtenir les statuts
  List<Map<String, dynamic>> get statuses => [
    {'value': 'pending', 'label': 'En attente', 'color': Colors.orange},
    {'value': 'approved', 'label': 'Approuvée', 'color': Colors.blue},
    {'value': 'in_progress', 'label': 'En cours', 'color': Colors.purple},
    {'value': 'completed', 'label': 'Terminée', 'color': Colors.green},
    {'value': 'rejected', 'label': 'Rejetée', 'color': Colors.red},
  ];

  // Chargement des clients validés : cache Hive d'abord, puis API.
  Future<void> loadValidatedClients() async {
    isLoadingClients = true;
    final cached = ClientService.getCachedClients(1);
    if (cached.isNotEmpty) {
      availableClients.clear();
      availableClients.addAll(cached);
      isLoadingClients = false;
    } else {
      availableClients.clear();
    }
    try {
      final clients = await _clientService.getClients(status: 1);
      availableClients.clear();
      availableClients.addAll(clients);
    } catch (e) {
      if (availableClients.isEmpty) {
        final fallback = ClientService.getCachedClients(1);
        if (fallback.isNotEmpty) {
          availableClients.clear();
          availableClients.addAll(fallback);
        } else {
          errorHelperShowSnackbar?.call(
            'Erreur',
            'Impossible de charger les clients validés',
          );
        }
      }
    } finally {
      isLoadingClients = false;
    }
  }

  // Sélection d'un client
  void selectClientForIntervention(Client client) {
    selectedClient = client;
    // Remplir automatiquement les champs du formulaire
    // Prioriser le nom de l'entreprise
    final displayName =
        client.nomEntreprise?.isNotEmpty == true
            ? client.nomEntreprise!
            : '${client.nom ?? ''} ${client.prenom ?? ''}'.trim().isNotEmpty
            ? '${client.nom ?? ''} ${client.prenom ?? ''}'.trim()
            : 'Client #${client.id}';
    clientNameController.text = displayName;
    clientEmailController.text = client.email ?? '';
    clientPhoneController.text = client.contact ?? '';
    // Si le client a une adresse, on peut l'utiliser pour la localisation
    if (client.adresse != null && locationController.text.isEmpty) {
      locationController.text = client.adresse!;
    }
  }

  // Effacer la sélection du client
  void clearSelectedClient() {
    selectedClient = null;
    // Ne pas effacer les champs manuellement remplis
  }

  // Vérifier les permissions
  bool get canManageInterventions {
    final userRole = AuthController.to.userAuth?.role;
    return userRole == 1 || userRole == 6; // Admin, Technicien
  }

  bool get canApproveInterventions {
    final userRole = AuthController.to.userAuth?.role;
    return userRole == 1 || userRole == 4; // Admin, Patron
  }

  bool get canViewInterventions {
    final userRole = AuthController.to.userAuth?.role;
    return userRole != null; // Tous les rôles
  }

  // Obtenir les interventions par statut
  List<Intervention> get interventionsByStatus {
    if (selectedStatus == 'all') return interventions;
    return interventions
        .where((intervention) => intervention.status == selectedStatus)
        .toList();
  }

  // Obtenir les interventions par type
  List<Intervention> get interventionsByType {
    if (selectedType == 'all') return interventions;
    return interventions
        .where((intervention) => intervention.type == selectedType)
        .toList();
  }

  // Obtenir les interventions filtrées
  List<Intervention> get filteredInterventions {
    List<Intervention> filtered = interventions;

    if (selectedStatus != 'all') {
      filtered =
          filtered
              .where(
                (intervention) => intervention.status == selectedStatus,
              )
              .toList();
    }

    if (selectedType != 'all') {
      filtered =
          filtered
              .where((intervention) => intervention.type == selectedType)
              .toList();
    }

    if (selectedPriority != 'all') {
      filtered =
          filtered
              .where(
                (intervention) =>
                    intervention.priority == selectedPriority,
              )
              .toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (intervention) =>
                    intervention.title.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    intervention.description.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    (intervention.clientName?.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();
    }

    return filtered;
  }
}
