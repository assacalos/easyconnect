import 'package:flutter/material.dart';
import 'package:easyconnect/Models/payment_model.dart';
import 'package:easyconnect/services/payment_service.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/reference_generator.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/error_helper.dart';

PaymentModel? _firstWherePayment(List<PaymentModel> list, bool Function(PaymentModel) test) {
  try {
    return list.firstWhere(test);
  } catch (_) {
    return null;
  }
}

class PaymentController {
  static final PaymentController _instance = PaymentController._();
  static PaymentController get to => _instance;
  factory PaymentController() => _instance;
  PaymentController._();

  final PaymentService _paymentService = PaymentService.to;

  // Variables
  final List<PaymentModel> payments = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String searchQuery = '';
  String selectedStatus = 'all';
  String selectedType = 'all';
  DateTime? startDate;
  DateTime? endDate;

  String selectedApprovalStatus = 'all';
  final List<String> approvalStatuses =
      <String>['all', 'pending', 'approved', 'rejected'];
  String? _currentApprovalStatusFilter;

  PaymentStats? paymentStats;

  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  int perPage = 15;
  final ScrollController scrollController = ScrollController();

  bool isCreating = false;
  String paymentType = 'one_time';
  DateTime paymentDate = DateTime.now();
  DateTime? dueDate;
  double amount = 0.0;
  String paymentMethod = 'bank_transfer';
  String currency = 'EUR';
  String selectedClientName = '';
  String selectedClientEmail = '';
  String selectedClientAddress = '';
  int selectedClientId = 0;

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();
  final TextEditingController clientNameController = TextEditingController();
  final TextEditingController clientEmailController = TextEditingController();
  final TextEditingController clientAddressController = TextEditingController();

  String generatedReference = '';

  DateTime scheduleStartDate = DateTime.now();
  DateTime scheduleEndDate =
      DateTime.now().add(const Duration(days: 365));
  int frequency = 30;
  int totalInstallments = 12;
  double installmentAmount = 0.0;

