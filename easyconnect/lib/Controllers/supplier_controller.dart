import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/supplier_model.dart';
import 'package:easyconnect/services/supplier_service.dart';

class SupplierController extends GetxController {
  late final SupplierService _supplierService;

  // Variables observables
  final RxList<Supplier> allSuppliers =
      <Supplier>[].obs; // Tous les fournisseurs
  final RxList<Supplier> suppliers = <Supplier>[].obs; // Fournisseurs filtrés
  final RxBool isLoading = false.obs;
  final Rx<SupplierStats?> supplierStats = Rx<SupplierStats?>(null);

  // Variables pour les filtres
  final RxString searchQuery = ''.obs;
  final RxString selectedStatus = 'all'.obs;

  // Permissions
  bool get canCreateSuppliers => true; // À adapter selon vos règles métier
  bool get canApproveSuppliers => true; // À adapter selon vos règles métier

  // Contrôleurs de formulaire
  final TextEditingController nomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telephoneController = TextEditingController();
  final TextEditingController adresseController = TextEditingController();
  final TextEditingController villeController = TextEditingController();
  final TextEditingController paysController = TextEditingController();
  final TextEditingController contactPrincipalController =
      TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController commentairesController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    print('🔧 SupplierController: onInit() appelé');

    try {
      _supplierService = Get.find<SupplierService>();
      print('✅ SupplierController: SupplierService trouvé');
    } catch (e) {
      print(
        '❌ SupplierController: Erreur lors de la récupération du SupplierService: $e',
      );
    }

