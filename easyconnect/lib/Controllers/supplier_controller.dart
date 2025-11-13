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
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController commentairesController = TextEditingController();

  @override
  void onInit() {
    super.onInit();

    try {
      _supplierService = Get.find<SupplierService>();
    } catch (e) {
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
    descriptionController.dispose();
    commentairesController.dispose();
    super.onClose();
  }

  // Charger tous les fournisseurs
  Future<void> loadSuppliers() async {
    try {
      isLoading.value = true;
      // Charger tous les fournisseurs sans filtre côté serveur
      final loadedSuppliers = await _supplierService.getSuppliers(
        status: null, // Toujours charger tous les fournisseurs
        search: null, // Pas de recherche côté serveur
      );
      // Stocker tous les fournisseurs
      allSuppliers.assignAll(loadedSuppliers);

      // Appliquer les filtres côté client
      applyFilters();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les fournisseurs',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Charger les statistiques
  Future<void> loadSupplierStats() async {
    try {
      final stats = await _supplierService.getSupplierStats();
      supplierStats.value = stats;
    } catch (e) {
    }
  }

  // Appliquer les filtres côté client
  void applyFilters() {
    List<Supplier> filteredSuppliers = List.from(allSuppliers);

    // Filtrer par statut
    if (selectedStatus.value != 'all') {
      filteredSuppliers =
          filteredSuppliers.where((supplier) {
            return supplier.statut == selectedStatus.value;
          }).toList();
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
    }

    suppliers.assignAll(filteredSuppliers);
  }

  // Rechercher
  void searchSuppliers(String query) {
    searchQuery.value = query;
    applyFilters(); // Appliquer les filtres sans recharger depuis l'API
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    selectedStatus.value = status;
    applyFilters(); // Appliquer les filtres sans recharger depuis l'API
  }

  // Créer un fournisseur
  Future<bool> createSupplier() async {
    try {
      isLoading.value = true;

      final supplier = Supplier(
        nom: nomController.text.trim(),
        email: emailController.text.trim(),
        telephone: telephoneController.text.trim(),
        adresse: adresseController.text.trim(),
        ville: villeController.text.trim(),
        pays: paysController.text.trim(),
        description:
            descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
        commentaires:
            commentairesController.text.trim().isEmpty
                ? null
                : commentairesController.text.trim(),
        statut: 'en_attente', // Statut par défaut selon la doc
      );

      await _supplierService.createSupplier(supplier);
      await loadSuppliers(); // Recharger tous les fournisseurs
      await loadSupplierStats();

      Get.snackbar(
        'Succès',
        'Fournisseur créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      clearForm();
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer le fournisseur: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Mettre à jour un fournisseur
  Future<bool> updateSupplier(Supplier supplier) async {
    try {
      isLoading.value = true;

      final updatedSupplier = supplier.copyWith(
        nom: nomController.text.trim(),
        email: emailController.text.trim(),
        telephone: telephoneController.text.trim(),
        adresse: adresseController.text.trim(),
        ville: villeController.text.trim(),
        pays: paysController.text.trim(),
        description:
            descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
        commentaires:
            commentairesController.text.trim().isEmpty
                ? null
                : commentairesController.text.trim(),
      );

      await _supplierService.updateSupplier(updatedSupplier);
      await loadSuppliers(); // Recharger tous les fournisseurs
      await loadSupplierStats();

      Get.snackbar(
        'Succès',
        'Fournisseur mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      clearForm();
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le fournisseur: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Supprimer un fournisseur
  Future<void> deleteSupplier(Supplier supplier) async {
    try {
      isLoading.value = true;

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
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le fournisseur',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Valider un fournisseur
  Future<void> approveSupplier(
    Supplier supplier, {
    String? validationComment,
  }) async {
    try {
      isLoading.value = true;

      final success = await _supplierService.approveSupplier(
        supplier.id!,
        validationComment: validationComment,
      );
      if (success) {
        await loadSuppliers(); // Recharger tous les fournisseurs
        await loadSupplierStats();

        Get.snackbar(
          'Succès',
          'Fournisseur validé avec succès',
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
        'Impossible de valider le fournisseur: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Rejeter un fournisseur
  Future<void> rejectSupplier(
    Supplier supplier, {
    required String rejectionReason,
    String? rejectionComment,
  }) async {
    try {
      isLoading.value = true;

      final success = await _supplierService.rejectSupplier(
        supplier.id!,
        rejectionReason: rejectionReason,
        rejectionComment: rejectionComment,
      );
      if (success) {
        await loadSuppliers(); // Recharger tous les fournisseurs
        await loadSupplierStats();

        Get.snackbar(
          'Succès',
          'Fournisseur rejeté',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Erreur lors du rejet');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter le fournisseur: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
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
