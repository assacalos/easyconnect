import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/intervention_model.dart';
import 'package:easyconnect/services/intervention_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';

class InterventionController extends GetxController {
  final InterventionService _interventionService = InterventionService();
  final AuthController _authController = Get.find<AuthController>();

  // Variables observables
  final RxList<Intervention> interventions = <Intervention>[].obs;
  final RxList<Intervention> pendingInterventions = <Intervention>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<InterventionStats?> interventionStats = Rx<InterventionStats?>(null);

  // Variables pour le formulaire
  final RxString searchQuery = ''.obs;
  final RxString selectedStatus = 'all'.obs;
  final RxString selectedType = 'all'.obs;
  final RxString selectedPriority = 'all'.obs;
  final Rx<Intervention?> selectedIntervention = Rx<Intervention?>(null);

  // Contrôleurs de formulaire
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController clientNameController = TextEditingController();
  final TextEditingController clientPhoneController = TextEditingController();
  final TextEditingController clientEmailController = TextEditingController();
  final TextEditingController equipmentController = TextEditingController();
  final TextEditingController problemController = TextEditingController();
  final TextEditingController solutionController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController completionNotesController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final TextEditingController estimatedDurationController = TextEditingController();
  final TextEditingController actualDurationController = TextEditingController();

