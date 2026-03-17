import 'package:flutter/material.dart';
import 'package:easyconnect/Models/contract_model.dart';
import 'package:easyconnect/services/contract_service.dart';
import 'package:easyconnect/services/employee_service.dart';
import 'package:easyconnect/Models/employee_model.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/error_helper.dart';
import 'package:collection/collection.dart';

class ContractController {
  static final ContractController _instance = ContractController._();
  static ContractController get to => _instance;
  factory ContractController() => _instance;

  final ContractService _contractService = ContractService.to;
  final EmployeeService _employeeService = EmployeeService.to;

  // Variables (plain types)
  bool isLoading = false;
  bool isLoadingMore = false;
  final List<Contract> contracts = [];
  final List<Contract> filteredContracts = [];
  Contract? selectedContract;
  ContractStats? contractStats;
  final List<Employee> employees = [];
  final List<String> departments = [];
  final List<ContractTemplate> contractTemplates = [];

  // Variables pour le formulaire
  final TextEditingController contractNumberController =
      TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController jobDescriptionController =
      TextEditingController();
  final TextEditingController workLocationController = TextEditingController();
  final TextEditingController workScheduleController = TextEditingController();
  final TextEditingController reportingManagerController =
      TextEditingController();
  final TextEditingController grossSalaryController = TextEditingController();
  final TextEditingController netSalaryController = TextEditingController();
  final TextEditingController weeklyHoursController = TextEditingController();
  final TextEditingController probationPeriodController =
      TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController employeeNameController = TextEditingController();
  final TextEditingController employeeEmailController = TextEditingController();
  final TextEditingController employeePhoneController = TextEditingController();
  final TextEditingController healthInsuranceController =
      TextEditingController();
  final TextEditingController retirementPlanController =
      TextEditingController();
  final TextEditingController vacationDaysController = TextEditingController();
  final TextEditingController otherBenefitsController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController attachmentsController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> selectedAttachments = [];

  // Variables de filtrage
  String selectedStatus = 'all';
  String selectedContractType = 'all';
  String selectedDepartment = 'all';
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
  int selectedEmployeeId = 0;
  Employee? selectedEmployee;
  String selectedDepartmentForm = '';
  String selectedContractTypeForm = 'all';
  String selectedPaymentFrequency = 'monthly';
  String selectedProbationPeriod = 'none';

  // Variables pour les permissions
  bool canManageContracts = true;
  bool canApproveContracts = true;
  bool canViewAllContracts = true;

  ContractController._() {
    generateContractNumber();
  }

  void dispose() {
    scrollController.dispose();
    jobTitleController.dispose();
    jobDescriptionController.dispose();
    workLocationController.dispose();
    grossSalaryController.dispose();
    netSalaryController.dispose();
    notesController.dispose();
    searchController.dispose();
  }

