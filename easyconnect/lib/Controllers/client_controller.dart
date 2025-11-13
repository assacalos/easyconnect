import 'package:get/get.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';

class ClientController extends GetxController {
  final ClientService _clientService = ClientService();
  final clients = <Client>[].obs; // ✅ Utilise bien ton modèle
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadClients();
  }

  Future<void> loadClients({int? status}) async {
    try {
      isLoading.value = true;
      final loadedClients = await _clientService.getClients(status: status);
      for (final client in loadedClients) {
      }

      clients.assignAll(loadedClients);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les clients',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createClient(Client client) async {
    try {
      isLoading.value = true;

      await _clientService.createClient(client);
      await loadClients();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer le client',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createClientFromMap(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;

      // Transformer le Map en objet Client
      final client = Client.fromJson(data);

      await _clientService.createClient(client);
      await loadClients();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer le client',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateClient(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;

      final client = Client.fromJson(data); // ✅ conversion
      await _clientService.updateClient(client);
      await loadClients();

      Get.snackbar(
        'Succès',
        'Client mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le client',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveClient(int clientId) async {
    try {
      isLoading.value = true;
      final success = await _clientService.approveClient(clientId);
      if (success) {
        await loadClients(
          status: null,
        ); // ✅ recharge tous les clients pour mettre à jour le dashboard
        Get.snackbar(
          'Succès',
          'Client validé avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception(
          'Erreur lors de la validation - Service a retourné false',
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de valider le client: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectClient(int clientId, String comment) async {
    try {
      isLoading.value = true;
      final success = await _clientService.rejectClient(clientId, comment);
      if (success) {
        await loadClients(
          status: null,
        ); // ✅ recharge tous les clients pour mettre à jour le dashboard
        Get.snackbar(
          'Succès',
          'Client rejeté avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors du rejet - Service a retourné false');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter le client: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteClient(int clientId) async {
    try {
      isLoading.value = true;
      final success = await _clientService.deleteClient(clientId);
      if (success) {
        clients.removeWhere((c) => c.id == clientId); // ✅ mise à jour locale
        Get.snackbar(
          'Succès',
          'Client supprimé avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le client',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
