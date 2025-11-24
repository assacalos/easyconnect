import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/recruitment_model.dart';
import 'package:easyconnect/services/recruitment_service.dart';

class RecruitmentController extends GetxController {
  final RecruitmentService _recruitmentService = RecruitmentService.to;

  // Variables observables
  final RxBool isLoading = false.obs;
  final RxList<RecruitmentRequest> recruitmentRequests =
      <RecruitmentRequest>[].obs;
  final RxList<RecruitmentRequest> filteredRequests =
      <RecruitmentRequest>[].obs;
  final Rx<RecruitmentRequest?> selectedRequest = Rx<RecruitmentRequest?>(null);
  final Rx<RecruitmentStats?> recruitmentStats = Rx<RecruitmentStats?>(null);
  final RxList<String> departments = <String>[].obs;
  final RxList<String> positions = <String>[].obs;

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
  final RxString selectedStatus = 'all'.obs;
  final RxString selectedDepartment = 'all'.obs;
  final RxString selectedPosition = 'all'.obs;
  final Rx<DateTime?> selectedStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedEndDate = Rx<DateTime?>(null);

  // Variables pour le formulaire de création
  final RxString selectedDepartmentForm = ''.obs;
  final RxString selectedPositionForm = ''.obs;
  final RxString selectedEmploymentTypeForm = ''.obs;
  final RxString selectedExperienceLevelForm = ''.obs;
  final Rx<DateTime?> selectedDeadlineForm = Rx<DateTime?>(null);
  final RxInt numberOfPositionsForm = 1.obs;

  // Variables pour les permissions
  final RxBool canManageRecruitment =
      true.obs; // TODO: Implémenter la vérification des permissions
  final RxBool canApproveRecruitment =
      true.obs; // TODO: Implémenter la vérification des permissions
  final RxBool canViewAllRecruitment =
      true.obs; // TODO: Implémenter la vérification des permissions

  @override
  void onInit() {
    super.onInit();
    loadDepartments();
    loadPositions();
    loadRecruitmentRequests();
    loadRecruitmentStats();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    requirementsController.dispose();
    responsibilitiesController.dispose();
    salaryRangeController.dispose();
    locationController.dispose();
    searchController.dispose();
    super.onClose();
  }

  // Charger les départements
  Future<void> loadDepartments() async {
    try {
      final depts = await _recruitmentService.getDepartments();
      departments.value = depts;
    } catch (e) {}
  }

  // Charger les postes
  Future<void> loadPositions() async {
    try {
      final pos = await _recruitmentService.getPositions();
      positions.value = pos;
    } catch (e) {}
  }

