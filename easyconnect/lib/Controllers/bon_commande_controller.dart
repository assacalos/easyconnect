import 'package:get/get.dart';
import 'package:easyconnect/Models/bon_commande_model.dart';
import 'package:easyconnect/services/bon_commande_service.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';

class BonCommandeController extends GetxController {
  late int userId;
  final BonCommandeService _bonCommandeService = BonCommandeService();
  final ClientService _clientService = ClientService();

  final bonCommandes = <BonCommande>[].obs;
  final selectedClient = Rxn<Client>();
  final isLoading = false.obs;
  final currentBonCommande = Rxn<BonCommande>();
  final items = <BonCommandeItem>[].obs;

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
    loadBonCommandes();
    loadStats();
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
      print('Erreur lors du chargement des statistiques: $e');
    }
  }

  Future<void> createBonCommande(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final newBonCommande = BonCommande(
        clientId: selectedClient.value!.id!,
        reference: data['reference'],
        dateCreation: DateTime.now(),
        dateLivraisonPrevue: data['date_livraison_prevue'],
        adresseLivraison: data['adresse_livraison'],
        notes: data['notes'],
        items: items,
        remiseGlobale: data['remise_globale'],
        tva: data['tva'],
        conditions: data['conditions'],
        commercialId: userId,
      );

      await _bonCommandeService.createBonCommande(newBonCommande);
      Get.back();
      Get.snackbar(
        'Succès',
        'Bon de commande créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
      loadBonCommandes();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer le bon de commande',
        snackPosition: SnackPosition.BOTTOM,
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

  // Sélection du client
  Future<void> searchClients(String query) async {
    try {
      final clients = await _clientService.getClients();
      // TODO: Implémenter la recherche de clients
    } catch (e) {
      print('Erreur lors de la recherche des clients: $e');
    }
  }

  void selectClient(Client client) {
    selectedClient.value = client;
  }

  void clearSelectedClient() {
    selectedClient.value = null;
  }
}