    loadSuppliers();
    loadSupplierStats();
  }

  @override
  void onClose() {
    nomController.dispose();
    emailController.dispose();
    telephoneController.dispose();
    adresseController.dispose();
    villeController.dispose();
    paysController.dispose();
    contactPrincipalController.dispose();
    descriptionController.dispose();
    commentairesController.dispose();
    super.onClose();
  }

  // Charger tous les fournisseurs
  Future<void> loadSuppliers() async {
    print('🔄 SupplierController: loadSuppliers() appelé');
    print('📊 SupplierController: selectedStatus = ${selectedStatus.value}');
    print('🔍 SupplierController: searchQuery = "${searchQuery.value}"');

    try {
      isLoading.value = true;
      print('⏳ SupplierController: Chargement en cours...');

      // Charger tous les fournisseurs sans filtre côté serveur
      final loadedSuppliers = await _supplierService.getSuppliers(
        status: null, // Toujours charger tous les fournisseurs
        search: null, // Pas de recherche côté serveur
      );

      print(
        '📦 SupplierController: ${loadedSuppliers.length} fournisseurs reçus du service',
      );

      // Stocker tous les fournisseurs
      allSuppliers.assignAll(loadedSuppliers);

      // Appliquer les filtres côté client
      applyFilters();

      print(
        '✅ SupplierController: Liste mise à jour avec ${suppliers.length} fournisseurs filtrés',
      );
    } catch (e) {
      print('❌ SupplierController: Erreur lors du chargement: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les fournisseurs',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      print('🏁 SupplierController: Chargement terminé');
    }
  }

  // Charger les statistiques
  Future<void> loadSupplierStats() async {
    try {
      final stats = await _supplierService.getSupplierStats();
      supplierStats.value = stats;
      print('📊 SupplierController: Statistiques chargées');
    } catch (e) {
      print(
        '❌ SupplierController: Erreur lors du chargement des statistiques: $e',
      );
    }
  }

  // Appliquer les filtres côté client
  void applyFilters() {
    print('🔍 SupplierController: applyFilters() appelé');
    print('📊 SupplierController: Statut sélectionné: ${selectedStatus.value}');
    print('🔍 SupplierController: Recherche: "${searchQuery.value}"');
    print('📦 SupplierController: Total fournisseurs: ${allSuppliers.length}');

    List<Supplier> filteredSuppliers = List.from(allSuppliers);

    // Filtrer par statut
    if (selectedStatus.value != 'all') {
      filteredSuppliers =
          filteredSuppliers.where((supplier) {
            return supplier.statut == selectedStatus.value;
          }).toList();
      print(
        '📊 SupplierController: Après filtrage par statut: ${filteredSuppliers.length}',
      );
    }

    // Filtrer par recherche
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filteredSuppliers =
          filteredSuppliers.where((supplier) {
            return supplier.nom.toLowerCase().contains(query) ||
                supplier.email.toLowerCase().contains(query) ||
                supplier.telephone.toLowerCase().contains(query) ||
                supplier.ville.toLowerCase().contains(query) ||
                supplier.pays.toLowerCase().contains(query);
          }).toList();
      print(
        '🔍 SupplierController: Après filtrage par recherche: ${filteredSuppliers.length}',
      );
    }

    suppliers.assignAll(filteredSuppliers);
    print(
      '✅ SupplierController: Filtrage terminé - ${suppliers.length} fournisseurs affichés',
    );
  }

  // Rechercher
  void searchSuppliers(String query) {
    print('🔍 SupplierController: searchSuppliers("$query") appelé');
    searchQuery.value = query;
    applyFilters(); // Appliquer les filtres sans recharger depuis l'API
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    print('🔍 SupplierController: filterByStatus($status) appelé');
    selectedStatus.value = status;
    print('📊 SupplierController: Nouveau statut sélectionné: $status');
    applyFilters(); // Appliquer les filtres sans recharger depuis l'API
  }

  // Créer un fournisseur
  Future<void> createSupplier() async {
    try {
      isLoading.value = true;
      print('➕ SupplierController: createSupplier() appelé');

      final supplier = Supplier(
        nom: nomController.text.trim(),
        email: emailController.text.trim(),
        telephone: telephoneController.text.trim(),
        adresse: adresseController.text.trim(),
        ville: villeController.text.trim(),
        pays: paysController.text.trim(),
        contactPrincipal: contactPrincipalController.text.trim(),
        description:
            descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
        commentaires:
            commentairesController.text.trim().isEmpty
                ? null
                : commentairesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _supplierService.createSupplier(supplier);
      await loadSuppliers(); // Recharger tous les fournisseurs
      await loadSupplierStats();

      Get.snackbar(
        'Succès',
        'Fournisseur créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      clearForm();
    } catch (e) {
      print('❌ SupplierController: Erreur lors de la création: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de créer le fournisseur',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Mettre à jour un fournisseur
  Future<void> updateSupplier(Supplier supplier) async {
    try {
      isLoading.value = true;
      print('✏️ SupplierController: updateSupplier(${supplier.id}) appelé');

      final updatedSupplier = supplier.copyWith(
        nom: nomController.text.trim(),
        email: emailController.text.trim(),
        telephone: telephoneController.text.trim(),
        adresse: adresseController.text.trim(),
        ville: villeController.text.trim(),
        pays: paysController.text.trim(),
        contactPrincipal: contactPrincipalController.text.trim(),
        description:
            descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
        commentaires:
            commentairesController.text.trim().isEmpty
                ? null
                : commentairesController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await _supplierService.updateSupplier(updatedSupplier);
      await loadSuppliers(); // Recharger tous les fournisseurs
      await loadSupplierStats();

      Get.snackbar(
        'Succès',
        'Fournisseur mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      clearForm();
    } catch (e) {
      print('❌ SupplierController: Erreur lors de la mise à jour: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le fournisseur',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Supprimer un fournisseur
  Future<void> deleteSupplier(Supplier supplier) async {
    try {
      isLoading.value = true;
      print('🗑️ SupplierController: deleteSupplier(${supplier.id}) appelé');

      final success = await _supplierService.deleteSupplier(supplier.id!);
      if (success) {
        await loadSuppliers(); // Recharger tous les fournisseurs
        await loadSupplierStats();

        Get.snackbar(
          'Succès',
          'Fournisseur supprimé avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      print('❌ SupplierController: Erreur lors de la suppression: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le fournisseur',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Approuver un fournisseur
  Future<void> approveSupplier(Supplier supplier, {String? comments}) async {
    try {
      isLoading.value = true;
      print('✅ SupplierController: approveSupplier(${supplier.id}) appelé');

      final success = await _supplierService.approveSupplier(
        supplier.id!,
        comments: comments,
      );
      if (success) {
        await loadSuppliers(); // Recharger tous les fournisseurs
        await loadSupplierStats();

        Get.snackbar(
          'Succès',
          'Fournisseur approuvé avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de l\'approbation');
      }
    } catch (e) {
      print('❌ SupplierController: Erreur lors de l\'approbation: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'approuver le fournisseur',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Rejeter un fournisseur
  Future<void> rejectSupplier(Supplier supplier, String reason) async {
    try {
      isLoading.value = true;
      print('❌ SupplierController: rejectSupplier(${supplier.id}) appelé');

      final success = await _supplierService.rejectSupplier(
        supplier.id!,
        reason,
      );
      if (success) {
        await loadSuppliers(); // Recharger tous les fournisseurs
        await loadSupplierStats();

        Get.snackbar(
          'Succès',
          'Fournisseur rejeté',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors du rejet');
      }
    } catch (e) {
      print('❌ SupplierController: Erreur lors du rejet: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter le fournisseur',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Remplir le formulaire avec les données d'un fournisseur
  void fillForm(Supplier supplier) {
    nomController.text = supplier.nom;
    emailController.text = supplier.email;
    telephoneController.text = supplier.telephone;
    adresseController.text = supplier.adresse;
    villeController.text = supplier.ville;
    paysController.text = supplier.pays;
    contactPrincipalController.text = supplier.contactPrincipal;
    descriptionController.text = supplier.description ?? '';
    commentairesController.text = supplier.commentaires ?? '';
  }

  // Vider le formulaire
  void clearForm() {
    nomController.clear();
    emailController.clear();
    telephoneController.clear();
    adresseController.clear();
    villeController.clear();
    paysController.clear();
    contactPrincipalController.clear();
    descriptionController.clear();
    commentairesController.clear();
  }

  // Évaluer un fournisseur
  Future<void> rateSupplier(
    Supplier supplier,
    double rating, {
    String? comments,
  }) async {
    try {
      isLoading.value = true;
      print(
        '⭐ SupplierController: rateSupplier(${supplier.id}, $rating) appelé',
      );

      final success = await _supplierService.rateSupplier(
        supplier.id!,
        rating,
        comments: comments,
      );
      if (success) {
        await loadSuppliers(); // Recharger tous les fournisseurs
        await loadSupplierStats();

        Get.snackbar(
          'Succès',
          'Fournisseur évalué avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de l\'évaluation');
      }
    } catch (e) {
      print('❌ SupplierController: Erreur lors de l\'évaluation: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'évaluer le fournisseur',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Soumettre un fournisseur
  Future<void> submitSupplier(Supplier supplier) async {
    try {
      isLoading.value = true;
      print('📤 SupplierController: submitSupplier(${supplier.id}) appelé');

      final success = await _supplierService.submitSupplier(supplier.id!);
      if (success) {
        await loadSuppliers(); // Recharger tous les fournisseurs
        await loadSupplierStats();

        Get.snackbar(
          'Succès',
          'Fournisseur soumis avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la soumission');
      }
    } catch (e) {
      print('❌ SupplierController: Erreur lors de la soumission: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de soumettre le fournisseur',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
