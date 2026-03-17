import 'package:flutter/material.dart';
import 'package:easyconnect/Models/employee_model.dart';
import 'package:easyconnect/services/employee_service.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/error_helper.dart';

class EmployeeController {
  static final EmployeeController _instance = EmployeeController._();
  static EmployeeController get to => _instance;
  factory EmployeeController() => _instance;
  EmployeeController._();

  final EmployeeService _employeeService = EmployeeService.to;

  // Variables
  bool isLoading = false;
  bool isLoadingMore = false;
  bool isCreating = false;
  bool isUpdating = false;
  bool isDeleting = false;
  final List<Employee> employees = [];
  Employee? selectedEmployee;
  Employee? selectedEmployeeForForm;
  EmployeeStats? employeeStats;
  final List<String> departments = [];
  final List<String> positions = [];

  String searchQuery = '';
  String selectedDepartment = 'all';
  String selectedPosition = 'all';
  String selectedStatus = 'all';
  String selectedSortBy = 'name';
  bool sortAscending = true;

  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  int perPage = 15;
  final ScrollController scrollController = ScrollController();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController idNumberController = TextEditingController();
  final TextEditingController socialSecurityController =
      TextEditingController();
  final TextEditingController positionController = TextEditingController();
  final TextEditingController managerController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  DateTime? selectedBirthDate;
  DateTime? selectedHireDate;
  DateTime? selectedContractStartDate;
  DateTime? selectedContractEndDate;
  String selectedGender = '';
  String selectedMaritalStatus = '';
  String selectedNationality = '';
  String selectedContractType = '';
  String selectedCurrency = 'fcfa';
  String selectedWorkSchedule = '';

  final TextEditingController documentNameController = TextEditingController();
  final TextEditingController documentDescriptionController =
      TextEditingController();
  String selectedDocumentType = '';
  DateTime? selectedDocumentExpiryDate;
  bool isDocumentRequired = false;

  String selectedLeaveType = '';
  DateTime? selectedLeaveStartDate;
  DateTime? selectedLeaveEndDate;
  final TextEditingController leaveReasonController = TextEditingController();

  final TextEditingController performancePeriodController =
      TextEditingController();
  final TextEditingController performanceCommentsController =
      TextEditingController();
  final TextEditingController performanceGoalsController =
      TextEditingController();
  final TextEditingController performanceAchievementsController =
      TextEditingController();
  final TextEditingController performanceImprovementController =
      TextEditingController();
  double selectedPerformanceRating = 0.0;

  // Listes pour les dropdowns
  final List<Map<String, dynamic>> genders = [
    {'value': 'male', 'label': 'Homme'},
    {'value': 'female', 'label': 'Femme'},
    {'value': 'other', 'label': 'Autre'},
  ];

  final List<Map<String, dynamic>> maritalStatuses = [
    {'value': 'single', 'label': 'Célibataire'},
    {'value': 'married', 'label': 'Marié(e)'},
    {'value': 'divorced', 'label': 'Divorcé(e)'},
    {'value': 'widowed', 'label': 'Veuf/Veuve'},
  ];

  final List<Map<String, dynamic>> nationalities = [
    {'value': 'cameroon', 'label': 'Camerounais(e)'},
    {'value': 'french', 'label': 'Français(e)'},
    {'value': 'nigerian', 'label': 'Nigérian(e)'},
    {'value': 'other', 'label': 'Autre'},
  ];

  final List<Map<String, dynamic>> contractTypes = [
    {'value': 'permanent', 'label': 'CDI'},
    {'value': 'temporary', 'label': 'CDD'},
    {'value': 'internship', 'label': 'Stage'},
    {'value': 'consultant', 'label': 'Consultant'},
  ];

  final List<Map<String, dynamic>> currencies = [
    {'value': 'fcfa', 'label': 'FCFA'},
    {'value': 'eur', 'label': 'EUR'},
    {'value': 'usd', 'label': 'USD'},
  ];

  final List<Map<String, dynamic>> workSchedules = [
    {'value': 'full_time', 'label': 'Temps plein'},
    {'value': 'part_time', 'label': 'Temps partiel'},
    {'value': 'flexible', 'label': 'Flexible'},
    {'value': 'shift', 'label': 'Par équipes'},
  ];

  final List<Map<String, dynamic>> employeeStatuses = [
    {'value': 'active', 'label': 'Actif'},
    {'value': 'inactive', 'label': 'Inactif'},
    {'value': 'on_leave', 'label': 'En congé'},
    {'value': 'terminated', 'label': 'Terminé'},
  ];

