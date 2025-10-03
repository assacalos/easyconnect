import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/leave_model.dart';
import 'package:easyconnect/services/leave_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/services/employee_service.dart';

class LeaveController extends GetxController {
  final LeaveService _leaveService = LeaveService.to;
  final EmployeeService _employeeService = EmployeeService.to;
  final AuthController _authController = Get.find<AuthController>();

  // Variables observables
  final RxBool isLoading = false.obs;
  final RxList<LeaveRequest> leaveRequests = <LeaveRequest>[].obs;
  final RxList<LeaveRequest> filteredRequests = <LeaveRequest>[].obs;
  final Rx<LeaveRequest?> selectedRequest = Rx<LeaveRequest?>(null);
  final Rx<LeaveStats?> leaveStats = Rx<LeaveStats?>(null);
  final RxList<LeaveType> leaveTypes = <LeaveType>[].obs;
  final RxList<Map<String, dynamic>> employees = <Map<String, dynamic>>[].obs;

  // Variables pour le formulaire
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController commentsController = TextEditingController();
  final TextEditingController rejectionReasonController =
      TextEditingController();
  final TextEditingController searchController = TextEditingController();

  // Variables de filtrage
  final RxString selectedStatus = 'all'.obs;
  final RxString selectedLeaveType = 'all'.obs;
  final RxString selectedEmployee = 'all'.obs;
  final Rx<DateTime?> selectedStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedEndDate = Rx<DateTime?>(null);

  // Variables pour le formulaire de création
  final RxString selectedEmployeeForm = ''.obs;
  final RxString selectedLeaveTypeForm = ''.obs;
  final Rx<DateTime?> selectedStartDateForm = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedEndDateForm = Rx<DateTime?>(null);
  final RxList<String> selectedAttachments = <String>[].obs;

  // Variables pour les permissions
  final RxBool canManageLeaves =
      true.obs; // TODO: Implémenter la vérification des permissions
  final RxBool canApproveLeaves =
      true.obs; // TODO: Implémenter la vérification des permissions
  final RxBool canViewAllLeaves =
      true.obs; // TODO: Implémenter la vérification des permissions

  @override
  void onInit() {
    super.onInit();
    loadLeaveTypes();
    loadEmployees();
    loadLeaveRequests();
    loadLeaveStats();
  }

  @override
  void onClose() {
    reasonController.dispose();
    commentsController.dispose();
    rejectionReasonController.dispose();
    searchController.dispose();
    super.onClose();
  }

  // Charger les types de congés
  Future<void> loadLeaveTypes() async {
    try {
      final types = await _leaveService.getLeaveTypes();
      leaveTypes.value = types;
    } catch (e) {
      print('Erreur lors du chargement des types de congés: $e');
    }
  }

  // Charger les employés
  Future<void> loadEmployees() async {
    try {
      // TODO: Implémenter la méthode getAllEmployees dans EmployeeService
      // Pour l'instant, on utilise des données de test
      employees.value = [
        {'id': 1, 'name': 'Jean Dupont', 'email': 'jean.dupont@example.com'},
        {'id': 2, 'name': 'Marie Martin', 'email': 'marie.martin@example.com'},
        {
          'id': 3,
          'name': 'Pierre Durand',
          'email': 'pierre.durand@example.com',
        },
      ];
    } catch (e) {
      print('Erreur lors du chargement des employés: $e');
    }
  }

