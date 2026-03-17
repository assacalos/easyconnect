import 'package:flutter/material.dart';
import 'package:easyconnect/Models/leave_model.dart';
import 'package:easyconnect/services/leave_service.dart';
import 'package:easyconnect/services/employee_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/error_helper.dart';

class LeaveController {
  static final LeaveController _instance = LeaveController._();
  static LeaveController get to => _instance;
  factory LeaveController() => _instance;
  LeaveController._();

  final LeaveService _leaveService = LeaveService.to;
  final EmployeeService _employeeService = EmployeeService.to;

  // Variables
  bool isLoading = false;
  bool isLoadingMore = false;
  final List<LeaveRequest> leaveRequests = [];
  final List<LeaveRequest> filteredRequests = [];
  LeaveRequest? selectedRequest;
  LeaveStats? leaveStats;
  final List<LeaveType> leaveTypes = [];
  final List<Map<String, dynamic>> employees = [];

  // Contrôleurs de formulaire
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController commentsController = TextEditingController();
  final TextEditingController rejectionReasonController =
      TextEditingController();
  final TextEditingController searchController = TextEditingController();

  // Variables de filtrage
  String selectedStatus = 'all';
  String selectedLeaveType = 'all';
  String selectedEmployee = 'all';
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  // Métadonnées de pagination
  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  int perPage = 15;
  final ScrollController scrollController = ScrollController();

  // Variables pour le formulaire de création
  String selectedEmployeeForm = '';
  String selectedLeaveTypeForm = '';
  DateTime? selectedStartDateForm;
  DateTime? selectedEndDateForm;
  final List<String> selectedAttachments = [];

  // Permissions
  bool canManageLeaves = true;
  bool canApproveLeaves = true;
  bool canViewAllLeaves = true;

  void ensureInitialized() {}

  void dispose() {
    scrollController.dispose();
    reasonController.dispose();
    commentsController.dispose();
    rejectionReasonController.dispose();
    searchController.dispose();
  }

