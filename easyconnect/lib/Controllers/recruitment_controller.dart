import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easyconnect/Models/recruitment_model.dart';
import 'package:easyconnect/services/recruitment_service.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/error_helper.dart';

class RecruitmentController {
  static final RecruitmentController _instance = RecruitmentController._();
  static RecruitmentController get to => _instance;
  factory RecruitmentController() => _instance;
  RecruitmentController._();

  final RecruitmentService _recruitmentService = RecruitmentService.to;

  // Variables
  bool isLoading = false;
  final List<RecruitmentRequest> recruitmentRequests = [];
  final List<RecruitmentRequest> filteredRequests = [];
  RecruitmentRequest? selectedRequest;
  RecruitmentStats? recruitmentStats;
  final List<String> departments = [];
  final List<String> positions = [];

  // Variables pour le formulaire
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController requirementsController = TextEditingController();
  final TextEditingController responsibilitiesController =
      TextEditingController();
  final TextEditingController salaryRangeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  // Variables de filtrage
  String selectedStatus = 'all';
  String selectedDepartment = 'all';
  String selectedPosition = 'all';
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  // Variables pour le formulaire de création
  final List<String> selectedDepartmentsForm = [];
  final List<String> selectedPositionsForm = [];
  String selectedEmploymentTypeForm = '';
  String selectedExperienceLevelForm = '';
  DateTime? selectedDeadlineForm;
  int numberOfPositionsForm = 1;

