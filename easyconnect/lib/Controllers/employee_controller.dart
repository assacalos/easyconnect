import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/employee_model.dart';
import 'package:easyconnect/services/employee_service.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/notification_helper.dart';

class EmployeeController extends GetxController {
  final EmployeeService _employeeService = EmployeeService.to;

  // Variables observables
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isDeleting = false.obs;
  final RxList<Employee> employees = <Employee>[].obs;
  final Rx<Employee?> selectedEmployee = Rx<Employee?>(null);
  final Rx<Employee?> selectedEmployeeForForm = Rx<Employee?>(null);
  final Rx<EmployeeStats?> employeeStats = Rx<EmployeeStats?>(null);
  final RxList<String> departments = <String>[].obs;
  final RxList<String> positions = <String>[].obs;

  // Variables pour la recherche et les filtres
  final RxString searchQuery = ''.obs;
  final RxString selectedDepartment = 'all'.obs;
  final RxString selectedPosition = 'all'.obs;
  final RxString selectedStatus = 'all'.obs;
  final RxString selectedSortBy = 'name'.obs;
  final RxBool sortAscending = true.obs;

  // Métadonnées de pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPreviousPage = false.obs;
  final RxInt perPage = 15.obs;

  // Variables pour le formulaire
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

  // Variables pour les sélections
  final Rx<DateTime?> selectedBirthDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedHireDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedContractStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedContractEndDate = Rx<DateTime?>(null);
  final RxString selectedGender = ''.obs;
  final RxString selectedMaritalStatus = ''.obs;
  final RxString selectedNationality = ''.obs;
  //final RxString selectedDepartment = ''.obs;
  final RxString selectedContractType = ''.obs;
  final RxString selectedCurrency = 'fcfa'.obs;
  final RxString selectedWorkSchedule = ''.obs;
  //final RxString selectedStatus = 'active'.obs;

  // Variables pour les documents
  final TextEditingController documentNameController = TextEditingController();
  final TextEditingController documentDescriptionController =
      TextEditingController();
  final RxString selectedDocumentType = ''.obs;
  final Rx<DateTime?> selectedDocumentExpiryDate = Rx<DateTime?>(null);
  final RxBool isDocumentRequired = false.obs;

  // Variables pour les congés
  final RxString selectedLeaveType = ''.obs;
  final Rx<DateTime?> selectedLeaveStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedLeaveEndDate = Rx<DateTime?>(null);
  final TextEditingController leaveReasonController = TextEditingController();

  // Variables pour les performances
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
  final RxDouble selectedPerformanceRating = 0.0.obs;

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

  @override
  void onInit() {
    super.onInit();
    loadEmployees();
    loadEmployeeStats();
    loadDepartments();
    loadPositions();
  }

  @override
  void onClose() {
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
    super.onClose();
  }

