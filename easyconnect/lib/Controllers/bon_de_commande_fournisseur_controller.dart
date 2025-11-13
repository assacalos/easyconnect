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
    loadClients();
    loadSuppliers();
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
    if (selectedStatus.value == null) {
      return bonDeCommandes;
    }
    return bonDeCommandes
        .where((bc) => bc.statut == selectedStatus.value)
        .toList();
  }

  Future<void> loadBonDeCommandes({String? status}) async {
    try {
      isLoading.value = true;
      final loadedBonDeCommandes = await _service.getBonDeCommandes();
      bonDeCommandes.value = loadedBonDeCommandes;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les bons de commande',
        snackPosition: SnackPosition.BOTTOM,
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

  Future<void> createBonDeCommande(Map<String, dynamic> data) async {
    try {
      if (selectedClient.value == null && selectedSupplier.value == null) {
        throw Exception('Veuillez sélectionner un client ou un fournisseur');
      }

      if (items.isEmpty) {
        throw Exception('Aucun article ajouté au bon de commande');
      }

      isLoading.value = true;

      final newBonDeCommande = BonDeCommande(
        clientId: selectedClient.value?.id,
        fournisseurId: selectedSupplier.value?.id,
        numeroCommande: data['numero_commande'],
        dateCommande: data['date_commande'] ?? DateTime.now(),
        dateLivraisonPrevue: data['date_livraison_prevue'],
        description: data['description'],
        statut: 'en_attente',
        commentaire: data['commentaire'],
        conditionsPaiement: data['conditions_paiement'],
        delaiLivraison: data['delai_livraison'],
        items: items.toList(),
      );

      await _service.createBonDeCommande(newBonDeCommande);

      clearForm();
      await loadBonDeCommandes();

      Get.back();
      Get.snackbar(
        'Succès',
        'Bon de commande créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
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
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateBonDeCommande(
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
        dateLivraisonPrevue:
            data['date_livraison_prevue'] ??
            bonDeCommandeToUpdate.dateLivraisonPrevue,
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
      Get.back();
      Get.snackbar(
        'Succès',
        'Bon de commande mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
      loadBonDeCommandes();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le bon de commande',
        snackPosition: SnackPosition.BOTTOM,
      );
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
      final bonDeCommande = bonDeCommandes.firstWhere(
        (b) => b.id == bonDeCommandeId,
      );
      final updated = BonDeCommande(
        id: bonDeCommande.id,
        clientId: bonDeCommande.clientId,
        fournisseurId: bonDeCommande.fournisseurId,
        numeroCommande: bonDeCommande.numeroCommande,
        dateCommande: bonDeCommande.dateCommande,
        dateLivraisonPrevue: bonDeCommande.dateLivraisonPrevue,
        description: bonDeCommande.description,
        statut: 'valide',
        commentaire: bonDeCommande.commentaire,
        conditionsPaiement: bonDeCommande.conditionsPaiement,
        delaiLivraison: bonDeCommande.delaiLivraison,
        items: bonDeCommande.items,
      );

      await _service.updateBonDeCommande(bonDeCommandeId, updated);
      await loadBonDeCommandes();
      Get.snackbar(
        'Succès',
        'Bon de commande approuvé avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'approuver le bon de commande',
        snackPosition: SnackPosition.BOTTOM,
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
      final bonDeCommande = bonDeCommandes.firstWhere(
        (b) => b.id == bonDeCommandeId,
      );
      final updated = BonDeCommande(
        id: bonDeCommande.id,
        clientId: bonDeCommande.clientId,
        fournisseurId: bonDeCommande.fournisseurId,
        numeroCommande: bonDeCommande.numeroCommande,
        dateCommande: bonDeCommande.dateCommande,
        dateLivraisonPrevue: bonDeCommande.dateLivraisonPrevue,
        description: bonDeCommande.description,
        statut: 'rejete',
        commentaire: commentaire,
        conditionsPaiement: bonDeCommande.conditionsPaiement,
        delaiLivraison: bonDeCommande.delaiLivraison,
        items: bonDeCommande.items,
      );

      await _service.updateBonDeCommande(bonDeCommandeId, updated);
      await loadBonDeCommandes();
      Get.snackbar(
        'Succès',
        'Bon de commande rejeté avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter le bon de commande',
        snackPosition: SnackPosition.BOTTOM,
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
