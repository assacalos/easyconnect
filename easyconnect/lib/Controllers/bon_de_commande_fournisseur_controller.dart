import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:easyconnect/Models/bon_de_commande_fournisseur_model.dart';
import 'package:easyconnect/services/bon_de_commande_fournisseur_service.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/Models/supplier_model.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/services/supplier_service.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/reference_generator.dart';

class BonDeCommandeFournisseurController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late int userId;
  final BonDeCommandeFournisseurService _service =
      BonDeCommandeFournisseurService();
  final ClientService _clientService = ClientService();
  final SupplierService _supplierService = SupplierService();

  final bonDeCommandes = <BonDeCommande>[].obs;
  final selectedClient = Rxn<Client>();
  final selectedSupplier = Rxn<Supplier>();
  final availableClients = <Client>[].obs;
  final availableSuppliers = <Supplier>[].obs;
  final isLoading = false.obs;
  final isLoadingClients = false.obs;
  final isLoadingSuppliers = false.obs;
  final currentBonDeCommande = Rxn<BonDeCommande>();
  final items = <BonDeCommandeItem>[].obs;

  // Référence générée automatiquement
  final generatedNumeroCommande = ''.obs;

  // Gestion des onglets
  late TabController tabController;
  final selectedStatus = Rxn<String>();

  // Statistiques
  final totalBonDeCommandes = 0.obs;
  final bonDeCommandesEnAttente = 0.obs;
  final bonDeCommandesValides = 0.obs;
  final bonDeCommandesRejetes = 0.obs;
  final bonDeCommandesLivres = 0.obs;
  final montantTotal = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    userId = int.parse(
      Get.find<AuthController>().userAuth.value!.id.toString(),
    );
    tabController = TabController(length: 5, vsync: this);
    tabController.addListener(_onTabChanged);
    loadBonDeCommandes();
    // Ne charger que les fournisseurs, pas les clients
    loadSuppliers();
    // Générer automatiquement le numéro de commande au démarrage
    initializeGeneratedNumeroCommande();
  }

  // Générer automatiquement le numéro de commande fournisseur
  Future<String> generateNumeroCommande() async {
    // Recharger les bons de commande pour avoir le comptage à jour
    await loadBonDeCommandes();

    // Extraire tous les numéros de commande existants
    final existingNumbers =
        bonDeCommandes
            .map((bc) => bc.numeroCommande)
            .where((num) => num.isNotEmpty)
            .toList();

    // Générer avec incrément
    return ReferenceGenerator.generateReferenceWithIncrement(
      'BCF',
      existingNumbers,
    );
  }

  // Initialiser le numéro de commande généré
  Future<void> initializeGeneratedNumeroCommande() async {
    if (generatedNumeroCommande.value.isEmpty) {
      generatedNumeroCommande.value = await generateNumeroCommande();
    }
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  void _onTabChanged() {
    if (tabController.indexIsChanging) {
      selectedStatus.value =
          tabController.index == 0
              ? null
              : _getStatusFromIndex(tabController.index);
    }
  }

  String _getStatusFromIndex(int index) {
    switch (index) {
      case 1:
        return 'en_attente';
      case 2:
        return 'valide';
      case 3:
        return 'rejete';
      case 4:
        return 'livre';
      default:
        return '';
    }
  }

  List<BonDeCommande> getFilteredBonDeCommandes() {
    // Si aucun statut sélectionné, retourner tous les bons de commande
    if (selectedStatus.value == null || selectedStatus.value == 'all') {
      return bonDeCommandes;
    }

    // Filtrer par statut (comparaison insensible à la casse)
    final statusLower = selectedStatus.value!.toLowerCase().trim();
    return bonDeCommandes.where((bc) {
      final bcStatus = bc.statut.toLowerCase().trim();
      // Gérer les différentes variantes de statuts
      switch (statusLower) {
        case 'en_attente':
        case 'pending':
          return bcStatus == 'en_attente' || bcStatus == 'pending';
        case 'valide':
        case 'approved':
        case 'validated':
          return bcStatus == 'valide' ||
              bcStatus == 'approved' ||
              bcStatus == 'validated';
        case 'rejete':
        case 'rejected':
          return bcStatus == 'rejete' || bcStatus == 'rejected';
        default:
          return bcStatus == statusLower;
      }
    }).toList();
  }

  Future<void> loadBonDeCommandes({String? status}) async {
    try {
      isLoading.value = true;
      print('🔄 Chargement des bons de commande fournisseur...');

      // Mettre à jour le statut sélectionné
      if (status != null) {
        selectedStatus.value = status;
      } else {
        selectedStatus.value = 'all';
      }

      // Charger tous les bons de commande (le filtrage se fera côté client)
      final loadedBonDeCommandes = await _service.getBonDeCommandes();
      bonDeCommandes.value = loadedBonDeCommandes;
    } catch (e) {
      bonDeCommandes.value = [];
      Get.snackbar(
        'Erreur',
        'Impossible de charger les bons de commande: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadClients() async {
    try {
      isLoadingClients.value = true;
      final clients = await _clientService.getClients(status: 1);
      availableClients.value = clients;
    } catch (e) {
      // Erreur silencieuse
    } finally {
      isLoadingClients.value = false;
    }
  }

  Future<void> loadSuppliers() async {
    try {
      isLoadingSuppliers.value = true;
      final suppliers = await _supplierService.getSuppliers();
      availableSuppliers.value = suppliers;
    } catch (e) {
      // Erreur silencieuse
    } finally {
      isLoadingSuppliers.value = false;
    }
  }

  Future<bool> createBonDeCommande(Map<String, dynamic> data) async {
    try {
      if (selectedSupplier.value == null) {
        throw Exception('Veuillez sélectionner un fournisseur');
      }

      if (selectedSupplier.value!.id == null) {
        throw Exception(
          'L\'ID du fournisseur est manquant. Veuillez sélectionner un fournisseur valide.',
        );
      }

      if (items.isEmpty) {
        throw Exception('Aucun article ajouté au bon de commande');
      }

      // Valider les items
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        if (item.designation.isEmpty) {
          throw Exception('La désignation de l\'article ${i + 1} est requise');
        }
        if (item.quantite <= 0) {
          throw Exception(
            'La quantité de l\'article ${i + 1} doit être supérieure à 0',
          );
        }
        if (item.prixUnitaire <= 0) {
          throw Exception(
            'Le prix unitaire de l\'article ${i + 1} doit être supérieur à 0',
          );
        }
      }

      isLoading.value = true;

      // Utiliser le numéro généré si disponible, sinon celui fourni
      final numeroCommande =
          generatedNumeroCommande.value.isNotEmpty
              ? generatedNumeroCommande.value
              : data['numero_commande'];

      final newBonDeCommande = BonDeCommande(
        clientId: null, // Pas de client pour un bon de commande fournisseur
        fournisseurId: selectedSupplier.value!.id!,
        numeroCommande: numeroCommande,
        dateCommande: data['date_commande'] ?? DateTime.now(),
        description: data['description'],
        statut: 'en_attente',
        commentaire: data['commentaire'],
        conditionsPaiement: data['conditions_paiement'],
        delaiLivraison: data['delai_livraison'],
        items: items.toList(),
      );

      await _service.createBonDeCommande(newBonDeCommande);

      // Réinitialiser le formulaire
      clearForm();

      // Recharger la liste des bons de commande
      await loadBonDeCommandes();

      // Afficher le message de succès
      Get.snackbar(
        'Succès',
        'Bon de commande créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return true;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      Get.snackbar(
        'Erreur',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateBonDeCommande(
    int bonDeCommandeId,
    Map<String, dynamic> data,
  ) async {
    try {
      isLoading.value = true;
      final bonDeCommandeToUpdate = bonDeCommandes.firstWhere(
        (b) => b.id == bonDeCommandeId,
      );
      final updatedBonDeCommande = BonDeCommande(
        id: bonDeCommandeId,
        clientId: data['client_id'] ?? bonDeCommandeToUpdate.clientId,
        fournisseurId:
            data['fournisseur_id'] ?? bonDeCommandeToUpdate.fournisseurId,
        numeroCommande:
            data['numero_commande'] ?? bonDeCommandeToUpdate.numeroCommande,
        dateCommande: bonDeCommandeToUpdate.dateCommande,
        description: data['description'] ?? bonDeCommandeToUpdate.description,
        statut: bonDeCommandeToUpdate.statut,
        commentaire: data['commentaire'] ?? bonDeCommandeToUpdate.commentaire,
        conditionsPaiement:
            data['conditions_paiement'] ??
            bonDeCommandeToUpdate.conditionsPaiement,
        delaiLivraison:
            data['delai_livraison'] ?? bonDeCommandeToUpdate.delaiLivraison,
        items: items.isEmpty ? bonDeCommandeToUpdate.items : items,
      );

      await _service.updateBonDeCommande(bonDeCommandeId, updatedBonDeCommande);
      Get.snackbar(
        'Succès',
        'Bon de commande mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
      loadBonDeCommandes();
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le bon de commande',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteBonDeCommande(int bonDeCommandeId) async {
    try {
      isLoading.value = true;
      final success = await _service.deleteBonDeCommande(bonDeCommandeId);
      if (success) {
        bonDeCommandes.removeWhere((b) => b.id == bonDeCommandeId);
        Get.snackbar(
          'Succès',
          'Bon de commande supprimé avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le bon de commande',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveBonDeCommande(int bonDeCommandeId) async {
    try {
      isLoading.value = true;
      final success = await _service.validateBonDeCommande(bonDeCommandeId);

      if (success) {
        await loadBonDeCommandes();
        Get.snackbar(
          'Succès',
          'Bon de commande approuvé avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Erreur lors de l\'approbation');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'approuver le bon de commande: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectBonDeCommande(
    int bonDeCommandeId,
    String commentaire,
  ) async {
    try {
      isLoading.value = true;
      final success = await _service.rejectBonDeCommande(
        bonDeCommandeId,
        commentaire,
      );

      if (success) {
        await loadBonDeCommandes();
        Get.snackbar(
          'Succès',
          'Bon de commande rejeté avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Erreur lors du rejet');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter le bon de commande: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Gestion des items
  void addItem(BonDeCommandeItem item) {
    items.add(item);
  }

  void removeItem(int index) {
    items.removeAt(index);
  }

  void updateItem(int index, BonDeCommandeItem item) {
    items[index] = item;
  }

  void clearItems() {
    items.clear();
  }

  void selectClient(Client? client) {
    selectedClient.value = client;
  }

  void selectSupplier(Supplier? supplier) {
    selectedSupplier.value = supplier;
  }

  void clearForm() {
    selectedClient.value = null;
    selectedSupplier.value = null;
    items.clear();
    generatedNumeroCommande.value = '';
    // Régénérer un nouveau numéro de commande
    initializeGeneratedNumeroCommande();
  }

  Future<void> generatePDF(int bonDeCommandeId) async {
    try {
      isLoading.value = true;

      final bonDeCommande = bonDeCommandes.firstWhere(
        (bc) => bc.id == bonDeCommandeId,
      );

      final itemsData =
          bonDeCommande.items
              .map(
                (item) => {
                  'ref': item.ref ?? '',
                  'designation': item.designation,
                  'quantite': item.quantite,
                  'prix_unitaire': item.prixUnitaire,
                  'montant_total': item.montantTotal,
                },
              )
              .toList();

      await PdfService().generateBonCommandePdf(
        bonCommande: {
          'reference': bonDeCommande.numeroCommande,
          'date_creation': bonDeCommande.dateCommande,
          'montant_ht': bonDeCommande.montantTotalCalcule,
          'tva': 0.0,
          'total_ttc': bonDeCommande.montantTotalCalcule,
        },
        items: itemsData,
        fournisseur: {
          'nom': selectedSupplier.value?.nom ?? 'N/A',
          'email': selectedSupplier.value?.email ?? '',
          'contact': selectedSupplier.value?.telephone ?? '',
          'adresse': selectedSupplier.value?.adresse ?? '',
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
