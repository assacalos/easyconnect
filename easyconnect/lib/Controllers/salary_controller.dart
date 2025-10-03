import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/salary_model.dart';
import 'package:easyconnect/services/salary_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';

class SalaryController extends GetxController {
  final SalaryService _salaryService = SalaryService();
  final AuthController _authController = Get.find<AuthController>();

  // Variables observables
  final RxList<Salary> allSalaries = <Salary>[].obs; // Tous les salaires
  final RxList<Salary> salaries = <Salary>[].obs; // Salaires filtrés
  final RxList<Salary> pendingSalaries = <Salary>[].obs;
  final RxList<SalaryComponent> salaryComponents = <SalaryComponent>[].obs;
  final RxList<Map<String, dynamic>> employees = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<SalaryStats?> salaryStats = Rx<SalaryStats?>(null);

  // Variables pour le formulaire
  final RxString searchQuery = ''.obs;
  final RxString selectedStatus = 'all'.obs;
  final RxString selectedMonth = 'all'.obs;
  final RxInt selectedYear = DateTime.now().year.obs;
  final Rx<Salary?> selectedSalary = Rx<Salary?>(null);

  // Contrôleurs de formulaire
  final TextEditingController employeeSearchController =
      TextEditingController();
  final TextEditingController baseSalaryController = TextEditingController();
  final TextEditingController bonusController = TextEditingController();
  final TextEditingController deductionsController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final RxInt selectedEmployeeId = 0.obs;
  final RxString selectedEmployeeName = ''.obs;
  final RxString selectedEmployeeEmail = ''.obs;
  final RxString selectedMonthForm = ''.obs;
  final RxInt selectedYearForm = DateTime.now().year.obs;

  @override
  void onInit() {
    super.onInit();
    loadSalaries();
    loadSalaryStats();
    loadPendingSalaries();
    loadEmployees();
    loadSalaryComponents();
  }

  @override
  void onClose() {
    employeeSearchController.dispose();
    baseSalaryController.dispose();
    bonusController.dispose();
    deductionsController.dispose();
    notesController.dispose();
    super.onClose();
  }

