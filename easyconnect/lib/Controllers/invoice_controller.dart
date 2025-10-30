import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/invoice_model.dart';
import 'package:easyconnect/services/invoice_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/services/pdf_service.dart';

class InvoiceController extends GetxController {
  final InvoiceService _invoiceService = InvoiceService.to;
  final AuthController _authController = Get.find<AuthController>();
  final ClientService _clientService = ClientService();

  // Variables observables
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<InvoiceModel> invoices = <InvoiceModel>[].obs;
  final RxList<InvoiceModel> pendingInvoices = <InvoiceModel>[].obs;
  final Rx<InvoiceStats?> invoiceStats = Rx<InvoiceStats?>(null);
  final RxList<InvoiceTemplate> templates = <InvoiceTemplate>[].obs;

  // Variables pour la gestion des clients validés
  final RxList<Client> availableClients = <Client>[].obs;
  final RxBool isLoadingClients = false.obs;
  final Rx<Client?> selectedClient = Rx<Client?>(null);

  // Variables pour le formulaire de création
  final RxInt selectedClientId = 0.obs;
  final RxString selectedClientName = ''.obs;
  final RxString selectedClientEmail = ''.obs;
  final RxString selectedClientAddress = ''.obs;
  final RxList<InvoiceItem> invoiceItems = <InvoiceItem>[].obs;
  final RxDouble taxRate = 20.0.obs; // Taux de TVA par défaut
  final RxString notes = ''.obs;
  final RxString terms = ''.obs;
  final Rx<DateTime> invoiceDate = DateTime.now().obs;
  final Rx<DateTime> dueDate = DateTime.now().add(const Duration(days: 30)).obs;

  // Contrôleurs de formulaire
  final TextEditingController clientNameController = TextEditingController();
  final TextEditingController clientEmailController = TextEditingController();
  final TextEditingController clientAddressController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController termsController = TextEditingController();