  // Charger les employés
  Future<void> loadEmployees() async {
    print('🚀 [CONTRACT_CONTROLLER] ===== loadEmployees APPELÉ =====');
    print(
      '🚀 [CONTRACT_CONTROLLER] Liste actuelle: ${employees.length} employés',
    );

    try {
      print(
        '📡 [CONTRACT_CONTROLLER] Appel de _employeeService.getEmployees()...',
      );
      final emp = await _employeeService.getEmployees();
      print(
        '✅ [CONTRACT_CONTROLLER] getEmployees retourné: ${emp.length} employés',
      );

      if (emp.isNotEmpty) {
        print(
          '📝 [CONTRACT_CONTROLLER] Premier employé: id=${emp.first.id}, name=${emp.first.firstName} ${emp.first.lastName}',
        );
      }

      employees.clear();
      employees.addAll(emp);
      print(
        '📝 [CONTRACT_CONTROLLER] Liste mise à jour: ${employees.length} employés',
      );

      if (emp.isEmpty) {
        print(
          '⚠️ [CONTRACT_CONTROLLER] La liste est vide (peut-etre qu\'il n\'y a pas d\'employes)',
        );
        // Si la liste est vide, ne pas afficher d'erreur (peut-être qu'il n'y a pas d'employés)
        return;
      }
    } catch (e, stackTrace) {
      print('❌ [CONTRACT_CONTROLLER] ERREUR dans loadEmployees: $e');
      print('❌ [CONTRACT_CONTROLLER] Stack trace: $stackTrace');

      // Ne pas afficher d'erreur si des employés sont déjà chargés
      if (employees.isEmpty) {
        print('🔄 [CONTRACT_CONTROLLER] Tentative avec le cache...');
        // Vérifier le cache avant d'afficher l'erreur
        final cached = CacheHelper.get<List<Employee>>(
          'employees_all_all_all_1_50',
        );
        if (cached != null && cached.isNotEmpty) {
          print(
            '✅ [CONTRACT_CONTROLLER] Cache trouvé: ${cached.length} employés',
          );
          employees.clear();
          employees.addAll(cached);
          return;
        }
        print('⚠️ [CONTRACT_CONTROLLER] Aucun cache trouvé');

        // Afficher l'erreur seulement si vraiment nécessaire
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ErrorHelper.showError('Impossible de charger les employés. Veuillez réessayer.', title: 'Erreur');
        });
      } else {
        print(
          '✅ [CONTRACT_CONTROLLER] Des employés sont déjà chargés (${employees.length}), pas d\'erreur affichée',
        );
      }
    }
  }

  // Charger les départements
  Future<void> loadDepartments() async {
    try {
      final depts = await _employeeService.getDepartments();
      departments.clear();
      departments.addAll(depts);
    } catch (e) {
      // En cas d'erreur, utiliser les départements par défaut
      departments.clear();
      departments.addAll([
        'Ressources Humaines',
        'Commercial',
        'Comptabilité',
        'Technique',
        'Support',
        'Direction',
      ]);
    }
  }

  // Charger les modèles de contrat
  Future<void> loadContractTemplates() async {
    try {
      final templates = await _contractService.getContractTemplates();
      contractTemplates.clear();
      contractTemplates.addAll(templates);
    } catch (e) {}
  }

  // Générer un numéro de contrat
  Future<void> generateContractNumber() async {
    try {
      final number = await _contractService.generateContractNumber();
      contractNumberController.text = number;
    } catch (e) {}
  }

  // Charger les contrats
  Future<void> loadContracts({int page = 1, bool forceRefresh = false}) async {
    try {
      if (page == 1) {
        if (!forceRefresh) {
          final hiveList = ContractService.getCachedContracts();
          if (hiveList.isNotEmpty) {
            contracts.clear();
            contracts.addAll(hiveList);
            applyFilters();
            isLoading = false;
            Future.microtask(() => _refreshContractsFromApi());
            return;
          }
        }
        isLoading = true;
      }
      if (page > 1) {
        isLoadingMore = true;
      }

      try {
        final paginatedResponse = await _contractService.getContractsPaginated(
          status: selectedStatus != 'all' ? selectedStatus : null,
          contractType:
              selectedContractType != 'all'
                  ? selectedContractType
                  : null,
          department:
              selectedDepartment != 'all'
                  ? selectedDepartment
                  : null,
          search:
              searchController.text.isNotEmpty ? searchController.text : null,
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
          contracts.clear();
          contracts.addAll(paginatedResponse.data);
        } else {
          // Pour les pages suivantes, ajouter les données
          contracts.addAll(paginatedResponse.data);
        }
        applyFilters();
      } catch (e) {
        // En cas d'erreur, essayer la méthode non-paginée en fallback
        final contractsList = await _contractService.getAllContracts(
          status: selectedStatus != 'all' ? selectedStatus : null,
          contractType:
              selectedContractType != 'all'
                  ? selectedContractType
                  : null,
          department:
              selectedDepartment != 'all'
                  ? selectedDepartment
                  : null,
        );
        if (page == 1) {
          contracts.clear();
        contracts.addAll(contractsList);
        } else {
          contracts.addAll(contractsList);
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
        if (contracts.isEmpty) {
          ErrorHelper.showError('Impossible de charger les contrats', title: 'Erreur');
        }
      }
    } finally {
      isLoading = false;
      isLoadingMore = false;
    }
  }

  /// Rafraîchit les contrats depuis l'API (page 1) et met à jour la liste si le filtre est inchangé.
  Future<void> _refreshContractsFromApi() async {
    try {
      final paginatedResponse = await _contractService.getContractsPaginated(
        status: selectedStatus != 'all' ? selectedStatus : null,
        contractType:
            selectedContractType != 'all'
                ? selectedContractType
                : null,
        department:
            selectedDepartment != 'all' ? selectedDepartment : null,
        search: searchController.text.isNotEmpty ? searchController.text : null,
        page: 1,
        perPage: perPage,
      );
      contracts.clear();
      contracts.addAll(paginatedResponse.data);
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
      loadContracts(page: currentPage + 1);
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage && !isLoading) {
      loadContracts(page: currentPage - 1);
    }
  }

  // Charger les statistiques
  Future<void> loadContractStats() async {
    try {
      final stats = await _contractService.getContractStats(
        startDate: selectedStartDate,
        endDate: selectedEndDate,
        department:
            selectedDepartment != 'all' ? selectedDepartment : null,
        contractType:
            selectedContractType != 'all'
                ? selectedContractType
                : null,
      );
      contractStats = stats;
    } catch (e) {}
  }

  // Appliquer les filtres
  void applyFilters() {
    List<Contract> filtered =
        contracts.where((contract) {
          // Filtre par recherche
          if (searchController.text.isNotEmpty) {
            final searchTerm = searchController.text.toLowerCase();
            if (!contract.contractNumber.toLowerCase().contains(searchTerm) &&
                !contract.employeeName.toLowerCase().contains(searchTerm) &&
                !contract.jobTitle.toLowerCase().contains(searchTerm) &&
                !contract.department.toLowerCase().contains(searchTerm)) {
              return false;
            }
          }

          return true;
        }).toList();

    filteredContracts.clear();
    filteredContracts.addAll(filtered);
  }

  // Rechercher dans les contrats
  void searchContracts(String query) {
    searchController.text = query;
    applyFilters();
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    selectedStatus = status;
    loadContracts();
  }

  // Filtrer par type de contrat
  void filterByContractType(String type) {
    selectedContractType = type;
    loadContracts();
  }

  // Filtrer par département
  void filterByDepartment(String department) {
    selectedDepartment = department;
    loadContracts();
  }

  // Filtrer par date
  void filterByDateRange(DateTime? startDate, DateTime? endDate) {
    selectedStartDate = startDate;
    selectedEndDate = endDate;
    loadContractStats();
  }

  // Créer un contrat
  Future<bool> createContract() async {
    try {
      // Validation des champs obligatoires
      final department =
          selectedDepartmentForm.isNotEmpty
              ? selectedDepartmentForm
              : departmentController.text.trim();

      if (selectedEmployeeId == 0) {
        ErrorHelper.showValidationError('Veuillez sélectionner un employé');
        return false;
      }

      if (selectedContractTypeForm.isEmpty ||
          selectedContractTypeForm == 'all') {
        ErrorHelper.showValidationError('Veuillez sélectionner un type de contrat');
        return false;
      }

      // Validation spéciale pour les contrats fixed_term : end_date est obligatoire
      if (selectedContractTypeForm == 'fixed_term') {
        if (endDateController.text.trim().isEmpty) {
          ErrorHelper.showValidationError('La date de fin est obligatoire pour les contrats à durée déterminée (CDD)');
          return false;
        }
      }

      if (department.isEmpty) {
        ErrorHelper.showValidationError('Veuillez sélectionner un département');
        return false;
      }

      if (jobTitleController.text.trim().isEmpty) {
        ErrorHelper.showValidationError('Le poste est obligatoire');
        return false;
      }

      // Validation de longueur pour job_title et position (max 100 caractères)
      // Note: position et job_title utilisent la même valeur (jobTitleController)
      if (jobTitleController.text.trim().length > 100) {
        ErrorHelper.showValidationError('Le poste ne doit pas dépasser 100 caractères (actuellement: ${jobTitleController.text.trim().length})');
        return false;
      }

      // Validation de longueur pour department (max 100 caractères)
      if (department.length > 100) {
        ErrorHelper.showValidationError('Le département ne doit pas dépasser 100 caractères (actuellement: ${department.length})');
        return false;
      }

      if (jobDescriptionController.text.trim().isEmpty) {
        ErrorHelper.showValidationError('La description du poste est obligatoire');
        return false;
      }

      if (jobDescriptionController.text.trim().length < 50) {
        ErrorHelper.showValidationError('La description du poste doit contenir au moins 50 caractères (actuellement: ${jobDescriptionController.text.trim().length})');
        return false;
      }

      if (grossSalaryController.text.trim().isEmpty) {
        ErrorHelper.showValidationError('Le salaire brut est obligatoire');
        return false;
      }

      if (selectedPaymentFrequency.isEmpty) {
        ErrorHelper.showValidationError('Veuillez sélectionner une fréquence de paiement');
        return false;
      }

      if (startDateController.text.trim().isEmpty) {
        ErrorHelper.showValidationError('La date de début est obligatoire');
        return false;
      }

      if (workLocationController.text.trim().isEmpty) {
        ErrorHelper.showValidationError('Le lieu de travail est obligatoire');
        return false;
      }

      // Validation de longueur pour work_location (max 255 caractères)
      if (workLocationController.text.trim().length > 255) {
        ErrorHelper.showValidationError('Le lieu de travail ne doit pas dépasser 255 caractères (actuellement: ${workLocationController.text.trim().length})');
        return false;
      }

      if (workScheduleController.text.trim().isEmpty) {
        ErrorHelper.showValidationError('L\'horaire de travail est obligatoire');
        return false;
      }

      // Vérifier que work_schedule est une valeur valide
      final validWorkSchedules = ['full_time', 'part_time', 'flexible'];
      if (!validWorkSchedules.contains(workScheduleController.text.trim())) {
        ErrorHelper.showValidationError('L\'horaire de travail doit être : Temps plein, Temps partiel ou Flexible');
        return false;
      }

      final grossSalary = double.tryParse(grossSalaryController.text);
      final weeklyHours = double.tryParse(weeklyHoursController.text) ?? 40.0;

      if (grossSalary == null) {
        ErrorHelper.showValidationError('Le montant du salaire doit être un nombre valide');
        return false;
      }

      if (grossSalary < 0) {
        ErrorHelper.showValidationError('Le salaire brut doit être supérieur ou égal à 0');
        return false;
      }

      // Validation de weekly_hours (1-168)
      final weeklyHoursInt = weeklyHours.toInt();
      if (weeklyHoursInt < 1 || weeklyHoursInt > 168) {
        ErrorHelper.showValidationError('Les heures hebdomadaires doivent être entre 1 et 168 (actuellement: $weeklyHoursInt)');
        return false;
      }

      // Utiliser la valeur sélectionnée pour la période d'essai (enum: 'none', '1_month', '3_months', '6_months')
      final String probationPeriod = selectedProbationPeriod;

      // Parser la date de début (format dd/MM/yyyy)
      DateTime startDate;
      try {
        if (startDateController.text.contains('/')) {
          // Format dd/MM/yyyy
          final parts = startDateController.text.split('/');
          if (parts.length == 3) {
            startDate = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          } else {
            throw Exception('Format de date invalide');
          }
        } else {
          // Format ISO
          startDate = DateTime.parse(startDateController.text);
        }
      } catch (e) {
        ErrorHelper.showValidationError('Format de date de début invalide: ${startDateController.text}');
        return false;
      }

      // Parser la date de fin si présente
      DateTime? endDate;
      if (endDateController.text.isNotEmpty) {
        try {
          if (endDateController.text.contains('/')) {
            // Format dd/MM/yyyy
            final parts = endDateController.text.split('/');
            if (parts.length == 3) {
              endDate = DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
            } else {
              throw Exception('Format de date invalide');
            }
          } else {
            // Format ISO
            endDate = DateTime.parse(endDateController.text);
          }

          // Vérifier que end_date est après start_date
          if (endDate.isBefore(startDate)) {
            ErrorHelper.showValidationError('La date de fin doit être après la date de début');
            return false;
          }
        } catch (e) {
          ErrorHelper.showValidationError('Format de date de fin invalide: ${endDateController.text}');
          return false;
        }
      }

      // Calculer la durée en mois si endDate est fourni
      int? durationMonths;
      if (endDate != null) {
        final difference = endDate.difference(startDate);
        durationMonths = (difference.inDays / 30).round();
      }

      final result = await _contractService.createContract(
        employeeId: selectedEmployeeId,
        contractType: selectedContractTypeForm,
        position: jobTitleController.text.trim(),
        department: department,
        jobTitle: jobTitleController.text.trim(),
        jobDescription: jobDescriptionController.text.trim(),
        grossSalary: grossSalary,
        netSalary: grossSalary * 0.8, // Calcul automatique du salaire net
        salaryCurrency: 'FCFA',
        paymentFrequency: selectedPaymentFrequency,
        startDate: startDate,
        endDate: endDate,
        durationMonths: durationMonths,
        workLocation: workLocationController.text.trim(),
        workSchedule: workScheduleController.text.trim(),
        weeklyHours: weeklyHours.toInt(),
        probationPeriod: probationPeriod,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
        contractTemplate: null, // Pas de template sélectionné pour l'instant
      );

      if (result['success'] == true) {
        // Notifier le patron de la soumission
        if (result['data'] != null && result['data']['id'] != null) {
          final contractData = result['data'];
          NotificationHelper.notifySubmission(
            entityType: 'contract',
            entityName: NotificationHelper.getEntityDisplayName(
              'contract',
              contractData,
            ),
            entityId: contractData['id'].toString(),
            route: NotificationHelper.getEntityRoute(
              'contract',
              contractData['id'].toString(),
            ),
          );
        }

        ErrorHelper.showSuccess('Contrat créé avec succès');
        clearForm();
        loadContracts();
        loadContractStats();
        return true;
      } else {
        final errorMessage = result['message'] ?? 'Erreur lors de la création';
        ErrorHelper.showError(errorMessage, title: 'Erreur');
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

      ErrorHelper.showError('Erreur lors de la création du contrat: $e', title: 'Erreur');
      return false;
    }
  }

  // Soumettre un contrat
  Future<void> submitContract(Contract contract) async {
    try {
      final result = await _contractService.submitContract(contract.id!);

      if (result['success'] == true) {
        // Notifier le patron de la soumission
        NotificationHelper.notifySubmission(
          entityType: 'contract',
          entityName: NotificationHelper.getEntityDisplayName(
            'contract',
            contract,
          ),
          entityId: contract.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'contract',
            contract.id.toString(),
          ),
        );

        ErrorHelper.showSuccess('Contrat soumis avec succès');
        loadContracts();
        loadContractStats();
      } else {
        ErrorHelper.showError(result['message'] ?? 'Erreur lors de la soumission', title: 'Erreur');
      }
    } catch (e) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      final errorStr = e.toString().toLowerCase();
      if (!errorStr.contains('parsing') &&
          !errorStr.contains('json') &&
          !errorStr.contains('type') &&
          !errorStr.contains('cast') &&
          !errorStr.contains('null')) {
        ErrorHelper.showError('Erreur lors de la soumission: $e', title: 'Erreur');
      }
    }
  }

  // Approuver un contrat
  Future<void> approveContract(Contract contract, {String? notes}) async {
    try {
      final result = await _contractService.approveContract(
        contract.id!,
        notes: notes,
      );

      if (result['success'] == true) {
        // Notifier l'utilisateur concerné de la validation
        NotificationHelper.notifyValidation(
          entityType: 'contract',
          entityName: NotificationHelper.getEntityDisplayName(
            'contract',
            contract,
          ),
          entityId: contract.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'contract',
            contract.id.toString(),
          ),
          entity: contract,
        );

        ErrorHelper.showSuccess('Contrat approuvé avec succès');
        loadContracts();
        loadContractStats();
      } else {
        ErrorHelper.showError(result['message'] ?? 'Erreur lors de l\'approbation', title: 'Erreur');
      }
    } catch (e) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      final errorStr = e.toString().toLowerCase();
      if (!errorStr.contains('parsing') &&
          !errorStr.contains('json') &&
          !errorStr.contains('type') &&
          !errorStr.contains('cast') &&
          !errorStr.contains('null')) {
        ErrorHelper.showError('Erreur lors de l\'approbation: $e', title: 'Erreur');
      }
    }
  }

  // Rejeter un contrat
  Future<void> rejectContract(Contract contract, String reason) async {
    try {
      final result = await _contractService.rejectContract(
        contract.id!,
        reason: reason,
      );

      if (result['success'] == true) {
        // Notifier l'utilisateur concerné du rejet
        NotificationHelper.notifyRejection(
          entityType: 'contract',
          entityName: NotificationHelper.getEntityDisplayName(
            'contract',
            contract,
          ),
          entityId: contract.id.toString(),
          reason: reason,
          route: NotificationHelper.getEntityRoute(
            'contract',
            contract.id.toString(),
          ),
          entity: contract,
        );

        ErrorHelper.showSuccess('Contrat rejeté');
        loadContracts();
        loadContractStats();
      } else {
        ErrorHelper.showError(result['message'] ?? 'Erreur lors du rejet', title: 'Erreur');
      }
    } catch (e) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      final errorStr = e.toString().toLowerCase();
      if (!errorStr.contains('parsing') &&
          !errorStr.contains('json') &&
          !errorStr.contains('type') &&
          !errorStr.contains('cast') &&
          !errorStr.contains('null')) {
        ErrorHelper.showError('Erreur lors du rejet: $e', title: 'Erreur');
      }
    }
  }

  // Résilier un contrat
  Future<void> terminateContract(
    Contract contract,
    String reason,
    DateTime terminationDate,
  ) async {
    try {
      final result = await _contractService.terminateContract(
        id: contract.id!,
        reason: reason,
        terminationDate: terminationDate,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
      );

      if (result['success'] == true) {
        ErrorHelper.showSuccess('Contrat résilié');
        loadContracts();
        loadContractStats();
      } else {
        ErrorHelper.showError(result['message'] ?? 'Erreur lors de la résiliation', title: 'Erreur');
      }
    } catch (e) {
      ErrorHelper.showError('Erreur lors de la résiliation: $e', title: 'Erreur');
    }
  }

  // Annuler un contrat
  Future<void> cancelContract(Contract contract, {String? reason}) async {
    try {
      final result = await _contractService.cancelContract(
        contract.id!,
        reason: reason,
      );

      if (result['success'] == true) {
        ErrorHelper.showSuccess('Contrat annulé');
        loadContracts();
        loadContractStats();
      } else {
        ErrorHelper.showError(result['message'] ?? 'Erreur lors de l\'annulation', title: 'Erreur');
      }
    } catch (e) {
      ErrorHelper.showError('Erreur lors de l\'annulation: $e', title: 'Erreur');
    }
  }

  // Supprimer un contrat
  Future<void> deleteContract(Contract contract) async {
    try {
      final result = await _contractService.deleteContract(contract.id!);

      if (result['success'] == true) {
        ErrorHelper.showSuccess('Contrat supprimé');
        loadContracts();
        loadContractStats();
      } else {
        ErrorHelper.showError(result['message'] ?? 'Erreur lors de la suppression', title: 'Erreur');
      }
    } catch (e) {
      ErrorHelper.showError('Erreur lors de la suppression: $e', title: 'Erreur');
    }
  }

  // Sélectionner une date de début
  Future<void> selectStartDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      startDateController.text = date.toIso8601String().split('T')[0];
    }
  }

  // Sélectionner une date de fin
  Future<void> selectEndDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      endDateController.text = date.toIso8601String().split('T')[0];
    }
  }

  // Sélectionner un employé
  void setEmployee(int? employeeId) {
    if (employeeId == null) {
      selectedEmployeeId = 0;
      selectedEmployee = null;
      employeeNameController.clear();
      employeeEmailController.clear();
      employeePhoneController.clear();
      return;
    }

    selectedEmployeeId = employeeId;
    // Mettre à jour les informations de l'employé
    final employee = employees.firstWhereOrNull((e) => e.id == employeeId);
    if (employee != null) {
      selectedEmployee = employee;
      employeeNameController.text = employee.fullName;
      employeeEmailController.text = employee.email;
      employeePhoneController.text = employee.phone ?? '';
      // Pré-remplir le département si disponible
      if (employee.department != null && employee.department!.isNotEmpty) {
        selectedDepartmentForm = employee.department!;
        departmentController.text = employee.department!;
      }
      // Pré-remplir le poste si disponible
      if (employee.position != null && employee.position!.isNotEmpty) {
        jobTitleController.text = employee.position!;
      }
    }
  }

  // Sélectionner un type de contrat
  void setContractType(String type) {
    selectedContractTypeForm = type;
  }

  // Sélectionner une fréquence de paiement
  void setPaymentFrequency(String frequency) {
    selectedPaymentFrequency = frequency;
  }

  // Sélectionner un horaire de travail
  void selectWorkSchedule(String schedule) {
    workScheduleController.text = schedule;
  }

  // Sélectionner une période d'essai
  void selectProbationPeriod(String period) {
    probationPeriodController.text = period;
  }

  // Calculer le salaire net automatiquement
  void calculateNetSalary() {
    final grossSalary = double.tryParse(grossSalaryController.text);
    if (grossSalary != null) {
      // Calcul simplifié (à adapter selon les règles fiscales)
      final netSalary = grossSalary * 0.8; // 20% de charges
      netSalaryController.text = netSalary.toStringAsFixed(0);
    }
  }

  // Sélectionner un département
  void setDepartment(String department) {
    selectedDepartmentForm = department;
    departmentController.text = department;
  }

  // Réinitialiser le formulaire
  void clearForm() {
    selectedEmployeeId = 0;
    selectedEmployee = null;
    selectedDepartmentForm = '';
    selectedContractTypeForm = '';
    selectedPaymentFrequency =
        'monthly'; // Réinitialiser à la valeur par défaut
    selectedProbationPeriod = 'none';
    startDateController.clear();
    endDateController.clear();
    contractNumberController.clear();
    departmentController.clear();
    jobTitleController.clear();
    jobDescriptionController.clear();
    workLocationController.clear();
    workScheduleController.clear();
    reportingManagerController.clear();
    grossSalaryController.clear();
    netSalaryController.clear();
    weeklyHoursController.clear();
    probationPeriodController.clear();
    employeeNameController.clear();
    employeeEmailController.clear();
    employeePhoneController.clear();
    healthInsuranceController.clear();
    retirementPlanController.clear();
    vacationDaysController.clear();
    otherBenefitsController.clear();
    notesController.clear();
    attachmentsController.clear();
    selectedAttachments.clear();
    generateContractNumber();
  }

  // Sélectionner des fichiers pour les pièces jointes
  Future<void> selectAttachments() async {
    try {
      // Note: file_picker nécessite d'être ajouté au pubspec.yaml
      // Pour l'instant, on utilise image_picker comme solution temporaire
      // TODO: Ajouter file_picker pour sélectionner tous types de fichiers

      ErrorHelper.showInfo('Fonctionnalité de sélection de fichiers en cours de développement');
    } catch (e) {
      ErrorHelper.showError('Erreur lors de la sélection des fichiers: $e', title: 'Erreur');
    }
  }

  // Supprimer un fichier de la liste
  void removeAttachment(int index) {
    if (index >= 0 && index < selectedAttachments.length) {
      selectedAttachments.removeAt(index);
      updateAttachmentsDisplay();
    }
  }

  // Mettre à jour l'affichage des pièces jointes
  void updateAttachmentsDisplay() {
    if (selectedAttachments.isEmpty) {
      attachmentsController.clear();
    } else {
      final fileNames = selectedAttachments
          .map((file) => file['name'] ?? 'Fichier')
          .join(', ');
      attachmentsController.text = fileNames;
    }
  }

  // Réinitialiser les filtres
  void clearFilters() {
    selectedStatus = 'all';
    selectedContractType = 'all';
    selectedDepartment = 'all';
    selectedStartDate = null;
    selectedEndDate = null;
    searchController.clear();
    loadContracts();
  }

  // Obtenir les options de statut
  List<Map<String, String>> get statusOptions => [
    {'value': 'all', 'label': 'Tous'},
    {'value': 'pending', 'label': 'En attente'},
    {'value': 'active', 'label': 'Actif'},
    {'value': 'expired', 'label': 'Expiré'},
    {'value': 'terminated', 'label': 'Résilié'},
    {'value': 'cancelled', 'label': 'Annulé'},
  ];

  // Obtenir les options de type de contrat
  List<Map<String, String>> get contractTypeOptions => [
    {'value': 'all', 'label': 'Tous'},
    {'value': 'permanent', 'label': 'CDI'},
    {'value': 'fixed_term', 'label': 'CDD'},
    {'value': 'temporary', 'label': 'Intérim'},
    {'value': 'internship', 'label': 'Stage'},
    {'value': 'consultant', 'label': 'Consultant'},
  ];

  // Obtenir les options de département pour le formulaire
  List<String> get departmentOptionsForForm {
    return departments;
  }

  // Obtenir les options de fréquence de paiement
  List<Map<String, String>> get paymentFrequencyOptions => [
    {'value': 'monthly', 'label': 'Mensuel'},
    {'value': 'weekly', 'label': 'Hebdomadaire'},
    {'value': 'daily', 'label': 'Journalier'},
    {'value': 'hourly', 'label': 'Horaire'},
  ];

  // Obtenir les options d'horaire de travail
  List<Map<String, String>> get workScheduleOptions => [
    {'value': 'full_time', 'label': 'Temps plein'},
    {'value': 'part_time', 'label': 'Temps partiel'},
    {'value': 'flexible', 'label': 'Flexible'},
  ];

  // Obtenir les options de période d'essai
  List<Map<String, String>> get probationPeriodOptions => [
    {'value': 'none', 'label': 'Aucune'},
    {'value': '1_month', 'label': '1 mois'},
    {'value': '3_months', 'label': '3 mois'},
    {'value': '6_months', 'label': '6 mois'},
  ];

  // Remplir le formulaire avec les données d'un contrat existant
  void fillForm(Contract contract) {
    contractNumberController.text = contract.contractNumber;
    departmentController.text = contract.department;
    selectedDepartmentForm = contract.department;
    jobTitleController.text = contract.jobTitle;
    jobDescriptionController.text = contract.jobDescription;
    workLocationController.text = contract.workLocation;
    workScheduleController.text = contract.workSchedule;
    reportingManagerController.text = contract.reportingManager ?? '';
    grossSalaryController.text = contract.grossSalary.toString();
    netSalaryController.text = contract.netSalary.toString();
    weeklyHoursController.text = contract.weeklyHours.toString();
    selectedProbationPeriod = contract.probationPeriod;
    probationPeriodController.text = contract.probationPeriod;
    startDateController.text =
        contract.startDate.toIso8601String().split('T')[0];
    endDateController.text =
        contract.endDate?.toIso8601String().split('T')[0] ?? '';
    employeeNameController.text = contract.employeeName;
    employeeEmailController.text = contract.employeeEmail;
    employeePhoneController.text = contract.employeePhone ?? '';
    healthInsuranceController.text = contract.healthInsurance ?? '';
    retirementPlanController.text = contract.retirementPlan ?? '';
    vacationDaysController.text = contract.vacationDays?.toString() ?? '';
    otherBenefitsController.text = contract.otherBenefits ?? '';
    notesController.text = contract.notes ?? '';
    attachmentsController.text = contract.attachments
        .map((a) => a.fileName)
        .join(', ');

    selectedContractTypeForm = contract.contractType;
    selectedPaymentFrequency = contract.paymentFrequency;
  }

  // Mettre à jour un contrat
  Future<bool> updateContract(Contract contract) async {
    try {
      if (selectedEmployeeId == 0 ||
          selectedContractTypeForm.isEmpty ||
          departmentController.text.trim().isEmpty ||
          jobTitleController.text.trim().isEmpty ||
          grossSalaryController.text.trim().isEmpty ||
          selectedPaymentFrequency.isEmpty ||
          startDateController.text.trim().isEmpty ||
          workLocationController.text.trim().isEmpty) {
        ErrorHelper.showValidationError('Veuillez remplir tous les champs obligatoires');
        return false;
      }

      final grossSalary = double.tryParse(grossSalaryController.text);
      final weeklyHours = double.tryParse(weeklyHoursController.text) ?? 40.0;

      if (grossSalary == null) {
        ErrorHelper.showValidationError('Le montant du salaire doit être un nombre valide');
        return false;
      }

      // Utiliser la valeur sélectionnée pour la période d'essai (enum: 'none', '1_month', '3_months', '6_months')
      final String probationPeriod = selectedProbationPeriod;

      final result = await _contractService.updateContract(
        id: contract.id!,
        contractType: selectedContractTypeForm,
        position: jobTitleController.text.trim(),
        department: departmentController.text.trim(),
        jobTitle: jobTitleController.text.trim(),
        jobDescription: jobDescriptionController.text.trim(),
        grossSalary: grossSalary,
        netSalary: grossSalary * 0.8, // Calcul automatique du salaire net
        salaryCurrency: 'FCFA',
        paymentFrequency: selectedPaymentFrequency,
        startDate: DateTime.parse(startDateController.text),
        endDate:
            endDateController.text.isNotEmpty
                ? DateTime.parse(endDateController.text)
                : null,
        workLocation: workLocationController.text.trim(),
        workSchedule: workScheduleController.text.trim(),
        weeklyHours: weeklyHours.toInt(),
        probationPeriod: probationPeriod,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
      );

      if (result['success'] == true) {
        ErrorHelper.showSuccess('Contrat mis à jour avec succès');
        clearForm();
        loadContracts();
        loadContractStats();
        return true;
      } else {
        ErrorHelper.showError(result['message'] ?? 'Erreur lors de la mise à jour', title: 'Erreur');
        return false;
      }
    } catch (e) {
      ErrorHelper.showError('Erreur lors de la mise à jour du contrat: $e', title: 'Erreur');
      return false;
    }
  }
}