  // Variables de sélection
  final RxString selectedTypeForm = 'external'.obs;
  final RxString selectedPriorityForm = 'medium'.obs;
  final Rx<DateTime?> selectedScheduledDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedEndDate = Rx<DateTime?>(null);
  final RxList<String> selectedAttachments = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadInterventions();
    loadInterventionStats();
    loadPendingInterventions();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    clientNameController.dispose();
    clientPhoneController.dispose();
    clientEmailController.dispose();
    equipmentController.dispose();
    problemController.dispose();
    solutionController.dispose();
    notesController.dispose();
    completionNotesController.dispose();
    costController.dispose();
    estimatedDurationController.dispose();
    actualDurationController.dispose();
    super.onClose();
  }

  // Charger toutes les interventions
  Future<void> loadInterventions() async {
    try {
      isLoading.value = true;
      final loadedInterventions = await _interventionService.getInterventions(
        status: selectedStatus.value == 'all' ? null : selectedStatus.value,
        type: selectedType.value == 'all' ? null : selectedType.value,
        priority: selectedPriority.value == 'all' ? null : selectedPriority.value,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
      );
      interventions.assignAll(loadedInterventions);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les interventions',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Charger les interventions en attente
  Future<void> loadPendingInterventions() async {
    try {
      final pending = await _interventionService.getPendingInterventions();
      pendingInterventions.assignAll(pending);
    } catch (e) {
      print('Erreur lors du chargement des interventions en attente: $e');
    }
  }

  // Charger les statistiques
  Future<void> loadInterventionStats() async {
    try {
      final stats = await _interventionService.getInterventionStats();
      interventionStats.value = stats;
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
    }
  }

  // Créer une intervention
  Future<void> createIntervention() async {
    try {
      isLoading.value = true;

      final intervention = Intervention(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        type: selectedTypeForm.value,
        priority: selectedPriorityForm.value,
        scheduledDate: selectedScheduledDate.value ?? DateTime.now(),
        location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
        clientName: clientNameController.text.trim().isEmpty ? null : clientNameController.text.trim(),
        clientPhone: clientPhoneController.text.trim().isEmpty ? null : clientPhoneController.text.trim(),
        clientEmail: clientEmailController.text.trim().isEmpty ? null : clientEmailController.text.trim(),
        equipment: equipmentController.text.trim().isEmpty ? null : equipmentController.text.trim(),
        problemDescription: problemController.text.trim().isEmpty ? null : problemController.text.trim(),
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        estimatedDuration: double.tryParse(estimatedDurationController.text),
        cost: double.tryParse(costController.text),
        attachments: selectedAttachments.isEmpty ? null : selectedAttachments,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _interventionService.createIntervention(intervention);
      await loadInterventions();
      await loadInterventionStats();

      Get.snackbar(
        'Succès',
        'Intervention créée avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      clearForm();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer l\'intervention',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Mettre à jour une intervention
  Future<void> updateIntervention(Intervention intervention) async {
    try {
      isLoading.value = true;

      final updatedIntervention = Intervention(
        id: intervention.id,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        type: selectedTypeForm.value,
        priority: selectedPriorityForm.value,
        status: intervention.status,
        scheduledDate: selectedScheduledDate.value ?? intervention.scheduledDate,
        startDate: selectedStartDate.value ?? intervention.startDate,
        endDate: selectedEndDate.value ?? intervention.endDate,
        location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
        clientName: clientNameController.text.trim().isEmpty ? null : clientNameController.text.trim(),
        clientPhone: clientPhoneController.text.trim().isEmpty ? null : clientPhoneController.text.trim(),
        clientEmail: clientEmailController.text.trim().isEmpty ? null : clientEmailController.text.trim(),
        equipment: equipmentController.text.trim().isEmpty ? null : equipmentController.text.trim(),
        problemDescription: problemController.text.trim().isEmpty ? null : problemController.text.trim(),
        solution: solutionController.text.trim().isEmpty ? null : solutionController.text.trim(),
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        completionNotes: completionNotesController.text.trim().isEmpty ? null : completionNotesController.text.trim(),
        estimatedDuration: double.tryParse(estimatedDurationController.text),
        actualDuration: double.tryParse(actualDurationController.text),
        cost: double.tryParse(costController.text),
        attachments: selectedAttachments.isEmpty ? null : selectedAttachments,
        createdAt: intervention.createdAt,
        updatedAt: DateTime.now(),
        createdBy: intervention.createdBy,
        approvedBy: intervention.approvedBy,
        approvedAt: intervention.approvedAt,
        rejectionReason: intervention.rejectionReason,
      );

      await _interventionService.updateIntervention(updatedIntervention);
      await loadInterventions();
      await loadInterventionStats();

      Get.snackbar(
        'Succès',
        'Intervention mise à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      clearForm();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour l\'intervention',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Approuver une intervention
  Future<void> approveIntervention(Intervention intervention) async {
    try {
      isLoading.value = true;

      final success = await _interventionService.approveIntervention(
        intervention.id!,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      if (success) {
        await loadInterventions();
        await loadInterventionStats();
        await loadPendingInterventions();

        Get.snackbar(
          'Succès',
          'Intervention approuvée',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de l\'approbation');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'approuver l\'intervention',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Rejeter une intervention
  Future<void> rejectIntervention(Intervention intervention, String reason) async {
    try {
      isLoading.value = true;

      final success = await _interventionService.rejectIntervention(
        intervention.id!,
        reason: reason,
      );

      if (success) {
        await loadInterventions();
        await loadInterventionStats();
        await loadPendingInterventions();

        Get.snackbar(
          'Succès',
          'Intervention rejetée',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors du rejet');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter l\'intervention',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Démarrer une intervention
  Future<void> startIntervention(Intervention intervention) async {
    try {
      isLoading.value = true;

      final success = await _interventionService.startIntervention(
        intervention.id!,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      if (success) {
        await loadInterventions();
        await loadInterventionStats();

        Get.snackbar(
          'Succès',
          'Intervention démarrée',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors du démarrage');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de démarrer l\'intervention',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Terminer une intervention
  Future<void> completeIntervention(Intervention intervention) async {
    try {
      isLoading.value = true;

      final success = await _interventionService.completeIntervention(
        intervention.id!,
        solution: solutionController.text.trim(),
        completionNotes: completionNotesController.text.trim().isEmpty
            ? null
            : completionNotesController.text.trim(),
        actualDuration: double.tryParse(actualDurationController.text),
        cost: double.tryParse(costController.text),
      );

      if (success) {
        await loadInterventions();
        await loadInterventionStats();

        Get.snackbar(
          'Succès',
          'Intervention terminée',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la finalisation');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de terminer l\'intervention',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Supprimer une intervention
  Future<void> deleteIntervention(Intervention intervention) async {
    try {
      isLoading.value = true;

      final success = await _interventionService.deleteIntervention(intervention.id!);
      if (success) {
        interventions.removeWhere((i) => i.id == intervention.id);
        await loadInterventionStats();

        Get.snackbar(
          'Succès',
          'Intervention supprimée avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer l\'intervention',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Remplir le formulaire avec les données d'une intervention
  void fillForm(Intervention intervention) {
    titleController.text = intervention.title;
    descriptionController.text = intervention.description;
    selectedTypeForm.value = intervention.type;
    selectedPriorityForm.value = intervention.priority;
    selectedScheduledDate.value = intervention.scheduledDate;
    selectedStartDate.value = intervention.startDate;
    selectedEndDate.value = intervention.endDate;
    locationController.text = intervention.location ?? '';
    clientNameController.text = intervention.clientName ?? '';
    clientPhoneController.text = intervention.clientPhone ?? '';
    clientEmailController.text = intervention.clientEmail ?? '';
    equipmentController.text = intervention.equipment ?? '';
    problemController.text = intervention.problemDescription ?? '';
    solutionController.text = intervention.solution ?? '';
    notesController.text = intervention.notes ?? '';
    completionNotesController.text = intervention.completionNotes ?? '';
    costController.text = intervention.cost?.toString() ?? '';
    estimatedDurationController.text = intervention.estimatedDuration?.toString() ?? '';
    actualDurationController.text = intervention.actualDuration?.toString() ?? '';
    selectedAttachments.assignAll(intervention.attachments ?? []);
    selectedIntervention.value = intervention;
  }

  // Vider le formulaire
  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    selectedTypeForm.value = 'external';
    selectedPriorityForm.value = 'medium';
    selectedScheduledDate.value = null;
    selectedStartDate.value = null;
    selectedEndDate.value = null;
    locationController.clear();
    clientNameController.clear();
    clientPhoneController.clear();
    clientEmailController.clear();
    equipmentController.clear();
    problemController.clear();
    solutionController.clear();
    notesController.clear();
    completionNotesController.clear();
    costController.clear();
    estimatedDurationController.clear();
    actualDurationController.clear();
    selectedAttachments.clear();
    selectedIntervention.value = null;
  }

  // Rechercher
  void searchInterventions(String query) {
    searchQuery.value = query;
    loadInterventions();
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    selectedStatus.value = status;
    loadInterventions();
  }

  // Filtrer par type
  void filterByType(String type) {
    selectedType.value = type;
    loadInterventions();
  }

  // Filtrer par priorité
  void filterByPriority(String priority) {
    selectedPriority.value = priority;
    loadInterventions();
  }

  // Sélectionner le type
  void selectType(String type) {
    selectedTypeForm.value = type;
  }

  // Sélectionner la priorité
  void selectPriority(String priority) {
    selectedPriorityForm.value = priority;
  }

  // Sélectionner la date programmée
  void selectScheduledDate(DateTime date) {
    selectedScheduledDate.value = date;
  }

  // Sélectionner la date de début
  void selectStartDate(DateTime date) {
    selectedStartDate.value = date;
  }

  // Sélectionner la date de fin
  void selectEndDate(DateTime date) {
    selectedEndDate.value = date;
  }

  // Obtenir les types d'intervention
  List<Map<String, dynamic>> get interventionTypes => [
    {'value': 'external', 'label': 'Externe', 'icon': Icons.location_on, 'color': Colors.blue},
    {'value': 'on_site', 'label': 'Sur place', 'icon': Icons.home, 'color': Colors.green},
  ];

  // Obtenir les priorités
  List<Map<String, dynamic>> get priorities => [
    {'value': 'low', 'label': 'Faible', 'color': Colors.green},
    {'value': 'medium', 'label': 'Moyenne', 'color': Colors.blue},
    {'value': 'high', 'label': 'Élevée', 'color': Colors.orange},
    {'value': 'urgent', 'label': 'Urgente', 'color': Colors.red},
  ];

  // Obtenir les statuts
  List<Map<String, dynamic>> get statuses => [
    {'value': 'pending', 'label': 'En attente', 'color': Colors.orange},
    {'value': 'approved', 'label': 'Approuvée', 'color': Colors.blue},
    {'value': 'in_progress', 'label': 'En cours', 'color': Colors.purple},
    {'value': 'completed', 'label': 'Terminée', 'color': Colors.green},
    {'value': 'rejected', 'label': 'Rejetée', 'color': Colors.red},
  ];

  // Vérifier les permissions
  bool get canManageInterventions {
    final userRole = _authController.userAuth.value?.role;
    return userRole == 1 || userRole == 6; // Admin, Technicien
  }

  bool get canApproveInterventions {
    final userRole = _authController.userAuth.value?.role;
    return userRole == 1 || userRole == 4; // Admin, Patron
  }

  bool get canViewInterventions {
    final userRole = _authController.userAuth.value?.role;
    return userRole != null; // Tous les rôles
  }

  // Obtenir les interventions par statut
  List<Intervention> get interventionsByStatus {
    if (selectedStatus.value == 'all') return interventions;
    return interventions
        .where((intervention) => intervention.status == selectedStatus.value)
        .toList();
  }

  // Obtenir les interventions par type
  List<Intervention> get interventionsByType {
    if (selectedType.value == 'all') return interventions;
    return interventions
        .where((intervention) => intervention.type == selectedType.value)
        .toList();
  }

  // Obtenir les interventions filtrées
  List<Intervention> get filteredInterventions {
    List<Intervention> filtered = interventions;

    if (selectedStatus.value != 'all') {
      filtered = filtered
          .where((intervention) => intervention.status == selectedStatus.value)
          .toList();
    }

    if (selectedType.value != 'all') {
      filtered = filtered
          .where((intervention) => intervention.type == selectedType.value)
          .toList();
    }

    if (selectedPriority.value != 'all') {
      filtered = filtered
          .where((intervention) => intervention.priority == selectedPriority.value)
          .toList();
    }

    if (searchQuery.value.isNotEmpty) {
      filtered = filtered
          .where(
            (intervention) =>
                intervention.title.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ) ||
                intervention.description.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ) ||
                (intervention.clientName?.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ) ?? false),
          )
          .toList();
    }

    return filtered;
  }
}
