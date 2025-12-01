import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/leave_model.dart';
import 'package:easyconnect/services/leave_service.dart';
import 'package:easyconnect/services/employee_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/notification_helper.dart';

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
    } catch (e) {}
  }

  // Charger les employés
  Future<void> loadEmployees() async {
    try {
      // Réduire la limite pour éviter les réponses JSON tronquées
      // Si besoin de plus d'employés, on peut charger par pagination
      final employeesList = await _employeeService.getEmployees(
        limit: 50, // Limite réduite pour éviter les réponses trop grandes
        page: 1,
      );
      employees.value =
          employeesList.map((employee) {
            return {
              'id': employee.id,
              'name': '${employee.firstName} ${employee.lastName}',
              'email': employee.email,
            };
          }).toList();

      // Si la liste est toujours vide après le chargement, essayer de recharger avec une limite plus petite
      if (employees.isEmpty) {
        print(
          '⚠️ [LEAVE_CONTROLLER] Aucun employé chargé, nouvelle tentative avec limite réduite...',
        );
        // Nouvelle tentative après un court délai avec une limite plus petite
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          final retryList = await _employeeService.getEmployees(
            limit: 30,
            page: 1,
          );
          employees.value =
              retryList.map((employee) {
                return {
                  'id': employee.id,
                  'name': '${employee.firstName} ${employee.lastName}',
                  'email': employee.email,
                };
              }).toList();
        } catch (retryError) {
          print(
            '❌ [LEAVE_CONTROLLER] Erreur lors de la nouvelle tentative: $retryError',
          );
        }
      }
    } catch (e) {
      print('❌ [LEAVE_CONTROLLER] Erreur lors du chargement des employés: $e');

      // Si l'erreur est due à une réponse JSON tronquée, essayer avec une limite plus petite
      if (e.toString().contains('JSON tronqué') ||
          e.toString().contains('incomplet')) {
        print(
          '⚠️ [LEAVE_CONTROLLER] Tentative avec limite réduite (30 employés)...',
        );
        try {
          final employeesList = await _employeeService.getEmployees(
            limit: 30,
            page: 1,
          );
          employees.value =
              employeesList.map((employee) {
                return {
                  'id': employee.id,
                  'name': '${employee.firstName} ${employee.lastName}',
                  'email': employee.email,
                };
              }).toList();
        } catch (retryError) {
          print(
            '❌ [LEAVE_CONTROLLER] Erreur même avec limite réduite: $retryError',
          );
          employees.value = [];
        }
      } else {
        // En cas d'autre erreur, laisser la liste vide
        employees.value = [];
      }
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
          employeeId: user.id,
          startDate: selectedStartDate.value,
          endDate: selectedEndDate.value,
        );
      }

      leaveRequests.value = requests;
      applyFilters();
    } catch (e) {
      // Ne pas afficher d'erreur si des données sont disponibles (cache ou liste non vide)
      // Ne pas afficher d'erreur pour les erreurs d'authentification (déjà gérées)
      final errorString = e.toString().toLowerCase();
      if (!errorString.contains('session expirée') &&
          !errorString.contains('401') &&
          !errorString.contains('unauthorized')) {
        if (leaveRequests.isEmpty) {
          Get.snackbar(
            'Erreur',
            'Impossible de charger les demandes de congés',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
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
    } catch (e) {}
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
  Future<bool> createLeaveRequest() async {
    try {
      // Validation des champs obligatoires
      if (selectedEmployeeForm.value.isEmpty ||
          selectedLeaveTypeForm.value.isEmpty ||
          selectedStartDateForm.value == null ||
          selectedEndDateForm.value == null ||
          reasonController.text.trim().isEmpty) {
        Get.snackbar('Erreur', 'Veuillez remplir tous les champs obligatoires');
        return false;
      }

      // Validation de start_date (doit être aujourd'hui ou dans le futur)
      final today = DateTime.now().copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
      );
      if (selectedStartDateForm.value!.isBefore(today)) {
        Get.snackbar(
          'Erreur',
          'La date de début doit être aujourd\'hui ou dans le futur',
        );
        return false;
      }

      // Validation de end_date (doit être après start_date)
      if (selectedEndDateForm.value!.isBefore(selectedStartDateForm.value!) ||
          selectedEndDateForm.value!.isAtSameMomentAs(
            selectedStartDateForm.value!,
          )) {
        Get.snackbar(
          'Erreur',
          'La date de fin doit être après la date de début',
        );
        return false;
      }

      // Validation de reason (min 10 caractères, max 1000 caractères)
      final reasonText = reasonController.text.trim();
      if (reasonText.length < 10) {
        Get.snackbar(
          'Erreur',
          'La raison doit contenir au moins 10 caractères (actuellement: ${reasonText.length})',
        );
        return false;
      }
      if (reasonText.length > 1000) {
        Get.snackbar(
          'Erreur',
          'La raison ne doit pas dépasser 1000 caractères (actuellement: ${reasonText.length})',
        );
        return false;
      }

      // Validation de comments (max 2000 caractères)
      final commentsText = commentsController.text.trim();
      if (commentsText.length > 2000) {
        Get.snackbar(
          'Erreur',
          'Les commentaires ne doivent pas dépasser 2000 caractères (actuellement: ${commentsText.length})',
        );
        return false;
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
        // Notifier le patron de la soumission
        if (result['data'] != null && result['data']['id'] != null) {
          final leaveData = result['data'];
          NotificationHelper.notifySubmission(
            entityType: 'leave',
            entityName: NotificationHelper.getEntityDisplayName(
              'leave',
              leaveData,
            ),
            entityId: leaveData['id'].toString(),
            route: NotificationHelper.getEntityRoute(
              'leave',
              leaveData['id'].toString(),
            ),
          );
        }

        Get.snackbar('Succès', 'Demande de congé créée avec succès');
        clearForm();
        loadLeaveRequests();
        loadLeaveStats();
        return true;
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de la création',
        );
        return false;
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la création de la demande: $e');
      return false;
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
        // Notifier l'utilisateur concerné de la validation
        NotificationHelper.notifyValidation(
          entityType: 'leave',
          entityName: NotificationHelper.getEntityDisplayName('leave', request),
          entityId: request.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'leave',
            request.id.toString(),
          ),
        );

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
        // Notifier l'utilisateur concerné du rejet
        NotificationHelper.notifyRejection(
          entityType: 'leave',
          entityName: NotificationHelper.getEntityDisplayName('leave', request),
          entityId: request.id.toString(),
          reason: rejectionReasonController.text.trim(),
          route: NotificationHelper.getEntityRoute(
            'leave',
            request.id.toString(),
          ),
        );

        Get.snackbar('Succès', 'Demande rejetée');
        rejectionReasonController.clear();
        loadLeaveRequests();
        loadLeaveStats();
      } else {
        Get.snackbar('Erreur', result['message'] ?? 'Erreur lors du rejet');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors du rejet: $e');
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
