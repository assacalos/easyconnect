import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/contract_model.dart';
import 'package:easyconnect/services/contract_service.dart';
import 'package:easyconnect/services/employee_service.dart';
import 'package:easyconnect/Models/employee_model.dart';

class ContractController extends GetxController {
  final ContractService _contractService = ContractService.to;
  final EmployeeService _employeeService = EmployeeService.to;

  // Variables observables
  final RxBool isLoading = false.obs;
  final RxList<Contract> contracts = <Contract>[].obs;
  final RxList<Contract> filteredContracts = <Contract>[].obs;
  final Rx<Contract?> selectedContract = Rx<Contract?>(null);
  final Rx<ContractStats?> contractStats = Rx<ContractStats?>(null);
  final RxList<Employee> employees = <Employee>[].obs;
  final RxList<String> departments = <String>[].obs;
  final RxList<ContractTemplate> contractTemplates = <ContractTemplate>[].obs;

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

  // Liste des fichiers sélectionnés pour les pièces jointes
  final RxList<Map<String, dynamic>> selectedAttachments =
      <Map<String, dynamic>>[].obs;

  // Variables de filtrage
  final RxString selectedStatus = 'all'.obs;
  final RxString selectedContractType = 'all'.obs;
  final RxString selectedDepartment = 'all'.obs;
  final Rx<DateTime?> selectedStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedEndDate = Rx<DateTime?>(null);

  // Variables pour le formulaire de création
  final RxInt selectedEmployeeId = 0.obs;
  final Rx<Employee?> selectedEmployee = Rx<Employee?>(null);
  final RxString selectedDepartmentForm = ''.obs;
  final RxString selectedContractTypeForm = 'all'.obs;
  final RxString selectedPaymentFrequency = 'monthly'.obs;
  final RxString selectedProbationPeriod = 'none'.obs;

  // Variables pour les permissions
  final RxBool canManageContracts =
      true.obs; // TODO: Implémenter la vérification des permissions
  final RxBool canApproveContracts =
      true.obs; // TODO: Implémenter la vérification des permissions
  final RxBool canViewAllContracts =
      true.obs; // TODO: Implémenter la vérification des permissions

  @override
  void onInit() {
    super.onInit();
    loadEmployees();
    loadDepartments();
    loadContractTemplates();
    loadContracts();
    loadContractStats();
    generateContractNumber();
  }

  @override
  void onClose() {
    jobTitleController.dispose();
    jobDescriptionController.dispose();
    workLocationController.dispose();
    grossSalaryController.dispose();
    netSalaryController.dispose();
    notesController.dispose();
    searchController.dispose();
    super.onClose();
  }

