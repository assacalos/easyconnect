import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:easyconnect/services/devis_service.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';

class DevisController extends GetxController {
  int userId = int.parse(
    Get.find<AuthController>().userAuth.value!.id.toString(),
  );

  final DevisService _devisService = DevisService();
  final ClientService _clientService = ClientService();

  final devis = <Devis>[].obs;
  final selectedClient = Rxn<Client>();
  final isLoading = false.obs;
  final currentDevis = Rxn<Devis>();
  final items = <DevisItem>[].obs;

  // Statistiques
  final totalDevis = 0.obs;
  final devisEnvoyes = 0.obs;
  final devisAcceptes = 0.obs;
  final devisRefuses = 0.obs;
  final tauxConversion = 0.0.obs;
  final montantTotal = 0.0.obs;

  final clients = <Client>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDevis();
    loadStats();
  }

  Future<void> loadDevis({int? status}) async {
    try {
      isLoading.value = true;
      final loadedDevis = await _devisService.getDevis(status: status);
      devis.value = loadedDevis;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les devis',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadStats() async {
    try {
      final stats = await _devisService.getDevisStats();
      totalDevis.value = stats['total'] ?? 0;
      devisEnvoyes.value = stats['envoyes'] ?? 0;
      devisAcceptes.value = stats['acceptes'] ?? 0;
      devisRefuses.value = stats['refuses'] ?? 0;
      tauxConversion.value = stats['taux_conversion'] ?? 0.0;
      montantTotal.value = stats['montant_total'] ?? 0.0;
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
    }
  }

  Future<void> createDevis(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final newDevis = Devis(
        clientId: selectedClient.value!.id!,
        reference: data['reference'],
        dateCreation: DateTime.now(),
        dateValidite: data['date_validite'],
        notes: data['notes'],
        items: items,
        remiseGlobale: data['remise_globale'],
        tva: data['tva'],
        conditions: data['conditions'],
        commercialId: userId,
      );

      await _devisService.createDevis(newDevis);
      Get.back();
      Get.snackbar(
        'Succès',
        'Devis créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
      loadDevis();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer le devis',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateDevis(int devisId, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final devisToUpdate = devis.firstWhere((d) => d.id == devisId);
      final updatedDevis = Devis(
        id: devisId,
        clientId: devisToUpdate.clientId,
        reference: data['reference'] ?? devisToUpdate.reference,
        dateCreation: devisToUpdate.dateCreation,
        dateValidite: data['date_validite'] ?? devisToUpdate.dateValidite,
        notes: data['notes'] ?? devisToUpdate.notes,
        status: devisToUpdate.status,
        items: items.isEmpty ? devisToUpdate.items : items,
        remiseGlobale: data['remise_globale'] ?? devisToUpdate.remiseGlobale,
        tva: data['tva'] ?? devisToUpdate.tva,
        conditions: data['conditions'] ?? devisToUpdate.conditions,
        commercialId: devisToUpdate.commercialId,
      );

      await _devisService.updateDevis(updatedDevis);
      Get.back();
      Get.snackbar(
        'Succès',
        'Devis mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
      loadDevis();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le devis',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteDevis(int devisId) async {
    try {
      isLoading.value = true;
      final success = await _devisService.deleteDevis(devisId);
      if (success) {
        devis.removeWhere((d) => d.id == devisId);
        Get.snackbar(
          'Succès',
          'Devis supprimé avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le devis',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendDevis(int devisId) async {
    try {
      isLoading.value = true;
      final success = await _devisService.sendDevis(devisId);
      if (success) {
        await loadDevis();
        Get.snackbar(
          'Succès',
          'Devis envoyé avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de l\'envoi');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'envoyer le devis',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> acceptDevis(int devisId) async {
    try {
      isLoading.value = true;
      final success = await _devisService.acceptDevis(devisId);
      if (success) {
        await loadDevis();
        Get.snackbar(
          'Succès',
          'Devis accepté avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de l\'acceptation');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'accepter le devis',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectDevis(int devisId, String commentaire) async {
    try {
      isLoading.value = true;
      final success = await _devisService.rejectDevis(devisId, commentaire);
      if (success) {
        await loadDevis();
        Get.snackbar(
          'Succès',
          'Devis rejeté avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors du rejet');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter le devis',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> generatePDF(int devisId) async {
    try {
      isLoading.value = true;
      final pdfUrl = await _devisService.generatePDF(devisId);
      // Ouvrir le PDF ou le télécharger
      // TODO: Implémenter l'ouverture ou le téléchargement du PDF
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de générer le PDF',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Gestion des items
  void addItem(DevisItem item) {
    items.add(item);
  }

  void removeItem(int index) {
    items.removeAt(index);
  }

  void updateItem(int index, DevisItem item) {
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
