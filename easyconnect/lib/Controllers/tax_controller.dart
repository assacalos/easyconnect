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
    print('🔧 TaxController: onInit() appelé');

    try {
      _taxService = Get.find<TaxService>();
      print('✅ TaxController: TaxService trouvé');
    } catch (e) {
      print(
        '❌ TaxController: Erreur lors de la récupération du TaxService: $e',
      );
    }

    loadTaxes();
    loadTaxStats();
  }

  // Charger toutes les taxes
  Future<void> loadTaxes() async {
    print('🔄 TaxController: loadTaxes() appelé');
    try {
      isLoading.value = true;
      print('⏳ TaxController: Chargement en cours...');

      // Tester la connectivité d'abord
      print('🧪 TaxController: Test de connectivité...');
      final isConnected = await _taxService.testTaxConnection();
      print('🔗 TaxController: Connectivité: ${isConnected ? "✅" : "❌"}');

      if (!isConnected) {
        throw Exception('Impossible de se connecter à l\'API Laravel');
      }

      // Charger toutes les taxes depuis l'API
      final loadedTaxes = await _taxService.getTaxes(
        status: null, // Toujours charger toutes les taxes
        search: null, // Pas de recherche côté serveur
      );

      print('📦 TaxController: ${loadedTaxes.length} taxes reçues du service');

      // Stocker toutes les taxes
      allTaxes.assignAll(loadedTaxes);
      applyFilters();

      print(
        '✅ TaxController: Liste mise à jour avec ${taxes.length} taxes filtrées',
      );

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
      print('❌ TaxController: Erreur lors du chargement: $e');

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
      print('🏁 TaxController: Chargement terminé');
    }
  }

  // Charger les statistiques
  Future<void> loadTaxStats() async {
    try {
      final stats = await _taxService.getTaxStats();
      taxStats.value = stats;
      print('📊 TaxController: Statistiques chargées depuis l\'API');
    } catch (e) {
      print('❌ TaxController: Erreur lors du chargement des statistiques: $e');
    }
  }

  // Tester la connectivité à l'API
  Future<bool> testTaxConnection() async {
    try {
      print('🧪 TaxController: Test de connectivité API...');
      return await _taxService.testTaxConnection();
    } catch (e) {
      print('❌ TaxController: Erreur de test de connectivité: $e');
      return false;
    }
  }

  // Appliquer les filtres côté client
  void applyFilters() {
    print('🔍 TaxController: applyFilters() appelé');
    print('📊 TaxController: Statut sélectionné: ${selectedStatus.value}');
    print('🔍 TaxController: Recherche: "${searchQuery.value}"');
    print('📦 TaxController: Total taxes: ${allTaxes.length}');

    List<Tax> filteredTaxes = List.from(allTaxes);
    print('🔄 TaxController: Liste initiale: ${filteredTaxes.length} taxes');

    // Filtrer par statut
    if (selectedStatus.value != 'all') {
      print('🔍 TaxController: Filtrage par statut: ${selectedStatus.value}');
      final beforeCount = filteredTaxes.length;
      filteredTaxes =
          filteredTaxes.where((tax) {
            final matches = tax.status == selectedStatus.value;
            if (!matches) {
              print(
                '❌ TaxController: Taxe "${tax.name}" rejetée (statut: ${tax.status})',
              );
            }
            return matches;
          }).toList();
      print(
        '📊 TaxController: Après filtrage par statut: $beforeCount → ${filteredTaxes.length}',
      );
    } else {
      print('📊 TaxController: Pas de filtrage par statut (all)');
    }

    // Filtrer par recherche
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      print('🔍 TaxController: Filtrage par recherche: "$query"');
      final beforeCount = filteredTaxes.length;
      filteredTaxes =
          filteredTaxes.where((tax) {
            final matches =
                tax.name.toLowerCase().contains(query) ||
                (tax.description?.toLowerCase().contains(query) ?? false);
            if (!matches) {
              print(
                '❌ TaxController: Taxe "${tax.name}" rejetée par recherche',
              );
            }
            return matches;
          }).toList();
      print(
        '🔍 TaxController: Après filtrage par recherche: $beforeCount → ${filteredTaxes.length}',
      );
    } else {
      print('🔍 TaxController: Pas de filtrage par recherche');
    }

    taxes.assignAll(filteredTaxes);
    print(
      '✅ TaxController: Filtrage terminé - ${taxes.length} taxes affichées',
    );

    // Debug final
    if (taxes.isEmpty) {
      print('⚠️ TaxController: AUCUNE TAXE AFFICHÉE !');
      print('📊 TaxController: allTaxes.length = ${allTaxes.length}');
      print('📊 TaxController: selectedStatus = ${selectedStatus.value}');
      print('📊 TaxController: searchQuery = "${searchQuery.value}"');

      if (allTaxes.isNotEmpty) {
        print('📋 TaxController: Statuts disponibles:');
        for (final tax in allTaxes) {
          print('   - ${tax.name}: ${tax.status}');
        }
      }
    }
  }

  // Rechercher
  void searchTaxes(String query) {
    print('🔍 TaxController: searchTaxes("$query") appelé');
    searchQuery.value = query;
    applyFilters(); // Appliquer les filtres sans recharger depuis l'API
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    print('🔍 TaxController: filterByStatus($status) appelé');
    selectedStatus.value = status;
    print('📊 TaxController: Nouveau statut sélectionné: $status');
    applyFilters(); // Appliquer les filtres sans recharger depuis l'API
  }

  // Valider une taxe
  Future<void> validateTax(Tax tax) async {
    try {
      isLoading.value = true;
      print('✅ TaxController: validateTax(${tax.id}) appelé');

      // Mettre à jour la taxe via l'API
      final updatedTax = tax.copyWith(
        status: 'validated',
        updatedAt: DateTime.now(),
      );

      await _taxService.updateTax(updatedTax);

      // Recharger les données
      await loadTaxes();
      await loadTaxStats();

      Get.snackbar(
        'Succès',
        'Taxe validée avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('❌ TaxController: Erreur lors de la validation: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de valider la taxe',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Rejeter une taxe
  Future<void> rejectTax(Tax tax, String reason) async {
    try {
      isLoading.value = true;
      print('❌ TaxController: rejectTax(${tax.id}) appelé');

      // Mettre à jour la taxe via l'API
      final updatedTax = tax.copyWith(
        status: 'rejected',
        rejectionReason: reason,
        updatedAt: DateTime.now(),
      );

      await _taxService.updateTax(updatedTax);

      // Recharger les données
      await loadTaxes();
      await loadTaxStats();

      Get.snackbar(
        'Succès',
        'Taxe rejetée',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('❌ TaxController: Erreur lors du rejet: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter la taxe',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Supprimer une taxe
  Future<void> deleteTax(Tax tax) async {
    try {
      isLoading.value = true;
      print('🗑️ TaxController: deleteTax(${tax.id}) appelé');

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
      print('❌ TaxController: Erreur lors de la suppression: $e');
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