  // Variables pour les permissions
  bool canManageRecruitment = true;
  bool canApproveRecruitment = true;
  bool canViewAllRecruitment = true;

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    requirementsController.dispose();
    responsibilitiesController.dispose();
    salaryRangeController.dispose();
    locationController.dispose();
    searchController.dispose();
  }

  // Charger les départements
  Future<void> loadDepartments() async {
    try {
      final depts = await _recruitmentService.getDepartments();
      departments.clear();
      departments.addAll(depts);
    } catch (e) {}
  }

  // Charger les postes
  Future<void> loadPositions() async {
    try {
      final pos = await _recruitmentService.getPositions();
      positions.clear();
      positions.addAll(pos);
    } catch (e) {}
  }

  bool _isLoadingRecruitmentsInProgress = false;

  /// Charge les demandes de recrutement : Hive d'abord (affichage immédiat), puis API dans la même méthode.
  Future<void> loadRecruitmentRequests({bool forceRefresh = false}) async {
    if (_isLoadingRecruitmentsInProgress) return;
    _isLoadingRecruitmentsInProgress = true;

    isLoading = true;
    if (!forceRefresh) {
      final cached = RecruitmentService.getCachedRecruitments();
      if (cached.isNotEmpty) {
        recruitmentRequests.clear();
        recruitmentRequests.addAll(cached);
        applyFilters();
        isLoading = false;
      } else {
        recruitmentRequests.clear();
      }
    } else {
      recruitmentRequests.clear();
    }

    try {
      final requests = await _recruitmentService.getAllRecruitmentRequests(
        status: selectedStatus != 'all' ? selectedStatus : null,
        department: selectedDepartment != 'all' ? selectedDepartment : null,
        position: selectedPosition != 'all' ? selectedPosition : null,
      );

      recruitmentRequests.clear();
      recruitmentRequests.addAll(requests);
      applyFilters();
    } catch (e) {
      if (recruitmentRequests.isEmpty) {
        final fallback = RecruitmentService.getCachedRecruitments();
        if (fallback.isNotEmpty) {
          recruitmentRequests.clear();
          recruitmentRequests.addAll(fallback);
          applyFilters();
        } else {
          final err = e.toString().toLowerCase();
          if (!err.contains('401') && !err.contains('unauthorized')) {
            errorHelperShowSnackbar?.call(
              'Erreur',
              'Impossible de charger les demandes de recrutement',
              duration: const Duration(seconds: 5),
            );
          }
        }
      }
    } finally {
      isLoading = false;
      _isLoadingRecruitmentsInProgress = false;
    }
  }

  // Charger les statistiques
  Future<void> loadRecruitmentStats() async {
    try {
      final stats = await _recruitmentService.getRecruitmentStats(
        startDate: selectedStartDate,
        endDate: selectedEndDate,
        department:
            selectedDepartment != 'all' ? selectedDepartment : null,
      );
      recruitmentStats = stats;
    } catch (e) {}
  }

  // Appliquer les filtres
  void applyFilters() {
    List<RecruitmentRequest> filtered =
        recruitmentRequests.where((request) {
          // Filtre par recherche
          if (searchController.text.isNotEmpty) {
            final searchTerm = searchController.text.toLowerCase();
            if (!request.title.toLowerCase().contains(searchTerm) &&
                !request.position.toLowerCase().contains(searchTerm) &&
                !request.department.toLowerCase().contains(searchTerm)) {
              return false;
            }
          }

          return true;
        }).toList();

    filteredRequests.clear();
    filteredRequests.addAll(filtered);
  }

  // Rechercher dans les demandes
  void searchRequests(String query) {
    searchController.text = query;
    applyFilters();
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    selectedStatus = status;
    loadRecruitmentRequests();
  }

  // Filtrer par département
  void filterByDepartment(String department) {
    selectedDepartment = department;
    loadRecruitmentRequests();
  }

  // Filtrer par poste
  void filterByPosition(String position) {
    selectedPosition = position;
    loadRecruitmentRequests();
  }

  // Filtrer par date
  void filterByDateRange(DateTime? startDate, DateTime? endDate) {
    selectedStartDate = startDate;
    selectedEndDate = endDate;
    loadRecruitmentStats();
  }

  // Créer une demande de recrutement
  Future<bool> createRecruitmentRequest() async {
    try {
      // Vérification des champs obligatoires
      final title = titleController.text.trim();
      final departmentsList = selectedDepartmentsForm;
      final positionsList = selectedPositionsForm;
      final description = descriptionController.text.trim();
      final requirements = requirementsController.text.trim();
      final responsibilities = responsibilitiesController.text.trim();
      final employmentType = selectedEmploymentTypeForm;
      final experienceLevel = selectedExperienceLevelForm;
      final salaryRange = salaryRangeController.text.trim();
      final location = locationController.text.trim();
      final deadline = selectedDeadlineForm;
      final numberOfPositions = numberOfPositionsForm;

      // Validation des champs obligatoires
      if (title.isEmpty) {
        errorHelperShowSnackbar?.call('Erreur', 'Le titre est obligatoire');
        return false;
      }

      if (departmentsList.isEmpty) {
        errorHelperShowSnackbar?.call('Erreur', 'Au moins un département est obligatoire');
        return false;
      }

      if (positionsList.isEmpty) {
        errorHelperShowSnackbar?.call('Erreur', 'Au moins un poste est obligatoire');
        return false;
      }

      // Validation de la description (minimum 50 caractères)
      if (description.isEmpty) {
        errorHelperShowSnackbar?.call('Erreur', 'La description est obligatoire');
        return false;
      }
      if (description.length < 50) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'La description doit contenir au moins 50 caractères (actuellement: ${description.length})',
        );
        return false;
      }

      // Validation des exigences (minimum 20 caractères)
      if (requirements.isEmpty) {
        errorHelperShowSnackbar?.call('Erreur', 'Les exigences sont obligatoires');
        return false;
      }
      if (requirements.length < 20) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Les exigences doivent contenir au moins 20 caractères (actuellement: ${requirements.length})',
        );
        return false;
      }

      // Validation des responsabilités (minimum 20 caractères)
      if (responsibilities.isEmpty) {
        errorHelperShowSnackbar?.call('Erreur', 'Les responsabilités sont obligatoires');
        return false;
      }
      if (responsibilities.length < 20) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Les responsabilités doivent contenir au moins 20 caractères (actuellement: ${responsibilities.length})',
        );
        return false;
      }

      if (employmentType.isEmpty) {
        errorHelperShowSnackbar?.call('Erreur', 'Le type d\'emploi est obligatoire');
        return false;
      }

      if (experienceLevel.isEmpty) {
        errorHelperShowSnackbar?.call('Erreur', 'Le niveau d\'expérience est obligatoire');
        return false;
      }

      if (salaryRange.isEmpty) {
        errorHelperShowSnackbar?.call('Erreur', 'La fourchette salariale est obligatoire');
        return false;
      }

      if (location.isEmpty) {
        errorHelperShowSnackbar?.call('Erreur', 'La localisation est obligatoire');
        return false;
      }

      if (deadline == null) {
        errorHelperShowSnackbar?.call('Erreur', 'La date limite est obligatoire');
        return false;
      }

      // Vérifier que la date limite est dans le futur
      if (deadline.isBefore(DateTime.now())) {
        errorHelperShowSnackbar?.call('Erreur', 'La date limite doit être dans le futur');
        return false;
      }

      // Convertir les listes en chaînes séparées par des virgules pour le backend
      final departmentString = departmentsList.join(', ');
      final positionString = positionsList.join(', ');

      final result = await _recruitmentService.createRecruitmentRequest(
        title: title,
        department: departmentString,
        position: positionString,
        description: description,
        requirements: requirements,
        responsibilities: responsibilities,
        numberOfPositions: numberOfPositions,
        employmentType: employmentType,
        experienceLevel: experienceLevel,
        salaryRange: salaryRange,
        location: location,
        applicationDeadline: deadline,
      );

      if (result['success'] == true) {
        // Publier automatiquement le recrutement créé
        if (result['data'] != null && result['data']['id'] != null) {
          final recruitmentId = result['data']['id'] as int;
          final recruitmentData = result['data'];

          // Notifier le patron de la soumission
          NotificationHelper.notifySubmission(
            entityType: 'recruitment',
            entityName: NotificationHelper.getEntityDisplayName(
              'recruitment',
              recruitmentData,
            ),
            entityId: recruitmentId.toString(),
            route: NotificationHelper.getEntityRoute(
              'recruitment',
              recruitmentId.toString(),
            ),
          );

          try {
            final publishResult = await _recruitmentService
                .publishRecruitmentRequest(recruitmentId);
            if (publishResult['success'] == true) {
              errorHelperShowSnackbar?.call(
                'Succès',
                'Demande de recrutement créée et publiée avec succès',
              );
            } else {
              errorHelperShowSnackbar?.call(
                'Succès',
                'Demande de recrutement créée avec succès (publication en attente)',
              );
            }
          } catch (e) {
            errorHelperShowSnackbar?.call(
              'Succès',
              'Demande de recrutement créée avec succès (publication en attente)',
            );
          }
        } else {
          errorHelperShowSnackbar?.call('Succès', 'Demande de recrutement créée avec succès');
        }

        clearForm();
        // Réinitialiser le filtre de statut pour charger tous les recrutements
        selectedStatus = 'all';
        await loadRecruitmentRequests();
        await loadRecruitmentStats();
        return true;
      } else {
        final errorMessage = result['message'] ?? 'Erreur lors de la création';
        errorHelperShowSnackbar?.call('Erreur', errorMessage);
        return false;
      }
    } catch (e) {
      // Extraire le message d'erreur du backend si disponible
      String errorMessage = 'Erreur lors de la création de la demande';
      if (e.toString().contains('description field must be at least 50')) {
        errorMessage = 'La description doit contenir au moins 50 caractères';
      } else if (e.toString().contains('requirements') &&
          e.toString().contains('at least 20')) {
        errorMessage = 'Les exigences doivent contenir au moins 20 caractères';
      } else if (e.toString().contains('responsibilities') &&
          e.toString().contains('at least 20')) {
        errorMessage =
            'Les responsabilités doivent contenir au moins 20 caractères';
      } else if (e.toString().contains('application_deadline')) {
        errorMessage = 'La date limite doit être dans le futur';
      } else {
        // Essayer d'extraire le message depuis l'exception
        final errorStr = e.toString();
        if (errorStr.contains('message')) {
          try {
            final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(errorStr);
            if (jsonMatch != null) {
              final jsonStr = jsonMatch.group(0);
              final decoded = jsonDecode(jsonStr!);
              errorMessage = decoded['message'] ?? errorMessage;
            }
          } catch (_) {
            // Si le parsing échoue, utiliser le message par défaut
          }
        }
      }

      errorHelperShowSnackbar?.call('Erreur', errorMessage);
      return false;
    }
  }

  // Publier une demande
  Future<void> publishRecruitmentRequest(RecruitmentRequest request) async {
    try {
      final result = await _recruitmentService.publishRecruitmentRequest(
        request.id!,
      );

      if (result['success'] == true) {
        errorHelperShowSnackbar?.call('Succès', 'Demande publiée avec succès');
        // Recharger tous les recrutements pour mettre à jour la liste
        selectedStatus = 'all';
        await loadRecruitmentRequests();
        await loadRecruitmentStats();
      } else {
        errorHelperShowSnackbar?.call(
          'Erreur',
          result['message'] ?? 'Erreur lors de la publication',
        );
      }
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', 'Erreur lors de la publication: $e');
    }
  }

  // Approuver une demande
  Future<void> approveRecruitmentRequest(RecruitmentRequest request) async {
    try {
      final result = await _recruitmentService.approveRecruitmentRequest(
        request.id!,
      );

      if (result['success'] == true) {
        // Notifier l'utilisateur concerné de la validation
        NotificationHelper.notifyValidation(
          entityType: 'recruitment',
          entityName: NotificationHelper.getEntityDisplayName(
            'recruitment',
            request,
          ),
          entityId: request.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'recruitment',
            request.id.toString(),
          ),
          entity: request,
        );

        errorHelperShowSnackbar?.call('Succès', 'Demande approuvée avec succès');
        // Recharger tous les recrutements pour mettre à jour la liste
        selectedStatus = 'all';
        await loadRecruitmentRequests();
        await loadRecruitmentStats();
      } else {
        errorHelperShowSnackbar?.call(
          'Erreur',
          result['message'] ?? 'Erreur lors de l\'approbation',
        );
      }
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', 'Erreur lors de l\'approbation: $e');
    }
  }

  // Rejeter une demande
  Future<void> rejectRecruitmentRequest(
    RecruitmentRequest request,
    String reason,
  ) async {
    try {
      final result = await _recruitmentService.rejectRecruitmentRequest(
        request.id!,
        rejectionReason: reason,
      );

      if (result['success'] == true) {
        // Notifier l'utilisateur concerné du rejet
        NotificationHelper.notifyRejection(
          entityType: 'recruitment',
          entityName: NotificationHelper.getEntityDisplayName(
            'recruitment',
            request,
          ),
          entityId: request.id.toString(),
          reason: reason,
          route: NotificationHelper.getEntityRoute(
            'recruitment',
            request.id.toString(),
          ),
          entity: request,
        );

        errorHelperShowSnackbar?.call('Succès', 'Demande rejetée');
        // Recharger tous les recrutements pour mettre à jour la liste
        selectedStatus = 'all';
        await loadRecruitmentRequests();
        await loadRecruitmentStats();
      } else {
        errorHelperShowSnackbar?.call('Erreur', result['message'] ?? 'Erreur lors du rejet');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', 'Erreur lors du rejet: $e');
    }
  }

  // Fermer une demande
  Future<void> closeRecruitmentRequest(RecruitmentRequest request) async {
    try {
      final result = await _recruitmentService.closeRecruitmentRequest(
        request.id!,
      );

      if (result['success'] == true) {
        errorHelperShowSnackbar?.call('Succès', 'Demande fermée');
        loadRecruitmentRequests();
        loadRecruitmentStats();
      } else {
        errorHelperShowSnackbar?.call(
          'Erreur',
          result['message'] ?? 'Erreur lors de la fermeture',
        );
      }
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', 'Erreur lors de la fermeture: $e');
    }
  }

  // Annuler une demande
  Future<void> cancelRecruitmentRequest(RecruitmentRequest request) async {
    try {
      final result = await _recruitmentService.cancelRecruitmentRequest(
        request.id!,
      );

      if (result['success'] == true) {
        errorHelperShowSnackbar?.call('Succès', 'Demande annulée');
        loadRecruitmentRequests();
        loadRecruitmentStats();
      } else {
        errorHelperShowSnackbar?.call(
          'Erreur',
          result['message'] ?? 'Erreur lors de l\'annulation',
        );
      }
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', 'Erreur lors de l\'annulation: $e');
    }
  }

  // Supprimer une demande
  Future<void> deleteRecruitmentRequest(RecruitmentRequest request) async {
    try {
      final result = await _recruitmentService.deleteRecruitmentRequest(
        request.id!,
      );

      if (result['success'] == true) {
        errorHelperShowSnackbar?.call('Succès', 'Demande supprimée');
        loadRecruitmentRequests();
        loadRecruitmentStats();
      } else {
        errorHelperShowSnackbar?.call(
          'Erreur',
          result['message'] ?? 'Erreur lors de la suppression',
        );
      }
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', 'Erreur lors de la suppression: $e');
    }
  }

  // Sélectionner une date d'échéance
  Future<void> selectDeadline(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          selectedDeadlineForm ??
          DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      selectedDeadlineForm = date;
    }
  }

  // Ajouter/Retirer un département (sélection multiple)
  void toggleDepartment(String department) {
    if (selectedDepartmentsForm.contains(department)) {
      selectedDepartmentsForm.remove(department);
    } else {
      selectedDepartmentsForm.add(department);
    }
  }

  // Ajouter/Retirer un poste (sélection multiple)
  void togglePosition(String position) {
    if (selectedPositionsForm.contains(position)) {
      selectedPositionsForm.remove(position);
    } else {
      selectedPositionsForm.add(position);
    }
  }

  // Vérifier si un département est sélectionné
  bool isDepartmentSelected(String department) {
    return selectedDepartmentsForm.contains(department);
  }

  // Vérifier si un poste est sélectionné
  bool isPositionSelected(String position) {
    return selectedPositionsForm.contains(position);
  }

  // Sélectionner un type d'emploi
  void selectEmploymentType(String type) {
    selectedEmploymentTypeForm = type;
  }

  // Sélectionner un niveau d'expérience
  void selectExperienceLevel(String level) {
    selectedExperienceLevelForm = level;
  }

  // Réinitialiser le formulaire
  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    requirementsController.clear();
    responsibilitiesController.clear();
    salaryRangeController.clear();
    locationController.clear();
    selectedDepartmentsForm.clear();
    selectedPositionsForm.clear();
    selectedEmploymentTypeForm = '';
    selectedExperienceLevelForm = '';
    selectedDeadlineForm = null;
    numberOfPositionsForm = 1;
  }

  // Réinitialiser les filtres
  void clearFilters() {
    selectedStatus = 'all';
    selectedDepartment = 'all';
    selectedPosition = 'all';
    selectedStartDate = null;
    selectedEndDate = null;
    searchController.clear();
    loadRecruitmentRequests();
  }

  // Obtenir les options de statut
  List<Map<String, String>> get statusOptions => [
    {'value': 'all', 'label': 'Tous'},
    {'value': 'draft', 'label': 'Brouillon'},
    {'value': 'published', 'label': 'Publié'},
    {'value': 'closed', 'label': 'Fermé'},
    {'value': 'cancelled', 'label': 'Annulé'},
  ];

  // Obtenir les options de département
  List<Map<String, String>> get departmentOptions {
    final options = [
      {'value': 'all', 'label': 'Tous'},
    ];
    for (final dept in departments) {
      options.add({'value': dept, 'label': dept});
    }
    return options;
  }

  // Obtenir les options de poste
  List<Map<String, String>> get positionOptions {
    final options = [
      {'value': 'all', 'label': 'Tous'},
    ];
    for (final pos in positions) {
      options.add({'value': pos, 'label': pos});
    }
    return options;
  }

  // Obtenir les options de type d'emploi
  List<Map<String, String>> get employmentTypeOptions => [
    {'value': 'full_time', 'label': 'Temps plein'},
    {'value': 'part_time', 'label': 'Temps partiel'},
    {'value': 'contract', 'label': 'Contrat'},
    {'value': 'internship', 'label': 'Stage'},
  ];

  // Obtenir les options de niveau d'expérience
  List<Map<String, String>> get experienceLevelOptions => [
    {'value': 'entry', 'label': 'Débutant'},
    {'value': 'junior', 'label': 'Junior (0-2 ans)'},
    {'value': 'mid', 'label': 'Intermédiaire (2-5 ans)'},
    {'value': 'senior', 'label': 'Senior (5-10 ans)'},
    {'value': 'expert', 'label': 'Expert (10+ ans)'},
  ];
}
