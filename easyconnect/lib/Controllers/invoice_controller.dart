import 'package:flutter/material.dart';
import 'package:easyconnect/Models/invoice_model.dart';
import 'package:easyconnect/services/invoice_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/utils/reference_generator.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/error_helper.dart';

InvoiceModel? _firstWhereInvoice(List<InvoiceModel> list, bool Function(InvoiceModel) test) {
  try {
    return list.firstWhere(test);
  } catch (_) {
    return null;
  }
}

class InvoiceController {
  static final InvoiceController _instance = InvoiceController._();
  static InvoiceController get to => _instance;
  factory InvoiceController() => _instance;
  InvoiceController._();

  final InvoiceService _invoiceService = InvoiceService.to;
  final ClientService _clientService = ClientService();

  // Variables
  bool isLoading = false;
  bool isLoadingMore = false;
  bool isCreating = false;
  bool isSubmitting = false;
  final List<InvoiceModel> invoices = [];
  final List<InvoiceModel> pendingInvoices = [];
  InvoiceStats? invoiceStats;
  final List<InvoiceTemplate> templates = [];

  // Variables pour la gestion des clients validés
  final List<Client> availableClients = [];
  bool isLoadingClients = false;
  Client? selectedClient;

  // Variables pour le formulaire de création
  int selectedClientId = 0;
  String selectedClientName = '';
  String selectedClientEmail = '';
  String selectedClientAddress = '';
  final List<InvoiceItem> invoiceItems = [];
  double taxRate = 20.0;
  String notes = '';
  String terms = '';
  DateTime invoiceDate = DateTime.now();
  DateTime dueDate = DateTime.now().add(const Duration(days: 30));

  // Contrôleurs de formulaire
  final TextEditingController clientNameController = TextEditingController();
  final TextEditingController clientEmailController = TextEditingController();
  final TextEditingController clientAddressController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController termsController = TextEditingController();
  final TextEditingController invoiceNumberController = TextEditingController();

  String generatedInvoiceNumber = '';

  // Variables pour les filtres
  String selectedStatus = 'all';
  DateTime? startDate;
  DateTime? endDate;
  String searchQuery = '';

  // Métadonnées de pagination
  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  int perPage = 15;
  final ScrollController scrollController = ScrollController();

  /// À appeler au premier affichage.
  void ensureInitialized() {
    loadInvoices();
    loadTemplates();
    if (generatedInvoiceNumber.isEmpty) {
      initializeGeneratedReference();
    }
  }

  void dispose() {
    scrollController.dispose();
    clientNameController.dispose();
    clientEmailController.dispose();
    clientAddressController.dispose();
    notesController.dispose();
    termsController.dispose();
    invoiceNumberController.dispose();
  }

  // Générer automatiquement le numéro de facture
  Future<String> generateInvoiceNumber() async {
    // Recharger les factures pour avoir le comptage à jour
    await loadInvoices();

    // Extraire tous les numéros de facture existants
    final existingNumbers =
        invoices
            .map((inv) => inv.invoiceNumber)
            .where((num) => num.isNotEmpty)
            .toList();

    // Générer avec incrément
    return ReferenceGenerator.generateReferenceWithIncrement(
      'FACT',
      existingNumbers,
    );
  }

  Future<void> initializeGeneratedReference() async {
    if (generatedInvoiceNumber.isEmpty) {
      generatedInvoiceNumber = await generateInvoiceNumber();
      invoiceNumberController.text = generatedInvoiceNumber;
    }
  }

