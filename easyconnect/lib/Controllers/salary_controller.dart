import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/salary_model.dart';
import 'package:easyconnect/services/salary_service.dart';
import 'package:easyconnect/services/user_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class SalaryController extends GetxController {
  final SalaryService _salaryService = SalaryService();
  final UserService _userService = UserService();
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
  final RxDouble netSalary = 0.0.obs; // Salaire net calculé
  final RxList<Map<String, dynamic>> selectedFiles =
      <Map<String, dynamic>>[].obs; // Fichiers justificatifs

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
    try {
      isLoading.value = true;

      // Tester la connectivité d'abord
      final isConnected = await _salaryService.testSalaryConnection();

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

      // Stocker tous les salaires
      allSalaries.assignAll(loadedSalaries);
      applyFilters();

      // Ne pas afficher de message de succès à chaque chargement
      // Le chargement se fait silencieusement
    } catch (e) {
      // Vider la liste des salaires en cas d'erreur
      allSalaries.value = [];
      salaries.value = [];

      // Ne pas afficher de message d'erreur à l'utilisateur
      // L'erreur est loggée dans la console pour le débogage
    } finally {
      isLoading.value = false;
    }
  }

  // Charger les salaires en attente
  Future<void> loadPendingSalaries() async {
    try {
      final pending = await _salaryService.getPendingSalaries();
      pendingSalaries.assignAll(pending);
    } catch (e) {
      // Ne pas bloquer l'application si cette méthode échoue
      pendingSalaries.clear();
    }
  }

  // Charger les utilisateurs de l'application comme employés
  Future<void> loadEmployees() async {
    try {
      // Charger tous les utilisateurs de l'application
      final usersList = await _userService.getUsers();
      // Convertir les UserModel en Map<String, dynamic> au format attendu
      final employeesList =
          usersList.map((user) {
            // Construire le nom complet à partir de nom et prenom
            final fullName =
                [
                  user.nom ?? '',
                  user.prenom ?? '',
                ].where((part) => part.isNotEmpty).join(' ').trim();

            // Si aucun nom n'est disponible, utiliser l'email comme nom
            final displayName =
                fullName.isNotEmpty
                    ? fullName
                    : (user.email ?? 'Utilisateur ${user.id}');

            return {
              'id': user.id,
              'name': displayName,
              'email': user.email ?? '',
            };
          }).toList();

      employees.assignAll(employeesList);
    } catch (e) {
      // Ne pas bloquer l'application si cette méthode échoue
      employees.clear();
    }
  }

  // Charger les composants de salaire
  Future<void> loadSalaryComponents() async {
    try {
      final components = await _salaryService.getSalaryComponents();
      salaryComponents.assignAll(components);
    } catch (e) {
      // Ne pas bloquer l'application si cette méthode échoue
      salaryComponents.clear();
    }
  }

  // Charger les statistiques
  Future<void> loadSalaryStats() async {
    try {
      final stats = await _salaryService.getSalaryStats();
      salaryStats.value = stats;
    } catch (e) {}
  }

  // Tester la connectivité à l'API
  Future<bool> testSalaryConnection() async {
    try {
      return await _salaryService.testSalaryConnection();
    } catch (e) {
      return false;
    }
  }

  // Créer un salaire
  Future<bool> createSalary() async {
    try {
      isLoading.value = true;

      // Validation des champs obligatoires
      if (selectedEmployeeId.value == 0) {
        Get.snackbar(
          'Erreur',
          'Veuillez sélectionner un employé',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      if (selectedMonthForm.value.isEmpty) {
        Get.snackbar(
          'Erreur',
          'Veuillez sélectionner un mois',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      if (selectedYearForm.value == 0) {
        Get.snackbar(
          'Erreur',
          'Veuillez sélectionner une année',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      final baseSalary = double.tryParse(baseSalaryController.text) ?? 0.0;
      if (baseSalary <= 0) {
        Get.snackbar(
          'Erreur',
          'Le salaire de base doit être supérieur à 0',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

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
        status: 'pending', // Statut par défaut
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
        justificatifs:
            selectedFiles.map((file) => file['path'] as String).toList(),
        // Ne pas inclure createdAt et updatedAt - le serveur les gère
      );

      await _salaryService.createSalary(salary);
      await loadSalaries();
      await loadSalaryStats();

      Get.snackbar(
        'Succès',
        'Salaire créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      clearForm();
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer le salaire: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Mettre à jour un salaire
  Future<bool> updateSalary(Salary salary) async {
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
        justificatifs:
            selectedFiles.isNotEmpty
                ? selectedFiles.map((file) => file['path'] as String).toList()
                : salary.justificatifs,
      );

      await _salaryService.updateSalary(updatedSalary);
      await loadSalaries();
      await loadSalaryStats();

      Get.snackbar(
        'Succès',
        'Salaire mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      clearForm();
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le salaire: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Approuver un salaire
  Future<void> approveSalary(Salary salary) async {
    try {
      print(
        '🔵 [SALARY_CONTROLLER] approveSalary() appelé pour salaryId: ${salary.id}',
      );
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
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception(
          'Erreur lors de l\'approbation - La réponse du serveur indique un échec',
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'approuver le salaire: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
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
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        throw Exception(
          'Erreur lors du rejet - La réponse du serveur indique un échec',
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter le salaire: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
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
    // Charger les justificatifs existants
    selectedFiles.value =
        salary.justificatifs
            .map(
              (path) => {
                'name': path.split('/').last,
                'path': path,
                'size': 0,
                'type': path.toLowerCase().endsWith('.pdf') ? 'pdf' : 'image',
                'extension': path.split('.').last.toLowerCase(),
              },
            )
            .toList();
  }

  // Mettre à jour le salaire net calculé
  void updateNetSalary() {
    final baseSalary = double.tryParse(baseSalaryController.text) ?? 0.0;
    final bonus = double.tryParse(bonusController.text) ?? 0.0;
    final deductions = double.tryParse(deductionsController.text) ?? 0.0;
    netSalary.value = baseSalary + bonus - deductions;
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
    netSalary.value = 0.0;
    selectedFiles.clear();
  }

  // Sélectionner des fichiers justificatifs
  Future<void> selectFiles() async {
    try {
      final String? selectionType = await Get.dialog<String>(
        AlertDialog(
          title: const Text('Sélectionner des justificatifs'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Fichiers (PDF, Documents, etc.)'),
                onTap: () => Get.back(result: 'file'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Image depuis la galerie'),
                onTap: () => Get.back(result: 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo / Scanner'),
                onTap: () => Get.back(result: 'camera'),
              ),
            ],
          ),
        ),
      );

      if (selectionType == null) return;

      if (selectionType == 'file') {
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: true,
        );

        if (result != null && result.files.isNotEmpty) {
          for (var platformFile in result.files) {
            if (platformFile.path != null) {
              final file = File(platformFile.path!);
              final fileSize = await file.length();

              if (fileSize > 10 * 1024 * 1024) {
                Get.snackbar(
                  'Erreur',
                  'Le fichier "${platformFile.name}" est trop volumineux (max 10 MB)',
                  snackPosition: SnackPosition.BOTTOM,
                );
                continue;
              }

              String fileType = 'document';
              final extension = platformFile.extension?.toLowerCase() ?? '';
              if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
                fileType = 'image';
              } else if (extension == 'pdf') {
                fileType = 'pdf';
              }

              selectedFiles.add({
                'name': platformFile.name,
                'path': platformFile.path!,
                'size': fileSize,
                'type': fileType,
                'extension': extension,
              });
            }
          }

          Get.snackbar(
            'Succès',
            '${result.files.length} fichier(s) sélectionné(s)',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        final ImagePicker picker = ImagePicker();
        final ImageSource source =
            selectionType == 'camera'
                ? ImageSource.camera
                : ImageSource.gallery;

        final XFile? pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          final file = File(pickedFile.path);
          final fileSize = await file.length();

          if (fileSize > 10 * 1024 * 1024) {
            Get.snackbar(
              'Erreur',
              'Le fichier est trop volumineux (max 10 MB)',
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }

          selectedFiles.add({
            'name': pickedFile.name,
            'path': pickedFile.path,
            'size': fileSize,
            'type': 'image',
            'extension': 'jpg',
          });

          Get.snackbar(
            'Succès',
            'Fichier sélectionné',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la sélection du fichier: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Supprimer un fichier de la liste
  void removeFile(int index) {
    if (index >= 0 && index < selectedFiles.length) {
      selectedFiles.removeAt(index);
    }
  }

  // Appliquer les filtres côté client
  void applyFilters() {
    List<Salary> filteredSalaries = List.from(allSalaries);
    // Filtrer par statut
    if (selectedStatus.value != 'all') {
      filteredSalaries =
          filteredSalaries.where((salary) {
            return salary.status == selectedStatus.value;
          }).toList();
    }

    // Filtrer par mois
    if (selectedMonth.value != 'all') {
      filteredSalaries =
          filteredSalaries.where((salary) {
            return salary.month == selectedMonth.value;
          }).toList();
    }

    // Filtrer par recherche
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filteredSalaries =
          filteredSalaries.where((salary) {
            return (salary.employeeName?.toLowerCase().contains(query) ??
                    false) ||
                (salary.employeeEmail?.toLowerCase().contains(query) ?? false);
          }).toList();
    }

    salaries.assignAll(filteredSalaries);
  }

  // Rechercher
  void searchSalaries(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    selectedStatus.value = status;
    applyFilters();
  }

  // Filtrer par mois
  void filterByMonth(String month) {
    selectedMonth.value = month;
    applyFilters();
  }

  // Filtrer par année
  void filterByYear(int year) {
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