  // Charger les demandes de congés
  Future<void> loadLeaveRequests() async {
    try {
      isLoading.value = true;

      final user = _authController.userAuth.value;
      if (user == null) return;

      List<LeaveRequest> requests;

      if (canViewAllLeaves.value) {
        // RH ou Patron : voir toutes les demandes
        requests = await _leaveService.getAllLeaveRequests(
          startDate: selectedStartDate.value,
          endDate: selectedEndDate.value,
        );
      } else {
        // Employé : voir ses propres demandes
        requests = await _leaveService.getEmployeeLeaveRequests(
          employeeId: user.id!,
          startDate: selectedStartDate.value,
          endDate: selectedEndDate.value,
        );
      }

      leaveRequests.value = requests;
      applyFilters();
    } catch (e) {
      print('Erreur lors du chargement des demandes: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les demandes de congés',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Charger les statistiques
  Future<void> loadLeaveStats() async {
    try {
      final stats = await _leaveService.getLeaveStats(
        startDate: selectedStartDate.value,
        endDate: selectedEndDate.value,
      );
      leaveStats.value = stats;
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
    }
  }

  // Appliquer les filtres
  void applyFilters() {
    List<LeaveRequest> filtered =
        leaveRequests.where((request) {
          // Filtre par statut
          if (selectedStatus.value != 'all' &&
              request.status != selectedStatus.value) {
            return false;
          }

          // Filtre par type de congé
          if (selectedLeaveType.value != 'all' &&
              request.leaveType != selectedLeaveType.value) {
            return false;
          }

          // Filtre par employé
          if (selectedEmployee.value != 'all' &&
              request.employeeId.toString() != selectedEmployee.value) {
            return false;
          }

          // Filtre par recherche
          if (searchController.text.isNotEmpty) {
            final searchTerm = searchController.text.toLowerCase();
            if (!request.employeeName.toLowerCase().contains(searchTerm) &&
                !request.reason.toLowerCase().contains(searchTerm)) {
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
    applyFilters();
  }

  // Filtrer par type de congé
  void filterByLeaveType(String leaveType) {
    selectedLeaveType.value = leaveType;
    applyFilters();
  }

  // Filtrer par employé
  void filterByEmployee(String employeeId) {
    selectedEmployee.value = employeeId;
    applyFilters();
  }

  // Filtrer par date
  void filterByDateRange(DateTime? startDate, DateTime? endDate) {
    selectedStartDate.value = startDate;
    selectedEndDate.value = endDate;
    loadLeaveRequests();
  }

  // Créer une demande de congé
  Future<void> createLeaveRequest() async {
    try {
      if (selectedEmployeeForm.value.isEmpty ||
          selectedLeaveTypeForm.value.isEmpty ||
          selectedStartDateForm.value == null ||
          selectedEndDateForm.value == null ||
          reasonController.text.trim().isEmpty) {
        Get.snackbar('Erreur', 'Veuillez remplir tous les champs obligatoires');
        return;
      }

      final result = await _leaveService.createLeaveRequest(
        employeeId: int.parse(selectedEmployeeForm.value),
        leaveType: selectedLeaveTypeForm.value,
        startDate: selectedStartDateForm.value!,
        endDate: selectedEndDateForm.value!,
        reason: reasonController.text.trim(),
        comments:
            commentsController.text.trim().isEmpty
                ? null
                : commentsController.text.trim(),
        attachmentPaths:
            selectedAttachments.isNotEmpty ? selectedAttachments : null,
      );

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Demande de congé créée avec succès');
        clearForm();
        loadLeaveRequests();
        loadLeaveStats();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de la création',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la création de la demande: $e');
      print('Erreur createLeaveRequest: $e');
    }
  }

  // Approuver une demande
  Future<void> approveLeaveRequest(LeaveRequest request) async {
    try {
      final result = await _leaveService.approveLeaveRequest(
        request.id!,
        comments:
            commentsController.text.trim().isEmpty
                ? null
                : commentsController.text.trim(),
      );

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Demande approuvée avec succès');
        loadLeaveRequests();
        loadLeaveStats();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de l\'approbation',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de l\'approbation: $e');
      print('Erreur approveLeaveRequest: $e');
    }
  }

  // Rejeter une demande
  Future<void> rejectLeaveRequest(LeaveRequest request) async {
    try {
      if (rejectionReasonController.text.trim().isEmpty) {
        Get.snackbar('Erreur', 'Veuillez indiquer la raison du rejet');
        return;
      }

      final result = await _leaveService.rejectLeaveRequest(
        request.id!,
        rejectionReason: rejectionReasonController.text.trim(),
      );

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Demande rejetée');
        rejectionReasonController.clear();
        loadLeaveRequests();
        loadLeaveStats();
      } else {
        Get.snackbar('Erreur', result['message'] ?? 'Erreur lors du rejet');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors du rejet: $e');
      print('Erreur rejectLeaveRequest: $e');
    }
  }

  // Annuler une demande
  Future<void> cancelLeaveRequest(LeaveRequest request) async {
    try {
      final result = await _leaveService.cancelLeaveRequest(request.id!);

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Demande annulée');
        loadLeaveRequests();
        loadLeaveStats();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de l\'annulation',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de l\'annulation: $e');
      print('Erreur cancelLeaveRequest: $e');
    }
  }

  // Supprimer une demande
  Future<void> deleteLeaveRequest(LeaveRequest request) async {
    try {
      final result = await _leaveService.deleteLeaveRequest(request.id!);

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Demande supprimée');
        loadLeaveRequests();
        loadLeaveStats();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de la suppression',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la suppression: $e');
      print('Erreur deleteLeaveRequest: $e');
    }
  }

  // Sélectionner une date de début
  Future<void> selectStartDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedStartDateForm.value ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      selectedStartDateForm.value = date;
      // Ajuster la date de fin si elle est antérieure
      if (selectedEndDateForm.value != null &&
          selectedEndDateForm.value!.isBefore(date)) {
        selectedEndDateForm.value = date;
      }
    }
  }

  // Sélectionner une date de fin
  Future<void> selectEndDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          selectedEndDateForm.value ??
          selectedStartDateForm.value ??
          DateTime.now(),
      firstDate: selectedStartDateForm.value ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      selectedEndDateForm.value = date;
    }
  }

  // Sélectionner un employé
  void selectEmployee(String employeeId) {
    selectedEmployeeForm.value = employeeId;
  }

  // Sélectionner un type de congé
  void selectLeaveType(String leaveType) {
    selectedLeaveTypeForm.value = leaveType;
  }

  // Calculer le nombre de jours
  int calculateTotalDays() {
    if (selectedStartDateForm.value != null &&
        selectedEndDateForm.value != null) {
      return selectedEndDateForm.value!
              .difference(selectedStartDateForm.value!)
              .inDays +
          1;
    }
    return 0;
  }

  // Vérifier les conflits
  Future<bool> checkConflicts() async {
    if (selectedEmployeeForm.value.isEmpty ||
        selectedStartDateForm.value == null ||
        selectedEndDateForm.value == null) {
      return false;
    }

    try {
      final result = await _leaveService.checkLeaveConflicts(
        employeeId: int.parse(selectedEmployeeForm.value),
        startDate: selectedStartDateForm.value!,
        endDate: selectedEndDateForm.value!,
      );
      return result['has_conflicts'] == true;
    } catch (e) {
      print('Erreur lors de la vérification des conflits: $e');
      return false;
    }
  }

  // Réinitialiser le formulaire
  void clearForm() {
    selectedEmployeeForm.value = '';
    selectedLeaveTypeForm.value = '';
    selectedStartDateForm.value = null;
    selectedEndDateForm.value = null;
    reasonController.clear();
    commentsController.clear();
    selectedAttachments.clear();
  }

  // Réinitialiser les filtres
  void clearFilters() {
    selectedStatus.value = 'all';
    selectedLeaveType.value = 'all';
    selectedEmployee.value = 'all';
    selectedStartDate.value = null;
    selectedEndDate.value = null;
    searchController.clear();
    applyFilters();
  }

  // Obtenir les options de statut
  List<Map<String, String>> get statusOptions => [
    {'value': 'all', 'label': 'Tous'},
    {'value': 'pending', 'label': 'En attente'},
    {'value': 'approved', 'label': 'Approuvé'},
    {'value': 'rejected', 'label': 'Rejeté'},
    {'value': 'cancelled', 'label': 'Annulé'},
  ];

  // Obtenir les options de type de congé
  List<Map<String, String>> get leaveTypeOptions {
    final options = [
      {'value': 'all', 'label': 'Tous'},
    ];
    for (final type in leaveTypes) {
      options.add({'value': type.value, 'label': type.label});
    }
    return options;
  }

  // Obtenir les options d'employés
  List<Map<String, String>> get employeeOptions {
    final options = [
      {'value': 'all', 'label': 'Tous'},
    ];
    for (final emp in employees) {
      options.add({'value': emp['id'].toString(), 'label': emp['name']});
    }
    return options;
  }
}
