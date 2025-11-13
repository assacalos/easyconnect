import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:easyconnect/Models/bon_commande_model.dart';
import 'package:easyconnect/services/bon_commande_service.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';

class BonCommandeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late int userId;
  final BonCommandeService _bonCommandeService = BonCommandeService();
  final ClientService _clientService = ClientService();

  final bonCommandes = <BonCommande>[].obs;
  final selectedClient = Rxn<Client>();
  final availableClients = <Client>[].obs;
  final isLoading = false.obs;
  final isLoadingClients = false.obs;
  final currentBonCommande = Rxn<BonCommande>();
  final items = <BonCommandeItem>[].obs;

  // Gestion des onglets
  late TabController tabController;
  final selectedStatus = Rxn<int>();

  // Statistiques
  final totalBonCommandes = 0.obs;
  final bonCommandesEnvoyes = 0.obs;
  final bonCommandesAcceptes = 0.obs;
  final bonCommandesRefuses = 0.obs;
  final bonCommandesLivres = 0.obs;
  final montantTotal = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    userId = int.parse(
      Get.find<AuthController>().userAuth.value!.id.toString(),
    );
    tabController = TabController(length: 5, vsync: this);
    tabController.addListener(_onTabChanged);
    loadBonCommandes();
    loadStats();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  void _onTabChanged() {
    if (tabController.indexIsChanging) {
      selectedStatus.value =
          tabController.index == 0 ? null : tabController.index;
    }
  }

  // Obtenir les bons de commande filtrés selon l'onglet sélectionné
  List<BonCommande> getFilteredBonCommandes() {
    if (selectedStatus.value == null) {
      return bonCommandes;
    }
    return bonCommandes
        .where((bonCommande) => bonCommande.status == selectedStatus.value)
        .toList();
  }

  Future<void> loadBonCommandes({int? status}) async {
    try {
      isLoading.value = true;
      final loadedBonCommandes = await _bonCommandeService.getBonCommandes(
        status: status,
      );
      bonCommandes.value = loadedBonCommandes;
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

  Future<void> loadStats() async {
    try {
      final stats = await _bonCommandeService.getBonCommandeStats();
      totalBonCommandes.value = stats['total'] ?? 0;
      bonCommandesEnvoyes.value = stats['envoyes'] ?? 0;
      bonCommandesAcceptes.value = stats['acceptes'] ?? 0;
      bonCommandesRefuses.value = stats['refuses'] ?? 0;
      bonCommandesLivres.value = stats['livres'] ?? 0;
      montantTotal.value = stats['montant_total'] ?? 0.0;
    } catch (e) {
      // Erreur silencieuse lors du chargement des statistiques
    }
  }

  Future<void> createBonCommande(Map<String, dynamic> data) async {
    try {
      // Vérifications
      if (selectedClient.value == null) {
        throw Exception('Aucun client sélectionné');
      }

      if (selectedClient.value!.id == null) {
        throw Exception(
          'L\'ID du client est manquant. Veuillez sélectionner un client valide.',
        );
      }

      if (items.isEmpty) {
        throw Exception('Aucun article ajouté au bon de commande');
      }

      isLoading.value = true;

      final clientId = selectedClient.value!.id!;

      final newBonCommande = BonCommande(
        clientId: clientId,
        reference: data['reference'],
        dateCreation: DateTime.now(),
        dateLivraisonPrevue: data['date_livraison_prevue'],
        adresseLivraison: data['adresse_livraison'],
        notes: data['notes'],
        items: items.toList(), // Convertir en liste
        remiseGlobale:
            data['remise_globale'] != null
                ? (data['remise_globale'] is double
                    ? data['remise_globale']
                    : double.tryParse(data['remise_globale'].toString()))
                : null,
        tva:
            data['tva'] != null
                ? (data['tva'] is double
                    ? data['tva']
                    : double.tryParse(data['tva'].toString()) ?? 20.0)
                : 20.0,
        conditions: data['conditions'],
        commercialId: userId,
      );

      await _bonCommandeService.createBonCommande(newBonCommande);

      // Effacer le formulaire
      clearForm();

      // Recharger la liste des bons de commande
      await loadBonCommandes();

      // Fermer le formulaire et afficher le message de succès
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
      // Extraire le message d'erreur
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

  Future<void> updateBonCommande(
    int bonCommandeId,
    Map<String, dynamic> data,
  ) async {
    try {
      isLoading.value = true;
      final bonCommandeToUpdate = bonCommandes.firstWhere(
        (b) => b.id == bonCommandeId,
      );
      final updatedBonCommande = BonCommande(
        id: bonCommandeId,
        clientId: bonCommandeToUpdate.clientId,
        reference: data['reference'] ?? bonCommandeToUpdate.reference,
        dateCreation: bonCommandeToUpdate.dateCreation,
        dateLivraisonPrevue:
            data['date_livraison_prevue'] ??
            bonCommandeToUpdate.dateLivraisonPrevue,
        adresseLivraison:
            data['adresse_livraison'] ?? bonCommandeToUpdate.adresseLivraison,
        notes: data['notes'] ?? bonCommandeToUpdate.notes,
        status: bonCommandeToUpdate.status,
        items: items.isEmpty ? bonCommandeToUpdate.items : items,
        remiseGlobale:
            data['remise_globale'] ?? bonCommandeToUpdate.remiseGlobale,
        tva: data['tva'] ?? bonCommandeToUpdate.tva,
        conditions: data['conditions'] ?? bonCommandeToUpdate.conditions,
        commercialId: bonCommandeToUpdate.commercialId,
      );

      await _bonCommandeService.updateBonCommande(updatedBonCommande);
      Get.back();
      Get.snackbar(
        'Succès',
        'Bon de commande mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
      loadBonCommandes();
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

  Future<void> deleteBonCommande(int bonCommandeId) async {
    try {
      isLoading.value = true;
      final success = await _bonCommandeService.deleteBonCommande(
        bonCommandeId,
      );
      if (success) {
        bonCommandes.removeWhere((b) => b.id == bonCommandeId);
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

  Future<void> submitBonCommande(int bonCommandeId) async {
    try {
      isLoading.value = true;
      final success = await _bonCommandeService.submitBonCommande(
        bonCommandeId,
      );
      if (success) {
        await loadBonCommandes();
        Get.snackbar(
          'Succès',
          'Bon de commande soumis avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la soumission');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de soumettre le bon de commande',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveBonCommande(int bonCommandeId) async {
    try {
      isLoading.value = true;
      final success = await _bonCommandeService.approveBonCommande(
        bonCommandeId,
      );
      if (success) {
        await loadBonCommandes();
        Get.snackbar(
          'Succès',
          'Bon de commande approuvé avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de l\'approbation');
      }
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

  Future<void> rejectBonCommande(int bonCommandeId, String commentaire) async {
    try {
      isLoading.value = true;
      final success = await _bonCommandeService.rejectBonCommande(
        bonCommandeId,
        commentaire,
      );
      if (success) {
        await loadBonCommandes();
        Get.snackbar(
          'Succès',
          'Bon de commande rejeté avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors du rejet');
      }
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

  Future<void> markAsDelivered(int bonCommandeId) async {
    try {
      isLoading.value = true;
      final success = await _bonCommandeService.markAsDelivered(bonCommandeId);
      if (success) {
        await loadBonCommandes();
        Get.snackbar(
          'Succès',
          'Bon de commande marqué comme livré',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors du marquage comme livré');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de marquer le bon de commande comme livré',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> generateInvoice(int bonCommandeId) async {
    try {
      isLoading.value = true;
      final success = await _bonCommandeService.generateInvoice(bonCommandeId);
      if (success) {
        await loadBonCommandes();
        Get.snackbar(
          'Succès',
          'Facture générée avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la génération de la facture');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de générer la facture',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Gestion des items
  void addItem(BonCommandeItem item) {
    items.add(item);
  }

  void removeItem(int index) {
    items.removeAt(index);
  }

  void updateItem(int index, BonCommandeItem item) {
    items[index] = item;
  }

  void clearItems() {
    items.clear();
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

  // Recherche de clients validés
  Future<void> searchClients(String query) async {
    try {
      if (availableClients.isEmpty) {
        await loadValidatedClients();
      }
      // La recherche sera implémentée dans l'interface utilisateur
    } catch (e) {
      // Erreur silencieuse lors de la recherche des clients
    }
  }

  void selectClient(Client client) {
    selectedClient.value = client;
  }

  void clearSelectedClient() {
    selectedClient.value = null;
  }

  /// Effacer toutes les données du formulaire
  void clearForm() {
    selectedClient.value = null;
    items.clear();
  }

  /// Générer un PDF pour un bon de commande
  Future<void> generatePDF(int bonCommandeId) async {
    try {
      isLoading.value = true;

      // Trouver le bon de commande
      final bonCommande = bonCommandes.firstWhere(
        (bc) => bc.id == bonCommandeId,
      );

      // Charger les données nécessaires
      final clients = await _clientService.getClients();
      final client = clients.firstWhere((c) => c.id == bonCommande.clientId);
      final items =
          bonCommande.items
              .map(
                (item) => {
                  'designation': item.designation,
                  'unite': item.unite,
                  'quantite': item.quantite,
                  'prix_unitaire': item.prixUnitaire,
                  'montant_total': item.montantTotal,
                },
              )
              .toList();

      // Générer le PDF
      await PdfService().generateBonCommandePdf(
        bonCommande: {
          'reference': bonCommande.reference,
          'date_creation': bonCommande.dateCreation,
          'montant_ht': bonCommande.montantHT,
          'tva': bonCommande.tva,
          'total_ttc': bonCommande.montantTTC,
        },
        items: items,
        fournisseur: {
          'nom': client.nom ?? '',
          'email': client.email,
          'contact': client.contact,
          'adresse': client.adresse,
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