  // Charger les factures
  Future<void> loadInvoices({int page = 1, bool forceRefresh = false}) async {
    try {
      final user = AuthController.to.userAuth;
      if (user == null) return;

      final cacheKey = 'invoices_${user.role}_${selectedStatus}';
      final statusParam = selectedStatus != 'all' ? selectedStatus : null;
      final commercialIdParam = (user.role == 1 || user.role == 6) ? null : user.id;

      if (page == 1) {
        if (!forceRefresh) {
          final hiveList = InvoiceService.getCachedFactures(statusParam, commercialIdParam);
          if (hiveList.isNotEmpty) {
            invoices.clear();
            invoices.addAll(hiveList);
            isLoading = false;
            Future.microtask(() => _refreshInvoicesFromApi(cacheKey, statusParam, commercialIdParam));
            return;
          }
          final cachedInvoices = CacheHelper.get<List<InvoiceModel>>(cacheKey);
          if (cachedInvoices != null && cachedInvoices.isNotEmpty) {
            invoices.clear();
            invoices.addAll(cachedInvoices);
            isLoading = false;
            Future.microtask(() => _refreshInvoicesFromApi(cacheKey, statusParam, commercialIdParam));
            return;
          }
        }
        invoices.clear();
        isLoading = true;
      } else if (page > 1) {
        isLoadingMore = true;
      }

      try {
        // Utiliser la méthode paginée
        final paginatedResponse = await _invoiceService.getInvoicesPaginated(
          startDate: startDate,
          endDate: endDate,
          status: selectedStatus != 'all' ? selectedStatus : null,
          commercialId: (user.role == 1 || user.role == 6) ? null : user.id,
          page: page,
          perPage: perPage,
          search: searchQuery.isNotEmpty ? searchQuery : null,
        );

        // Mettre à jour les métadonnées de pagination
        totalPages = paginatedResponse.meta.lastPage;
        totalItems = paginatedResponse.meta.total;
        hasNextPage = paginatedResponse.hasNextPage;
        hasPreviousPage = paginatedResponse.hasPreviousPage;
        currentPage = paginatedResponse.meta.currentPage;

        // Mettre à jour la liste
        if (page == 1) {
          invoices.clear();
          invoices.addAll(paginatedResponse.data);
        } else {
          // Pour les pages suivantes, ajouter les données
          invoices.addAll(paginatedResponse.data);
        }

        // Sauvegarder dans le cache (seulement pour la page 1)
        if (page == 1) {
          CacheHelper.set(cacheKey, paginatedResponse.data);
        }

        AppLogger.info(
          '${paginatedResponse.data.length} factures chargées (Page $page/${paginatedResponse.meta.lastPage})',
          tag: 'INVOICE_CONTROLLER',
        );

        // Charger les statistiques (non-bloquant)
        loadInvoiceStats().catchError((e) {});
      } catch (e) {
        // En cas d'erreur, essayer la méthode non-paginée en fallback
        AppLogger.warning(
          'Erreur avec pagination, fallback vers méthode classique: $e',
          tag: 'INVOICE_CONTROLLER',
        );
        try {
          // OPTIMISATION : Limiter le fallback à 1000 factures max pour éviter la saturation mémoire
          final loadedInvoices = await _invoiceService.getAllInvoices(
            startDate: startDate,
            endDate: endDate,
            status: selectedStatus != 'all' ? selectedStatus : null,
            commercialId: (user.role == 1 || user.role == 6) ? null : user.id,
          );

          // Limiter à 1000 factures pour éviter la saturation mémoire
          final limitedInvoices = loadedInvoices.take(1000).toList();

          if (page == 1) {
            invoices.clear();
            invoices.addAll(limitedInvoices);
          } else {
            invoices.addAll(limitedInvoices);
          }
          if (page == 1) {
            CacheHelper.set(cacheKey, limitedInvoices);
          }

          // Avertir si on a limité les résultats
          if (loadedInvoices.length > 1000) {
            AppLogger.warning(
              'Fallback limité à 1000 factures sur ${loadedInvoices.length} totales',
              tag: 'INVOICE_CONTROLLER',
            );
          }
        } catch (fallbackError) {
          if (page > 1 || invoices.isEmpty) {
            final hiveList = InvoiceService.getCachedFactures();
            if (hiveList.isNotEmpty) {
              invoices.clear();
              invoices.addAll(hiveList);
              return;
            }
            final fallbackCache = CacheHelper.get<List<InvoiceModel>>('invoices_all');
            if (fallbackCache != null && fallbackCache.isNotEmpty) {
              invoices.clear();
              invoices.addAll(fallbackCache);
              return;
            }
            rethrow;
          }
        }
      }
    } catch (e) {
      // Ne pas afficher de message d'erreur si c'est une erreur d'authentification
      // (elle est déjà gérée par AuthErrorHandler)
      final errorString = e.toString().toLowerCase();
      if (!errorString.contains('session expirée') &&
          !errorString.contains('401') &&
          !errorString.contains('unauthorized')) {
        // Ne pas afficher d'erreur si des données sont disponibles (cache ou liste non vide)
        if (invoices.isEmpty) {
          // Vérifier une dernière fois le cache avant d'afficher l'erreur
          final cacheKey = 'invoices_all';
          final cachedInvoices = CacheHelper.get<List<InvoiceModel>>(cacheKey);
          if (cachedInvoices == null || cachedInvoices.isEmpty) {
            errorHelperShowSnackbar?.call(
              'Erreur',
              'Impossible de charger les factures: ${e.toString()}',
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
            );
          } else {
            invoices.clear();
            invoices.addAll(cachedInvoices);
          }
        }
      }
    } finally {
      isLoading = false;
      isLoadingMore = false;
    }
  }