  final List<Map<String, dynamic>> documentTypes = [
    {'value': 'contract', 'label': 'Contrat'},
    {'value': 'id_card', 'label': 'Carte d\'identité'},
    {'value': 'passport', 'label': 'Passeport'},
    {'value': 'diploma', 'label': 'Diplôme'},
    {'value': 'certificate', 'label': 'Certificat'},
    {'value': 'medical', 'label': 'Certificat médical'},
    {'value': 'other', 'label': 'Autre'},
  ];

  final List<Map<String, dynamic>> leaveTypes = [
    {'value': 'annual', 'label': 'Congé annuel'},
    {'value': 'sick', 'label': 'Congé maladie'},
    {'value': 'maternity', 'label': 'Congé maternité'},
    {'value': 'paternity', 'label': 'Congé paternité'},
    {'value': 'personal', 'label': 'Congé personnel'},
    {'value': 'unpaid', 'label': 'Congé sans solde'},
  ];

  final List<Map<String, dynamic>> sortOptions = [
    {'value': 'name', 'label': 'Nom'},
    {'value': 'department', 'label': 'Département'},
    {'value': 'position', 'label': 'Poste'},
    {'value': 'hire_date', 'label': 'Date d\'embauche'},
    {'value': 'salary', 'label': 'Salaire'},
  ];

  void ensureInitialized() {}

  void dispose() {
    scrollController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    idNumberController.dispose();
    socialSecurityController.dispose();
    positionController.dispose();
    managerController.dispose();
    salaryController.dispose();
    notesController.dispose();
    documentNameController.dispose();
    documentDescriptionController.dispose();
    leaveReasonController.dispose();
    performancePeriodController.dispose();
    performanceCommentsController.dispose();
    performanceGoalsController.dispose();
    performanceAchievementsController.dispose();
    performanceImprovementController.dispose();
  }

  bool _isLoadingEmployeesInProgress = false;