  // Charger les demandes de recrutement
  Future<void> loadRecruitmentRequests() async {
    try {
      isLoading.value = true;

      final requests = await _recruitmentService.getAllRecruitmentRequests(
        status: selectedStatus.value != 'all' ? selectedStatus.value : null,
        department:
            selectedDepartment.value != 'all' ? selectedDepartment.value : null,
        position:
            selectedPosition.value != 'all' ? selectedPosition.value : null,
      );

      recruitmentRequests.value = requests;
      applyFilters();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les demandes de recrutement',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Charger les statistiques
  Future<void> loadRecruitmentStats() async {
    try {
      final stats = await _recruitmentService.getRecruitmentStats(
        startDate: selectedStartDate.value,
        endDate: selectedEndDate.value,
        department:
            selectedDepartment.value != 'all' ? selectedDepartment.value : null,
      );
      recruitmentStats.value = stats;
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

    filteredRequests.value = filtered;
  }

  // Rechercher dans les demandes
  void searchRequests(String query) {
    searchController.text = query;
    applyFilters();
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    selectedStatus.value = status;
    loadRecruitmentRequests();
  }

  // Filtrer par département
  void filterByDepartment(String department) {
    selectedDepartment.value = department;
    loadRecruitmentRequests();
  }

  // Filtrer par poste
  void filterByPosition(String position) {
    selectedPosition.value = position;
    loadRecruitmentRequests();
  }

  // Filtrer par date
  void filterByDateRange(DateTime? startDate, DateTime? endDate) {
    selectedStartDate.value = startDate;
    selectedEndDate.value = endDate;
    loadRecruitmentStats();
  }

  // Créer une demande de recrutement
  Future<bool> createRecruitmentRequest() async {
    try {
      // Vérification des champs obligatoires
      final title = titleController.text.trim();
      final department = selectedDepartmentForm.value;
      final position = selectedPositionForm.value;
      final description = descriptionController.text.trim();
      final requirements = requirementsController.text.trim();
      final responsibilities = responsibilitiesController.text.trim();
      final employmentType = selectedEmploymentTypeForm.value;
      final experienceLevel = selectedExperienceLevelForm.value;
      final salaryRange = salaryRangeController.text.trim();
      final location = locationController.text.trim();
      final deadline = selectedDeadlineForm.value;
      final numberOfPositions = numberOfPositionsForm.value;

      // Validation des champs obligatoires
      if (title.isEmpty) {
        Get.snackbar('Erreur', 'Le titre est obligatoire');
        return false;
      }

      if (department.isEmpty) {
        Get.snackbar('Erreur', 'Le département est obligatoire');
        return false;
      }

      if (position.isEmpty) {
        Get.snackbar('Erreur', 'Le poste est obligatoire');
        return false;
      }

      // Validation de la description (minimum 50 caractères)
      if (description.isEmpty) {
        Get.snackbar('Erreur', 'La description est obligatoire');
        return false;
      }
      if (description.length < 50) {
        Get.snackbar(
          'Erreur',
          'La description doit contenir au moins 50 caractères (actuellement: ${description.length})',
        );
        return false;
      }

      // Validation des exigences (minimum 20 caractères)
      if (requirements.isEmpty) {
        Get.snackbar('Erreur', 'Les exigences sont obligatoires');
        return false;
      }
      if (requirements.length < 20) {
        Get.snackbar(
          'Erreur',
          'Les exigences doivent contenir au moins 20 caractères (actuellement: ${requirements.length})',
        );
        return false;
      }

      // Validation des responsabilités (minimum 20 caractères)
      if (responsibilities.isEmpty) {
        Get.snackbar('Erreur', 'Les responsabilités sont obligatoires');
        return false;
      }
      if (responsibilities.length < 20) {
        Get.snackbar(
          'Erreur',
          'Les responsabilités doivent contenir au moins 20 caractères (actuellement: ${responsibilities.length})',
        );
        return false;
      }

      if (employmentType.isEmpty) {
        Get.snackbar('Erreur', 'Le type d\'emploi est obligatoire');
        return false;
      }

      if (experienceLevel.isEmpty) {
        Get.snackbar('Erreur', 'Le niveau d\'expérience est obligatoire');
        return false;
      }

      if (salaryRange.isEmpty) {
        Get.snackbar('Erreur', 'La fourchette salariale est obligatoire');
        return false;
      }

      if (location.isEmpty) {
        Get.snackbar('Erreur', 'La localisation est obligatoire');
        return false;
      }

      if (deadline == null) {
        Get.snackbar('Erreur', 'La date limite est obligatoire');
        return false;
      }

      // Vérifier que la date limite est dans le futur
      if (deadline.isBefore(DateTime.now())) {
        Get.snackbar('Erreur', 'La date limite doit être dans le futur');
        return false;
      }

      final result = await _recruitmentService.createRecruitmentRequest(
        title: title,
        department: department,
        position: position,
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

          try {
            final publishResult = await _recruitmentService
                .publishRecruitmentRequest(recruitmentId);
            if (publishResult['success'] == true) {
              Get.snackbar(
                'Succès',
                'Demande de recrutement créée et publiée avec succès',
              );
            } else {
              Get.snackbar(
                'Succès',
                'Demande de recrutement créée avec succès (publication en attente)',
              );
            }
          } catch (e) {
            Get.snackbar(
              'Succès',
              'Demande de recrutement créée avec succès (publication en attente)',
            );
          }
        } else {
          Get.snackbar('Succès', 'Demande de recrutement créée avec succès');
        }

        clearForm();
        // Réinitialiser le filtre de statut pour charger tous les recrutements
        selectedStatus.value = 'all';
        await loadRecruitmentRequests();
        await loadRecruitmentStats();
        return true;
      } else {
        final errorMessage = result['message'] ?? 'Erreur lors de la création';
        Get.snackbar('Erreur', errorMessage);
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

      Get.snackbar('Erreur', errorMessage);
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
        Get.snackbar('Succès', 'Demande publiée avec succès');
        // Recharger tous les recrutements pour mettre à jour la liste
        selectedStatus.value = 'all';
        await loadRecruitmentRequests();
        await loadRecruitmentStats();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de la publication',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la publication: $e');
    }
  }

  // Approuver une demande
  Future<void> approveRecruitmentRequest(RecruitmentRequest request) async {
    try {
      final result = await _recruitmentService.approveRecruitmentRequest(
        request.id!,
      );

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Demande approuvée avec succès');
        // Recharger tous les recrutements pour mettre à jour la liste
        selectedStatus.value = 'all';
        await loadRecruitmentRequests();
        await loadRecruitmentStats();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de l\'approbation',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de l\'approbation: $e');
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
        Get.snackbar('Succès', 'Demande rejetée');
        // Recharger tous les recrutements pour mettre à jour la liste
        selectedStatus.value = 'all';
        await loadRecruitmentRequests();
        await loadRecruitmentStats();
      } else {
        Get.snackbar('Erreur', result['message'] ?? 'Erreur lors du rejet');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors du rejet: $e');
    }
  }

  // Fermer une demande
  Future<void> closeRecruitmentRequest(RecruitmentRequest request) async {
    try {
      final result = await _recruitmentService.closeRecruitmentRequest(
        request.id!,
      );

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Demande fermée');
        loadRecruitmentRequests();
        loadRecruitmentStats();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de la fermeture',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la fermeture: $e');
    }
  }

