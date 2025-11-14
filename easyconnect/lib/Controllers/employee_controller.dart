import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/employee_model.dart';
import 'package:easyconnect/services/employee_service.dart';

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

  // Charger les employés
  Future<void> loadEmployees({bool loadAll = false}) async {
    try {
      print('🔵 [EMPLOYEE_CONTROLLER] loadEmployees() appelé');
      isLoading.value = true;

      // Charger avec pagination pour éviter les réponses trop grandes
      final employeesList = await _employeeService.getEmployees(
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
        // Ne pas filtrer par statut si loadAll est true ou si on veut charger tous les employés
        status:
            (loadAll || selectedStatus.value == 'all')
                ? null
                : selectedStatus.value,
        page: 1, // Charger la première page
        limit:
            100, // Limite de 100 employés par page pour éviter les réponses trop grandes
      );
      print('✅ [EMPLOYEE_CONTROLLER] ${employeesList.length} employés chargés');
      employees.value = employeesList;
    } catch (e, stackTrace) {
      print('❌ [EMPLOYEE_CONTROLLER] Erreur loadEmployees: $e');
      print('❌ [EMPLOYEE_CONTROLLER] Stack trace: $stackTrace');

      // Extraire le message d'erreur
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      Get.snackbar(
        'Erreur',
        'Impossible de charger les employés: $errorMessage',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
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
  Future<void> createEmployee() async {
    try {
      isCreating.value = true;

      await _employeeService.createEmployee(
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
            selectedDepartment.value.isNotEmpty
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
                ? double.parse(salaryController.text)
                : null,
        currency: selectedCurrency.value,
        workSchedule:
            selectedWorkSchedule.value.isNotEmpty
                ? selectedWorkSchedule.value
                : null,
        notes:
            notesController.text.trim().isNotEmpty
                ? notesController.text.trim()
                : null,
      );

      Get.snackbar('Succès', 'Employé créé avec succès');
      clearForm();
      loadEmployees(loadAll: true);
      loadEmployeeStats();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la création de l\'employé: $e');
    } finally {
      isCreating.value = false;
    }
  }

  // Mettre à jour un employé
  Future<void> updateEmployee(Employee employee) async {
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
            selectedDepartment.value.isNotEmpty
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
                ? double.parse(salaryController.text)
                : null,
        currency: selectedCurrency.value,
        workSchedule:
            selectedWorkSchedule.value.isNotEmpty
                ? selectedWorkSchedule.value
                : null,
        status: selectedStatus.value,
        notes:
            notesController.text.trim().isNotEmpty
                ? notesController.text.trim()
                : null,
      );

      Get.snackbar('Succès', 'Employé mis à jour avec succès');
      clearForm();
      loadEmployees(loadAll: true);
      loadEmployeeStats();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la mise à jour de l\'employé: $e');
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
      Get.snackbar('Succès', 'Employé soumis pour approbation');
      loadEmployees();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la soumission: $e');
    }
  }

  // Approuver un employé
  Future<void> approveEmployee(Employee employee, {String? comments}) async {
    try {
      await _employeeService.approveEmployee(employee.id!, comments: comments);
      Get.snackbar('Succès', 'Employé approuvé');
      loadEmployees();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de l\'approbation: $e');
    }
  }

  // Rejeter un employé
  Future<void> rejectEmployee(
    Employee employee, {
    required String reason,
  }) async {
    try {
      await _employeeService.rejectEmployee(employee.id!, reason: reason);
      Get.snackbar('Succès', 'Employé rejeté');
      loadEmployees();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors du rejet: $e');
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