  void ensureInitialized() {
    loadPayments();
    loadPaymentStats();
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

  Future<void> initializeGeneratedReference() async {
    if (generatedReference.isEmpty) {
      generatedReference = await generatePaymentReference();
      referenceController.text = generatedReference;
    }
  }

  // Charger les paiements
  Future<void> loadPayments({
    String? approvalStatusFilter,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    try {
      _currentApprovalStatusFilter =
          approvalStatusFilter ??
          (selectedApprovalStatus == 'all'
              ? null
              : selectedApprovalStatus);

      final user = AuthController.to.userAuth;
      if (user == null) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Utilisateur non connecté',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final cacheKey =
          'payments_${user.role}_${_currentApprovalStatusFilter ?? 'all'}';

      if (page == 1) {
        if (!forceRefresh) {
          final hiveList = PaymentService.getCachedPaiements();
          if (hiveList.isNotEmpty) {
            payments.clear();
          payments.addAll(hiveList);
            isLoading = false;
            Future.microtask(() => _refreshPaymentsFromApi(cacheKey));
            return;
          }
          final cachedPayments = CacheHelper.get<List<PaymentModel>>(cacheKey);
          if (cachedPayments != null && cachedPayments.isNotEmpty) {
            payments.clear();
          payments.addAll(cachedPayments);
            isLoading = false;
            Future.microtask(() => _refreshPaymentsFromApi(cacheKey));
            return;
          }
        }
        payments.clear();
        isLoading = true;
      } else if (page > 1) {
        isLoadingMore = true;
      }

      try {
        // Utiliser la méthode paginée
        final paginatedResponse =
            (user.role == 1 || user.role == 6)
                ? await _paymentService.getAllPaymentsPaginated(
                  startDate: startDate,
                  endDate: endDate,
                  status: null,
                  type: null,
                  page: page,
                  perPage: perPage,
                  search:
                      searchQuery.isNotEmpty ? searchQuery : null,
                )
                : await _paymentService.getComptablePaymentsPaginated(
                  comptableId: user.id,
                  startDate: startDate,
                  endDate: endDate,
                  status:
                      selectedStatus != 'all'
                          ? selectedStatus
                          : null,
                  type: selectedType != 'all' ? selectedType : null,
                  page: page,
                  perPage: perPage,
                  search:
                      searchQuery.isNotEmpty ? searchQuery : null,
                );

        // Mettre à jour les métadonnées de pagination
        totalPages = paginatedResponse.meta.lastPage;
        totalItems = paginatedResponse.meta.total;
        hasNextPage = paginatedResponse.hasNextPage;
        hasPreviousPage = paginatedResponse.hasPreviousPage;
        currentPage = paginatedResponse.meta.currentPage;

        // Mettre à jour la liste
        if (page == 1) {
          payments.clear();
          payments.addAll(paginatedResponse.data);
        } else {
          // Pour les pages suivantes, ajouter les données
          payments.addAll(paginatedResponse.data);
        }

        // Sauvegarder dans le cache (seulement pour la page 1)
        if (page == 1) {
          CacheHelper.set(cacheKey, paginatedResponse.data);
        }
      } catch (e) {
        if (page > 1 || payments.isNotEmpty) rethrow;
        final fallbackCache = CacheHelper.get<List<PaymentModel>>(cacheKey);
        if (fallbackCache != null && fallbackCache.isNotEmpty) {
          payments.clear();
          payments.addAll(fallbackCache);
          return;
        }
        final hiveList = PaymentService.getCachedPaiements();
        if (hiveList.isNotEmpty) {
          payments.clear();
          payments.addAll(hiveList);
          return;
        }
        rethrow;
      }
    } catch (e) {
      // Ne pas vider la liste si elle contient déjà des paiements (Hive/cache)
      if (payments.isEmpty) {
        final hiveList = PaymentService.getCachedPaiements();
        if (hiveList.isNotEmpty) {
          payments.clear();
          payments.addAll(hiveList);
        } else {
          final user = AuthController.to.userAuth;
          if (user != null) {
            final cacheKey =
                'payments_${user.role}_${_currentApprovalStatusFilter ?? 'all'}';
            final cachedPayments = CacheHelper.get<List<PaymentModel>>(
              cacheKey,
            );
            if (cachedPayments != null && cachedPayments.isNotEmpty) {
              payments.clear();
              payments.addAll(cachedPayments);
            } else {
              payments.clear();
            }
          } else {
            payments.clear();
          }
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
      isLoading = false;
      isLoadingMore = false;
    }
  }

  /// Rafraîchit les paiements depuis l'API (page 1) et met à jour la liste/cache si le filtre est inchangé.
  Future<void> _refreshPaymentsFromApi(String cacheKey) async {
    try {
      final user = AuthController.to.userAuth;
      if (user == null) return;

      final paginatedResponse =
          (user.role == 1 || user.role == 6)
              ? await _paymentService.getAllPaymentsPaginated(
                startDate: startDate,
                endDate: endDate,
                status: null,
                type: null,
                page: 1,
                perPage: perPage,
                search: searchQuery.isNotEmpty ? searchQuery : null,
              )
              : await _paymentService.getComptablePaymentsPaginated(
                comptableId: user.id,
                startDate: startDate,
                endDate: endDate,
                status:
                    selectedStatus != 'all' ? selectedStatus : null,
                type: selectedType != 'all' ? selectedType : null,
                page: 1,
                perPage: perPage,
                search: searchQuery.isNotEmpty ? searchQuery : null,
              );
      final stillSame =
          _currentApprovalStatusFilter ==
          (selectedApprovalStatus == 'all'
              ? null
              : selectedApprovalStatus);
      if (!stillSame) return;

      payments.clear();
      payments.addAll(paginatedResponse.data);
      totalPages = paginatedResponse.meta.lastPage;
      totalItems = paginatedResponse.meta.total;
      hasNextPage = paginatedResponse.hasNextPage;
      hasPreviousPage = paginatedResponse.hasPreviousPage;
      currentPage = 1;
      CacheHelper.set(cacheKey, paginatedResponse.data);
      loadPaymentStats().catchError((_) {});
    } catch (_) {}
  }

  /// Chargement de la page suivante au scroll.
  void loadMore() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadNextPage();
    }
  }

  /// Charger la page suivante
  void loadNextPage() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadPayments(page: currentPage + 1);
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage && !isLoading) {
      loadPayments(page: currentPage - 1);
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
        startDate: startDate,
        endDate: endDate,
        type: selectedType != 'all' ? selectedType : null,
      );
      // Convertir Map en PaymentStats si nécessaire
      paymentStats = PaymentStats.fromJson(statsData);
    } catch (e) {}
  }

  // Créer un paiement
  Future<bool> createPayment() async {
    try {
      isCreating = true;

      final user = AuthController.to.userAuth;
      if (user == null) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Utilisateur non connecté',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // Validation des champs requis
      if (selectedClientId == 0 &&
          (selectedClientName.isEmpty ||
              selectedClientEmail.isEmpty ||
              selectedClientAddress.isEmpty)) {
        errorHelperShowSnackbar?.call(
          'Erreur de validation',
          'Veuillez sélectionner un client ou remplir les informations client',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return false;
      }

      if (amount <= 0) {
        errorHelperShowSnackbar?.call(
          'Erreur de validation',
          'Veuillez saisir un montant valide',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }
      // Validation et calcul pour les paiements mensuels
      if (paymentType == 'monthly') {
        // Validation des champs requis pour les paiements mensuels
        if (totalInstallments <= 0) {
          errorHelperShowSnackbar?.call(
            'Erreur de validation',
            'Le nombre d\'échéances doit être supérieur à 0',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          return false;
        }

        if (frequency <= 0) {
          errorHelperShowSnackbar?.call(
            'Erreur de validation',
            'La fréquence doit être supérieure à 0',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          return false;
        }

        if (scheduleEndDate.isBefore(scheduleStartDate)) {
          errorHelperShowSnackbar?.call(
            'Erreur de validation',
            'La date de fin doit être postérieure à la date de début',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          return false;
        }

        // Calculer le montant des échéances
        installmentAmount = amount / totalInstallments;

        if (installmentAmount <= 0) {
          errorHelperShowSnackbar?.call(
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
      if (paymentType == 'monthly') {
        // Normaliser les dates à minuit avant de créer le schedule
        final normalizedStartDate = DateTime(
          scheduleStartDate.year,
          scheduleStartDate.month,
          scheduleStartDate.day,
        );
        final normalizedEndDate = DateTime(
          scheduleEndDate.year,
          scheduleEndDate.month,
          scheduleEndDate.day,
        );

        // Mettre à jour les dates normalisées dans les observables
        scheduleStartDate = normalizedStartDate;
        scheduleEndDate = normalizedEndDate;

        schedule = PaymentSchedule(
          id: 0, // Sera généré par le serveur
          startDate: normalizedStartDate,
          endDate: normalizedEndDate,
          frequency: frequency,
          totalInstallments: totalInstallments,
          paidInstallments: 0,
          installmentAmount: installmentAmount,
          status: 'active',
          nextPaymentDate: normalizedStartDate,
          installments: [],
        );

        // Vérification supplémentaire
        if (installmentAmount.isNaN ||
            installmentAmount.isInfinite) {
          throw Exception(
            'Le montant par échéance est invalide. Vérifiez le montant total et le nombre d\'échéances.',
          );
        }
      }

      // Pour les paiements ponctuels, toujours régénérer la référence juste avant l'envoi
      // pour éviter les doublons. Pour les paiements mensuels, garder la référence existante.
      if (paymentType == 'one_time') {
        // Toujours régénérer pour les paiements ponctuels pour garantir l'unicité
        generatedReference = await generatePaymentReference();
        referenceController.text = generatedReference;
      } else if (generatedReference.isEmpty ||
          (referenceController.text.trim().isEmpty &&
              generatedReference.isNotEmpty)) {
        // Pour les paiements mensuels, ne régénérer que si nécessaire
        generatedReference = await generatePaymentReference();
        referenceController.text = generatedReference;
      }

      final result = await _paymentService.createPayment(
        clientId:
            selectedClientId > 0
                ? selectedClientId
                : 0, // Si pas de clientId, utiliser 0 et laisser le backend gérer
        clientName: selectedClientName,
        clientEmail: selectedClientEmail,
        clientAddress: selectedClientAddress,
        comptableId: user.id,
        comptableName: user.nom ?? 'Comptable',
        type: paymentType,
        paymentDate: paymentDate,
        dueDate: dueDate,
        amount: amount,
        paymentMethod: paymentMethod,
        description:
            descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
        reference:
            generatedReference.isNotEmpty
                ? generatedReference
                : (referenceController.text.trim().isEmpty
                    ? null
                    : referenceController.text.trim()),
        schedule: schedule,
      );

      // Vérifier le succès AVANT de faire les actions secondaires
      final isSuccess = result['success'] == true || result['success'] == 1;

      if (isSuccess) {
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
          }
        }

        errorHelperShowSnackbar?.call(
          'Succès',
          'Paiement créé avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Recharger les paiements de manière asynchrone (sans bloquer)
        loadPayments().catchError((e) {
          // Ignorer les erreurs pour ne pas bloquer la navigation
        });

        // Réinitialiser le formulaire
        resetForm();
        return true;
      } else {
        final errorMessage =
            result['message'] ??
            result['error'] ??
            'Erreur lors de la création';
        errorHelperShowSnackbar?.call(
          'Erreur',
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return false;
      }
    } catch (e) {
      // Ne capturer que les erreurs qui surviennent AVANT le succès
      // Si on arrive ici, c'est que l'appel API a échoué
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      // Détecter les erreurs de référence dupliquée et régénérer automatiquement
      if (errorMessage.contains('Duplicate entry') &&
          errorMessage.contains('reference')) {
        // Régénérer une nouvelle référence
        try {
          generatedReference = await generatePaymentReference();
          referenceController.text = generatedReference;
          errorHelperShowSnackbar?.call(
            'Référence régénérée',
            'La référence a été régénérée automatiquement. Veuillez réessayer.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        } catch (regenerateError) {
          // Si la régénération échoue, afficher l'erreur originale
          errorHelperShowSnackbar?.call(
            'Erreur',
            'Erreur de référence dupliquée. Veuillez réessayer.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
        }
        return false;
      }

      // Ne pas afficher d'erreur pour les erreurs de parsing ou de type
      // qui peuvent survenir lors du traitement de la réponse
      final errorStr = errorMessage.toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        // Probablement une erreur de parsing - ne pas afficher d'erreur
        // car l'action peut avoir réussi
        return false;
      }

      // Détecter les erreurs 500 et afficher un message plus clair
      if (errorMessage.contains('500') ||
          errorMessage.contains('Erreur serveur')) {
        errorHelperShowSnackbar?.call(
          'Erreur serveur',
          'Une erreur s\'est produite sur le serveur. Veuillez vérifier les données saisies et réessayer.\n'
              'Si le problème persiste, contactez le support technique.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
        );
      } else {
        errorHelperShowSnackbar?.call(
          'Erreur',
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
      return false;
    } finally {
      isCreating = false;
    }
  }

  // Soumettre un paiement au patron
  Future<void> submitPaymentToPatron(int paymentId) async {
    try {
      final result = await _paymentService.submitPaymentToPatron(paymentId);

      if (result['success'] == true) {
        // Notifier le patron de la soumission
        final payment = _firstWherePayment(payments, (p) => p.id == paymentId);
        if (payment != null) {
          NotificationHelper.notifySubmission(
            entityType: 'payment',
            entityName: NotificationHelper.getEntityDisplayName(
              'payment',
              payment,
            ),
            entityId: paymentId.toString(),
            route: NotificationHelper.getEntityRoute(
              'payment',
              paymentId.toString(),
            ),
          );
        }

        errorHelperShowSnackbar?.call('Succès', 'Paiement soumis au patron');
        await loadPayments();
      } else {
        errorHelperShowSnackbar?.call(
          'Erreur',
          result['message'] ?? 'Erreur lors de la soumission',
        );
      }
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', 'Erreur lors de la soumission du paiement');
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
        errorHelperShowSnackbar?.call('Succès', 'Paiement marqué comme payé');
        await loadPayments();
      } else {
        errorHelperShowSnackbar?.call('Erreur', result['message'] ?? 'Erreur lors du marquage');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', 'Erreur lors du marquage du paiement');
    }
  }

  // Supprimer un paiement
  Future<void> deletePayment(int paymentId) async {
    try {
      final result = await _paymentService.deletePayment(paymentId);

      if (result['success'] == true) {
        errorHelperShowSnackbar?.call('Succès', 'Paiement supprimé');
        await loadPayments();
      } else {
        errorHelperShowSnackbar?.call(
          'Erreur',
          result['message'] ?? 'Erreur lors de la suppression',
        );
      }
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', 'Erreur lors de la suppression du paiement');
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
        errorHelperShowSnackbar?.call('Succès', 'Planning modifié');
        await loadPayments();
      } else {
        errorHelperShowSnackbar?.call(
          'Erreur',
          result['message'] ?? 'Erreur lors de la modification',
        );
      }
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', 'Erreur lors de la modification du planning');
    }
  }

  // Réinitialiser le formulaire
  void resetForm() {
    paymentType = 'one_time';
    paymentDate = DateTime.now();
    dueDate = null;
    amount = 0.0;
    paymentMethod = 'bank_transfer';
    selectedClientName = '';
    selectedClientEmail = '';
    selectedClientAddress = '';
    selectedClientId = 0;

    descriptionController.clear();
    notesController.clear();
    generatedReference = '';
    referenceController.clear();
    clientNameController.clear();
    clientEmailController.clear();
    clientAddressController.clear();

    // Normaliser les dates à minuit
    final now = DateTime.now();
    scheduleStartDate = DateTime(now.year, now.month, now.day);
    scheduleEndDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 365));
    frequency = 30;
    totalInstallments = 12;
    installmentAmount = 0.0;

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
    selectedClientId = clientId;
    selectedClientName = clientName;
    selectedClientEmail = clientEmail;
    selectedClientAddress = clientAddress;

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
    final user = AuthController.to.userAuth;
    return user?.role == 1 || user?.role == 6; // Patron ou Admin
  }

  // Vérifier si l'utilisateur peut soumettre
  bool get canSubmitPayments {
    final user = AuthController.to.userAuth;
    return user?.role == 3; // Comptable
  }

  // Méthodes de filtrage par statut d'approbation
  void setApprovalStatusFilter(String approvalStatus) {
    selectedApprovalStatus = approvalStatus;
    loadPayments();
  }

  /// Charge les paiements pour l’onglet [index] (0=Tous, 1=En attente, 2=Validés, 3=Rejetés). Cache-first.
  void loadByStatus(int index, {bool forceRefresh = false}) {
    const statuses = ['all', 'pending', 'approved', 'rejected'];
    selectedApprovalStatus = statuses[index];
    loadPayments(forceRefresh: forceRefresh);
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
      isLoading = true;

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
            entity: paymentData,
          );
        } catch (e) {
          // Ignorer les erreurs de notification pour ne pas bloquer la validation
        }
      }

      errorHelperShowSnackbar?.call(
        'Succès',
        'Paiement approuvé avec succès',
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
      // Vérifier si l'erreur est survenue après un succès
      // Si c'est le cas, ne pas afficher d'erreur
      final errorStr = e.toString().toLowerCase();

      // Ne pas afficher d'erreur pour les erreurs de parsing ou de rechargement
      // qui peuvent survenir après un succès
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast')) {
        // Probablement une erreur de parsing après un succès
        // Recharger silencieusement
        loadPayments(
          approvalStatusFilter: _currentApprovalStatusFilter,
        ).catchError((e) {});
        return;
      }

      // Pour les autres erreurs, vérifier si c'est une erreur d'authentification
      if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('forbidden')) {
        // Erreur d'authentification - afficher
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Erreur d\'authentification. Veuillez vous reconnecter.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        // Autre erreur - recharger pour vérifier l'état
        loadPayments(
          approvalStatusFilter: _currentApprovalStatusFilter,
        ).catchError((e) {});
        // Ne pas afficher d'erreur car l'action peut avoir réussi
      }
    } finally {
      isLoading = false;
    }
  }

  Future<void> rejectPayment(int paymentId, {required String reason}) async {
    try {
      isLoading = true;

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
            entity: paymentData,
          );
        } catch (e) {
          // Ignorer les erreurs de notification pour ne pas bloquer le rejet
        }
      }

      errorHelperShowSnackbar?.call(
        'Succès',
        'Paiement rejeté avec succès',
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
      // Vérifier si l'erreur est survenue après un succès
      final errorStr = e.toString().toLowerCase();

      // Ne pas afficher d'erreur pour les erreurs de parsing ou de rechargement
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast')) {
        // Probablement une erreur de parsing après un succès
        loadPayments(
          approvalStatusFilter: _currentApprovalStatusFilter,
        ).catchError((e) {});
        return;
      }

      // Pour les autres erreurs, vérifier si c'est une erreur d'authentification
      if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('forbidden')) {
        // Erreur d'authentification - afficher
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Erreur d\'authentification. Veuillez vous reconnecter.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        // Autre erreur - recharger pour vérifier l'état
        loadPayments(
          approvalStatusFilter: _currentApprovalStatusFilter,
        ).catchError((e) {});
        // Ne pas afficher d'erreur car l'action peut avoir réussi
      }
    } finally {
      isLoading = false;
    }
  }

  Future<void> reactivatePayment(int paymentId) async {
    try {
      await _paymentService.reactivatePayment(paymentId);

      // Recharger les paiements
      await loadPayments();

      errorHelperShowSnackbar?.call(
        'Succès',
        'Paiement réactivé avec succès',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de réactiver le paiement: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void dispose() {
    scrollController.dispose();
    descriptionController.dispose();
    notesController.dispose();
    referenceController.dispose();
    clientNameController.dispose();
    clientEmailController.dispose();
    clientAddressController.dispose();
  }

  /// Générer un PDF pour un paiement
  Future<void> generatePDF(int paymentId) async {
    try {
      isLoading = true;

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
          'date_paiement':
              payment.paymentDate, // Passer directement le DateTime
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

      errorHelperShowSnackbar?.call(
        'Succès',
        'PDF généré avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Erreur lors de la génération du PDF: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading = false;
    }
  }
}
