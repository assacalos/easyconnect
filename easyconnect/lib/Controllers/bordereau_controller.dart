import 'package:get/get.dart';
import 'package:easyconnect/Models/bordereau_model.dart';
import 'package:easyconnect/services/bordereau_service.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';

class BordereauController extends GetxController {
  late int userId;
  final BordereauService _bordereauService = BordereauService();
  final ClientService _clientService = ClientService();

  final bordereaux = <Bordereau>[].obs;
  final selectedClient = Rxn<Client>();
  final isLoading = false.obs;
  final currentBordereau = Rxn<Bordereau>();
  final items = <BordereauItem>[].obs;

  // Statistiques
  final totalBordereaux = 0.obs;
  final bordereauEnvoyes = 0.obs;
  final bordereauAcceptes = 0.obs;
  final bordereauRefuses = 0.obs;
  final montantTotal = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    userId = int.parse(
      Get.find<AuthController>().userAuth.value!.id.toString(),
    );
    loadBordereaux();
    loadStats();
  }

  Future<void> loadBordereaux({int? status}) async {
    try {
      isLoading.value = true;
      final loadedBordereaux = await _bordereauService.getBordereaux(
        status: status,
      );
      bordereaux.value = loadedBordereaux;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les bordereaux',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadStats() async {
    try {
      final stats = await _bordereauService.getBordereauStats();
      totalBordereaux.value = stats['total'] ?? 0;
      bordereauEnvoyes.value = stats['envoyes'] ?? 0;
      bordereauAcceptes.value = stats['acceptes'] ?? 0;
      bordereauRefuses.value = stats['refuses'] ?? 0;
      montantTotal.value = stats['montant_total'] ?? 0.0;
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
    }
  }

  Future<void> createBordereau(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final newBordereau = Bordereau(
        clientId: selectedClient.value!.id!,
        reference: data['reference'],
        dateCreation: DateTime.now(),
        notes: data['notes'],
        items: items,
        remiseGlobale: data['remise_globale'],
        tva: data['tva'],
        conditions: data['conditions'],
        commercialId: userId,
      );

      await _bordereauService.createBordereau(newBordereau);
      Get.back();
      Get.snackbar(
        'Succès',
        'Bordereau créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
      loadBordereaux();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer le bordereau',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateBordereau(
    int bordereauId,
    Map<String, dynamic> data,
  ) async {
    try {
      isLoading.value = true;
      final bordereauToUpdate = bordereaux.firstWhere(
        (b) => b.id == bordereauId,
      );
      final updatedBordereau = Bordereau(
        id: bordereauId,
        clientId: bordereauToUpdate.clientId,
        reference: data['reference'] ?? bordereauToUpdate.reference,
        dateCreation: bordereauToUpdate.dateCreation,
        notes: data['notes'] ?? bordereauToUpdate.notes,
        status: bordereauToUpdate.status,
        items: items.isEmpty ? bordereauToUpdate.items : items,
        remiseGlobale:
            data['remise_globale'] ?? bordereauToUpdate.remiseGlobale,
        tva: data['tva'] ?? bordereauToUpdate.tva,
        conditions: data['conditions'] ?? bordereauToUpdate.conditions,
        commercialId: bordereauToUpdate.commercialId,
      );

      await _bordereauService.updateBordereau(updatedBordereau);
      Get.back();
      Get.snackbar(
        'Succès',
        'Bordereau mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
      loadBordereaux();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le bordereau',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteBordereau(int bordereauId) async {
    try {
      isLoading.value = true;
      final success = await _bordereauService.deleteBordereau(bordereauId);
      if (success) {
        bordereaux.removeWhere((b) => b.id == bordereauId);
        Get.snackbar(
          'Succès',
          'Bordereau supprimé avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le bordereau',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitBordereau(int bordereauId) async {
    try {
      isLoading.value = true;
      final success = await _bordereauService.submitBordereau(bordereauId);
      if (success) {
        await loadBordereaux();
        Get.snackbar(
          'Succès',
          'Bordereau soumis avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la soumission');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de soumettre le bordereau',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveBordereau(int bordereauId) async {
    try {
      isLoading.value = true;
      final success = await _bordereauService.approveBordereau(bordereauId);
      if (success) {
        await loadBordereaux();
        Get.snackbar(
          'Succès',
          'Bordereau approuvé avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de l\'approbation');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'approuver le bordereau',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectBordereau(int bordereauId, String commentaire) async {
    try {
      isLoading.value = true;
      final success = await _bordereauService.rejectBordereau(
        bordereauId,
        commentaire,
      );
      if (success) {
        await loadBordereaux();
        Get.snackbar(
          'Succès',
          'Bordereau rejeté avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors du rejet');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter le bordereau',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Gestion des items
  void addItem(BordereauItem item) {
    items.add(item);
  }

  void removeItem(int index) {
    items.removeAt(index);
  }

  void updateItem(int index, BordereauItem item) {
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