  // Charger les types de congés
  Future<void> loadLeaveTypes() async {
    try {
      final types = await _leaveService.getLeaveTypes();
      leaveTypes.clear();
      leaveTypes.addAll(types);
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
      employees.clear();
      employees.addAll(
          employeesList.map((employee) {
            return {
              'id': employee.id,
              'name': '${employee.firstName} ${employee.lastName}',
              'email': employee.email,
            };
          }).toList());

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
          employees.clear();
          employees.addAll(
              retryList.map((employee) {
                return {
                  'id': employee.id,
                  'name': '${employee.firstName} ${employee.lastName}',
                  'email': employee.email,
                };
              }).toList());
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
          employees.clear();
          employees.addAll(
              employeesList.map((employee) {
                return {
                  'id': employee.id,
                  'name': '${employee.firstName} ${employee.lastName}',
                  'email': employee.email,
                };
              }).toList());
        } catch (retryError) {
          print(
            '❌ [LEAVE_CONTROLLER] Erreur même avec limite réduite: $retryError',
          );
          employees.clear();
        }
      } else {
        // En cas d'autre erreur, laisser la liste vide
        employees.clear();
      }
    }
  }

  // Charger les demandes de congés
  Future<void> loadLeaveRequests({int page = 1, bool forceRefresh = false}) async {
    try {
      final user = AuthController.to.userAuth;
      if (user == null) return;

      if (page == 1) {
        if (!forceRefresh) {
          final hiveList = LeaveService.getCachedLeaves();
          if (hiveList.isNotEmpty) {
            leaveRequests.clear();
        leaveRequests.addAll(hiveList);
            applyFilters();
            isLoading = false;
            Future.microtask(() => _refreshLeavesFromApi());
            return;
          }
        }
        isLoading = true;
      }
      if (page > 1) {
        isLoadingMore = true;
      }

      try {
        final paginatedResponse = await _leaveService.getLeaveRequestsPaginated(
        startDate: selectedStartDate,
        endDate: selectedEndDate,
        status: selectedStatus != 'all' ? selectedStatus : null,
        leaveType:
            selectedLeaveType != 'all' ? selectedLeaveType : null,
        employeeId: canViewAllLeaves ? null : user.id,
        page: page,
        perPage: perPage,
        search:
            searchController.text.isNotEmpty ? searchController.text : null,
        );

        // Mettre à jour les métadonnées de pagination
        totalPages = paginatedResponse.meta.lastPage;
        totalItems = paginatedResponse.meta.total;
        hasNextPage = paginatedResponse.hasNextPage;
        hasPreviousPage = paginatedResponse.hasPreviousPage;
        currentPage = paginatedResponse.meta.currentPage;

        // Mettre à jour la liste
        if (page == 1) {
          leaveRequests.clear();
          leaveRequests.addAll(paginatedResponse.data);
        } else {
          // Pour les pages suivantes, ajouter les données
          leaveRequests.addAll(paginatedResponse.data);
        }
        applyFilters();
      } catch (e) {
        // En cas d'erreur, essayer la méthode non-paginée en fallback
        List<LeaveRequest> requests;
        if (canViewAllLeaves) {
          requests = await _leaveService.getAllLeaveRequests(
            startDate: selectedStartDate,
            endDate: selectedEndDate,
          );
        } else {
          requests = await _leaveService.getEmployeeLeaveRequests(
            employeeId: user.id,
            startDate: selectedStartDate,
            endDate: selectedEndDate,
          );
        }
        if (page == 1) {
          leaveRequests.clear();
          leaveRequests.addAll(requests);
        } else {
          leaveRequests.addAll(requests);
        }
        applyFilters();
      }
    } catch (e) {
      // Ne pas afficher d'erreur si des données sont disponibles (cache ou liste non vide)
      // Ne pas afficher d'erreur pour les erreurs d'authentification (déjà gérées)
      final errorString = e.toString().toLowerCase();
      if (!errorString.contains('session expirée') &&
          !errorString.contains('401') &&
          !errorString.contains('unauthorized')) {
        if (leaveRequests.isEmpty) {
          errorHelperShowSnackbar?.call(
            'Erreur',
            'Impossible de charger les demandes de congés',
          );
        }
      }
    } finally {
      isLoading = false;
        isLoadingMore = false;
    }
  }

  /// Rafraîchit les demandes de congé depuis l'API (page 1) et met à jour la liste si le filtre est inchangé.
  Future<void> _refreshLeavesFromApi() async {
    try {
      final user = AuthController.to.userAuth;
      if (user == null) return;
      final paginatedResponse = await _leaveService.getLeaveRequestsPaginated(
      startDate: selectedStartDate,
      endDate: selectedEndDate,
      status: selectedStatus != 'all' ? selectedStatus : null,
      leaveType:
          selectedLeaveType != 'all' ? selectedLeaveType : null,
      employeeId: canViewAllLeaves ? null : user.id,
      page: 1,
      perPage: perPage,
      search: searchController.text.isNotEmpty ? searchController.text : null,
    );
    leaveRequests.clear();
    leaveRequests.addAll(paginatedResponse.data);
    totalPages = paginatedResponse.meta.lastPage;
    totalItems = paginatedResponse.meta.total;
    hasNextPage = paginatedResponse.hasNextPage;
    hasPreviousPage = paginatedResponse.hasPreviousPage;
    currentPage = 1;
      applyFilters();
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
      loadLeaveRequests(page: currentPage + 1);
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage && !isLoading && !isLoadingMore) {
      loadLeaveRequests(page: currentPage - 1);
    }
  }

  // Charger les statistiques
  Future<void> loadLeaveStats() async {
    try {
      final stats = await _leaveService.getLeaveStats(
        startDate: selectedStartDate,
        endDate: selectedEndDate,
      );
      leaveStats = stats;
    } catch (e) {}
  }

  // Appliquer les filtres
  void applyFilters() {
    List<LeaveRequest> filtered =
        leaveRequests.where((request) {
          // Filtre par statut
          if (selectedStatus != 'all' &&
              request.status != selectedStatus) {
            return false;
          }

          // Filtre par type de congé
          if (selectedLeaveType != 'all' &&
              request.leaveType != selectedLeaveType) {
            return false;
          }

          // Filtre par employé
          if (selectedEmployee != 'all' &&
              request.employeeId.toString() != selectedEmployee) {
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
    applyFilters();
  }

  // Filtrer par type de congé
  void filterByLeaveType(String leaveType) {
    selectedLeaveType = leaveType;
    applyFilters();
  }

  // Filtrer par employé
  void filterByEmployee(String employeeId) {
    selectedEmployee = employeeId;
    applyFilters();
  }

  // Filtrer par date
  void filterByDateRange(DateTime? startDate, DateTime? endDate) {
    selectedStartDate = startDate;
    selectedEndDate = endDate;
    loadLeaveRequests();
  }

  // Créer une demande de congé
  Future<bool> createLeaveRequest() async {
    try {
      // Validation des champs obligatoires
      if (selectedEmployeeForm.isEmpty ||
          selectedLeaveTypeForm.isEmpty ||
          selectedStartDateForm == null ||
          selectedEndDateForm == null ||
          reasonController.text.trim().isEmpty) {
        errorHelperShowSnackbar?.call('Erreur', 'Veuillez remplir tous les champs obligatoires');
        return false;
      }

      // Validation de start_date (doit être aujourd'hui ou dans le futur)
      final today = DateTime.now().copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
      );
      if (selectedStartDateForm!.isBefore(today)) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'La date de début doit être aujourd\'hui ou dans le futur',
        );
        return false;
      }

      // Validation de end_date (doit être après start_date)
      if (selectedEndDateForm!.isBefore(selectedStartDateForm!) ||
          selectedEndDateForm!.isAtSameMomentAs(
            selectedStartDateForm!,
          )) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'La date de fin doit être après la date de début',
        );
        return false;
      }

      // Validation de reason (min 10 caractères, max 1000 caractères)
      final reasonText = reasonController.text.trim();
      if (reasonText.length < 10) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'La raison doit contenir au moins 10 caractères (actuellement: ${reasonText.length})',
        );
        return false;
      }
      if (reasonText.length > 1000) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'La raison ne doit pas dépasser 1000 caractères (actuellement: ${reasonText.length})',
        );
        return false;
      }

      // Validation de comments (max 2000 caractères)
      final commentsText = commentsController.text.trim();
      if (commentsText.length > 2000) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Les commentaires ne doivent pas dépasser 2000 caractères (actuellement: ${commentsText.length})',
        );
        return false;
      }

      final result = await _leaveService.createLeaveRequest(
        employeeId: int.parse(selectedEmployeeForm),
        leaveType: selectedLeaveTypeForm,
        startDate: selectedStartDateForm!,
        endDate: selectedEndDateForm!,
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

        errorHelperShowSnackbar?.call('Succès', 'Demande de congé créée avec succès');
        clearForm();
        loadLeaveRequests();
        loadLeaveStats();
        return true;
      } else {
        errorHelperShowSnackbar?.call(
          'Erreur',
          result['message'] ?? 'Erreur lors de la création',
        );
        return false;
      }
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

      errorHelperShowSnackbar?.call('Erreur', 'Erreur lors de la création de la demande: $e');
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
          entity: request,
        );

        errorHelperShowSnackbar?.call('Succès', 'Demande approuvée avec succès');
        loadLeaveRequests();
        loadLeaveStats();
      } else {
        errorHelperShowSnackbar?.call(
          'Erreur',
          result['message'] ?? 'Erreur lors de l\'approbation',
        );
      }
    } catch (e) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      final errorStr = e.toString().toLowerCase();
      if (!errorStr.contains('parsing') &&
          !errorStr.contains('json') &&
          !errorStr.contains('type') &&
          !errorStr.contains('cast') &&
          !errorStr.contains('null')) {
        errorHelperShowSnackbar?.call('Erreur', 'Erreur lors de l\'approbation: $e');
      }
    }
  }

  // Rejeter une demande
  Future<void> rejectLeaveRequest(LeaveRequest request) async {
    try {
      if (rejectionReasonController.text.trim().isEmpty) {
        errorHelperShowSnackbar?.call('Erreur', 'Veuillez indiquer la raison du rejet');
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
          entity: request,
        );

        errorHelperShowSnackbar?.call('Succès', 'Demande rejetée');
        rejectionReasonController.clear();
        loadLeaveRequests();
        loadLeaveStats();
      } else {
        errorHelperShowSnackbar?.call('Erreur', result['message'] ?? 'Erreur lors du rejet');
      }
    } catch (e) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      final errorStr = e.toString().toLowerCase();
      if (!errorStr.contains('parsing') &&
          !errorStr.contains('json') &&
          !errorStr.contains('type') &&
          !errorStr.contains('cast') &&
          !errorStr.contains('null')) {
        errorHelperShowSnackbar?.call('Erreur', 'Erreur lors du rejet: $e');
      }
    }
  }

  // Annuler une demande
  Future<void> cancelLeaveRequest(LeaveRequest request) async {
    try {
      final result = await _leaveService.cancelLeaveRequest(request.id!);

      if (result['success'] == true) {
        errorHelperShowSnackbar?.call('Succès', 'Demande annulée');
        loadLeaveRequests();
        loadLeaveStats();
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
  Future<void> deleteLeaveRequest(LeaveRequest request) async {
    try {
      final result = await _leaveService.deleteLeaveRequest(request.id!);

      if (result['success'] == true) {
        errorHelperShowSnackbar?.call('Succès', 'Demande supprimée');
        loadLeaveRequests();
        loadLeaveStats();
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

  // Sélectionner une date de début
  Future<void> selectStartDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedStartDateForm ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      selectedStartDateForm = date;
      // Ajuster la date de fin si elle est antérieure
      if (selectedEndDateForm != null &&
          selectedEndDateForm!.isBefore(date)) {
        selectedEndDateForm = date;
      }
    }
  }

  // Sélectionner une date de fin
  Future<void> selectEndDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          selectedEndDateForm ??
          selectedStartDateForm ??
          DateTime.now(),
      firstDate: selectedStartDateForm ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      selectedEndDateForm = date;
    }
  }

  // Sélectionner un employé
  void selectEmployee(String employeeId) {
    selectedEmployeeForm = employeeId;
  }

  // Sélectionner un type de congé
  void selectLeaveType(String leaveType) {
    selectedLeaveTypeForm = leaveType;
  }

  // Calculer le nombre de jours
  int calculateTotalDays() {
    if (selectedStartDateForm != null &&
        selectedEndDateForm != null) {
      return selectedEndDateForm!
              .difference(selectedStartDateForm!)
              .inDays +
          1;
    }
    return 0;
  }

  // Vérifier les conflits
  Future<bool> checkConflicts() async {
    if (selectedEmployeeForm.isEmpty ||
        selectedStartDateForm == null ||
        selectedEndDateForm == null) {
      return false;
    }

    try {
      final result = await _leaveService.checkLeaveConflicts(
        employeeId: int.parse(selectedEmployeeForm),
        startDate: selectedStartDateForm!,
        endDate: selectedEndDateForm!,
      );
      return result['has_conflicts'] == true;
    } catch (e) {
      return false;
    }
  }

  // Réinitialiser le formulaire
  void clearForm() {
    selectedEmployeeForm = '';
    selectedLeaveTypeForm = '';
    selectedStartDateForm = null;
    selectedEndDateForm = null;
    reasonController.clear();
    commentsController.clear();
    selectedAttachments.clear();
  }

  // Réinitialiser les filtres
  void clearFilters() {
    selectedStatus = 'all';
    selectedLeaveType = 'all';
    selectedEmployee = 'all';
    selectedStartDate = null;
    selectedEndDate = null;
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