  /// Charge les employés : Hive d'abord (affichage immédiat), puis API dans la même méthode.
  Future<void> loadEmployees({
    bool loadAll = false,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    if (_isLoadingEmployeesInProgress) return;
    _isLoadingEmployeesInProgress = true;
    final cacheKey =
        'employees_${searchQuery}_${selectedDepartment}_${selectedPosition}_${selectedStatus}';

    if (page == 1) {
      isLoading = true;
      final hiveList = EmployeeService.getCachedEmployees();
      if (hiveList.isNotEmpty && !forceRefresh) {
        employees.clear();
        employees.addAll(hiveList);
        isLoading = false;
        currentPage = 1;
      } else {
        final cached = CacheHelper.get<List<Employee>>(cacheKey);
        if (cached != null && cached.isNotEmpty && !forceRefresh) {
          employees.clear();
          employees.addAll(cached);
          isLoading = false;
        } else {
          employees.clear();
        }
      }
    } else {
      isLoadingMore = true;
    }

    try {
      final paginatedResponse = await _employeeService.getEmployeesPaginated(
        search: searchQuery.isNotEmpty ? searchQuery : null,
        department:
            selectedDepartment != 'all' && selectedDepartment.isNotEmpty
                ? selectedDepartment
                : null,
        position:
            selectedPosition != 'all' && selectedPosition.isNotEmpty
                ? selectedPosition
                : null,
        status: (loadAll || selectedStatus == 'all') ? null : selectedStatus,
        page: page,
        perPage: perPage,
      );

      totalPages = paginatedResponse.meta.lastPage;
      totalItems = paginatedResponse.meta.total;
      hasNextPage = paginatedResponse.hasNextPage;
      hasPreviousPage = paginatedResponse.hasPreviousPage;
      currentPage = paginatedResponse.meta.currentPage;

      final employeesList = paginatedResponse.data;
      if (page == 1) {
        employees.clear();
        employees.addAll(employeesList);
        CacheHelper.set(cacheKey, employeesList, duration: AppConfig.mediumCacheDuration);
      } else {
        final existingIds = employees.map((e) => e.id).toSet();
        employees.addAll(
          employeesList.where((e) => e.id != null && !existingIds.contains(e.id)),
        );
      }

      employees.sort((a, b) {
        final nameA = '${a.lastName} ${a.firstName}'.toLowerCase();
        final nameB = '${b.lastName} ${b.firstName}'.toLowerCase();
        return nameA.compareTo(nameB);
      });
    } catch (e) {
      if (page == 1 && employees.isEmpty) {
        final fallback = EmployeeService.getCachedEmployees();
        if (fallback.isNotEmpty) {
          employees.clear();
          employees.addAll(fallback);
        } else {
          final cached = CacheHelper.get<List<Employee>>(cacheKey);
          if (cached != null && cached.isNotEmpty) {
            employees.clear();
          employees.addAll(cached);
          } else {
            final err = e.toString().toLowerCase();
            if (!err.contains('401') && !err.contains('unauthorized')) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                errorHelperShowSnackbar?.call(
                  'Erreur',
                  'Impossible de charger les employés',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 5),
                );
              });
            }
          }
        }
      }
    } finally {
      isLoading = false;
      isLoadingMore = false;
      _isLoadingEmployeesInProgress = false;
    }
  }

  /// Chargement de la page suivante au scroll.
  void loadMore() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadNextPage();
    }
  }

  /// Charger la page suivante (pour scroll infini)
  Future<void> loadNextPage() async {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      await loadEmployees(page: currentPage + 1);
    }
  }

  /// Charger la page précédente
  Future<void> loadPreviousPage() async {
    if (hasPreviousPage && !isLoading) {
      await loadEmployees(page: currentPage - 1);
    }
  }

  /// Recharger la page actuelle
  Future<void> reloadCurrentPage() async {
    await loadEmployees(page: currentPage);
  }

  // Charger les statistiques
  Future<void> loadEmployeeStats() async {
    try {
      final stats = await _employeeService.getEmployeeStats();
      employeeStats = stats;
    } catch (e) {}
  }

  // Charger les départements
  Future<void> loadDepartments() async {
    try {
      final departmentsList = await _employeeService.getDepartments();
      departments.clear();
      departments.addAll(departmentsList);
    } catch (e) {}
  }

  // Charger les postes
  Future<void> loadPositions() async {
    try {
      final positionsList = await _employeeService.getPositions();
      positions.clear();
      positions.addAll(positionsList);
    } catch (e) {}
  }

  // Rechercher des employés
  void searchEmployees(String query) {
    searchQuery = query;
    loadEmployees();
  }

  // Filtrer par département
  void filterByDepartment(String department) {
    selectedDepartment = department;
    loadEmployees();
  }

  // Filtrer par poste
  void filterByPosition(String position) {
    selectedPosition = position;
    loadEmployees();
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    selectedStatus = status;
    loadEmployees();
  }

  /// Charge les employés pour l’onglet [index] (0=Actifs, 1=Inactifs, 2=En congé, 3=Terminés). Cache-first.
  void loadByStatus(int index, {bool forceRefresh = false}) {
    const statuses = ['active', 'inactive', 'on_leave', 'terminated'];
    selectedStatus = statuses[index];
    loadEmployees(forceRefresh: forceRefresh);
  }

  // Trier les employés
  void sortEmployees(String sortBy) {
    if (selectedSortBy == sortBy) {
      sortAscending = !sortAscending;
    } else {
      selectedSortBy = sortBy;
      sortAscending = true;
    }
    _applySorting();
  }

  // Appliquer le tri
  void _applySorting() {
    employees.sort((a, b) {
      int comparison = 0;
      switch (selectedSortBy) {
        case 'name':
          comparison = a.fullName.compareTo(b.fullName);
          break;
        case 'department':
          comparison = (a.department ?? '').compareTo(b.department ?? '');
          break;
        case 'position':
          comparison = (a.position ?? '').compareTo(b.position ?? '');
          break;
        case 'hire_date':
          comparison = (a.hireDate ?? DateTime.now()).compareTo(
            b.hireDate ?? DateTime.now(),
          );
          break;
        case 'salary':
          comparison = (a.salary ?? 0).compareTo(b.salary ?? 0);
          break;
      }
      return sortAscending ? comparison : -comparison;
    });
  }

  // Obtenir les employés filtrés
  List<Employee> get filteredEmployees {
    List<Employee> filtered = employees;

    if (searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (employee) =>
                    employee.fullName.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    employee.email.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    (employee.position ?? '').toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    }

    if (selectedDepartment != 'all') {
      filtered =
          filtered
              .where(
                (employee) => employee.department == selectedDepartment,
              )
              .toList();
    }

    if (selectedPosition != 'all') {
      filtered =
          filtered
              .where((employee) => employee.position == selectedPosition)
              .toList();
    }

    if (selectedStatus != 'all') {
      filtered =
          filtered
              .where((employee) => employee.status == selectedStatus)
              .toList();
    }

    return filtered;
  }

  // Créer un nouvel employé
  Future<bool> createEmployee() async {
    try {
      isCreating = true;

      // Validation des champs obligatoires
      if (firstNameController.text.trim().isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          errorHelperShowSnackbar?.call(
            'Erreur',
            'Le prénom est obligatoire',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        });
        return false;
      }

      if (lastNameController.text.trim().isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          errorHelperShowSnackbar?.call(
            'Erreur',
            'Le nom est obligatoire',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        });
        return false;
      }

      if (emailController.text.trim().isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          errorHelperShowSnackbar?.call(
            'Erreur',
            'L\'email est obligatoire',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        });
        return false;
      }

      // Validation de l'email
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(emailController.text.trim())) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          errorHelperShowSnackbar?.call(
            'Erreur',
            'Format d\'email invalide',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        });
        return false;
      }

      print('✅ [EMPLOYEE_CONTROLLER] Validation OK, création de l\'employé...');
      print(
        '📝 [EMPLOYEE_CONTROLLER] Prénom: ${firstNameController.text.trim()}',
      );
      print('📝 [EMPLOYEE_CONTROLLER] Nom: ${lastNameController.text.trim()}');
      print('📝 [EMPLOYEE_CONTROLLER] Email: ${emailController.text.trim()}');

      final result = await _employeeService.createEmployee(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        phone:
            phoneController.text.trim().isNotEmpty
                ? phoneController.text.trim()
                : null,
        address:
            addressController.text.trim().isNotEmpty
                ? addressController.text.trim()
                : null,
        birthDate: selectedBirthDate,
        gender: selectedGender.isNotEmpty ? selectedGender : null,
        maritalStatus:
            selectedMaritalStatus.isNotEmpty
                ? selectedMaritalStatus
                : null,
        nationality:
            selectedNationality.isNotEmpty
                ? selectedNationality
                : null,
        idNumber:
            idNumberController.text.trim().isNotEmpty
                ? idNumberController.text.trim()
                : null,
        socialSecurityNumber:
            socialSecurityController.text.trim().isNotEmpty
                ? socialSecurityController.text.trim()
                : null,
        position:
            positionController.text.trim().isNotEmpty
                ? positionController.text.trim()
                : null,
        department:
            selectedDepartment.isNotEmpty &&
                    selectedDepartment != 'all'
                ? selectedDepartment
                : null,
        manager:
            managerController.text.trim().isNotEmpty
                ? managerController.text.trim()
                : null,
        hireDate: selectedHireDate,
        contractStartDate: selectedContractStartDate,
        contractEndDate: selectedContractEndDate,
        contractType:
            selectedContractType.isNotEmpty
                ? selectedContractType
                : null,
        salary:
            salaryController.text.isNotEmpty
                ? double.tryParse(salaryController.text)
                : null,
        currency:
            selectedCurrency.isNotEmpty
                ? selectedCurrency
                : 'fcfa', // Valeur par défaut
        workSchedule:
            selectedWorkSchedule.isNotEmpty
                ? selectedWorkSchedule
                : null,
        notes:
            notesController.text.trim().isNotEmpty
                ? notesController.text.trim()
                : null,
      );

      // Mise à jour optimiste : ajouter l'employé créé à la liste et persister le cache Hive
      try {
        if (result['data'] != null) {
          final createdEmployee = Employee.fromJson(result['data']);
          if (!employees.any((e) => e.id == createdEmployee.id)) {
            employees.insert(0, createdEmployee);
            EmployeeService.saveCachedEmployees(employees.toList());
          }
        }
      } catch (e) {
        print(
          '⚠️ [EMPLOYEE_CONTROLLER] Impossible d\'ajouter l\'employé créé à la liste: $e',
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        errorHelperShowSnackbar?.call(
          'Succès',
          'Employé créé avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      });

      clearForm();
      CacheHelper.clearByPrefix('employees_');
      // Pas de loadEmployees(forceRefresh: true) pour ne pas écraser l'insertion

      await loadEmployeeStats();
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

      // Utiliser addPostFrameCallback pour éviter l'erreur "visitChildElements during build"
      WidgetsBinding.instance.addPostFrameCallback((_) {
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        errorHelperShowSnackbar?.call(
          'Erreur',
          'Erreur lors de la création de l\'employé: $errorMessage',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      });
      return false;
    } finally {
      isCreating = false;
    }
  }

  // Mettre à jour un employé
  Future<bool> updateEmployee(Employee employee) async {
    try {
      isUpdating = true;

      await _employeeService.updateEmployee(
        id: employee.id!,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        phone:
            phoneController.text.trim().isNotEmpty
                ? phoneController.text.trim()
                : null,
        address:
            addressController.text.trim().isNotEmpty
                ? addressController.text.trim()
                : null,
        birthDate: selectedBirthDate,
        gender: selectedGender.isNotEmpty ? selectedGender : null,
        maritalStatus:
            selectedMaritalStatus.isNotEmpty
                ? selectedMaritalStatus
                : null,
        nationality:
            selectedNationality.isNotEmpty
                ? selectedNationality
                : null,
        idNumber:
            idNumberController.text.trim().isNotEmpty
                ? idNumberController.text.trim()
                : null,
        socialSecurityNumber:
            socialSecurityController.text.trim().isNotEmpty
                ? socialSecurityController.text.trim()
                : null,
        position:
            positionController.text.trim().isNotEmpty
                ? positionController.text.trim()
                : null,
        department:
            selectedDepartment.isNotEmpty &&
                    selectedDepartment != 'all'
                ? selectedDepartment
                : null,
        manager:
            managerController.text.trim().isNotEmpty
                ? managerController.text.trim()
                : null,
        hireDate: selectedHireDate,
        contractStartDate: selectedContractStartDate,
        contractEndDate: selectedContractEndDate,
        contractType:
            selectedContractType.isNotEmpty
                ? selectedContractType
                : null,
        salary:
            salaryController.text.isNotEmpty
                ? double.tryParse(salaryController.text)
                : null,
        currency:
            selectedCurrency.isNotEmpty
                ? selectedCurrency
                : 'fcfa', // Valeur par défaut
        workSchedule:
            selectedWorkSchedule.isNotEmpty
                ? selectedWorkSchedule
                : null,
        status:
            selectedStatus.isNotEmpty && selectedStatus != 'all'
                ? selectedStatus
                : null,
        notes:
            notesController.text.trim().isNotEmpty
                ? notesController.text.trim()
                : null,
      );

      // Utiliser addPostFrameCallback pour éviter l'erreur "visitChildElements during build"
      WidgetsBinding.instance.addPostFrameCallback((_) {
        errorHelperShowSnackbar?.call(
          'Succès',
          'Employé mis à jour avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      });

      clearForm();
      CacheHelper.clearByPrefix('employees_');
      await loadEmployees(loadAll: true, forceRefresh: true);
      await loadEmployeeStats();
      return true;
    } catch (e, stackTrace) {
      // Logger l'erreur pour le débogage
      print('❌ [EMPLOYEE_CONTROLLER] Erreur lors de la mise à jour: $e');
      print('❌ [EMPLOYEE_CONTROLLER] Stack trace: $stackTrace');

      // Utiliser addPostFrameCallback pour éviter l'erreur "visitChildElements during build"
      WidgetsBinding.instance.addPostFrameCallback((_) {
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        errorHelperShowSnackbar?.call(
          'Erreur',
          'Erreur lors de la mise à jour de l\'employé: $errorMessage',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      });
      return false;
    } finally {
      isUpdating = false;
    }
  }

  // Supprimer un employé
  Future<void> deleteEmployee(Employee employee) async {
    try {
      isDeleting = true;

      await _employeeService.deleteEmployee(employee.id!);

      errorHelperShowSnackbar?.call('Succès', 'Employé supprimé avec succès');
      CacheHelper.clearByPrefix('employees_');
      loadEmployees(loadAll: true, forceRefresh: true);
      loadEmployeeStats();
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', 'Erreur lors de la suppression de l\'employé: $e');
    } finally {
      isDeleting = false;
    }
  }

  // Soumettre un employé pour approbation
  Future<void> submitEmployeeForApproval(Employee employee) async {
    try {
      await _employeeService.submitEmployeeForApproval(employee.id!);

      // Notifier le patron de la soumission
      NotificationHelper.notifySubmission(
        entityType: 'employee',
        entityName: NotificationHelper.getEntityDisplayName(
          'employee',
          employee,
        ),
        entityId: employee.id.toString(),
        route: NotificationHelper.getEntityRoute(
          'employee',
          employee.id.toString(),
        ),
      );

      errorHelperShowSnackbar?.call('Succès', 'Employé soumis pour approbation');
      loadEmployees();
    } catch (e) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      final errorStr = e.toString().toLowerCase();
      if (!errorStr.contains('parsing') &&
          !errorStr.contains('json') &&
          !errorStr.contains('type') &&
          !errorStr.contains('cast') &&
          !errorStr.contains('null')) {
        errorHelperShowSnackbar?.call('Erreur', 'Erreur lors de la soumission: $e');
      }
    }
  }

  // Approuver un employé
  Future<void> approveEmployee(Employee employee, {String? comments}) async {
    try {
      await _employeeService.approveEmployee(employee.id!, comments: comments);

      // Notifier l'utilisateur concerné de la validation
      NotificationHelper.notifyValidation(
        entityType: 'employee',
        entityName: NotificationHelper.getEntityDisplayName(
          'employee',
          employee,
        ),
        entityId: employee.id.toString(),
        route: NotificationHelper.getEntityRoute(
          'employee',
          employee.id.toString(),
        ),
        entity: employee,
      );

      errorHelperShowSnackbar?.call('Succès', 'Employé approuvé');
      loadEmployees();
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

  // Rejeter un employé
  Future<void> rejectEmployee(
    Employee employee, {
    required String reason,
  }) async {
    try {
      await _employeeService.rejectEmployee(employee.id!, reason: reason);

      // Notifier l'utilisateur concerné du rejet
      NotificationHelper.notifyRejection(
        entityType: 'employee',
        entityName: NotificationHelper.getEntityDisplayName(
          'employee',
          employee,
        ),
        entityId: employee.id.toString(),
        reason: reason,
        route: NotificationHelper.getEntityRoute(
          'employee',
          employee.id.toString(),
        ),
        entity: employee,
      );

      errorHelperShowSnackbar?.call('Succès', 'Employé rejeté');
      loadEmployees();
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

  // Remplir le formulaire pour l'édition
  void fillForm(Employee employee) {
    firstNameController.text = employee.firstName;
    lastNameController.text = employee.lastName;
    emailController.text = employee.email;
    phoneController.text = employee.phone ?? '';
    addressController.text = employee.address ?? '';
    idNumberController.text = employee.idNumber ?? '';
    socialSecurityController.text = employee.socialSecurityNumber ?? '';
    positionController.text = employee.position ?? '';
    managerController.text = employee.manager ?? '';
    salaryController.text = employee.salary?.toString() ?? '';
    notesController.text = employee.notes ?? '';

    selectedBirthDate = employee.birthDate;
    selectedHireDate = employee.hireDate;
    selectedContractStartDate = employee.contractStartDate;
    selectedContractEndDate = employee.contractEndDate;
    selectedGender = employee.gender ?? '';
    selectedMaritalStatus = employee.maritalStatus ?? '';
    selectedNationality = employee.nationality ?? '';
    selectedDepartment = employee.department ?? '';
    selectedContractType = employee.contractType ?? '';
    selectedCurrency = employee.currency ?? 'fcfa';
    selectedWorkSchedule = employee.workSchedule ?? '';
    selectedStatus = employee.status ?? 'active';
  }

  // Vider le formulaire
  void clearForm() {
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    phoneController.clear();
    addressController.clear();
    idNumberController.clear();
    socialSecurityController.clear();
    positionController.clear();
    managerController.clear();
    salaryController.clear();
    notesController.clear();

    selectedBirthDate = null;
    selectedHireDate = null;
    selectedContractStartDate = null;
    selectedContractEndDate = null;
    selectedGender = '';
    selectedMaritalStatus = '';
    selectedNationality = '';
    selectedDepartment = '';
    selectedContractType = '';
    selectedCurrency = 'fcfa';
    selectedWorkSchedule = '';
    selectedStatus = 'active';
  }

  // Sélectionner une date
  Future<void> selectDate(BuildContext context, DateTime? initialValue, void Function(DateTime?) onDatePicked) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialValue ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onDatePicked(picked);
    }
  }

  // Sélectionner un employé
  void selectEmployee(Employee employee) {
    selectedEmployee = employee;
  }

  // Sélectionner un employé pour remplir le formulaire
  void selectEmployeeForForm(Employee? employee) {
    selectedEmployeeForForm = employee;
    if (employee != null) {
      fillForm(employee);
    } else {
      clearForm();
    }
  }

  // Vérifier les permissions
  bool get canManageEmployees =>
      true; // TODO: Implémenter la vérification des permissions
  bool get canViewEmployees =>
      true; // TODO: Implémenter la vérification des permissions
  bool get canApproveEmployees =>
      true; // TODO: Implémenter la vérification des permissions
}
