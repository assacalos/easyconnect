import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/payment_model.dart';
import 'package:easyconnect/services/payment_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';

class PaymentController extends GetxController {
  final PaymentService _paymentService = PaymentService.to;
  final AuthController _authController = Get.find<AuthController>();

  // Observables pour la liste des paiements
  final RxList<PaymentModel> payments = <PaymentModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedStatus = 'all'.obs;
  final RxString selectedType = 'all'.obs;
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);

  // Observables pour les statistiques
  final Rx<PaymentStats?> paymentStats = Rx<PaymentStats?>(null);

  // Observables pour le formulaire
  final RxBool isCreating = false.obs;
  final RxString paymentType = 'one_time'.obs;
  final Rx<DateTime> paymentDate = DateTime.now().obs;
  final Rx<DateTime?> dueDate = Rx<DateTime?>(null);
  final RxDouble amount = 0.0.obs;
  final RxString paymentMethod = 'bank_transfer'.obs;
  final RxString currency = 'EUR'.obs;
  final RxString selectedClientName = ''.obs;
  final RxString selectedClientEmail = ''.obs;
  final RxString selectedClientAddress = ''.obs;
  final RxInt selectedClientId = 0.obs;

  // Contrôleurs de texte
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();
  final TextEditingController clientNameController = TextEditingController();
  final TextEditingController clientEmailController = TextEditingController();
  final TextEditingController clientAddressController = TextEditingController();

  // Pour les paiements mensuels
  final Rx<DateTime> scheduleStartDate = DateTime.now().obs;
  final Rx<DateTime> scheduleEndDate =
      DateTime.now().add(const Duration(days: 365)).obs;
  final RxInt frequency = 30.obs; // Jours entre les paiements
  final RxInt totalInstallments = 12.obs;
  final RxDouble installmentAmount = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadPayments();
    loadPaymentStats();
  }

  // Charger les paiements
  Future<void> loadPayments() async {
    try {
      isLoading.value = true;

      final user = _authController.userAuth.value;
      if (user == null) return;

      List<PaymentModel> paymentList;

      if (user.role == 1) {
        // Patron
        paymentList = await _paymentService.getAllPayments(
          startDate: startDate.value,
          endDate: endDate.value,
          status: selectedStatus.value != 'all' ? selectedStatus.value : null,
          type: selectedType.value != 'all' ? selectedType.value : null,
        );
      } else {
        // Comptable
        paymentList = await _paymentService.getComptablePayments(
          comptableId: user.id!,
          startDate: startDate.value,
          endDate: endDate.value,
          status: selectedStatus.value != 'all' ? selectedStatus.value : null,
          type: selectedType.value != 'all' ? selectedType.value : null,
        );
      }

      // Filtrer par recherche
      if (searchQuery.value.isNotEmpty) {
        paymentList =
            paymentList
                .where(
                  (payment) =>
                      payment.paymentNumber.toLowerCase().contains(
                        searchQuery.value.toLowerCase(),
                      ) ||
                      payment.clientName.toLowerCase().contains(
                        searchQuery.value.toLowerCase(),
                      ),
                )
                .toList();
      }

      payments.value = paymentList;
    } catch (e) {
      print('Erreur lors du chargement des paiements: $e');
      Get.snackbar('Erreur', 'Erreur lors du chargement des paiements');
    } finally {
      isLoading.value = false;
    }
  }

  // Charger les statistiques
  Future<void> loadPaymentStats() async {
    try {
      final stats = await _paymentService.getPaymentStats(
        startDate: startDate.value,
        endDate: endDate.value,
        type: selectedType.value != 'all' ? selectedType.value : null,
      );
      paymentStats.value = stats;
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
    }
  }

  // Créer un paiement
  Future<void> createPayment() async {
    try {
      isCreating.value = true;

      final user = _authController.userAuth.value;
      if (user == null) return;

      // Calculer le montant des échéances pour les paiements mensuels
      if (paymentType.value == 'monthly') {
        installmentAmount.value = amount.value / totalInstallments.value;
      }

      PaymentSchedule? schedule;
      if (paymentType.value == 'monthly') {
        schedule = PaymentSchedule(
          id: 0, // Sera généré par le serveur
          startDate: scheduleStartDate.value,
          endDate: scheduleEndDate.value,
          frequency: frequency.value,
          totalInstallments: totalInstallments.value,
          paidInstallments: 0,
          installmentAmount: installmentAmount.value,
          status: 'active',
          nextPaymentDate: scheduleStartDate.value,
          installments: [],
        );
      }

      final result = await _paymentService.createPayment(
        clientId: selectedClientId.value,
        clientName: selectedClientName.value,
        clientEmail: selectedClientEmail.value,
        clientAddress: selectedClientAddress.value,
        comptableId: user.id!,
        comptableName: user.nom ?? 'Comptable',
        type: paymentType.value,
        paymentDate: paymentDate.value,
        dueDate: dueDate.value,
        amount: amount.value,
        paymentMethod: paymentMethod.value,
        description:
            descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
        reference:
            referenceController.text.trim().isEmpty
                ? null
                : referenceController.text.trim(),
        schedule: schedule,
      );

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Paiement créé avec succès');

        // Recharger les paiements
        await loadPayments();

        // Réinitialiser le formulaire
        resetForm();

        // Retourner à la liste
        Get.back();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de la création',
        );
      }
    } catch (e) {
      print('Erreur lors de la création du paiement: $e');
      Get.snackbar('Erreur', 'Erreur lors de la création du paiement');
    } finally {
      isCreating.value = false;
    }
  }

  // Soumettre un paiement au patron
  Future<void> submitPaymentToPatron(int paymentId) async {
    try {
      final result = await _paymentService.submitPaymentToPatron(paymentId);

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Paiement soumis au patron');
        await loadPayments();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de la soumission',
        );
      }
    } catch (e) {
      print('Erreur lors de la soumission du paiement: $e');
      Get.snackbar('Erreur', 'Erreur lors de la soumission du paiement');
    }
  }

  // Approuver un paiement
  Future<void> approvePayment(int paymentId, {String? comments}) async {
    try {
      final result = await _paymentService.approvePayment(
        paymentId,
        comments: comments,
      );

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Paiement approuvé');
        await loadPayments();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de l\'approbation',
        );
      }
    } catch (e) {
      print('Erreur lors de l\'approbation du paiement: $e');
      Get.snackbar('Erreur', 'Erreur lors de l\'approbation du paiement');
    }
  }

  // Rejeter un paiement
  Future<void> rejectPayment(int paymentId, {required String reason}) async {
    try {
      final result = await _paymentService.rejectPayment(
        paymentId,
        reason: reason,
      );

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Paiement rejeté');
        await loadPayments();
      } else {
        Get.snackbar('Erreur', result['message'] ?? 'Erreur lors du rejet');
      }
    } catch (e) {
      print('Erreur lors du rejet du paiement: $e');
      Get.snackbar('Erreur', 'Erreur lors du rejet du paiement');
    }
  }

  // Marquer comme payé
  Future<void> markAsPaid(
    int paymentId, {
    String? paymentReference,
    String? notes,
  }) async {
    try {
      final result = await _paymentService.markAsPaid(
        paymentId,
        paymentReference: paymentReference,
        notes: notes,
      );

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Paiement marqué comme payé');
        await loadPayments();
      } else {
        Get.snackbar('Erreur', result['message'] ?? 'Erreur lors du marquage');
      }
    } catch (e) {
      print('Erreur lors du marquage du paiement: $e');
      Get.snackbar('Erreur', 'Erreur lors du marquage du paiement');
    }
  }

  // Supprimer un paiement
  Future<void> deletePayment(int paymentId) async {
    try {
      final result = await _paymentService.deletePayment(paymentId);

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Paiement supprimé');
        await loadPayments();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de la suppression',
        );
      }
    } catch (e) {
      print('Erreur lors de la suppression du paiement: $e');
      Get.snackbar('Erreur', 'Erreur lors de la suppression du paiement');
    }
  }

  // Pause/Reprendre un paiement mensuel
  Future<void> togglePaymentSchedule(
    int paymentId, {
    required String action,
    String? reason,
  }) async {
    try {
      final result = await _paymentService.togglePaymentSchedule(
        paymentId,
        action: action,
        reason: reason,
      );

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Planning modifié');
        await loadPayments();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de la modification',
        );
      }
    } catch (e) {
      print('Erreur lors de la modification du planning: $e');
      Get.snackbar('Erreur', 'Erreur lors de la modification du planning');
    }
  }

  // Réinitialiser le formulaire
  void resetForm() {
    paymentType.value = 'one_time';
    paymentDate.value = DateTime.now();
    dueDate.value = null;
    amount.value = 0.0;
    paymentMethod.value = 'bank_transfer';
    selectedClientName.value = '';
    selectedClientEmail.value = '';
    selectedClientAddress.value = '';
    selectedClientId.value = 0;

    descriptionController.clear();
    notesController.clear();
    referenceController.clear();
    clientNameController.clear();
    clientEmailController.clear();
    clientAddressController.clear();

    scheduleStartDate.value = DateTime.now();
    scheduleEndDate.value = DateTime.now().add(const Duration(days: 365));
    frequency.value = 30;
    totalInstallments.value = 12;
    installmentAmount.value = 0.0;
  }

  // Sélectionner un client
  void selectClient({
    required int clientId,
    required String clientName,
    required String clientEmail,
    required String clientAddress,
  }) {
    selectedClientId.value = clientId;
    selectedClientName.value = clientName;
    selectedClientEmail.value = clientEmail;
    selectedClientAddress.value = clientAddress;

    clientNameController.text = clientName;
    clientEmailController.text = clientEmail;
    clientAddressController.text = clientAddress;
  }

  // Obtenir la couleur du statut
  Color getPaymentStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'submitted':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Obtenir le nom du statut
  String getPaymentStatusName(String status) {
    switch (status) {
      case 'draft':
        return 'Brouillon';
      case 'submitted':
        return 'Soumis';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      case 'paid':
        return 'Payé';
      case 'overdue':
        return 'En retard';
      default:
        return status;
    }
  }

  // Obtenir le nom du type
  String getPaymentTypeName(String type) {
    switch (type) {
      case 'one_time':
        return 'Ponctuel';
      case 'monthly':
        return 'Mensuel';
      default:
        return type;
    }
  }

  // Obtenir le nom de la méthode de paiement
  String getPaymentMethodName(String method) {
    switch (method) {
      case 'bank_transfer':
        return 'Virement bancaire';
      case 'check':
        return 'Chèque';
      case 'cash':
        return 'Espèces';
      case 'card':
        return 'Carte bancaire';
      case 'direct_debit':
        return 'Prélèvement';
      default:
        return method;
    }
  }

  // Vérifier si l'utilisateur peut approuver
  bool get canApprovePayments {
    final user = _authController.userAuth.value;
    return user?.role == 1; // Patron
  }

  // Vérifier si l'utilisateur peut soumettre
  bool get canSubmitPayments {
    final user = _authController.userAuth.value;
    return user?.role == 3; // Comptable
  }

  @override
  void onClose() {
    descriptionController.dispose();
    notesController.dispose();
    referenceController.dispose();
    clientNameController.dispose();
    clientEmailController.dispose();
    clientAddressController.dispose();
    super.onClose();
  }
}
