import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/payment_model.dart';
import 'package:easyconnect/services/payment_service.dart';
import 'package:easyconnect/services/pdf_service.dart';
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
    loadPayments();
    loadPaymentStats();
  }

  // Charger les paiements
  Future<void> loadPayments() async {
    try {
      print('🔵 [PAYMENT_CONTROLLER] loadPayments() appelé');
      print('🔵 [PAYMENT_CONTROLLER] selectedStatus: ${selectedStatus.value}');
      isLoading.value = true;

      final user = _authController.userAuth.value;
      if (user == null) {
        print('🔵 [PAYMENT_CONTROLLER] ⚠️ Utilisateur null');
        Get.snackbar(
          'Erreur',
          'Utilisateur non connecté',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      print('🔵 [PAYMENT_CONTROLLER] Rôle utilisateur: ${user.role}');
      // Chargement direct des paiements (test de connectivité supprimé car non nécessaire)
      List<PaymentModel> paymentList;

      // Patron (role 6) ou Admin (role 1) peuvent voir tous les paiements
      if (user.role == 1 || user.role == 6) {
        // Patron ou Admin
        print('🔵 [PAYMENT_CONTROLLER] Appel getAllPayments pour Patron/Admin');
        paymentList = await _paymentService.getAllPayments(
          startDate: startDate.value,
          endDate: endDate.value,
          status: selectedStatus.value != 'all' ? selectedStatus.value : null,
          type: selectedType.value != 'all' ? selectedType.value : null,
        );
      } else {
        // Comptable ou autre rôle
        print(
          '🔵 [PAYMENT_CONTROLLER] Appel getComptablePayments pour Comptable',
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
        '🔵 [PAYMENT_CONTROLLER] ✅ ${paymentList.length} paiements chargés',
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
        // Ne pas afficher de snackbar automatiquement pour éviter le spam
      } else {
        // Ne pas afficher de snackbar automatiquement pour éviter le spam
      }
    } catch (e) {
      // Ne pas vider la liste si elle contient déjà des paiements
      // (ils peuvent s'être chargés avant l'erreur)
      if (payments.isEmpty) {
        payments.value = [];
      }

      // Ne pas afficher de message d'erreur automatique
      // Les paiements peuvent se charger malgré certaines erreurs
      // Les erreurs sont loggées pour le débogage
    } finally {
      isLoading.value = false;
    }
  }

  // Tester la connectivité à l'API pour les paiements
  Future<bool> testPaymentConnection() async {
    try {
      return await _paymentService.testPaymentConnection();
    } catch (e) {
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
    } catch (e) {}
  }

  // Créer un paiement
  Future<void> createPayment() async {
    try {
      isCreating.value = true;

      final user = _authController.userAuth.value;
      if (user == null) {
        Get.snackbar(
          'Erreur',
          'Utilisateur non connecté',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Validation des champs requis
      if (selectedClientId.value == 0 &&
          (selectedClientName.value.isEmpty ||
              selectedClientEmail.value.isEmpty ||
              selectedClientAddress.value.isEmpty)) {
        Get.snackbar(
          'Erreur de validation',
          'Veuillez sélectionner un client ou remplir les informations client',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      if (amount.value <= 0) {
        Get.snackbar(
          'Erreur de validation',
          'Veuillez saisir un montant valide',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }
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
        clientId:
            selectedClientId.value > 0
                ? selectedClientId.value
                : 0, // Si pas de clientId, utiliser 0 et laisser le backend gérer
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
      if (result['success'] == true || result['success'] == 1) {
        Get.snackbar(
          'Succès',
          'Paiement créé avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Recharger les paiements
        await Future.delayed(const Duration(milliseconds: 500));
        await loadPayments();

        // Réinitialiser le formulaire
        resetForm();

        // Retourner à la liste
        if (Navigator.canPop(Get.context!)) {
          Get.back();
        }
      } else {
        final errorMessage =
            result['message'] ??
            result['error'] ??
            'Erreur lors de la création';
        Get.snackbar(
          'Erreur',
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la création du paiement: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
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
    final statusLower = status.toLowerCase().trim();
    switch (statusLower) {
      case 'draft':
      case 'drafts': // Gérer le pluriel
        return Colors.grey;
      case 'submitted':
      case 'soumis':
        return Colors.orange;
      case 'approved':
      case 'approuve':
      case 'approuvé':
      case 'valide':
        return Colors.blue;
      case 'rejected':
      case 'rejete':
      case 'rejeté':
        return Colors.red;
      case 'paid':
      case 'paye':
      case 'payé':
        return Colors.green;
      case 'overdue':
      case 'en_retard':
        return Colors.red;
      case 'pending':
      case 'en_attente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Obtenir le nom du statut
  String getPaymentStatusName(String status) {
    final statusLower = status.toLowerCase().trim();
    switch (statusLower) {
      case 'draft':
      case 'drafts': // Gérer le pluriel
        return 'Brouillon';
      case 'submitted':
      case 'soumis':
        return 'Soumis';
      case 'approved':
      case 'approuve':
      case 'approuvé':
      case 'valide':
        return 'Approuvé';
      case 'rejected':
      case 'rejete':
      case 'rejeté':
        return 'Rejeté';
      case 'paid':
      case 'paye':
      case 'payé':
        return 'Payé';
      case 'overdue':
      case 'en_retard':
        return 'En retard';
      case 'pending':
      case 'en_attente':
        return 'En attente';
      default:
        // Si le statut n'est pas reconnu, essayer de le formater
        return status
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) {
              if (word.isEmpty) return '';
              return word[0].toUpperCase() + word.substring(1).toLowerCase();
            })
            .join(' ');
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
    return user?.role == 1 || user?.role == 6; // Patron ou Admin
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
    return pendingPayments;
  }

  List<PaymentModel> getApprovedPayments() {
    final approvedPayments =
        payments.where((payment) => payment.isApproved).toList();
    return approvedPayments;
  }

  List<PaymentModel> getRejectedPayments() {
    final rejectedPayments =
        payments.where((payment) => payment.isRejected).toList();
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
      print(
        '🔵 [PAYMENT_CONTROLLER] approvePayment() appelé pour paymentId: $paymentId',
      );
      isLoading.value = true;

      final result = await _paymentService.approvePayment(
        paymentId,
        comments: comments,
      );
      print('🔵 [PAYMENT_CONTROLLER] Résultat approvePayment: $result');

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
    } catch (e, stackTrace) {
      print('❌ [PAYMENT_CONTROLLER] Erreur approvePayment: $e');
      print('❌ [PAYMENT_CONTROLLER] Stack trace: $stackTrace');
      Get.snackbar(
        'Erreur',
        'Impossible d\'approuver le paiement: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectPayment(int paymentId, {required String reason}) async {
    try {
      print(
        '🔵 [PAYMENT_CONTROLLER] rejectPayment() appelé pour paymentId: $paymentId',
      );
      isLoading.value = true;

      final result = await _paymentService.rejectPayment(
        paymentId,
        reason: reason,
      );
      print('🔵 [PAYMENT_CONTROLLER] Résultat rejectPayment: $result');

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
    } catch (e, stackTrace) {
      print('❌ [PAYMENT_CONTROLLER] Erreur rejectPayment: $e');
      print('❌ [PAYMENT_CONTROLLER] Stack trace: $stackTrace');
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter le paiement: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reactivatePayment(int paymentId) async {
    try {
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

  /// Générer un PDF pour un paiement
  Future<void> generatePDF(int paymentId) async {
    try {
      isLoading.value = true;

      // Trouver le paiement
      final payment = payments.firstWhere((p) => p.id == paymentId);

      // Générer le PDF
      await PdfService().generatePaiementPdf(
        paiement: {
          'reference': payment.reference,
          'montant': payment.amount,
          'mode_paiement': payment.paymentMethod,
          'date_paiement': payment.paymentDate,
        },
        facture: {'reference': payment.paymentNumber},
        client: {
          'nom': payment.clientName,
          'prenom': '',
          'nom_entreprise': payment.clientName,
          'email': payment.clientEmail,
          'contact': '',
          'adresse': payment.clientAddress,
        },
      );

      Get.snackbar(
        'Succès',
        'PDF généré avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la génération du PDF: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