  // Annuler une demande
  Future<void> cancelRecruitmentRequest(RecruitmentRequest request) async {
    try {
      final result = await _recruitmentService.cancelRecruitmentRequest(
        request.id!,
      );

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Demande annulée');
        loadRecruitmentRequests();
        loadRecruitmentStats();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de l\'annulation',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de l\'annulation: $e');
    }
  }

  // Supprimer une demande
  Future<void> deleteRecruitmentRequest(RecruitmentRequest request) async {
    try {
      final result = await _recruitmentService.deleteRecruitmentRequest(
        request.id!,
      );

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Demande supprimée');
        loadRecruitmentRequests();
        loadRecruitmentStats();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de la suppression',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la suppression: $e');
    }
  }

  // Sélectionner une date d'échéance
  Future<void> selectDeadline(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          selectedDeadlineForm.value ??
          DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      selectedDeadlineForm.value = date;
    }
  }

  // Sélectionner un département
  void selectDepartment(String department) {
    selectedDepartmentForm.value = department;
  }

  // Sélectionner un poste
  void selectPosition(String position) {
    selectedPositionForm.value = position;
  }

  // Sélectionner un type d'emploi
  void selectEmploymentType(String type) {
    selectedEmploymentTypeForm.value = type;
  }

  // Sélectionner un niveau d'expérience
  void selectExperienceLevel(String level) {
    selectedExperienceLevelForm.value = level;
  }

  // Réinitialiser le formulaire
  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    requirementsController.clear();
    responsibilitiesController.clear();
    salaryRangeController.clear();
    locationController.clear();
    selectedDepartmentForm.value = '';
    selectedPositionForm.value = '';
    selectedEmploymentTypeForm.value = '';
    selectedExperienceLevelForm.value = '';
    selectedDeadlineForm.value = null;
    numberOfPositionsForm.value = 1;
  }

  // Réinitialiser les filtres
  void clearFilters() {
    selectedStatus.value = 'all';
    selectedDepartment.value = 'all';
    selectedPosition.value = 'all';
    selectedStartDate.value = null;
    selectedEndDate.value = null;
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