  // Charger tous les salaires
  Future<void> loadSalaries() async {
    print('🔄 SalaryController: loadSalaries() appelé');
    try {
      isLoading.value = true;
      print('⏳ SalaryController: Chargement en cours...');

      // Tester la connectivité d'abord
      print('🧪 SalaryController: Test de connectivité...');
      final isConnected = await _salaryService.testSalaryConnection();
      print('🔗 SalaryController: Connectivité: ${isConnected ? "✅" : "❌"}');

      if (!isConnected) {
        throw Exception('Impossible de se connecter à l\'API Laravel');
      }

      // Charger toutes les salaires depuis l'API
      final loadedSalaries = await _salaryService.getSalaries(
        status: null, // Toujours charger tous les salaires
        month: null, // Pas de filtre côté serveur
        year: null, // Pas de filtre côté serveur
        search: null, // Pas de recherche côté serveur
      );

      print(
        '📦 SalaryController: ${loadedSalaries.length} salaires reçus du service',
      );

      // Stocker tous les salaires
      allSalaries.assignAll(loadedSalaries);
      applyFilters();

      print(
        '✅ SalaryController: Liste mise à jour avec ${salaries.length} salaires filtrés',
      );

      if (loadedSalaries.isNotEmpty) {
        Get.snackbar(
          'Succès',
          '${loadedSalaries.length} salaires chargés avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('❌ SalaryController: Erreur lors du chargement: $e');

      // Vider la liste des salaires en cas d'erreur
      allSalaries.value = [];
      salaries.value = [];

      // Message d'erreur spécifique selon le type d'erreur
      String errorMessage;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage =
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
      } else if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        errorMessage = 'Session expirée. Veuillez vous reconnecter.';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Erreur serveur. Veuillez réessayer plus tard.';
      } else if (e.toString().contains('FormatException') ||
          e.toString().contains('Unexpected end of input')) {
        errorMessage =
            'Erreur de format des données. Contactez l\'administrateur.';
      } else if (e.toString().contains('Null') ||
          e.toString().contains('not a subtype')) {
        errorMessage =
            'Erreur de format des données. Contactez l\'administrateur.';
      } else {
        errorMessage = 'Erreur lors du chargement des salaires: $e';
      }

      Get.snackbar(
        'Erreur',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
      print('🏁 SalaryController: Chargement terminé');
    }
  }

  // Charger les salaires en attente
  Future<void> loadPendingSalaries() async {
    print('🔄 SalaryController: loadPendingSalaries() appelé');
    try {
      print('🔄 SalaryController: Chargement des salaires en attente...');
      final pending = await _salaryService.getPendingSalaries();
      print(
        '📦 SalaryController: ${pending.length} salaires en attente reçus du service',
      );
      pendingSalaries.assignAll(pending);
      print(
        '✅ SalaryController: ${pending.length} salaires en attente chargés dans pendingSalaries',
      );
    } catch (e) {
      print(
        '❌ SalaryController: Erreur lors du chargement des salaires en attente: $e',
      );
      // Ne pas bloquer l'application si cette méthode échoue
      print(
        '🔄 SalaryController: Utilisation d\'une liste vide pour pendingSalaries',
      );
      pendingSalaries.clear();
    }
  }

  // Charger les employés
  Future<void> loadEmployees() async {
    print('🔄 SalaryController: loadEmployees() appelé');
    try {
      print('🔄 SalaryController: Chargement des employés...');
      final employeeList = await _salaryService.getEmployees();
      print(
        '👥 SalaryController: ${employeeList.length} employés reçus du service',
      );
      employees.assignAll(employeeList);
      print(
        '✅ SalaryController: ${employeeList.length} employés chargés dans employees',
      );
    } catch (e) {
      print('❌ SalaryController: Erreur lors du chargement des employés: $e');
      // Ne pas bloquer l'application si cette méthode échoue
      print(
        '🔄 SalaryController: Utilisation d\'une liste vide pour employees',
      );
      employees.clear();
    }
  }

  // Charger les composants de salaire
  Future<void> loadSalaryComponents() async {
    print('🔄 SalaryController: loadSalaryComponents() appelé');
    try {
      print('🔄 SalaryController: Chargement des composants de salaire...');
      final components = await _salaryService.getSalaryComponents();
      print(
        '🧩 SalaryController: ${components.length} composants reçus du service',
      );
      salaryComponents.assignAll(components);
      print(
        '✅ SalaryController: ${components.length} composants chargés dans salaryComponents',
      );
    } catch (e) {
      print('❌ SalaryController: Erreur lors du chargement des composants: $e');
      // Ne pas bloquer l'application si cette méthode échoue
      print(
        '🔄 SalaryController: Utilisation d\'une liste vide pour salaryComponents',
      );
      salaryComponents.clear();
    }
  }

  // Charger les statistiques
  Future<void> loadSalaryStats() async {
    try {
      final stats = await _salaryService.getSalaryStats();
      salaryStats.value = stats;
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
    }
  }

  // Tester la connectivité à l'API
  Future<bool> testSalaryConnection() async {
    try {
      print('🧪 SalaryController: Test de connectivité API...');
      return await _salaryService.testSalaryConnection();
    } catch (e) {
      print('❌ SalaryController: Erreur de test de connectivité: $e');
      return false;
    }
  }

  // Créer un salaire
  Future<void> createSalary() async {
    try {
      isLoading.value = true;

      final baseSalary = double.tryParse(baseSalaryController.text) ?? 0.0;
      final bonus = double.tryParse(bonusController.text) ?? 0.0;
      final deductions = double.tryParse(deductionsController.text) ?? 0.0;
      final netSalary = baseSalary + bonus - deductions;

      final salary = Salary(
        employeeId: selectedEmployeeId.value,
        employeeName: selectedEmployeeName.value,
        employeeEmail: selectedEmployeeEmail.value,
        baseSalary: baseSalary,
        bonus: bonus,
        deductions: deductions,
        netSalary: netSalary,
        month: selectedMonthForm.value,
        year: selectedYearForm.value,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _salaryService.createSalary(salary);
      await loadSalaries();
      await loadSalaryStats();

      Get.snackbar(
        'Succès',
        'Salaire créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      clearForm();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer le salaire',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Mettre à jour un salaire
  Future<void> updateSalary(Salary salary) async {
    try {
      isLoading.value = true;

      final baseSalary = double.tryParse(baseSalaryController.text) ?? 0.0;
      final bonus = double.tryParse(bonusController.text) ?? 0.0;
      final deductions = double.tryParse(deductionsController.text) ?? 0.0;
      final netSalary = baseSalary + bonus - deductions;

      final updatedSalary = Salary(
        id: salary.id,
        employeeId: selectedEmployeeId.value,
        employeeName: selectedEmployeeName.value,
        employeeEmail: selectedEmployeeEmail.value,
        baseSalary: baseSalary,
        bonus: bonus,
        deductions: deductions,
        netSalary: netSalary,
        month: selectedMonthForm.value,
        year: selectedYearForm.value,
        status: salary.status,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
        createdAt: salary.createdAt,
        updatedAt: DateTime.now(),
        createdBy: salary.createdBy,
        approvedBy: salary.approvedBy,
        approvedAt: salary.approvedAt,
        paidAt: salary.paidAt,
        rejectionReason: salary.rejectionReason,
      );

      await _salaryService.updateSalary(updatedSalary);
      await loadSalaries();
      await loadSalaryStats();

      Get.snackbar(
        'Succès',
        'Salaire mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      clearForm();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le salaire',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Approuver un salaire
  Future<void> approveSalary(Salary salary) async {
    try {
      isLoading.value = true;

      final success = await _salaryService.approveSalary(
        salary.id!,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
      );

      if (success) {
        await loadSalaries();
        await loadSalaryStats();
        await loadPendingSalaries();

        Get.snackbar(
          'Succès',
          'Salaire approuvé',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de l\'approbation');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'approuver le salaire',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Rejeter un salaire
  Future<void> rejectSalary(Salary salary, String reason) async {
    try {
      isLoading.value = true;

      final success = await _salaryService.rejectSalary(
        salary.id!,
        reason: reason,
      );

      if (success) {
        await loadSalaries();
        await loadSalaryStats();
        await loadPendingSalaries();

        Get.snackbar(
          'Succès',
          'Salaire rejeté',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors du rejet');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter le salaire',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Marquer comme payé
  Future<void> markSalaryAsPaid(Salary salary) async {
    try {
      isLoading.value = true;

      final success = await _salaryService.markSalaryAsPaid(
        salary.id!,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
      );

      if (success) {
        await loadSalaries();
        await loadSalaryStats();
        await loadPendingSalaries();

        Get.snackbar(
          'Succès',
          'Salaire marqué comme payé',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors du paiement');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de marquer le salaire comme payé',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Supprimer un salaire
  Future<void> deleteSalary(Salary salary) async {
    try {
      isLoading.value = true;

      final success = await _salaryService.deleteSalary(salary.id!);
      if (success) {
        salaries.removeWhere((s) => s.id == salary.id);
        await loadSalaryStats();

        Get.snackbar(
          'Succès',
          'Salaire supprimé avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le salaire',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Remplir le formulaire avec les données d'un salaire
  void fillForm(Salary salary) {
    selectedEmployeeId.value = salary.employeeId ?? 0;
    selectedEmployeeName.value = salary.employeeName ?? '';
    selectedEmployeeEmail.value = salary.employeeEmail ?? '';
    baseSalaryController.text = salary.baseSalary.toString();
    bonusController.text = salary.bonus.toString();
    deductionsController.text = salary.deductions.toString();
    selectedMonthForm.value = salary.month ?? '';
    selectedYearForm.value = salary.year ?? 0;
    notesController.text = salary.notes ?? '';
    selectedSalary.value = salary;
  }

  // Vider le formulaire
  void clearForm() {
    selectedEmployeeId.value = 0;
    selectedEmployeeName.value = '';
    selectedEmployeeEmail.value = '';
    baseSalaryController.clear();
    bonusController.clear();
    deductionsController.clear();
    notesController.clear();
    selectedMonthForm.value = '';
    selectedYearForm.value = DateTime.now().year;
    selectedSalary.value = null;
  }

  // Appliquer les filtres côté client
  void applyFilters() {
    print('🔍 SalaryController: applyFilters() appelé');
    print('📊 SalaryController: Statut sélectionné: ${selectedStatus.value}');
    print('📅 SalaryController: Mois sélectionné: ${selectedMonth.value}');
    print('🔍 SalaryController: Recherche: "${searchQuery.value}"');
    print('📦 SalaryController: Total salaires: ${allSalaries.length}');

    List<Salary> filteredSalaries = List.from(allSalaries);
    print(
      '🔄 SalaryController: Liste initiale: ${filteredSalaries.length} salaires',
    );

    // Filtrer par statut
    if (selectedStatus.value != 'all') {
      print(
        '🔍 SalaryController: Filtrage par statut: ${selectedStatus.value}',
      );
      final beforeCount = filteredSalaries.length;
      filteredSalaries =
          filteredSalaries.where((salary) {
            final matches = salary.status == selectedStatus.value;
            if (!matches) {
              print(
                '❌ SalaryController: Salaire "${salary.employeeName}" rejeté (statut: ${salary.status})',
              );
            }
            return matches;
          }).toList();
      print(
        '📊 SalaryController: Après filtrage par statut: $beforeCount → ${filteredSalaries.length}',
      );
    } else {
      print('📊 SalaryController: Pas de filtrage par statut (all)');
    }

    // Filtrer par mois
    if (selectedMonth.value != 'all') {
      print('📅 SalaryController: Filtrage par mois: ${selectedMonth.value}');
      final beforeCount = filteredSalaries.length;
      filteredSalaries =
          filteredSalaries.where((salary) {
            final matches = salary.month == selectedMonth.value;
            if (!matches) {
              print(
                '❌ SalaryController: Salaire "${salary.employeeName}" rejeté par mois (${salary.month})',
              );
            }
            return matches;
          }).toList();
      print(
        '📅 SalaryController: Après filtrage par mois: $beforeCount → ${filteredSalaries.length}',
      );
    } else {
      print('📅 SalaryController: Pas de filtrage par mois (all)');
    }

    // Filtrer par recherche
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      print('🔍 SalaryController: Filtrage par recherche: "$query"');
      final beforeCount = filteredSalaries.length;
      filteredSalaries =
          filteredSalaries.where((salary) {
            final matches =
                (salary.employeeName?.toLowerCase().contains(query) ?? false) ||
                (salary.employeeEmail?.toLowerCase().contains(query) ?? false);
            if (!matches) {
              print(
                '❌ SalaryController: Salaire "${salary.employeeName}" rejeté par recherche',
              );
            }
            return matches;
          }).toList();
      print(
        '🔍 SalaryController: Après filtrage par recherche: $beforeCount → ${filteredSalaries.length}',
      );
    } else {
      print('🔍 SalaryController: Pas de filtrage par recherche');
    }

    salaries.assignAll(filteredSalaries);
    print(
      '✅ SalaryController: Filtrage terminé - ${salaries.length} salaires affichés',
    );

    // Debug final
    if (salaries.isEmpty) {
      print('⚠️ SalaryController: AUCUN SALAIRE AFFICHÉ !');
      print('📊 SalaryController: allSalaries.length = ${allSalaries.length}');
      print('📊 SalaryController: selectedStatus = ${selectedStatus.value}');
      print('📅 SalaryController: selectedMonth = ${selectedMonth.value}');
      print('📊 SalaryController: searchQuery = "${searchQuery.value}"');

      if (allSalaries.isNotEmpty) {
        print('📋 SalaryController: Statuts disponibles:');
        for (final salary in allSalaries) {
          print(
            '   - ${salary.employeeName}: ${salary.status} (${salary.month})',
          );
        }
      }
    }
  }

  // Rechercher
  void searchSalaries(String query) {
    print('🔍 SalaryController: searchSalaries("$query") appelé');
    searchQuery.value = query;
    applyFilters();
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    print('📊 SalaryController: filterByStatus("$status") appelé');
    selectedStatus.value = status;
    applyFilters();
  }

  // Filtrer par mois
  void filterByMonth(String month) {
    print('📅 SalaryController: filterByMonth("$month") appelé');
    selectedMonth.value = month;
    applyFilters();
  }

  // Filtrer par année
  void filterByYear(int year) {
    print('📅 SalaryController: filterByYear($year) appelé');
    selectedYear.value = year;
    applyFilters();
  }

  // Sélectionner un employé
  void selectEmployee(Map<String, dynamic> employee) {
    selectedEmployeeId.value = employee['id'];
    selectedEmployeeName.value = employee['name'];
    selectedEmployeeEmail.value = employee['email'];
  }

  // Sélectionner le mois
  void selectMonth(String month) {
    selectedMonthForm.value = month;
  }

  // Sélectionner l'année
  void selectYear(int year) {
    selectedYearForm.value = year;
  }

  // Obtenir les mois
  List<Map<String, dynamic>> get months => [
    {'value': '01', 'label': 'Janvier'},
    {'value': '02', 'label': 'Février'},
    {'value': '03', 'label': 'Mars'},
    {'value': '04', 'label': 'Avril'},
    {'value': '05', 'label': 'Mai'},
    {'value': '06', 'label': 'Juin'},
    {'value': '07', 'label': 'Juillet'},
    {'value': '08', 'label': 'Août'},
    {'value': '09', 'label': 'Septembre'},
    {'value': '10', 'label': 'Octobre'},
    {'value': '11', 'label': 'Novembre'},
    {'value': '12', 'label': 'Décembre'},
  ];

  // Obtenir les années
  List<int> get years {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) => currentYear - 2 + index);
  }

  // Vérifier les permissions
  bool get canManageSalaries {
    final userRole = _authController.userAuth.value?.role;
    return userRole == 1 || userRole == 3; // Admin, Comptable
  }

  bool get canApproveSalaries {
    final userRole = _authController.userAuth.value?.role;
    return userRole == 1 || userRole == 4; // Admin, Patron
  }

  bool get canViewSalaries {
    final userRole = _authController.userAuth.value?.role;
    return userRole != null; // Tous les rôles
  }

  // Obtenir les salaires par statut
  List<Salary> get salariesByStatus {
    if (selectedStatus.value == 'all') return salaries;
    return salaries
        .where((salary) => salary.status == selectedStatus.value)
        .toList();
  }

  // Obtenir les salaires par mois
  List<Salary> get salariesByMonth {
    if (selectedMonth.value == 'all') return salaries;
    return salaries
        .where((salary) => salary.month == selectedMonth.value)
        .toList();
  }

  // Obtenir les salaires filtrés
  List<Salary> get filteredSalaries {
    List<Salary> filtered = salaries;

    if (selectedStatus.value != 'all') {
      filtered =
          filtered
              .where((salary) => salary.status == selectedStatus.value)
              .toList();
    }

    if (selectedMonth.value != 'all') {
      filtered =
          filtered
              .where((salary) => salary.month == selectedMonth.value)
              .toList();
    }

    if (searchQuery.value.isNotEmpty) {
      filtered =
          filtered
              .where(
                (salary) =>
                    (salary.employeeName?.toLowerCase().contains(
                          searchQuery.value.toLowerCase(),
                        ) ??
                        false) ||
                    (salary.employeeEmail?.toLowerCase().contains(
                          searchQuery.value.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();
    }

    return filtered;
  }
}