  // Charger les employés avec pagination
  Future<void> loadEmployees({bool loadAll = false, int page = 1}) async {
    try {
      // Afficher immédiatement les données du cache si disponibles (seulement pour la première page)
      if (page == 1) {
        final cacheKey =
            'employees_${searchQuery.value}_${selectedDepartment.value}_${selectedPosition.value}_${selectedStatus.value}';
        final cachedEmployees = CacheHelper.get<List<Employee>>(cacheKey);
        if (cachedEmployees != null && cachedEmployees.isNotEmpty) {
          employees.value = cachedEmployees;
          isLoading.value = false; // Permettre l'affichage immédiat
        } else {
          isLoading.value = true;
        }
      } else {
        isLoading.value = true;
      }

      currentPage.value = page;

      // Utiliser la méthode paginée pour obtenir les métadonnées
      final paginatedResponse = await _employeeService.getEmployeesPaginated(
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        department:
            selectedDepartment.value != 'all' &&
                    selectedDepartment.value.isNotEmpty
                ? selectedDepartment.value
                : null,
        position:
            selectedPosition.value != 'all' && selectedPosition.value.isNotEmpty
                ? selectedPosition.value
                : null,
        status:
            (loadAll || selectedStatus.value == 'all')
                ? null
                : selectedStatus.value,
        page: page,
        perPage: perPage.value,
      );

      // Mettre à jour les métadonnées de pagination
      totalPages.value = paginatedResponse.meta.lastPage;
      totalItems.value = paginatedResponse.meta.total;
      hasNextPage.value = paginatedResponse.hasNextPage;
      hasPreviousPage.value = paginatedResponse.hasPreviousPage;
      currentPage.value = paginatedResponse.meta.currentPage;

      // Mettre à jour la liste des employés
      final employeesList = paginatedResponse.data;

      // Si c'est la première page, remplacer la liste
      // Sinon, ajouter à la liste existante (pour le scroll infini)
      if (page == 1) {
        employees.value = employeesList;
        // Sauvegarder dans le cache pour un affichage instantané la prochaine fois (durée 15 min)
        final cacheKey =
            'employees_${searchQuery.value}_${selectedDepartment.value}_${selectedPosition.value}_${selectedStatus.value}';
        CacheHelper.set(cacheKey, employeesList, duration: AppConfig.mediumCacheDuration);
      } else {
        // Ajouter les nouveaux éléments à la liste existante
        final existingIds = employees.map((e) => e.id).toSet();
        final newEmployees =
            employeesList
                .where((e) => e.id != null && !existingIds.contains(e.id))
                .toList();
        employees.addAll(newEmployees);
      }

      // Trier la liste
      employees.sort((a, b) {
        final nameA = '${a.lastName} ${a.firstName}'.toLowerCase();
        final nameB = '${b.lastName} ${b.firstName}'.toLowerCase();
        return nameA.compareTo(nameB);
      });
    } catch (e) {
      // Extraire le message d'erreur
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      // Vérifier le cache en cas d'erreur réseau (seulement pour la première page)
      if (page == 1 && employees.isEmpty) {
        final cacheKey =
            'employees_${searchQuery.value}_${selectedDepartment.value}_${selectedPosition.value}_${selectedStatus.value}';
        final cachedEmployees = CacheHelper.get<List<Employee>>(cacheKey);
        if (cachedEmployees != null && cachedEmployees.isNotEmpty) {
          // Charger les données du cache si disponibles
          employees.value = cachedEmployees;
          // Ne pas afficher d'erreur si on a des données en cache
          return;
        }
      }

      // Ne pas afficher d'erreur si des données sont disponibles (cache ou liste non vide)
      // Ne pas afficher d'erreur pour les erreurs d'authentification (déjà gérées)
      final errorString = e.toString().toLowerCase();
      if (!errorString.contains('session expirée') &&
          !errorString.contains('401') &&
          !errorString.contains('unauthorized')) {
        if (employees.isEmpty) {
          // Utiliser addPostFrameCallback pour éviter l'erreur "visitChildElements during build"
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.snackbar(
              'Erreur',
              'Impossible de charger les employés: $errorMessage',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
          });
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Charger la page suivante (pour scroll infini)
  Future<void> loadNextPage() async {
    if (hasNextPage.value && !isLoading.value) {
      await loadEmployees(page: currentPage.value + 1);
    }
  }

  /// Charger la page précédente
  Future<void> loadPreviousPage() async {
    if (hasPreviousPage.value && !isLoading.value) {
      await loadEmployees(page: currentPage.value - 1);
    }
  }

  /// Recharger la page actuelle
  Future<void> reloadCurrentPage() async {
    await loadEmployees(page: currentPage.value);
  }

  // Charger les statistiques
  Future<void> loadEmployeeStats() async {
    try {
      final stats = await _employeeService.getEmployeeStats();
      employeeStats.value = stats;
    } catch (e) {}
  }

  // Charger les départements
  Future<void> loadDepartments() async {
    try {
      final departmentsList = await _employeeService.getDepartments();
      departments.value = departmentsList;
    } catch (e) {}
  }

  // Charger les postes
  Future<void> loadPositions() async {
    try {
      final positionsList = await _employeeService.getPositions();
      positions.value = positionsList;
    } catch (e) {}
  }

  // Rechercher des employés
  void searchEmployees(String query) {
    searchQuery.value = query;
    loadEmployees();
  }

  // Filtrer par département
  void filterByDepartment(String department) {
    selectedDepartment.value = department;
    loadEmployees();
  }

  // Filtrer par poste
  void filterByPosition(String position) {
    selectedPosition.value = position;
    loadEmployees();
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    selectedStatus.value = status;
    loadEmployees();
  }

  // Trier les employés
  void sortEmployees(String sortBy) {
    if (selectedSortBy.value == sortBy) {
      sortAscending.value = !sortAscending.value;
    } else {
      selectedSortBy.value = sortBy;
      sortAscending.value = true;
    }
    _applySorting();
  }

  // Appliquer le tri
  void _applySorting() {
    employees.sort((a, b) {
      int comparison = 0;
      switch (selectedSortBy.value) {
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
      return sortAscending.value ? comparison : -comparison;
    });
  }

  // Obtenir les employés filtrés
  List<Employee> get filteredEmployees {
    List<Employee> filtered = employees;

    if (searchQuery.value.isNotEmpty) {
      filtered =
          filtered
              .where(
                (employee) =>
                    employee.fullName.toLowerCase().contains(
                      searchQuery.value.toLowerCase(),
                    ) ||
                    employee.email.toLowerCase().contains(
                      searchQuery.value.toLowerCase(),
                    ) ||
                    (employee.position ?? '').toLowerCase().contains(
                      searchQuery.value.toLowerCase(),
                    ),
              )
              .toList();
    }

    if (selectedDepartment.value != 'all') {
      filtered =
          filtered
              .where(
                (employee) => employee.department == selectedDepartment.value,
              )
              .toList();
    }

    if (selectedPosition.value != 'all') {
      filtered =
          filtered
              .where((employee) => employee.position == selectedPosition.value)
              .toList();
    }

    if (selectedStatus.value != 'all') {
      filtered =
          filtered
              .where((employee) => employee.status == selectedStatus.value)
              .toList();
    }

    return filtered;
  }

  // Créer un nouvel employé
  Future<bool> createEmployee() async {
    try {
      isCreating.value = true;

      // Validation des champs obligatoires
      if (firstNameController.text.trim().isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'Erreur',
            'Le prénom est obligatoire',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        });
        return false;
      }

      if (lastNameController.text.trim().isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'Erreur',
            'Le nom est obligatoire',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        });
        return false;
      }

      if (emailController.text.trim().isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'Erreur',
            'L\'email est obligatoire',
            snackPosition: SnackPosition.BOTTOM,
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
          Get.snackbar(
            'Erreur',
            'Format d\'email invalide',
            snackPosition: SnackPosition.BOTTOM,
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
        birthDate: selectedBirthDate.value,
        gender: selectedGender.value.isNotEmpty ? selectedGender.value : null,
        maritalStatus:
            selectedMaritalStatus.value.isNotEmpty
                ? selectedMaritalStatus.value
                : null,
        nationality:
            selectedNationality.value.isNotEmpty
                ? selectedNationality.value
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
            selectedDepartment.value.isNotEmpty &&
                    selectedDepartment.value != 'all'
                ? selectedDepartment.value
                : null,
        manager:
            managerController.text.trim().isNotEmpty
                ? managerController.text.trim()
                : null,
        hireDate: selectedHireDate.value,
        contractStartDate: selectedContractStartDate.value,
        contractEndDate: selectedContractEndDate.value,
        contractType:
            selectedContractType.value.isNotEmpty
                ? selectedContractType.value
                : null,
        salary:
            salaryController.text.isNotEmpty
                ? double.tryParse(salaryController.text)
                : null,
        currency:
            selectedCurrency.value.isNotEmpty
                ? selectedCurrency.value
                : 'fcfa', // Valeur par défaut
        workSchedule:
            selectedWorkSchedule.value.isNotEmpty
                ? selectedWorkSchedule.value
                : null,
        notes:
            notesController.text.trim().isNotEmpty
                ? notesController.text.trim()
                : null,
      );

      // Mise à jour optimiste : ajouter l'employé créé à la liste immédiatement
      try {
        if (result['data'] != null) {
          final createdEmployee = Employee.fromJson(result['data']);
          // Vérifier si l'employé n'existe pas déjà dans la liste
          if (!employees.any((e) => e.id == createdEmployee.id)) {
            employees.add(createdEmployee);
          }
        }
      } catch (e) {
        print(
          '⚠️ [EMPLOYEE_CONTROLLER] Impossible d\'ajouter l\'employé créé à la liste: $e',
        );
      }

      // Utiliser addPostFrameCallback pour éviter l'erreur "visitChildElements during build"
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Succès',
          'Employé créé avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      });

      clearForm();

      // Recharger en arrière-plan pour synchroniser avec le serveur
      Future.microtask(() async {
        try {
          await loadEmployees(loadAll: true);
        } catch (e) {
          // Ignorer les erreurs de rechargement en arrière-plan
          print(
            '⚠️ [EMPLOYEE_CONTROLLER] Erreur lors du rechargement en arrière-plan: $e',
          );
        }
      });

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

        Get.snackbar(
          'Erreur',
          'Erreur lors de la création de l\'employé: $errorMessage',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      });
      return false;
    } finally {
      isCreating.value = false;
    }
  }