  // Charger les employés
  Future<void> loadEmployees() async {
    try {
      final emp = await _employeeService.getEmployees();
      employees.value = emp;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les employés',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Charger les départements
  Future<void> loadDepartments() async {
    try {
      final depts = await _employeeService.getDepartments();
      departments.value = depts;
    } catch (e) {
      // En cas d'erreur, utiliser les départements par défaut
      departments.value = [
        'Ressources Humaines',
        'Commercial',
        'Comptabilité',
        'Technique',
        'Support',
        'Direction',
      ];
    }
  }

  // Charger les modèles de contrat
  Future<void> loadContractTemplates() async {
    try {
      final templates = await _contractService.getContractTemplates();
      contractTemplates.value = templates;
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
  Future<void> loadContracts() async {
    try {
      isLoading.value = true;

      final contractsList = await _contractService.getAllContracts(
        status: selectedStatus.value != 'all' ? selectedStatus.value : null,
        contractType:
            selectedContractType.value != 'all'
                ? selectedContractType.value
                : null,
        department:
            selectedDepartment.value != 'all' ? selectedDepartment.value : null,
      );

      contracts.value = contractsList;
      applyFilters();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les contrats',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Charger les statistiques
  Future<void> loadContractStats() async {
    try {
      final stats = await _contractService.getContractStats(
        startDate: selectedStartDate.value,
        endDate: selectedEndDate.value,
        department:
            selectedDepartment.value != 'all' ? selectedDepartment.value : null,
        contractType:
            selectedContractType.value != 'all'
                ? selectedContractType.value
                : null,
      );
      contractStats.value = stats;
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

    filteredContracts.value = filtered;
  }

  // Rechercher dans les contrats
  void searchContracts(String query) {
    searchController.text = query;
    applyFilters();
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    selectedStatus.value = status;
    loadContracts();
  }

  // Filtrer par type de contrat
  void filterByContractType(String type) {
    selectedContractType.value = type;
    loadContracts();
  }

  // Filtrer par département
  void filterByDepartment(String department) {
    selectedDepartment.value = department;
    loadContracts();
  }

  // Filtrer par date
  void filterByDateRange(DateTime? startDate, DateTime? endDate) {
    selectedStartDate.value = startDate;
    selectedEndDate.value = endDate;
    loadContractStats();
  }

  // Créer un contrat
  Future<void> createContract() async {
    try {
      // Validation des champs obligatoires
      final department =
          selectedDepartmentForm.value.isNotEmpty
              ? selectedDepartmentForm.value
              : departmentController.text.trim();

      if (selectedEmployeeId.value == 0) {
        Get.snackbar('Erreur', 'Veuillez sélectionner un employé');
        return;
      }

      if (selectedContractTypeForm.value.isEmpty ||
          selectedContractTypeForm.value == 'all') {
        Get.snackbar('Erreur', 'Veuillez sélectionner un type de contrat');
        return;
      }

      // Validation spéciale pour les contrats fixed_term : end_date est obligatoire
      if (selectedContractTypeForm.value == 'fixed_term') {
        if (endDateController.text.trim().isEmpty) {
          Get.snackbar(
            'Erreur',
            'La date de fin est obligatoire pour les contrats à durée déterminée (CDD)',
          );
          return;
        }
      }

      if (department.isEmpty) {
        Get.snackbar('Erreur', 'Veuillez sélectionner un département');
        return;
      }

      if (jobTitleController.text.trim().isEmpty) {
        Get.snackbar('Erreur', 'Le poste est obligatoire');
        return;
      }

      // Validation de longueur pour job_title et position (max 100 caractères)
      // Note: position et job_title utilisent la même valeur (jobTitleController)
      if (jobTitleController.text.trim().length > 100) {
        Get.snackbar(
          'Erreur',
          'Le poste ne doit pas dépasser 100 caractères (actuellement: ${jobTitleController.text.trim().length})',
        );
        return;
      }

      // Validation de longueur pour department (max 100 caractères)
      if (department.length > 100) {
        Get.snackbar(
          'Erreur',
          'Le département ne doit pas dépasser 100 caractères (actuellement: ${department.length})',
        );
        return;
      }

      if (jobDescriptionController.text.trim().isEmpty) {
        Get.snackbar('Erreur', 'La description du poste est obligatoire');
        return;
      }

      if (jobDescriptionController.text.trim().length < 50) {
        Get.snackbar(
          'Erreur',
          'La description du poste doit contenir au moins 50 caractères (actuellement: ${jobDescriptionController.text.trim().length})',
        );
        return;
      }

      if (grossSalaryController.text.trim().isEmpty) {
        Get.snackbar('Erreur', 'Le salaire brut est obligatoire');
        return;
      }

      if (selectedPaymentFrequency.value.isEmpty) {
        Get.snackbar(
          'Erreur',
          'Veuillez sélectionner une fréquence de paiement',
        );
        return;
      }

      if (startDateController.text.trim().isEmpty) {
        Get.snackbar('Erreur', 'La date de début est obligatoire');
        return;
      }

      if (workLocationController.text.trim().isEmpty) {
        Get.snackbar('Erreur', 'Le lieu de travail est obligatoire');
        return;
      }

      // Validation de longueur pour work_location (max 255 caractères)
      if (workLocationController.text.trim().length > 255) {
        Get.snackbar(
          'Erreur',
          'Le lieu de travail ne doit pas dépasser 255 caractères (actuellement: ${workLocationController.text.trim().length})',
        );
        return;
      }

      if (workScheduleController.text.trim().isEmpty) {
        Get.snackbar('Erreur', 'L\'horaire de travail est obligatoire');
        return;
      }

      // Vérifier que work_schedule est une valeur valide
      final validWorkSchedules = ['full_time', 'part_time', 'flexible'];
      if (!validWorkSchedules.contains(workScheduleController.text.trim())) {
        Get.snackbar(
          'Erreur',
          'L\'horaire de travail doit être : Temps plein, Temps partiel ou Flexible',
        );
        return;
      }

      final grossSalary = double.tryParse(grossSalaryController.text);
      final weeklyHours = double.tryParse(weeklyHoursController.text) ?? 40.0;

      if (grossSalary == null) {
        Get.snackbar(
          'Erreur',
          'Le montant du salaire doit être un nombre valide',
        );
        return;
      }

      if (grossSalary < 0) {
        Get.snackbar(
          'Erreur',
          'Le salaire brut doit être supérieur ou égal à 0',
        );
        return;
      }

      // Validation de weekly_hours (1-168)
      final weeklyHoursInt = weeklyHours.toInt();
      if (weeklyHoursInt < 1 || weeklyHoursInt > 168) {
        Get.snackbar(
          'Erreur',
          'Les heures hebdomadaires doivent être entre 1 et 168 (actuellement: $weeklyHoursInt)',
        );
        return;
      }

      // Utiliser la valeur sélectionnée pour la période d'essai (enum: 'none', '1_month', '3_months', '6_months')
      final String probationPeriod = selectedProbationPeriod.value;

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
        Get.snackbar(
          'Erreur',
          'Format de date de début invalide: ${startDateController.text}',
        );
        return;
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
            Get.snackbar(
              'Erreur',
              'La date de fin doit être après la date de début',
            );
            return;
          }
        } catch (e) {
          Get.snackbar(
            'Erreur',
            'Format de date de fin invalide: ${endDateController.text}',
          );
          return;
        }
      }

      // Calculer la durée en mois si endDate est fourni
      int? durationMonths;
      if (endDate != null) {
        final difference = endDate.difference(startDate);
        durationMonths = (difference.inDays / 30).round();
      }

      final result = await _contractService.createContract(
        employeeId: selectedEmployeeId.value,
        contractType: selectedContractTypeForm.value,
        position: jobTitleController.text.trim(),
        department: department,
        jobTitle: jobTitleController.text.trim(),
        jobDescription: jobDescriptionController.text.trim(),
        grossSalary: grossSalary,
        netSalary: grossSalary * 0.8, // Calcul automatique du salaire net
        salaryCurrency: 'FCFA',
        paymentFrequency: selectedPaymentFrequency.value,
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
        Get.snackbar('Succès', 'Contrat créé avec succès');
        clearForm();
        loadContracts();
        loadContractStats();
      } else {
        final errorMessage = result['message'] ?? 'Erreur lors de la création';
        Get.snackbar('Erreur', errorMessage);
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la création du contrat: $e');
    }
  }

  // Soumettre un contrat
  Future<void> submitContract(Contract contract) async {
    try {
      final result = await _contractService.submitContract(contract.id!);

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Contrat soumis avec succès');
        loadContracts();
        loadContractStats();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de la soumission',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la soumission: $e');
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
        Get.snackbar('Succès', 'Contrat approuvé avec succès');
        loadContracts();
        loadContractStats();
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

  // Rejeter un contrat
  Future<void> rejectContract(Contract contract, String reason) async {
    try {
      final result = await _contractService.rejectContract(
        contract.id!,
        reason: reason,
      );

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Contrat rejeté');
        loadContracts();
        loadContractStats();
      } else {
        Get.snackbar('Erreur', result['message'] ?? 'Erreur lors du rejet');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors du rejet: $e');
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
        Get.snackbar('Succès', 'Contrat résilié');
        loadContracts();
        loadContractStats();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de la résiliation',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la résiliation: $e');
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
        Get.snackbar('Succès', 'Contrat annulé');
        loadContracts();
        loadContractStats();
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

  // Supprimer un contrat
  Future<void> deleteContract(Contract contract) async {
    try {
      final result = await _contractService.deleteContract(contract.id!);

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Contrat supprimé');
        loadContracts();
        loadContractStats();
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
      selectedEmployeeId.value = 0;
      selectedEmployee.value = null;
      employeeNameController.clear();
      employeeEmailController.clear();
      employeePhoneController.clear();
      return;
    }

    selectedEmployeeId.value = employeeId;
    // Mettre à jour les informations de l'employé
    final employee = employees.firstWhereOrNull((e) => e.id == employeeId);
    if (employee != null) {
      selectedEmployee.value = employee;
      employeeNameController.text = employee.fullName;
      employeeEmailController.text = employee.email;
      employeePhoneController.text = employee.phone ?? '';
      // Pré-remplir le département si disponible
      if (employee.department != null && employee.department!.isNotEmpty) {
        selectedDepartmentForm.value = employee.department!;
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
    selectedContractTypeForm.value = type;
  }

  // Sélectionner une fréquence de paiement
  void setPaymentFrequency(String frequency) {
    selectedPaymentFrequency.value = frequency;
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
    selectedDepartmentForm.value = department;
    departmentController.text = department;
  }

  // Réinitialiser le formulaire
  void clearForm() {
    selectedEmployeeId.value = 0;
    selectedEmployee.value = null;
    selectedDepartmentForm.value = '';
    selectedContractTypeForm.value = '';
    selectedPaymentFrequency.value =
        'monthly'; // Réinitialiser à la valeur par défaut
    selectedProbationPeriod.value = 'none';
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

      Get.snackbar(
        'Info',
        'Fonctionnalité de sélection de fichiers en cours de développement',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la sélection des fichiers: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
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
    selectedStatus.value = 'all';
    selectedContractType.value = 'all';
    selectedDepartment.value = 'all';
    selectedStartDate.value = null;
    selectedEndDate.value = null;
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
    selectedDepartmentForm.value = contract.department;
    jobTitleController.text = contract.jobTitle;
    jobDescriptionController.text = contract.jobDescription;
    workLocationController.text = contract.workLocation;
    workScheduleController.text = contract.workSchedule;
    reportingManagerController.text = contract.reportingManager ?? '';
    grossSalaryController.text = contract.grossSalary.toString();
    netSalaryController.text = contract.netSalary.toString();
    weeklyHoursController.text = contract.weeklyHours.toString();
    selectedProbationPeriod.value = contract.probationPeriod;
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

    selectedContractTypeForm.value = contract.contractType;
    selectedPaymentFrequency.value = contract.paymentFrequency;
  }

  // Mettre à jour un contrat
  Future<void> updateContract(Contract contract) async {
    try {
      if (selectedEmployeeId.value == 0 ||
          selectedContractTypeForm.value.isEmpty ||
          departmentController.text.trim().isEmpty ||
          jobTitleController.text.trim().isEmpty ||
          grossSalaryController.text.trim().isEmpty ||
          selectedPaymentFrequency.value.isEmpty ||
          startDateController.text.trim().isEmpty ||
          workLocationController.text.trim().isEmpty) {
        Get.snackbar('Erreur', 'Veuillez remplir tous les champs obligatoires');
        return;
      }

      final grossSalary = double.tryParse(grossSalaryController.text);
      final weeklyHours = double.tryParse(weeklyHoursController.text) ?? 40.0;

      if (grossSalary == null) {
        Get.snackbar(
          'Erreur',
          'Le montant du salaire doit être un nombre valide',
        );
        return;
      }

      // Utiliser la valeur sélectionnée pour la période d'essai (enum: 'none', '1_month', '3_months', '6_months')
      final String probationPeriod = selectedProbationPeriod.value;

      final result = await _contractService.updateContract(
        id: contract.id!,
        contractType: selectedContractTypeForm.value,
        position: jobTitleController.text.trim(),
        department: departmentController.text.trim(),
        jobTitle: jobTitleController.text.trim(),
        jobDescription: jobDescriptionController.text.trim(),
        grossSalary: grossSalary,
        netSalary: grossSalary * 0.8, // Calcul automatique du salaire net
        salaryCurrency: 'FCFA',
        paymentFrequency: selectedPaymentFrequency.value,
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
        Get.snackbar('Succès', 'Contrat mis à jour avec succès');
        clearForm();
        loadContracts();
        loadContractStats();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de la mise à jour',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la mise à jour du contrat: $e');
    }
  }
}