  /// Rafraîchit les factures depuis l'API (page 1) et met à jour la liste/cache si le filtre est inchangé.
  Future<void> _refreshInvoicesFromApi(
    String cacheKey,
    String? statusParam,
    int? commercialIdParam,
  ) async {
    try {
      final user = AuthController.to.userAuth;
      if (user == null) return;
      final currentStatus = selectedStatus != 'all' ? selectedStatus : null;
      final currentCommercialId = (user.role == 1 || user.role == 6) ? null : user.id;
      if (currentStatus != statusParam || currentCommercialId != commercialIdParam) return;

      final paginatedResponse = await _invoiceService.getInvoicesPaginated(
        startDate: startDate,
        endDate: endDate,
        status: statusParam,
        commercialId: commercialIdParam,
        page: 1,
        perPage: perPage,
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );
      final stillSameStatus = (selectedStatus != 'all' ? selectedStatus : null) == statusParam;
      final stillSameCommercial = (user.role == 1 || user.role == 6) ? commercialIdParam == null : commercialIdParam == user.id;
      if (!stillSameStatus || !stillSameCommercial) return;

      invoices.clear();
      invoices.addAll(paginatedResponse.data);
      totalPages = paginatedResponse.meta.lastPage;
      totalItems = paginatedResponse.meta.total;
      hasNextPage = paginatedResponse.hasNextPage;
      hasPreviousPage = paginatedResponse.hasPreviousPage;
      currentPage = 1;
      CacheHelper.set(cacheKey, paginatedResponse.data);
      loadInvoiceStats().catchError((_) {});
    } catch (_) {}
  }

