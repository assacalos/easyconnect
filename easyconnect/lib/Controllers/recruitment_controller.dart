import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/recruitment_model.dart';
import 'package:easyconnect/services/recruitment_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';

class RecruitmentController extends GetxController {
  final RecruitmentService _recruitmentService = RecruitmentService.to;
  final AuthController _authController = Get.find<AuthController>();

  // Variables observables
  final RxBool isLoading = false.obs;
  final RxList<RecruitmentRequest> recruitmentRequests = <RecruitmentRequest>[].obs;
  final RxList<RecruitmentRequest> filteredRequests = <RecruitmentRequest>[].obs;
  final Rx<RecruitmentRequest?> selectedRequest = Rx<RecruitmentRequest?>(null);
  final Rx<RecruitmentStats?> recruitmentStats = Rx<RecruitmentStats?>(null);
  final RxList<String> departments = <String>[].obs;
  final RxList<String> positions = <String>[].obs;

  // Variables pour le formulaire
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController requirementsController = TextEditingController();
  final TextEditingController responsibilitiesController = TextEditingController();
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
  final RxBool canManageRecruitment = true.obs; // TODO: Implémenter la vérification des permissions
  final RxBool canApproveRecruitment = true.obs; // TODO: Implémenter la vérification des permissions
  final RxBool canViewAllRecruitment = true.obs; // TODO: Implémenter la vérification des permissions

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
    } catch (e) {
      print('Erreur lors du chargement des départements: $e');
    }
  }

  // Charger les postes
  Future<void> loadPositions() async {
    try {
      final pos = await _recruitmentService.getPositions();
      positions.value = pos;
    } catch (e) {
      print('Erreur lors du chargement des postes: $e');
    }
  }

  // Charger les demandes de recrutement
  Future<void> loadRecruitmentRequests() async {
    try {
      isLoading.value = true;

      final requests = await _recruitmentService.getAllRecruitmentRequests(
        status: selectedStatus.value != 'all' ? selectedStatus.value : null,
        department: selectedDepartment.value != 'all' ? selectedDepartment.value : null,
        position: selectedPosition.value != 'all' ? selectedPosition.value : null,
      );

      recruitmentRequests.value = requests;
      applyFilters();
    } catch (e) {
      print('Erreur lors du chargement des demandes: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les demandes de recrutement',
        snackPosition: SnackPosition.BOTTOM,
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
        department: selectedDepartment.value != 'all' ? selectedDepartment.value : null,
      );
      recruitmentStats.value = stats;
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
    }
  }

  // Appliquer les filtres
  void applyFilters() {
    List<RecruitmentRequest> filtered = recruitmentRequests.where((request) {
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
  Future<void> createRecruitmentRequest() async {
    try {
      if (titleController.text.trim().isEmpty ||
          selectedDepartmentForm.value.isEmpty ||
          selectedPositionForm.value.isEmpty ||
          descriptionController.text.trim().isEmpty ||
          requirementsController.text.trim().isEmpty ||
          responsibilitiesController.text.trim().isEmpty ||
          selectedEmploymentTypeForm.value.isEmpty ||
          selectedExperienceLevelForm.value.isEmpty ||
          salaryRangeController.text.trim().isEmpty ||
          locationController.text.trim().isEmpty ||
          selectedDeadlineForm.value == null) {
        Get.snackbar('Erreur', 'Veuillez remplir tous les champs obligatoires');
        return;
      }

      final result = await _recruitmentService.createRecruitmentRequest(
        title: titleController.text.trim(),
        department: selectedDepartmentForm.value,
        position: selectedPositionForm.value,
        description: descriptionController.text.trim(),
        requirements: requirementsController.text.trim(),
        responsibilities: responsibilitiesController.text.trim(),
        numberOfPositions: numberOfPositionsForm.value,
        employmentType: selectedEmploymentTypeForm.value,
        experienceLevel: selectedExperienceLevelForm.value,
        salaryRange: salaryRangeController.text.trim(),
        location: locationController.text.trim(),
        applicationDeadline: selectedDeadlineForm.value!,
      );

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Demande de recrutement créée avec succès');
        clearForm();
        loadRecruitmentRequests();
        loadRecruitmentStats();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de la création',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la création de la demande: $e');
      print('Erreur createRecruitmentRequest: $e');
    }
  }

  // Publier une demande
  Future<void> publishRecruitmentRequest(RecruitmentRequest request) async {
    try {
      final result = await _recruitmentService.publishRecruitmentRequest(request.id!);

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Demande publiée avec succès');
        loadRecruitmentRequests();
        loadRecruitmentStats();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de la publication',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la publication: $e');
      print('Erreur publishRecruitmentRequest: $e');
    }
  }

  // Approuver une demande
  Future<void> approveRecruitmentRequest(RecruitmentRequest request) async {
    try {
      final result = await _recruitmentService.approveRecruitmentRequest(request.id!);

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Demande approuvée avec succès');
        loadRecruitmentRequests();
        loadRecruitmentStats();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de l\'approbation',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de l\'approbation: $e');
      print('Erreur approveRecruitmentRequest: $e');
    }
  }

  // Rejeter une demande
  Future<void> rejectRecruitmentRequest(RecruitmentRequest request, String reason) async {
    try {
      final result = await _recruitmentService.rejectRecruitmentRequest(
        request.id!,
        rejectionReason: reason,
      );

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Demande rejetée');
        loadRecruitmentRequests();
        loadRecruitmentStats();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors du rejet',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors du rejet: $e');
      print('Erreur rejectRecruitmentRequest: $e');
    }
  }

  // Fermer une demande
  Future<void> closeRecruitmentRequest(RecruitmentRequest request) async {
    try {
      final result = await _recruitmentService.closeRecruitmentRequest(request.id!);

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
      print('Erreur closeRecruitmentRequest: $e');
    }
  }

  // Annuler une demande
  Future<void> cancelRecruitmentRequest(RecruitmentRequest request) async {
    try {
      final result = await _recruitmentService.cancelRecruitmentRequest(request.id!);

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
      print('Erreur cancelRecruitmentRequest: $e');
    }
  }

  // Supprimer une demande
  Future<void> deleteRecruitmentRequest(RecruitmentRequest request) async {
    try {
      final result = await _recruitmentService.deleteRecruitmentRequest(request.id!);

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
      print('Erreur deleteRecruitmentRequest: $e');
    }
  }

  // Sélectionner une date d'échéance
  Future<void> selectDeadline(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDeadlineForm.value ?? DateTime.now().add(const Duration(days: 30)),
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