  // Variables pour les filtres
  final RxString selectedStatus = 'all'.obs;
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadInvoices();
    loadTemplates();
  }

  @override
  void onClose() {
    clientNameController.dispose();
    clientEmailController.dispose();
    clientAddressController.dispose();
    notesController.dispose();
    termsController.dispose();
    super.onClose();
  }

  // Charger les factures
  Future<void> loadInvoices() async {
    try {
      isLoading.value = true;

      final user = _authController.userAuth.value;
      if (user == null) return;

      List<InvoiceModel> invoiceList;

      if (user.role == 1) {
        // Patron
        invoiceList = await _invoiceService.getAllInvoices(
          startDate: startDate.value,
          endDate: endDate.value,
          status: selectedStatus.value != 'all' ? selectedStatus.value : null,
        );
      } else {
        // Comptable
        invoiceList = await _invoiceService.getCommercialInvoices(
          commercialId: user.id,
          startDate: startDate.value,
          endDate: endDate.value,
          status: selectedStatus.value != 'all' ? selectedStatus.value : null,
        );
      }

      // Filtrer par recherche
      if (searchQuery.value.isNotEmpty) {
        invoiceList =
            invoiceList
                .where(
                  (invoice) =>
                      invoice.invoiceNumber.toLowerCase().contains(
                        searchQuery.value.toLowerCase(),
                      ) ||
                      invoice.clientName.toLowerCase().contains(
                        searchQuery.value.toLowerCase(),
                      ),
                )
                .toList();
      }

      // Trier les factures par statut et date
      invoiceList.sort((a, b) {
        // D'abord par statut (en_attente en premier, puis valide, puis rejete)
        final statusOrder = {'en_attente': 0, 'valide': 1, 'rejete': 2};

        final statusA = statusOrder[a.status] ?? 999;
        final statusB = statusOrder[b.status] ?? 999;

        if (statusA != statusB) {
          return statusA.compareTo(statusB);
        }

        // Ensuite par date de création (plus récent en premier)
        return b.createdAt.compareTo(a.createdAt);
      });

      invoices.value = invoiceList;

      // Charger les statistiques
      await loadInvoiceStats();
    } catch (e) {
      print('Erreur lors du chargement des factures: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les factures',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Charger les factures en attente (pour le patron)
  Future<void> loadPendingInvoices() async {
    try {
      final user = _authController.userAuth.value;
      if (user == null || user.role != 1) return; // Seulement pour le patron

      final pendingList = await _invoiceService.getPendingInvoices();
      pendingInvoices.value = pendingList;
    } catch (e) {
      print('Erreur lors du chargement des factures en attente: $e');
    }
  }

  // Charger les statistiques
  Future<void> loadInvoiceStats() async {
    try {
      final user = _authController.userAuth.value;
      if (user == null) return;

      final stats = await _invoiceService.getInvoiceStats(
        startDate: startDate.value,
        endDate: endDate.value,
        commercialId: user.role != 1 ? user.id : null,
      );
      invoiceStats.value = stats;
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
    }
  }

  // Charger les modèles
  Future<void> loadTemplates() async {
    try {
      final templatesList = await _invoiceService.getInvoiceTemplates();
      templates.value = templatesList;
    } catch (e) {
      print('Erreur lors du chargement des modèles: $e');
    }
  }

  // Créer une facture
  Future<void> createInvoice() async {
    try {
      isCreating.value = true;

      final user = _authController.userAuth.value;
      if (user == null) {
        Get.snackbar('Erreur', 'Utilisateur non connecté');
        return;
      }

      // Vérifier qu'un client validé est sélectionné
      if (selectedClient.value == null) {
        Get.snackbar(
          'Erreur',
          'Veuillez sélectionner un client validé',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Vérifier que le client sélectionné est bien validé
      if (selectedClient.value!.status != 1) {
        Get.snackbar(
          'Erreur',
          'Seuls les clients validés peuvent être sélectionnés',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (invoiceItems.isEmpty) {
        Get.snackbar('Erreur', 'Veuillez ajouter au moins un article');
        return;
      }

      final result = await _invoiceService.createInvoice(
        clientId: selectedClient.value!.id!,
        clientName:
            '${selectedClient.value!.nom ?? ''} ${selectedClient.value!.prenom ?? ''}'
                .trim(),
        clientEmail: selectedClient.value!.email ?? '',
        clientAddress: selectedClient.value!.adresse ?? '',
        commercialId: user.id,
        commercialName: user.nom ?? 'Comptable',
        invoiceDate: invoiceDate.value,
        dueDate: dueDate.value,
        items: invoiceItems,
        taxRate: taxRate.value,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
        terms:
            termsController.text.trim().isEmpty
                ? null
                : termsController.text.trim(),
      );

      if (result['success'] == true) {
        // Effacer le formulaire
        clearForm();

        // Recharger les factures
        await loadInvoices();

        // Fermer le formulaire et afficher le message de succès
        Get.back();
        Get.snackbar(
          'Succès',
          'Facture créée avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de la création',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la création de la facture: $e');
      print('Erreur createInvoice: $e');
    } finally {
      isCreating.value = false;
    }
  }

  // Soumettre une facture au patron
  Future<void> submitInvoiceToPatron(int invoiceId) async {
    try {
      isSubmitting.value = true;

      final result = await _invoiceService.submitInvoiceToPatron(invoiceId);

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Facture soumise au patron');
        await loadInvoices();
        await loadPendingInvoices();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de la soumission',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la soumission: $e');
      print('Erreur submitInvoiceToPatron: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  // Approuver une facture (pour le patron)
  Future<void> approveInvoice(int invoiceId, {String? comments}) async {
    try {
      final result = await _invoiceService.approveInvoice(
        invoiceId: invoiceId,
        comments: comments,
      );

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Facture approuvée');
        await loadInvoices();
        await loadPendingInvoices();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de l\'approbation',
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de l\'approbation: $e');
      print('Erreur approveInvoice: $e');
    }
  }

  // Rejeter une facture (pour le patron)
  Future<void> rejectInvoice(int invoiceId, String reason) async {
    try {
      final result = await _invoiceService.rejectInvoice(
        invoiceId: invoiceId,
        reason: reason,
      );

      if (result['success'] == true) {
        Get.snackbar('Succès', 'Facture rejetée');
        await loadInvoices();
        await loadPendingInvoices();
      } else {
        Get.snackbar('Erreur', result['message'] ?? 'Erreur lors du rejet');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors du rejet: $e');
      print('Erreur rejectInvoice: $e');
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
  double get taxAmount => subtotal * (taxRate.value / 100);

  // Calculer le total
  double get totalAmount => subtotal + taxAmount;

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

  // Réinitialiser le formulaire
  void resetForm() {
    selectedClientId.value = 0;
    selectedClientName.value = '';
    selectedClientEmail.value = '';
    selectedClientAddress.value = '';
    invoiceItems.clear();
    taxRate.value = 20.0;
    notes.value = '';
    terms.value = '';
    invoiceDate.value = DateTime.now();
    dueDate.value = DateTime.now().add(const Duration(days: 30));

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
    selectedStatus.value = status ?? 'all';
    startDate.value = start;
    endDate.value = end;
    searchQuery.value = search ?? '';
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

    invoices.value = sortedInvoices;
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
    final user = _authController.userAuth.value;
    return user?.role == 1; // Patron
  }

  // Vérifier si l'utilisateur peut soumettre
  bool get canSubmitInvoices {
    final user = _authController.userAuth.value;
    return user?.role == 3; // Comptable
  }

  // Chargement des clients validés
  Future<void> loadValidatedClients() async {
    try {
      isLoadingClients.value = true;
      final clients = await _clientService.getClients(
        status: 1,
      ); // Status 1 = Validé
      availableClients.value = clients;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les clients validés',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingClients.value = false;
    }
  }

  // Sélection d'un client
  void selectClientForInvoice(Client client) {
    selectedClient.value = client;
    selectedClientId.value = client.id!;
    selectedClientName.value =
        '${client.nom ?? ''} ${client.prenom ?? ''}'.trim();
    selectedClientEmail.value = client.email ?? '';
    selectedClientAddress.value = client.adresse ?? '';

    // Mettre à jour les contrôleurs de formulaire pour l'affichage
    clientNameController.text = selectedClientName.value;
    clientEmailController.text = selectedClientEmail.value;
    clientAddressController.text = selectedClientAddress.value;
  }

  // Effacer la sélection du client
  void clearSelectedClient() {
    selectedClient.value = null;
    selectedClientId.value = 0;
    selectedClientName.value = '';
    selectedClientEmail.value = '';
    selectedClientAddress.value = '';

    // Effacer les contrôleurs de formulaire
    clientNameController.clear();
    clientEmailController.clear();
    clientAddressController.clear();
  }

  /// Effacer toutes les données du formulaire
  void clearForm() {
    clearSelectedClient();
    invoiceItems.clear();
    notes.value = '';
    terms.value = '';
  }

  /// Générer un PDF pour une facture
  Future<void> generatePDF(int invoiceId) async {
    try {
      isLoading.value = true;

      // Trouver la facture
      final invoice = invoices.firstWhere((i) => i.id == invoiceId);

      // Charger les données nécessaires
      final items =
          invoice.items
              .map(
                (item) => {
                  'designation': item.description,
                  'unite': 'unité',
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
          'date_creation': invoice.createdAt,
          'montant_ht': invoice.subtotal,
          'tva': invoice.taxRate,
          'total_ttc': invoice.totalAmount,
        },
        items: items,
        client: {
          'nom': invoice.clientName,
          'prenom': '',
          'nom_entreprise': invoice.clientName,
          'email': invoice.clientEmail,
          'contact': '',
          'adresse': invoice.clientAddress,
        },
        commercial: {'nom': 'Commercial', 'prenom': '', 'email': ''},
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
