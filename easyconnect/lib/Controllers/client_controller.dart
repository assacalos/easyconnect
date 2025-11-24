import 'package:get/get.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';

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
      clients.assignAll(loadedClients);
    } catch (e) {
      // Ne pas afficher de message d'erreur si c'est une erreur d'authentification
      // (elle est déjà gérée par AuthErrorHandler)
      final errorString = e.toString().toLowerCase();
      if (!errorString.contains('session expirée') &&
          !errorString.contains('401')) {
        Get.snackbar(
          'Erreur',
          'Impossible de charger les clients',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createClient(Client client) async {
    try {
      isLoading.value = true;

      // Créer le client
      await _clientService.createClient(client);

      // Essayer de recharger la liste (mais ne pas faire échouer si ça échoue)
      try {
        await loadClients();
      } catch (e) {
        // Si le rechargement échoue, on ne fait rien car le client a été créé avec succès
        // L'utilisateur peut recharger manuellement si nécessaire
      }
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

  Future<bool> createClientFromMap(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;

      // Transformer le Map en objet Client
      final client = Client.fromJson(data);

      // Créer le client
      await _clientService.createClient(client);

      // Si la création réussit, afficher le message de succès
      Get.snackbar(
        'Succès',
        'Client enregistré avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Essayer de recharger la liste (mais ne pas faire échouer si ça échoue)
      try {
        await loadClients();
      } catch (e) {
        // Si le rechargement échoue, on ne fait rien car le client a été créé avec succès
        // L'utilisateur peut recharger manuellement si nécessaire
      }

      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer le client',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateClient(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;

      final client = Client.fromJson(data); // ✅ conversion
      await _clientService.updateClient(client);

      // Si la mise à jour réussit, afficher le message de succès
      Get.snackbar(
        'Succès',
        'Client mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Essayer de recharger la liste (mais ne pas faire échouer si ça échoue)
      try {
        await loadClients();
      } catch (e) {
        // Si le rechargement échoue, on ne fait rien car le client a été mis à jour avec succès
        // L'utilisateur peut recharger manuellement si nécessaire
      }

      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le client',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
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

        // Rafraîchir les compteurs du dashboard patron
        DashboardRefreshHelper.refreshPatronCounter('client');

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

        // Rafraîchir les compteurs du dashboard patron
        DashboardRefreshHelper.refreshPatronCounter('client');

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

  /// Réinitialiser le formulaire
  void clearForm() {
    // Cette méthode est vide car les contrôleurs sont dans le formulaire
    // Mais elle peut être utilisée pour d'autres réinitialisations si nécessaire
  }
}