  // Mettre à jour un employé
  Future<bool> updateEmployee(Employee employee) async {
    try {
      isUpdating.value = true;

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
        birthDate: selectedBirthDate.value,
        gender: selectedGender.value.isNotEmpty ? selectedGender.value : null,
        maritalStatus:
            selectedMaritalStatus.value.isNotEmpty
                ? selectedMaritalStatus.value
                : null,
        nationality:
            selectedNationality.value.isNotEmpty
                ? selectedNationality.value
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
            selectedDepartment.value.isNotEmpty &&
                    selectedDepartment.value != 'all'
                ? selectedDepartment.value
                : null,
        manager:
            managerController.text.trim().isNotEmpty
                ? managerController.text.trim()
                : null,
        hireDate: selectedHireDate.value,
        contractStartDate: selectedContractStartDate.value,
        contractEndDate: selectedContractEndDate.value,
        contractType:
            selectedContractType.value.isNotEmpty
                ? selectedContractType.value
                : null,
        salary:
            salaryController.text.isNotEmpty
                ? double.tryParse(salaryController.text)
                : null,
        currency:
            selectedCurrency.value.isNotEmpty
                ? selectedCurrency.value
                : 'fcfa', // Valeur par défaut
        workSchedule:
            selectedWorkSchedule.value.isNotEmpty
                ? selectedWorkSchedule.value
                : null,
        status:
            selectedStatus.value.isNotEmpty && selectedStatus.value != 'all'
                ? selectedStatus.value
                : null,
        notes:
            notesController.text.trim().isNotEmpty
                ? notesController.text.trim()
                : null,
      );

      // Utiliser addPostFrameCallback pour éviter l'erreur "visitChildElements during build"
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Succès',
          'Employé mis à jour avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      });

      clearForm();
      await loadEmployees(loadAll: true);
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

        Get.snackbar(
          'Erreur',
          'Erreur lors de la mise à jour de l\'employé: $errorMessage',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      });
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // Supprimer un employé
  Future<void> deleteEmployee(Employee employee) async {
    try {
      isDeleting.value = true;

      await _employeeService.deleteEmployee(employee.id!);

      Get.snackbar('Succès', 'Employé supprimé avec succès');
      loadEmployees(loadAll: true);
      loadEmployeeStats();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la suppression de l\'employé: $e');
    } finally {
      isDeleting.value = false;
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

      Get.snackbar('Succès', 'Employé soumis pour approbation');
      loadEmployees();
    } catch (e) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      final errorStr = e.toString().toLowerCase();
      if (!errorStr.contains('parsing') &&
          !errorStr.contains('json') &&
          !errorStr.contains('type') &&
          !errorStr.contains('cast') &&
          !errorStr.contains('null')) {
        Get.snackbar('Erreur', 'Erreur lors de la soumission: $e');
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

      Get.snackbar('Succès', 'Employé approuvé');
      loadEmployees();
    } catch (e) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      final errorStr = e.toString().toLowerCase();
      if (!errorStr.contains('parsing') &&
          !errorStr.contains('json') &&
          !errorStr.contains('type') &&
          !errorStr.contains('cast') &&
          !errorStr.contains('null')) {
        Get.snackbar('Erreur', 'Erreur lors de l\'approbation: $e');
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

      Get.snackbar('Succès', 'Employé rejeté');
      loadEmployees();
    } catch (e) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      final errorStr = e.toString().toLowerCase();
      if (!errorStr.contains('parsing') &&
          !errorStr.contains('json') &&
          !errorStr.contains('type') &&
          !errorStr.contains('cast') &&
          !errorStr.contains('null')) {
        Get.snackbar('Erreur', 'Erreur lors du rejet: $e');
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

    selectedBirthDate.value = employee.birthDate;
    selectedHireDate.value = employee.hireDate;
    selectedContractStartDate.value = employee.contractStartDate;
    selectedContractEndDate.value = employee.contractEndDate;
    selectedGender.value = employee.gender ?? '';
    selectedMaritalStatus.value = employee.maritalStatus ?? '';
    selectedNationality.value = employee.nationality ?? '';
    selectedDepartment.value = employee.department ?? '';
    selectedContractType.value = employee.contractType ?? '';
    selectedCurrency.value = employee.currency ?? 'fcfa';
    selectedWorkSchedule.value = employee.workSchedule ?? '';
    selectedStatus.value = employee.status ?? 'active';
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

    selectedBirthDate.value = null;
    selectedHireDate.value = null;
    selectedContractStartDate.value = null;
    selectedContractEndDate.value = null;
    selectedGender.value = '';
    selectedMaritalStatus.value = '';
    selectedNationality.value = '';
    selectedDepartment.value = '';
    selectedContractType.value = '';
    selectedCurrency.value = 'fcfa';
    selectedWorkSchedule.value = '';
    selectedStatus.value = 'active';
  }

  // Sélectionner une date
  Future<void> selectDate(BuildContext context, Rx<DateTime?> dateRx) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dateRx.value ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      dateRx.value = picked;
    }
  }

  // Sélectionner un employé
  void selectEmployee(Employee employee) {
    selectedEmployee.value = employee;
  }

  // Sélectionner un employé pour remplir le formulaire
  void selectEmployeeForForm(Employee? employee) {
    selectedEmployeeForForm.value = employee;
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
