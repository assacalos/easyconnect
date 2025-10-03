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

  // Filtres par statut d'approbation
  final RxString selectedApprovalStatus = 'all'.obs;
  final RxList<String> approvalStatuses =
      <String>['all', 'pending', 'approved', 'rejected'].obs;

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
    print('🔄 PaymentController: onInit() appelé');
    print(
      '📊 PaymentController: Nombre de paiements avant chargement: ${payments.length}',
    );
    loadPayments();
    loadPaymentStats();
    print(
      '📊 PaymentController: Nombre de paiements après chargement: ${payments.length}',
    );
  }

  // Charger les paiements
  Future<void> loadPayments() async {
    print('🔄 PaymentController: loadPayments() appelé');
    try {
      isLoading.value = true;
      print('⏳ PaymentController: Chargement en cours...');

      final user = _authController.userAuth.value;
      if (user == null) {
        print('❌ PaymentController: Utilisateur non connecté');
        Get.snackbar(
          'Erreur',
          'Utilisateur non connecté',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      print(
        '👤 PaymentController: Utilisateur connecté - Role: ${user.role}, ID: ${user.id}',
      );

      // Tester la connectivité d'abord
      print('🧪 PaymentController: Test de connectivité...');
      final isConnected = await _paymentService.testPaymentConnection();
      if (!isConnected) {
        throw Exception('Impossible de se connecter à l\'API Laravel');
      }

      List<PaymentModel> paymentList;

      if (user.role == 1) {
        // Patron
        print('👑 PaymentController: Chargement des paiements pour le patron');
        paymentList = await _paymentService.getAllPayments(
          startDate: startDate.value,
          endDate: endDate.value,
          status: selectedStatus.value != 'all' ? selectedStatus.value : null,
          type: selectedType.value != 'all' ? selectedType.value : null,
        );
      } else {
        // Comptable
        print(
          '💰 PaymentController: Chargement des paiements pour le comptable',
        );
        paymentList = await _paymentService.getComptablePayments(
          comptableId: user.id,
          startDate: startDate.value,
          endDate: endDate.value,
          status: selectedStatus.value != 'all' ? selectedStatus.value : null,
          type: selectedType.value != 'all' ? selectedType.value : null,
        );
      }

      print(
        '📦 PaymentController: ${paymentList.length} paiements reçus du service',
      );

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

      // Afficher un message de succès si des paiements sont trouvés
      if (paymentList.isNotEmpty) {
        print(
          '✅ PaymentController: ${paymentList.length} paiements chargés avec succès',
        );
        Get.snackbar(
          'Succès',
          '${paymentList.length} paiements chargés avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        print(
          '⚠️ PaymentController: Aucun paiement trouvé dans la base de données',
        );
        Get.snackbar(
          'Information',
          'Aucun paiement trouvé dans la base de données',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('❌ PaymentController: Erreur lors du chargement: $e');

      // Vider la liste des paiements en cas d'erreur
      payments.value = [];

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
          e.toString().contains('Unexpected end of input') ||
          e.toString().contains('Unexpected character')) {
        errorMessage =
            'Erreur de format des données. Contactez l\'administrateur.';
      } else if (e.toString().contains('Null') ||
          e.toString().contains('not a subtype')) {
        errorMessage =
            'Erreur de format des données. Contactez l\'administrateur.';
      } else if (e.toString().contains('Erreur de format des données')) {
        errorMessage =
            'Données corrompues reçues du serveur. Veuillez réessayer.';
      } else {
        errorMessage = 'Erreur lors du chargement des paiements: $e';
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
      print('🏁 PaymentController: Chargement terminé');
    }
  }

  // Tester la connectivité à l'API pour les paiements
  Future<bool> testPaymentConnection() async {
    try {
      print('🧪 PaymentController: Test de connectivité API...');
      return await _paymentService.testPaymentConnection();
    } catch (e) {
      print('❌ PaymentController: Erreur de test de connectivité: $e');
      return false;
    }
  }

  // Charger les statistiques
  Future<void> loadPaymentStats() async {
    try {
      final statsData = await _paymentService.getPaymentStats(
        startDate: startDate.value,
        endDate: endDate.value,
        type: selectedType.value != 'all' ? selectedType.value : null,
      );
      // Convertir Map en PaymentStats si nécessaire
      paymentStats.value = PaymentStats.fromJson(statsData);
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
        comptableId: user.id,
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

  // Méthodes de filtrage par statut d'approbation
  void setApprovalStatusFilter(String approvalStatus) {
    selectedApprovalStatus.value = approvalStatus;
    loadPayments();
  }

  List<PaymentModel> getPendingPayments() {
    final pendingPayments =
        payments.where((payment) => payment.isPending).toList();
    print(
      '📊 PaymentController: getPendingPayments() - ${pendingPayments.length} paiements en attente',
    );
    return pendingPayments;
  }

  List<PaymentModel> getApprovedPayments() {
    final approvedPayments =
        payments.where((payment) => payment.isApproved).toList();
    print(
      '📊 PaymentController: getApprovedPayments() - ${approvedPayments.length} paiements approuvés',
    );
    return approvedPayments;
  }

  List<PaymentModel> getRejectedPayments() {
    final rejectedPayments =
        payments.where((payment) => payment.isRejected).toList();
    print(
      '📊 PaymentController: getRejectedPayments() - ${rejectedPayments.length} paiements rejetés',
    );
    return rejectedPayments;
  }

  List<PaymentModel> getPaymentsByApprovalStatus(String status) {
    switch (status) {
      case 'pending':
        return getPendingPayments();
      case 'approved':
        return getApprovedPayments();
      case 'rejected':
        return getRejectedPayments();
      default:
        return payments;
    }
  }

  // Méthodes pour gérer l'approbation des paiements
  Future<void> approvePayment(int paymentId, {String? comments}) async {
    try {
      print('✅ PaymentController: Approbation du paiement $paymentId');

      await _paymentService.approvePayment(paymentId, comments: comments);

      // Recharger les paiements
      await loadPayments();

      Get.snackbar(
        'Succès',
        'Paiement approuvé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ PaymentController: Erreur lors de l\'approbation: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'approuver le paiement: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> rejectPayment(int paymentId, {required String reason}) async {
    try {
      print('❌ PaymentController: Rejet du paiement $paymentId');

      await _paymentService.rejectPayment(paymentId, reason: reason);

      // Recharger les paiements
      await loadPayments();

      Get.snackbar(
        'Succès',
        'Paiement rejeté avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ PaymentController: Erreur lors du rejet: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter le paiement: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> reactivatePayment(int paymentId) async {
    try {
      print('🔄 PaymentController: Réactivation du paiement $paymentId');

      await _paymentService.reactivatePayment(paymentId);

      // Recharger les paiements
      await loadPayments();

      Get.snackbar(
        'Succès',
        'Paiement réactivé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ PaymentController: Erreur lors de la réactivation: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de réactiver le paiement: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
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