  /// Chargement de la page suivante au scroll (appelé par la vue).
  void loadMore() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadNextPage();
    }
  }

  /// Charger la page suivante
  void loadNextPage() {
    if (hasNextPage && !isLoading) {
      loadInvoices(page: currentPage + 1);
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage && !isLoading) {
      loadInvoices(page: currentPage - 1);
    }
  }

  // Charger les factures en attente (pour le patron)
  Future<void> loadPendingInvoices() async {
    try {
      final user = AuthController.to.userAuth;
      if (user == null || (user.role != 1 && user.role != 6))
        return; // Seulement pour le patron ou admin

      final pendingList = await _invoiceService.getPendingInvoices();
      pendingInvoices.clear();
      pendingInvoices.addAll(pendingList);
    } catch (e) {}
  }

  // Charger les statistiques
  Future<void> loadInvoiceStats() async {
    try {
      final user = AuthController.to.userAuth;
      if (user == null) return;

      final stats = await _invoiceService.getInvoiceStats(
        startDate: startDate,
        endDate: endDate,
        commercialId: (user.role != 1 && user.role != 6) ? user.id : null,
      );
      invoiceStats = stats;
    } catch (e) {}
  }

  // Charger les modèles
  Future<void> loadTemplates() async {
    try {
      final templatesList = await _invoiceService.getInvoiceTemplates();
      templates.clear();
      templates.addAll(templatesList);
    } catch (e) {}
  }

  // Créer une facture
  Future<bool> createInvoice() async {
    if (isCreating) return false;
    bool successReturned = false;
    try {
      isCreating = true;

      final user = AuthController.to.userAuth;
      if (user == null) {
        errorHelperShowSnackbar?.call('Erreur', 'Utilisateur non connecté');
        return false;
      }

      // Vérifier qu'un client validé est sélectionné
      if (selectedClient == null) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Veuillez sélectionner un client validé',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // Vérifier que le client sélectionné est bien validé
      if (selectedClient!.status != 1) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Seuls les clients validés peuvent être sélectionnés',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      if (invoiceItems.isEmpty) {
        errorHelperShowSnackbar?.call('Erreur', 'Veuillez ajouter au moins un article');
        return false;
      }

      final result = await _invoiceService.createInvoice(
        clientId: selectedClient!.id!,
        clientName:
            '${selectedClient!.nom ?? ''} ${selectedClient!.prenom ?? ''}'
                .trim(),
        clientEmail: selectedClient!.email ?? '',
        clientAddress: selectedClient!.adresse ?? '',
        commercialId: user.id,
        commercialName: user.nom ?? 'Comptable',
        invoiceDate: invoiceDate,
        dueDate: dueDate,
        items: invoiceItems,
        taxRate: taxRate,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
        terms:
            termsController.text.trim().isEmpty
                ? null
                : termsController.text.trim(),
      );

      // Vérifier si la réponse contient success == true
      // Gérer différents formats de réponse
      final isSuccess =
          result['success'] == true ||
          result['success'] == 1 ||
          result['success'] == 'true' ||
          (result['success'] == null && result['data'] != null);

      if (isSuccess) {
        // Invalider le cache
        CacheHelper.clearByPrefix('invoices_');

        // Rafraîchir les compteurs du dashboard patron
        DashboardRefreshHelper.refreshPatronCounter('invoice');

        // Effacer le formulaire immédiatement
        clearForm();

        // Mettre isCreating à false immédiatement pour permettre la fermeture du formulaire
        isCreating = false;

        // Afficher le message de succès
        errorHelperShowSnackbar?.call(
          'Succès',
          result['message'] ?? 'Facture créée avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // Recharger la liste en arrière-plan (ne pas bloquer)
        Future.microtask(() async {
          await Future.delayed(const Duration(milliseconds: 500));
          try {
            await loadInvoices();
          } catch (e) {
            // Si le rechargement échoue, on ne fait rien car la facture a été créée avec succès
            // L'utilisateur peut recharger manuellement si nécessaire
          }
        });

        successReturned = true;
        return true;
      } else {
        errorHelperShowSnackbar?.call(
          'Erreur',
          result['message'] ?? 'Erreur lors de la création de la facture',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        // Probablement une erreur de parsing après un succès
        return false;
      }

      // Extraire le message d'erreur de manière plus lisible
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      errorHelperShowSnackbar?.call(
        'Erreur',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return false;
    } finally {
      // Ne pas mettre isCreating à false ici si on a déjà réussi
      // (il a été mis à false dans le bloc de succès pour fermer le formulaire plus vite)
      if (!successReturned) {
        isCreating = false;
      }
    }
  }

  // Soumettre une facture au patron
  Future<void> submitInvoiceToPatron(int invoiceId) async {
    try {
      isSubmitting = true;

      final result = await _invoiceService.submitInvoiceToPatron(invoiceId);

      if (result['success'] == true) {
        errorHelperShowSnackbar?.call('Succès', 'Facture soumise au patron');
        // Notifier de manière asynchrone (non-bloquant)
        final invoice = _firstWhereInvoice(invoices, (i) => i.id == invoiceId);
        if (invoice != null) {
          NotificationHelper.notifySubmission(
            entityType: 'facture',
            entityName: NotificationHelper.getEntityDisplayName(
              'facture',
              invoice,
            ),
            entityId: invoiceId.toString(),
            route: NotificationHelper.getEntityRoute(
              'facture',
              invoiceId.toString(),
            ),
          );
        }
        await loadInvoices();
        await loadPendingInvoices();
      } else {
        errorHelperShowSnackbar?.call(
          'Erreur',
          result['message'] ?? 'Erreur lors de la soumission',
        );
      }
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', 'Erreur lors de la soumission: $e');
    } finally {
      isSubmitting = false;
    }
  }

  // Approuver une facture (pour le patron)
  Future<void> approveInvoice(int invoiceId, {String? comments}) async {
    try {
      AppLogger.info(
        'Approbation de la facture: $invoiceId',
        tag: 'INVOICE_CONTROLLER',
      );
      isLoading = true;

      // Invalider le cache avant l'appel API
      CacheHelper.clearByPrefix('invoices_');
      CacheHelper.clearByPrefix('factures_');

      // Mise à jour optimiste de l'UI - mettre à jour le statut sans retirer de la liste
      final invoiceIndex = pendingInvoices.indexWhere((i) => i.id == invoiceId);
      InvoiceModel? originalInvoice;
      if (invoiceIndex != -1) {
        originalInvoice = pendingInvoices[invoiceIndex];
        // Retirer de la liste des factures en attente
        pendingInvoices.removeAt(invoiceIndex);
      }

      // Mettre à jour dans la liste principale - NE PAS RETIRER, juste mettre à jour le statut
      final mainInvoiceIndex = invoices.indexWhere((i) => i.id == invoiceId);
      if (mainInvoiceIndex != -1) {
        originalInvoice ??= invoices[mainInvoiceIndex];
        // Mettre à jour le statut à 'valide' (le backend retourne 'valide')
        final original = invoices[mainInvoiceIndex];
        final updatedInvoice = InvoiceModel(
          id: original.id,
          invoiceNumber: original.invoiceNumber,
          clientId: original.clientId,
          clientName: original.clientName,
          clientEmail: original.clientEmail,
          clientAddress: original.clientAddress,
          commercialId: original.commercialId,
          commercialName: original.commercialName,
          invoiceDate: original.invoiceDate,
          dueDate: original.dueDate,
          subtotal: original.subtotal,
          taxRate: original.taxRate,
          taxAmount: original.taxAmount,
          totalAmount: original.totalAmount,
          currency: original.currency,
          status:
              'valide', // Mettre à jour le statut (le backend retourne 'valide')
          items: original.items,
          notes: original.notes,
          terms: original.terms,
          paymentInfo: original.paymentInfo,
          createdAt: original.createdAt,
          updatedAt: DateTime.now(),
          sentAt: original.sentAt,
          paidAt: original.paidAt,
        );
        invoices[mainInvoiceIndex] = updatedInvoice;
      } else {
        // Si la facture n'est pas dans la liste principale, la récupérer depuis pendingInvoices
        if (originalInvoice != null) {
          final updatedInvoice = InvoiceModel(
            id: originalInvoice.id,
            invoiceNumber: originalInvoice.invoiceNumber,
            clientId: originalInvoice.clientId,
            clientName: originalInvoice.clientName,
            clientEmail: originalInvoice.clientEmail,
            clientAddress: originalInvoice.clientAddress,
            commercialId: originalInvoice.commercialId,
            commercialName: originalInvoice.commercialName,
            invoiceDate: originalInvoice.invoiceDate,
            dueDate: originalInvoice.dueDate,
            subtotal: originalInvoice.subtotal,
            taxRate: originalInvoice.taxRate,
            taxAmount: originalInvoice.taxAmount,
            totalAmount: originalInvoice.totalAmount,
            currency: originalInvoice.currency,
            status: 'valide',
            items: originalInvoice.items,
            notes: originalInvoice.notes,
            terms: originalInvoice.terms,
            paymentInfo: originalInvoice.paymentInfo,
            createdAt: originalInvoice.createdAt,
            updatedAt: DateTime.now(),
            sentAt: originalInvoice.sentAt,
            paidAt: originalInvoice.paidAt,
          );
          // Ajouter à la liste principale pour qu'elle soit visible
          invoices.add(updatedInvoice);
        }
      }

      final result = await _invoiceService.approveInvoice(
        invoiceId: invoiceId,
        comments: comments,
      );

      // Si result['success'] est true OU si le status code était 200/201, considérer comme succès
      final isSuccess =
          result['success'] == true ||
          result['success'] == 1 ||
          result['success'] == 'true';

      if (isSuccess) {
        errorHelperShowSnackbar?.call(
          'Succès',
          result['message'] ?? 'Facture approuvée avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // Rafraîchir les compteurs du dashboard patron
        DashboardRefreshHelper.refreshPatronCounter('invoice');

        // Notifier de manière asynchrone (non-bloquant)
        if (originalInvoice != null) {
          NotificationHelper.notifyValidation(
            entityType: 'facture',
            entityName: NotificationHelper.getEntityDisplayName(
              'facture',
              originalInvoice,
            ),
            entityId: invoiceId.toString(),
            route: NotificationHelper.getEntityRoute(
              'facture',
              invoiceId.toString(),
            ),
            entity: originalInvoice,
          );
        }

        // Recharger les données en arrière-plan pour synchroniser avec le serveur
        // Mais garder la mise à jour optimiste pour que la facture reste visible
        // Forcer le chargement de toutes les factures (status: null)
        selectedStatus = 'all'; // Forcer le chargement de toutes les factures
        Future.delayed(const Duration(milliseconds: 500), () async {
          await loadInvoices();
          await loadPendingInvoices();
        });
      } else {
        // En cas d'échec, recharger pour restaurer l'état
        await loadInvoices();
        await loadPendingInvoices();
        // Ne pas afficher d'erreur si la validation a peut-être réussi côté serveur
        errorHelperShowSnackbar?.call(
          'Attention',
          'La validation peut avoir réussi. Veuillez vérifier.',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de l\'approbation de la facture: $e',
        tag: 'INVOICE_CONTROLLER',
        error: e,
        stackTrace: stackTrace,
      );
      // En cas d'erreur, recharger pour restaurer l'état correct
      await loadInvoices();
      await loadPendingInvoices();
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible d\'approuver la facture: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading = false;
    }
  }

  // Rejeter une facture (pour le patron)
  Future<void> rejectInvoice(int invoiceId, String reason) async {
    try {
      AppLogger.info(
        'Rejet de la facture: $invoiceId',
        tag: 'INVOICE_CONTROLLER',
      );
      isLoading = true;

      // Mise à jour optimiste : retirer des pending, mettre à jour statut dans la liste principale
      final pendingIndex = pendingInvoices.indexWhere((i) => i.id == invoiceId);
      InvoiceModel? originalInvoice;
      if (pendingIndex != -1) {
        originalInvoice = pendingInvoices[pendingIndex];
        pendingInvoices.removeAt(pendingIndex);
      }
      final mainIndex = invoices.indexWhere((i) => i.id == invoiceId);
      if (mainIndex != -1) {
        final original = invoices[mainIndex];
        originalInvoice ??= original;
        final updatedInvoice = InvoiceModel(
          id: original.id,
          invoiceNumber: original.invoiceNumber,
          clientId: original.clientId,
          clientName: original.clientName,
          clientEmail: original.clientEmail,
          clientAddress: original.clientAddress,
          commercialId: original.commercialId,
          commercialName: original.commercialName,
          invoiceDate: original.invoiceDate,
          dueDate: original.dueDate,
          subtotal: original.subtotal,
          taxRate: original.taxRate,
          taxAmount: original.taxAmount,
          totalAmount: original.totalAmount,
          currency: original.currency,
          status: 'rejetee',
          items: original.items,
          notes: original.notes,
          terms: original.terms,
          paymentInfo: original.paymentInfo,
          createdAt: original.createdAt,
          updatedAt: DateTime.now(),
          sentAt: original.sentAt,
          paidAt: original.paidAt,
        );
        invoices[mainIndex] = updatedInvoice;
      }

      final result = await _invoiceService.rejectInvoice(
        invoiceId: invoiceId,
        reason: reason,
      );

      if (result['success'] == true) {
        errorHelperShowSnackbar?.call(
          'Succès',
          'Facture rejetée',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        final invoice = _firstWhereInvoice(invoices, (i) => i.id == invoiceId) ?? originalInvoice;
        if (invoice != null) {
          NotificationHelper.notifyRejection(
            entityType: 'facture',
            entityName: NotificationHelper.getEntityDisplayName(
              'facture',
              invoice,
            ),
            entityId: invoiceId.toString(),
            reason: reason,
            route: NotificationHelper.getEntityRoute(
              'facture',
              invoiceId.toString(),
            ),
            entity: invoice,
          );
        }
        // Sync en arrière-plan sans bloquer l'UI
        loadInvoices().catchError((_) {});
        loadPendingInvoices().catchError((_) {});
      } else {
        errorHelperShowSnackbar?.call(
          'Erreur',
          result['message'] ?? 'Erreur lors du rejet',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors du rejet de la facture: $e',
        tag: 'INVOICE_CONTROLLER',
        error: e,
        stackTrace: stackTrace,
      );
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Erreur lors du rejet: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading = false;
    }
  }

  // Ajouter un article à la facture
  void addInvoiceItem({
    required String description,
    required int quantity,
    required double unitPrice,
    String? unit,
  }) {
    final totalPrice = quantity * unitPrice;
    final item = InvoiceItem(
      id: DateTime.now().millisecondsSinceEpoch,
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
      unit: unit,
    );
    invoiceItems.add(item);
  }

  // Supprimer un article
  void removeInvoiceItem(int index) {
    if (index >= 0 && index < invoiceItems.length) {
      invoiceItems.removeAt(index);
    }
  }

  // Mettre à jour un article
  void updateInvoiceItem(int index, InvoiceItem item) {
    if (index >= 0 && index < invoiceItems.length) {
      invoiceItems[index] = item;
    }
  }

  // Calculer le sous-total
  double get subtotal =>
      invoiceItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  // Calculer le montant de la TVA
  double get taxAmount => subtotal * (taxRate / 100);

  // Calculer le total
  double get totalAmount => subtotal + taxAmount;

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

  // Réinitialiser le formulaire
  void resetForm() {
    selectedClientId = 0;
    selectedClientName = '';
    selectedClientEmail = '';
    selectedClientAddress = '';
    invoiceItems.clear();
    taxRate = 20.0;
    notes = '';
    terms = '';
    invoiceDate = DateTime.now();
    dueDate = DateTime.now().add(const Duration(days: 30));

    clientNameController.clear();
    clientEmailController.clear();
    clientAddressController.clear();
    notesController.clear();
    termsController.clear();
  }

  // Filtrer les factures
  void filterInvoices({
    String? status,
    DateTime? start,
    DateTime? end,
    String? search,
  }) {
    selectedStatus = status ?? 'all';
    startDate = start;
    endDate = end;
    searchQuery = search ?? '';
    loadInvoices();
  }

  // Trier les factures par statut
  void sortInvoicesByStatus() {
    final sortedInvoices = List<InvoiceModel>.from(invoices);

    sortedInvoices.sort((a, b) {
      // Ordre de priorité des statuts
      final statusOrder = {'en_attente': 0, 'valide': 1, 'rejete': 2};

      final statusA = statusOrder[a.status] ?? 999;
      final statusB = statusOrder[b.status] ?? 999;

      if (statusA != statusB) {
        return statusA.compareTo(statusB);
      }

      // Ensuite par date de création (plus récent en premier)
      return b.createdAt.compareTo(a.createdAt);
    });

    invoices.clear();
    invoices.addAll(sortedInvoices);
  }

  // Obtenir le statut de la facture
  String getInvoiceStatusText(String status) {
    switch (status) {
      case 'en_attente':
        return 'En attente';
      case 'valide':
        return 'Validée';
      case 'rejete':
        return 'Rejetée';
      default:
        return 'Inconnu';
    }
  }

  // Obtenir la couleur du statut
  Color getInvoiceStatusColor(String status) {
    switch (status) {
      case 'en_attente':
        return Colors.orange;
      case 'valide':
        return Colors.green;
      case 'rejete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Vérifier si l'utilisateur peut approuver
  bool get canApproveInvoices {
    final user = AuthController.to.userAuth;
    return user?.role == 1 || user?.role == 6; // Patron ou Admin
  }

  // Vérifier si l'utilisateur peut soumettre
  bool get canSubmitInvoices {
    final user = AuthController.to.userAuth;
    return user?.role == 3; // Comptable
  }

  // Chargement des clients validés : cache Hive d'abord, puis API.
  Future<void> loadValidatedClients() async {
    isLoadingClients = true;
    final cached = ClientService.getCachedClients(1);
    if (cached.isNotEmpty) {
      availableClients.clear();
      availableClients.addAll(cached);
      isLoadingClients = false;
    } else {
      availableClients.clear();
    }
    try {
      final clients = await _clientService.getClients(status: 1);
      availableClients.clear();
      availableClients.addAll(clients);
    } catch (e) {
      if (availableClients.isEmpty) {
        final fallback = ClientService.getCachedClients(1);
        if (fallback.isNotEmpty) {
          availableClients.clear();
          availableClients.addAll(fallback);
        } else {
          errorHelperShowSnackbar?.call(
            'Erreur',
            'Impossible de charger les clients validés',
          );
        }
      }
    } finally {
      isLoadingClients = false;
    }
  }

  // Sélection d'un client
  void selectClientForInvoice(Client client) {
    selectedClient = client;
    selectedClientId = client.id!;
    selectedClientName =
        '${client.nom ?? ''} ${client.prenom ?? ''}'.trim();
    selectedClientEmail = client.email ?? '';
    selectedClientAddress = client.adresse ?? '';

    // Mettre à jour les contrôleurs de formulaire pour l'affichage
    clientNameController.text = selectedClientName;
    clientEmailController.text = selectedClientEmail;
    clientAddressController.text = selectedClientAddress;
  }

  // Effacer la sélection du client
  void clearSelectedClient() {
    selectedClient = null;
    selectedClientId = 0;
    selectedClientName = '';
    selectedClientEmail = '';
    selectedClientAddress = '';

    // Effacer les contrôleurs de formulaire
    clientNameController.clear();
    clientEmailController.clear();
    clientAddressController.clear();
  }

  /// Effacer toutes les données du formulaire
  void clearForm() {
    clearSelectedClient();
    invoiceItems.clear();
    notes = '';
    terms = '';
    generatedInvoiceNumber = '';
    invoiceNumberController.clear();
    // Régénérer une nouvelle référence
    initializeGeneratedReference();
  }

  /// Générer un PDF pour une facture
  Future<void> generatePDF(int invoiceId) async {
    try {
      isLoading = true;

      // Récupérer la facture depuis la liste ou depuis l'API si pas trouvée
      InvoiceModel invoice;
      try {
        invoice = invoices.firstWhere((i) => i.id == invoiceId);
      } catch (e) {
        // Si pas trouvée dans la liste (Bad state: No element), la charger depuis l'API
        try {
          invoice = await _invoiceService.getInvoiceById(invoiceId);
        } catch (apiError) {
          throw Exception(
            'Impossible de charger la facture. Veuillez réessayer.',
          );
        }
      }

      // Vérifier que la facture a des items
      if (invoice.items.isEmpty) {
        throw Exception(
          'Impossible de générer le PDF: la facture n\'a pas d\'articles',
        );
      }

      // Charger les données nécessaires
      final items =
          invoice.items
              .map(
                (item) => {
                  'designation': item.description,
                  'unite': item.unit ?? 'unité',
                  'quantite': item.quantity,
                  'prix_unitaire': item.unitPrice,
                  'montant_total': item.totalPrice,
                },
              )
              .toList();

      // Générer le PDF
      await PdfService().generateFacturePdf(
        facture: {
          'reference': invoice.invoiceNumber,
          'date_creation': invoice.invoiceDate,
          'date_echeance': invoice.dueDate,
          'montant_ht': invoice.subtotal,
          'tva': invoice.taxRate,
          'montant_tva': invoice.taxAmount,
          'total_ttc': invoice.totalAmount,
        },
        items: items,
        client: {
          'nom':
              invoice.clientName.isNotEmpty
                  ? (invoice.clientName.split(' ').isNotEmpty
                      ? invoice.clientName.split(' ').first
                      : '')
                  : '',
          'prenom':
              invoice.clientName.isNotEmpty &&
                      invoice.clientName.split(' ').length > 1
                  ? invoice.clientName.split(' ').sublist(1).join(' ')
                  : '',
          'nom_entreprise': invoice.clientName,
          'email': invoice.clientEmail,
          'contact': '',
          'adresse': invoice.clientAddress,
        },
        commercial: {
          'nom':
              invoice.commercialName.isNotEmpty
                  ? (invoice.commercialName.split(' ').isNotEmpty
                      ? invoice.commercialName.split(' ').first
                      : 'Commercial')
                  : 'Commercial',
          'prenom':
              invoice.commercialName.isNotEmpty &&
                      invoice.commercialName.split(' ').length > 1
                  ? invoice.commercialName.split(' ').sublist(1).join(' ')
                  : '',
          'email': '',
        },
      );

      errorHelperShowSnackbar?.call(
        'Succès',
        'PDF généré avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la génération du PDF: $e',
        tag: 'INVOICE_CONTROLLER',
        error: e,
        stackTrace: stackTrace,
      );
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de générer le PDF: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      rethrow;
    } finally {
      isLoading = false;
    }
  }

  // Charger une facture pour modification
  Future<void> loadInvoiceForEdit(int invoiceId) async {
    try {
      isLoading = true;
      final invoice = await _invoiceService.getInvoiceById(invoiceId);

      // Remplir le formulaire avec les données de la facture
      selectedClientId = invoice.clientId;
      selectedClientName = invoice.clientName;
      selectedClientEmail = invoice.clientEmail;
      selectedClientAddress = invoice.clientAddress;
      invoiceDate = invoice.invoiceDate;
      dueDate = invoice.dueDate;
      taxRate = invoice.taxRate;
      invoiceItems.clear();
      invoiceItems.addAll(invoice.items);
      notes = invoice.notes ?? '';
      terms = invoice.terms ?? '';

      notesController.text = invoice.notes ?? '';
      termsController.text = invoice.terms ?? '';
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', 'Impossible de charger la facture: $e');
    } finally {
      isLoading = false;
    }
  }

  // Modifier une facture
  Future<void> updateInvoice(int invoiceId, [BuildContext? context]) async {
    try {
      if (invoiceItems.isEmpty) {
        errorHelperShowSnackbar?.call('Erreur', 'Veuillez ajouter au moins un article');
        return;
      }

      isCreating = true;

      final user = AuthController.to.userAuth;
      if (user == null) return;

      final subtotal = invoiceItems.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );
      final taxAmount = subtotal * (taxRate / 100);
      final totalAmount = subtotal + taxAmount;

      final result = await _invoiceService.updateInvoice(
        invoiceId: invoiceId,
        data: {
          'date_facture': invoiceDate.toIso8601String().split('T')[0],
          'date_echeance': dueDate.toIso8601String().split('T')[0],
          'subtotal': subtotal,
          'tax_rate': taxRate,
          'tax_amount': taxAmount,
          'total_amount': totalAmount,
          'notes':
              notesController.text.trim().isEmpty
                  ? null
                  : notesController.text.trim(),
          'terms':
              termsController.text.trim().isEmpty
                  ? null
                  : termsController.text.trim(),
          'items': invoiceItems.map((item) => item.toJson()).toList(),
        },
      );

      if (result['success'] == true) {
        errorHelperShowSnackbar?.call(
          'Succès',
          'Facture modifiée avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        if (context != null && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        // Essayer de recharger la liste (mais ne pas faire échouer si ça échoue)
        try {
          await loadInvoices();
        } catch (e) {
          // Si le rechargement échoue, on ne fait rien car la facture a été mise à jour avec succès
          // L'utilisateur peut recharger manuellement si nécessaire
        }
      } else {
        errorHelperShowSnackbar?.call(
          'Erreur',
          result['message'] ?? 'Erreur lors de la modification',
        );
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Erreur lors de la modification de la facture: $e',
      );
    } finally {
      isCreating = false;
    }
  }
}
