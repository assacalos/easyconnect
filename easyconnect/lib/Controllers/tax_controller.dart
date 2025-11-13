import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/tax_model.dart';
import 'package:easyconnect/services/tax_service.dart';

class TaxController extends GetxController {
  late final TaxService _taxService;

  // Variables observables
  final RxList<Tax> allTaxes = <Tax>[].obs; // Toutes les taxes
  final RxList<Tax> taxes = <Tax>[].obs; // Taxes filtrées
  final RxBool isLoading = false.obs;
  final Rx<TaxStats?> taxStats = Rx<TaxStats?>(null);

  // Variables pour les filtres
  final RxString selectedStatus = 'all'.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();

    try {
      _taxService = Get.find<TaxService>();
    } catch (e) {
    }

    loadTaxes();
    loadTaxStats();
  }

  // Charger toutes les taxes
  Future<void> loadTaxes() async {
    try {
      isLoading.value = true;
      // Tester la connectivité d'abord
      final isConnected = await _taxService.testTaxConnection();
      if (!isConnected) {
        throw Exception('Impossible de se connecter à l\'API Laravel');
      }

      // Charger toutes les taxes depuis l'API
      final loadedTaxes = await _taxService.getTaxes(
        status: null, // Toujours charger toutes les taxes
        search: null, // Pas de recherche côté serveur
      );
      // Stocker toutes les taxes
      allTaxes.assignAll(loadedTaxes);
      applyFilters();
      if (loadedTaxes.isNotEmpty) {
        Get.snackbar(
          'Succès',
          '${loadedTaxes.length} impôts chargés avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      // Vider la liste des impôts en cas d'erreur
      allTaxes.value = [];
      taxes.value = [];

      // Message d'erreur spécifique selon le type d'erreur
      String errorMessage;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage =
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
      } else if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        errorMessage = 'Session expirée. Veuillez vous reconnecter.';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Erreur serveur. Veuillez réessayer plus tard.';
      } else if (e.toString().contains('FormatException') ||
          e.toString().contains('Unexpected end of input')) {
        errorMessage =
            'Erreur de format des données. Contactez l\'administrateur.';
      } else if (e.toString().contains('Null') ||
          e.toString().contains('not a subtype')) {
        errorMessage =
            'Erreur de format des données. Contactez l\'administrateur.';
      } else {
        errorMessage = 'Erreur lors du chargement des impôts: $e';
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

  // Charger les statistiques
  Future<void> loadTaxStats() async {
    try {
      final stats = await _taxService.getTaxStats();
      taxStats.value = stats;
    } catch (e) {
    }
  }

  // Tester la connectivité à l'API
  Future<bool> testTaxConnection() async {
    try {
      return await _taxService.testTaxConnection();
    } catch (e) {
      return false;
    }
  }

  // Appliquer les filtres côté client
  void applyFilters() {
    List<Tax> filteredTaxes = List.from(allTaxes);
    // Filtrer par statut (normalisation vers les 4 statuts)
    if (selectedStatus.value != 'all') {
      final beforeCount = filteredTaxes.length;
      filteredTaxes =
          filteredTaxes.where((tax) {
            bool matches = false;
            final statusLower = selectedStatus.value.toLowerCase();
            if (statusLower == 'en_attente') {
              matches = tax.isPending;
            } else if (statusLower == 'valide') {
              matches = tax.isValidated;
            } else if (statusLower == 'rejete') {
              matches = tax.isRejected;
            } else if (statusLower == 'paid') {
              matches = tax.isPaid;
            }
            if (!matches) {
            }
            return matches;
          }).toList();
    } else {
    }

    // Filtrer par recherche
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      final beforeCount = filteredTaxes.length;
      filteredTaxes =
          filteredTaxes.where((tax) {
            final matches =
                tax.name.toLowerCase().contains(query) ||
                (tax.description?.toLowerCase().contains(query) ?? false);
            if (!matches) {
            }
            return matches;
          }).toList();
    } else {
    }

    taxes.assignAll(filteredTaxes);
    // Debug final
    if (taxes.isEmpty) {
      if (allTaxes.isNotEmpty) {
        for (final tax in allTaxes) {
        }
      }
    }
  }

  // Rechercher
  void searchTaxes(String query) {
    searchQuery.value = query;
    applyFilters(); // Appliquer les filtres sans recharger depuis l'API
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    selectedStatus.value = status;
    applyFilters(); // Appliquer les filtres sans recharger depuis l'API
  }

  // Valider une taxe
  Future<void> validateTax(Tax tax, {String? validationComment}) async {
    try {
      isLoading.value = true;

      // Utiliser l'endpoint dédié pour la validation
      final success = await _taxService.approveTax(
        tax.id!,
        notes: validationComment,
      );

      if (success) {
        // Recharger les données
        await loadTaxes();
        await loadTaxStats();

        Get.snackbar(
          'Succès',
          'Taxe validée avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Erreur lors de la validation');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de valider la taxe: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Rejeter une taxe
  Future<void> rejectTax(
    Tax tax,
    String reason, {
    String? rejectionComment,
  }) async {
    try {
      isLoading.value = true;

      // Utiliser l'endpoint dédié pour le rejet
      final success = await _taxService.rejectTax(
        tax.id!,
        reason: reason,
        notes: rejectionComment,
      );

      if (success) {
        // Recharger les données
        await loadTaxes();
        await loadTaxStats();

        Get.snackbar(
          'Succès',
          'Taxe rejetée',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Erreur lors du rejet');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter la taxe: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Marquer une taxe comme payée
  Future<void> markTaxAsPaid(Tax tax) async {
    try {
      isLoading.value = true;

      // Utiliser le service pour marquer comme payé
      final success = await _taxService.markTaxAsPaid(
        tax.id!,
        paymentMethod: 'manual',
        notes: 'Marqué comme payé depuis l\'application',
      );

      if (success) {
        // Recharger les données
        await loadTaxes();
        await loadTaxStats();

        Get.snackbar(
          'Succès',
          'Taxe marquée comme payée avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Erreur lors du marquage comme payé');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de marquer la taxe comme payée: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Supprimer une taxe
  Future<void> deleteTax(Tax tax) async {
    try {
      isLoading.value = true;

      // Supprimer via l'API
      final success = await _taxService.deleteTax(tax.id!);

      if (success) {
        // Recharger les données
        await loadTaxes();
        await loadTaxStats();

        Get.snackbar(
          'Succès',
          'Taxe supprimée avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer la taxe',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
