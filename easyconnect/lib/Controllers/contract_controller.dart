import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/contract_model.dart';
import 'package:easyconnect/services/contract_service.dart';

class ContractController extends GetxController {
  final ContractService _contractService = ContractService.to;

  // Variables observables
  final RxBool isLoading = false.obs;
  final RxList<Contract> contracts = <Contract>[].obs;
  final RxList<Contract> filteredContracts = <Contract>[].obs;
  final Rx<Contract?> selectedContract = Rx<Contract?>(null);
  final Rx<ContractStats?> contractStats = Rx<ContractStats?>(null);
  final RxList<Map<String, dynamic>> employees = <Map<String, dynamic>>[].obs;
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

  // Variables de filtrage
  final RxString selectedStatus = 'all'.obs;
  final RxString selectedContractType = 'all'.obs;
  final RxString selectedDepartment = 'all'.obs;
  final Rx<DateTime?> selectedStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedEndDate = Rx<DateTime?>(null);

  // Variables pour le formulaire de création
  final RxInt selectedEmployeeId = 0.obs;
  final RxString selectedContractTypeForm = 'all'.obs;
  final RxString selectedPaymentFrequency = 'monthly'.obs;

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
      final emp = await _contractService.getAvailableEmployees();
      employees.value = emp;
    } catch (e) {
      print('Erreur lors du chargement des employés: $e');
    }
  }

  // Charger les modèles de contrat
  Future<void> loadContractTemplates() async {
    try {
      final templates = await _contractService.getContractTemplates();
      contractTemplates.value = templates;
    } catch (e) {
      print('Erreur lors du chargement des modèles: $e');
    }
  }

  // Générer un numéro de contrat
  Future<void> generateContractNumber() async {
    try {
      final number = await _contractService.generateContractNumber();
      contractNumberController.text = number;
    } catch (e) {
      print('Erreur lors de la génération du numéro: $e');
    }
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
      print('Erreur lors du chargement des contrats: $e');
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
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
    }
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
      final probationPeriod = int.tryParse(probationPeriodController.text);

      if (grossSalary == null) {
        Get.snackbar(
          'Erreur',
          'Le montant du salaire doit être un nombre valide',
        );
        return;
      }

      final result = await _contractService.createContract(
        employeeId: selectedEmployeeId.value,
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
        probationPeriod: probationPeriod.toString(),
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
      );

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Contrat créé avec succès');
        clearForm();
        loadContracts();
        loadContractStats();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de la création',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la création du contrat: $e');
      print('Erreur createContract: $e');
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
      print('Erreur submitContract: $e');
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
      print('Erreur approveContract: $e');
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
      print('Erreur rejectContract: $e');
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
      print('Erreur terminateContract: $e');
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
      print('Erreur cancelContract: $e');
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
      print('Erreur deleteContract: $e');
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
  void setEmployee(int employeeId) {
    selectedEmployeeId.value = employeeId;
    // Mettre à jour les informations de l'employé
    final employee = employees.firstWhereOrNull((e) => e['id'] == employeeId);
    if (employee != null) {
      employeeNameController.text = employee['name'] ?? '';
      employeeEmailController.text = employee['email'] ?? '';
      employeePhoneController.text = employee['phone'] ?? '';
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

  // Réinitialiser le formulaire
  void clearForm() {
    selectedEmployeeId.value = 0;
    selectedContractTypeForm.value = '';
    selectedPaymentFrequency.value = '';
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
    generateContractNumber();
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
    {'value': 'draft', 'label': 'Brouillon'},
    {'value': 'pending', 'label': 'En attente'},
    {'value': 'active', 'label': 'Actif'},
    {'value': 'expired', 'label': 'Expiré'},
    {'value': 'terminated', 'label': 'Résilié'},
    {'value': 'cancelled', 'label': 'Annulé'},
  ];

  // Obtenir les options d'employés
  List<Map<String, dynamic>> get employeeOptions {
    final options = <Map<String, dynamic>>[];
    for (final emp in employees) {
      options.add({
        'id': emp['id'],
        'name': '${emp['name']} - ${emp['position']}',
      });
    }
    return options;
  }

  // Obtenir les options de type de contrat
  List<Map<String, String>> get contractTypeOptions => [
    {'value': 'permanent', 'label': 'CDI'},
    {'value': 'fixed_term', 'label': 'CDD'},
    {'value': 'temporary', 'label': 'Intérim'},
    {'value': 'internship', 'label': 'Stage'},
    {'value': 'consultant', 'label': 'Consultant'},
  ];

  // Obtenir les options de département
  List<Map<String, String>> get departmentOptions {
    final options = [
      {'value': 'all', 'label': 'Tous'},
    ];
    final departments = [
      'Ressources Humaines',
      'Commercial',
      'Comptabilité',
      'Technique',
      'Support',
      'Direction',
    ];
    for (final dept in departments) {
      options.add({'value': dept, 'label': dept});
    }
    return options;
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
    jobTitleController.text = contract.jobTitle;
    jobDescriptionController.text = contract.jobDescription;
    workLocationController.text = contract.workLocation;
    workScheduleController.text = contract.workSchedule;
    reportingManagerController.text = contract.reportingManager ?? '';
    grossSalaryController.text = contract.grossSalary.toString();
    netSalaryController.text = contract.netSalary.toString();
    weeklyHoursController.text = contract.weeklyHours.toString();
    probationPeriodController.text = contract.probationPeriod.toString();
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
      final probationPeriod = int.tryParse(probationPeriodController.text);

      if (grossSalary == null) {
        Get.snackbar(
          'Erreur',
          'Le montant du salaire doit être un nombre valide',
        );
        return;
      }

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
        probationPeriod: probationPeriod?.toString(),
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
      print('Erreur updateContract: $e');
    }
  }
}
