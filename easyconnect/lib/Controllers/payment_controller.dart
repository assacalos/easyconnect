import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/payment_model.dart';
import 'package:easyconnect/services/payment_service.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/reference_generator.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';

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
  String?
  _currentApprovalStatusFilter; // Mémoriser le filtre de statut d'approbation actuel

  // Observables pour les statistiques
  final Rx<PaymentStats?> paymentStats = Rx<PaymentStats?>(null);

  // Métadonnées de pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPreviousPage = false.obs;
  final RxInt perPage = 15.obs;

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

  // Référence générée automatiquement
  final generatedReference = ''.obs;

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
    // Générer automatiquement la référence au démarrage
    initializeGeneratedReference();
  }

  // Générer automatiquement la référence de paiement
  Future<String> generatePaymentReference() async {
    // Recharger les paiements pour avoir le comptage à jour
    await loadPayments();

    // Extraire toutes les références existantes
    final existingReferences =
        payments
            .map((pay) => pay.reference)
            .where((ref) => ref != null && ref.isNotEmpty)
            .map((ref) => ref!)
            .toList();

    // Générer avec incrément
    return ReferenceGenerator.generateReferenceWithIncrement(
      'PAY',
      existingReferences,
    );
  }

  // Initialiser la référence générée
  Future<void> initializeGeneratedReference() async {
    if (generatedReference.value.isEmpty) {
      generatedReference.value = await generatePaymentReference();
      referenceController.text = generatedReference.value;
    }
  }

  // Charger les paiements
  Future<void> loadPayments({
    String? approvalStatusFilter,
    int page = 1,
  }) async {
    try {
      _currentApprovalStatusFilter =
          approvalStatusFilter ??
          (selectedApprovalStatus.value == 'all'
              ? null
              : selectedApprovalStatus.value);

      final user = _authController.userAuth.value;
      if (user == null) {
        Get.snackbar(
          'Erreur',
          'Utilisateur non connecté',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Afficher immédiatement les données du cache si disponibles (seulement page 1)
      final cacheKey =
          'payments_${user.role}_${_currentApprovalStatusFilter ?? 'all'}';
      final cachedPayments = CacheHelper.get<List<PaymentModel>>(cacheKey);
      if (cachedPayments != null && cachedPayments.isNotEmpty && page == 1) {
        payments.assignAll(cachedPayments);
        isLoading.value = false; // Permettre l'affichage immédiat
      } else {
        isLoading.value = true;
      }

      try {
        // Utiliser la méthode paginée
        final paginatedResponse =
            (user.role == 1 || user.role == 6)
                ? await _paymentService.getAllPaymentsPaginated(
                  startDate: startDate.value,
                  endDate: endDate.value,
                  status: null,
                  type: null,
                  page: page,
                  perPage: perPage.value,
                  search:
                      searchQuery.value.isNotEmpty ? searchQuery.value : null,
                )
                : await _paymentService.getComptablePaymentsPaginated(
                  comptableId: user.id,
                  startDate: startDate.value,
                  endDate: endDate.value,
                  status:
                      selectedStatus.value != 'all'
                          ? selectedStatus.value
                          : null,
                  type: selectedType.value != 'all' ? selectedType.value : null,
                  page: page,
                  perPage: perPage.value,
                  search:
                      searchQuery.value.isNotEmpty ? searchQuery.value : null,
                );

        // Mettre à jour les métadonnées de pagination
        totalPages.value = paginatedResponse.meta.lastPage;
        totalItems.value = paginatedResponse.meta.total;
        hasNextPage.value = paginatedResponse.hasNextPage;
        hasPreviousPage.value = paginatedResponse.hasPreviousPage;
        currentPage.value = paginatedResponse.meta.currentPage;

        // Mettre à jour la liste
        if (page == 1) {
          payments.value = paginatedResponse.data;
        } else {
          // Pour les pages suivantes, ajouter les données
          payments.addAll(paginatedResponse.data);
        }

        // Sauvegarder dans le cache (seulement pour la page 1)
        if (page == 1) {
          CacheHelper.set(cacheKey, paginatedResponse.data);
        }

        print(
          '🔵 [PAYMENT_CONTROLLER] ✅ ${paginatedResponse.data.length} paiements chargés (Page $page/${paginatedResponse.meta.lastPage})',
        );
      } catch (e) {
        // Si le chargement échoue mais qu'on a du cache, on garde le cache
        if (cachedPayments == null || cachedPayments.isEmpty || page > 1) {
          if (payments.isEmpty) {
            // Vérifier une dernière fois le cache avant de vider la liste
            final cacheKey =
                'payments_${user.role}_${_currentApprovalStatusFilter ?? 'all'}';
            final cachedPayments = CacheHelper.get<List<PaymentModel>>(
              cacheKey,
            );
            if (cachedPayments != null && cachedPayments.isNotEmpty) {
              payments.assignAll(cachedPayments);
              return; // Ne pas afficher d'erreur si on a du cache
            }
          }
          rethrow; // Relancer l'erreur seulement si on n'avait pas de cache
        }
      }
    } catch (e) {
      // Ne pas vider la liste si elle contient déjà des paiements
      // (ils peuvent s'être chargés avant l'erreur)
      if (payments.isEmpty) {
        // Vérifier une dernière fois le cache avant de vider la liste
        final user = _authController.userAuth.value;
        if (user != null) {
          final cacheKey =
              'payments_${user.role}_${_currentApprovalStatusFilter ?? 'all'}';
          final cachedPayments = CacheHelper.get<List<PaymentModel>>(cacheKey);
          if (cachedPayments != null && cachedPayments.isNotEmpty) {
            // Charger les données du cache si disponibles
            payments.assignAll(cachedPayments);
          } else {
            payments.value = [];
          }
        } else {
          payments.value = [];
        }
      }

      // Ne pas afficher de message d'erreur automatique si des données sont disponibles
      // Ne pas afficher d'erreur pour les erreurs d'authentification (déjà gérées)
      final errorString = e.toString().toLowerCase();
      if (payments.isEmpty &&
          !errorString.contains('session expirée') &&
          !errorString.contains('401') &&
          !errorString.contains('unauthorized')) {
        // Les erreurs sont loggées pour le débogage mais pas affichées si des données sont disponibles
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Charger la page suivante
  void loadNextPage() {
    if (hasNextPage.value && !isLoading.value) {
      loadPayments(page: currentPage.value + 1);
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage.value && !isLoading.value) {
      loadPayments(page: currentPage.value - 1);
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
  Future<bool> createPayment() async {
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
        return false;
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
        return false;
      }

      if (amount.value <= 0) {
        Get.snackbar(
          'Erreur de validation',
          'Veuillez saisir un montant valide',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }
      // Validation et calcul pour les paiements mensuels
      if (paymentType.value == 'monthly') {
        // Validation des champs requis pour les paiements mensuels
        if (totalInstallments.value <= 0) {
          Get.snackbar(
            'Erreur de validation',
            'Le nombre d\'échéances doit être supérieur à 0',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          return false;
        }

        if (frequency.value <= 0) {
          Get.snackbar(
            'Erreur de validation',
            'La fréquence doit être supérieure à 0',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          return false;
        }

        if (scheduleEndDate.value.isBefore(scheduleStartDate.value)) {
          Get.snackbar(
            'Erreur de validation',
            'La date de fin doit être postérieure à la date de début',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          return false;
        }

        // Calculer le montant des échéances
        installmentAmount.value = amount.value / totalInstallments.value;

        if (installmentAmount.value <= 0) {
          Get.snackbar(
            'Erreur de validation',
            'Le montant par échéance doit être supérieur à 0',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          return false;
        }
      }

      PaymentSchedule? schedule;
      if (paymentType.value == 'monthly') {
        // Normaliser les dates à minuit avant de créer le schedule
        final normalizedStartDate = DateTime(
          scheduleStartDate.value.year,
          scheduleStartDate.value.month,
          scheduleStartDate.value.day,
        );
        final normalizedEndDate = DateTime(
          scheduleEndDate.value.year,
          scheduleEndDate.value.month,
          scheduleEndDate.value.day,
        );

        // Mettre à jour les dates normalisées dans les observables
        scheduleStartDate.value = normalizedStartDate;
        scheduleEndDate.value = normalizedEndDate;

        schedule = PaymentSchedule(
          id: 0, // Sera généré par le serveur
          startDate: normalizedStartDate,
          endDate: normalizedEndDate,
          frequency: frequency.value,
          totalInstallments: totalInstallments.value,
          paidInstallments: 0,
          installmentAmount: installmentAmount.value,
          status: 'active',
          nextPaymentDate: normalizedStartDate,
          installments: [],
        );

        // Logger les données du schedule pour le débogage
        print('📋 [PAYMENT_CONTROLLER] Schedule créé:');
        print('   - Start Date: ${normalizedStartDate.toIso8601String()}');
        print('   - End Date: ${normalizedEndDate.toIso8601String()}');
        print('   - Frequency: ${frequency.value} jours');
        print('   - Total Installments: ${totalInstallments.value}');
        print('   - Installment Amount: ${installmentAmount.value}');
        print('   - Amount: ${amount.value}');
        print(
          '   - Calcul: ${amount.value} / ${totalInstallments.value} = ${installmentAmount.value}',
        );

        // Vérification supplémentaire
        if (installmentAmount.value.isNaN ||
            installmentAmount.value.isInfinite) {
          throw Exception(
            'Le montant par échéance est invalide. Vérifiez le montant total et le nombre d\'échéances.',
          );
        }
      }

      // Pour les paiements ponctuels, toujours régénérer la référence juste avant l'envoi
      // pour éviter les doublons. Pour les paiements mensuels, garder la référence existante.
      if (paymentType.value == 'one_time') {
        // Toujours régénérer pour les paiements ponctuels pour garantir l'unicité
        generatedReference.value = await generatePaymentReference();
        referenceController.text = generatedReference.value;
      } else if (generatedReference.value.isEmpty ||
          (referenceController.text.trim().isEmpty &&
              generatedReference.value.isNotEmpty)) {
        // Pour les paiements mensuels, ne régénérer que si nécessaire
        generatedReference.value = await generatePaymentReference();
        referenceController.text = generatedReference.value;
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
            generatedReference.value.isNotEmpty
                ? generatedReference.value
                : (referenceController.text.trim().isEmpty
                    ? null
                    : referenceController.text.trim()),
        schedule: schedule,
      );
      if (result['success'] == true || result['success'] == 1) {
        // Invalider le cache
        CacheHelper.clearByPrefix('payments_');
        CacheHelper.clearByPrefix('dashboard_comptable_pendingPaiements');

        // Rafraîchir les compteurs des dashboards
        DashboardRefreshHelper.refreshPatronCounter('payment');
        DashboardRefreshHelper.refreshComptablePending('paiement');

        // Notifier le patron de la soumission
        if (result['data'] != null) {
          try {
            final paymentData = result['data'];
            // Extraire l'ID de manière sécurisée
            String paymentIdStr = '';
            if (paymentData is Map) {
              paymentIdStr = paymentData['id']?.toString() ?? '';
            } else {
              try {
                paymentIdStr = paymentData.id?.toString() ?? '';
              } catch (e) {
                paymentIdStr = '';
              }
            }

            NotificationHelper.notifySubmission(
              entityType: 'payment',
              entityName: NotificationHelper.getEntityDisplayName(
                'payment',
                paymentData,
              ),
              entityId: paymentIdStr,
              route: NotificationHelper.getEntityRoute('payment', paymentIdStr),
            );
          } catch (e) {
            // Ignorer les erreurs de notification pour ne pas bloquer la création
            print('⚠️ Erreur lors de la notification: $e');
          }
        }

        Get.snackbar(
          'Succès',
          'Paiement créé avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Recharger les paiements de manière asynchrone (sans bloquer)
        loadPayments().catchError((e) {
          // Ignorer les erreurs pour ne pas bloquer la navigation
          print('⚠️ Erreur lors du rechargement des paiements: $e');
        });

        // Réinitialiser le formulaire
        resetForm();
        return true;
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
        return false;
      }
    } catch (e) {
      // Extraire le message d'erreur de manière plus lisible
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      // Détecter les erreurs de référence dupliquée et régénérer automatiquement
      if (errorMessage.contains('Duplicate entry') &&
          errorMessage.contains('reference')) {
        // Régénérer une nouvelle référence
        try {
          generatedReference.value = await generatePaymentReference();
          referenceController.text = generatedReference.value;
          Get.snackbar(
            'Référence régénérée',
            'La référence a été régénérée automatiquement. Veuillez réessayer.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        } catch (regenerateError) {
          // Si la régénération échoue, afficher l'erreur originale
          Get.snackbar(
            'Erreur',
            'Erreur de référence dupliquée. Veuillez réessayer.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
        }
        return false;
      }

      // Détecter les erreurs 500 et afficher un message plus clair
      if (errorMessage.contains('500') ||
          errorMessage.contains('Erreur serveur')) {
        Get.snackbar(
          'Erreur serveur',
          'Une erreur s\'est produite sur le serveur. Veuillez vérifier les données saisies et réessayer.\n'
              'Si le problème persiste, contactez le support technique.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
          maxWidth: 400,
          isDismissible: true,
          shouldIconPulse: true,
        );
      } else {
        Get.snackbar(
          'Erreur',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          maxWidth: 400,
          isDismissible: true,
          shouldIconPulse: true,
        );
      }
      return false;
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
    generatedReference.value = '';
    referenceController.clear();
    clientNameController.clear();
    clientEmailController.clear();
    clientAddressController.clear();

    // Normaliser les dates à minuit
    final now = DateTime.now();
    scheduleStartDate.value = DateTime(now.year, now.month, now.day);
    scheduleEndDate.value = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 365));
    frequency.value = 30;
    totalInstallments.value = 12;
    installmentAmount.value = 0.0;

    // Régénérer une nouvelle référence
    initializeGeneratedReference();
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
      isLoading.value = true;

      // Invalider le cache avant l'appel API
      CacheHelper.clearByPrefix('payments_');

      // Mise à jour optimiste de l'UI - mettre à jour immédiatement
      final paymentIndex = payments.indexWhere((p) => p.id == paymentId);
      if (paymentIndex != -1) {
        // Note: Le modèle PaymentModel a beaucoup de champs
        // Pour une mise à jour complète, il faudrait recharger depuis le serveur
        // La mise à jour optimiste sera effectuée après le rechargement
      }

      final result = await _paymentService.approvePayment(
        paymentId,
        comments: comments,
      );

      // Rafraîchir les compteurs du dashboard patron
      DashboardRefreshHelper.refreshPatronCounter('payment');

      // Notifier l'utilisateur concerné de la validation
      if (result['success'] == true && result['data'] != null) {
        try {
          final paymentData = result['data'];
          NotificationHelper.notifyValidation(
            entityType: 'payment',
            entityName: NotificationHelper.getEntityDisplayName(
              'payment',
              paymentData,
            ),
            entityId: paymentId.toString(),
            route: NotificationHelper.getEntityRoute(
              'payment',
              paymentId.toString(),
            ),
          );
        } catch (e) {
          // Ignorer les erreurs de notification pour ne pas bloquer la validation
          print('⚠️ Erreur lors de la notification: $e');
        }
      }

      Get.snackbar(
        'Succès',
        'Paiement approuvé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Recharger les données en arrière-plan avec le filtre actuel
      // pour synchroniser avec le serveur (mais garder la mise à jour optimiste)
      Future.delayed(const Duration(milliseconds: 500), () {
        loadPayments(
          approvalStatusFilter: _currentApprovalStatusFilter,
        ).catchError((e) {});
      });
    } catch (e) {
      // En cas d'erreur, recharger pour restaurer l'état correct
      await loadPayments(approvalStatusFilter: _currentApprovalStatusFilter);
      // Ne pas afficher d'erreur si c'est juste un problème de parsing
      final errorStr = e.toString().toLowerCase();
      if (!errorStr.contains('401') &&
          !errorStr.contains('403') &&
          !errorStr.contains('unauthorized') &&
          !errorStr.contains('forbidden')) {
        Get.snackbar(
          'Attention',
          'La validation peut avoir réussi. Veuillez vérifier.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectPayment(int paymentId, {required String reason}) async {
    try {
      isLoading.value = true;

      // Invalider le cache avant l'appel API
      CacheHelper.clearByPrefix('payments_');

      // Mise à jour optimiste de l'UI - mettre à jour immédiatement
      final paymentIndex = payments.indexWhere((p) => p.id == paymentId);
      if (paymentIndex != -1) {
        // Note: Le modèle PaymentModel a beaucoup de champs
        // Pour une mise à jour complète, il faudrait recharger depuis le serveur
        // La mise à jour optimiste sera effectuée après le rechargement
      }

      final result = await _paymentService.rejectPayment(
        paymentId,
        reason: reason,
      );

      // Rafraîchir les compteurs du dashboard patron
      DashboardRefreshHelper.refreshPatronCounter('payment');

      // Notifier l'utilisateur concerné du rejet
      if (result['success'] == true && result['data'] != null) {
        try {
          final paymentData = result['data'];
          NotificationHelper.notifyRejection(
            entityType: 'payment',
            entityName: NotificationHelper.getEntityDisplayName(
              'payment',
              paymentData,
            ),
            entityId: paymentId.toString(),
            reason: reason,
            route: NotificationHelper.getEntityRoute(
              'payment',
              paymentId.toString(),
            ),
          );
        } catch (e) {
          // Ignorer les erreurs de notification pour ne pas bloquer le rejet
          print('⚠️ Erreur lors de la notification: $e');
        }
      }

      Get.snackbar(
        'Succès',
        'Paiement rejeté avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Recharger les données en arrière-plan avec le filtre actuel
      // pour synchroniser avec le serveur (mais garder la mise à jour optimiste)
      Future.delayed(const Duration(milliseconds: 500), () {
        loadPayments(
          approvalStatusFilter: _currentApprovalStatusFilter,
        ).catchError((e) {});
      });
    } catch (e) {
      // En cas d'erreur, recharger pour restaurer l'état correct
      await loadPayments(approvalStatusFilter: _currentApprovalStatusFilter);
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
      final payment = payments.firstWhere(
        (p) => p.id == paymentId,
        orElse: () => throw Exception('Paiement introuvable'),
      );

      // Générer le PDF
      await PdfService().generatePaiementPdf(
        paiement: {
          'reference': payment.reference ?? payment.paymentNumber,
          'montant': payment.amount,
          'mode_paiement': payment.paymentMethod,
          'date_paiement': payment.paymentDate, // Passer directement le DateTime
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
