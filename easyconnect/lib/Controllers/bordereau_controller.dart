import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:easyconnect/Models/bordereau_model.dart';
import 'package:easyconnect/services/bordereau_service.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:easyconnect/services/devis_service.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';

class BordereauxController extends GetxController {
  late int userId;
  final BordereauService _bordereauService = BordereauService();
  final ClientService _clientService = ClientService();
  final DevisService _devisService = DevisService();

  final bordereaux = <Bordereau>[].obs;
  final selectedClient = Rxn<Client>();
  final availableClients = <Client>[].obs;
  final isLoading = false.obs;
  final isLoadingClients = false.obs;
  final currentBordereau = Rxn<Bordereau>();
  final items = <BordereauItem>[].obs;

  // Variables pour la gestion des devis
  final availableDevis = <Devis>[].obs;
  final selectedDevis = Rxn<Devis>();
  final isLoadingDevis = false.obs;

  // Référence générée automatiquement
  final generatedReference = ''.obs;

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
    // loadStats(); // Temporairement désactivé car l'endpoint n'existe pas
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
    } catch (e) {}
  }

  Future<bool> createBordereau(Map<String, dynamic> data) async {
    try {
      // Vérifications
      if (selectedClient.value == null) {
        throw Exception('Aucun client sélectionné');
      }
      if (items.isEmpty) {
        throw Exception('Aucun article ajouté au bordereau');
      }

      isLoading.value = true;

      // Utiliser la référence générée si un devis est sélectionné, sinon utiliser celle fournie
      final reference =
          selectedDevis.value != null && generatedReference.value.isNotEmpty
              ? generatedReference.value
              : data['reference'];

      final newBordereau = Bordereau(
        clientId: selectedClient.value!.id!,
        devisId: selectedDevis.value?.id,
        reference: reference,
        dateCreation: DateTime.now(),
        notes: data['notes'],
        status: 1, // Forcer le statut à 1 (En attente)
        items: items.toList(), // Convertir en liste
        commercialId: userId,
      );

      await _bordereauService.createBordereau(newBordereau);

      // Si la création réussit, afficher le message de succès
      Get.snackbar(
        'Succès',
        'Bordereau créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Effacer le formulaire
      clearForm();

      // Essayer de recharger la liste (mais ne pas faire échouer si ça échoue)
      try {
        await loadBordereaux();
      } catch (e) {
        // Si le rechargement échoue, on ne fait rien car le bordereau a été créé avec succès
        // L'utilisateur peut recharger manuellement si nécessaire
      }

      return true;
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
        duration: const Duration(seconds: 8),
        maxWidth: 400,
        isDismissible: true,
        shouldIconPulse: true,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateBordereau(
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
        commercialId: bordereauToUpdate.commercialId,
      );

      await _bordereauService.updateBordereau(updatedBordereau);

      // Si la mise à jour réussit, afficher le message de succès
      Get.snackbar(
        'Succès',
        'Bordereau mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Essayer de recharger la liste (mais ne pas faire échouer si ça échoue)
      try {
        await loadBordereaux();
      } catch (e) {
        // Si le rechargement échoue, on ne fait rien car le bordereau a été mis à jour avec succès
        // L'utilisateur peut recharger manuellement si nécessaire
      }

      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le bordereau',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
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
      try {
        final success = await _bordereauService.approveBordereau(bordereauId);

        if (success) {
          await loadBordereaux();

          // Rafraîchir les compteurs du dashboard patron
          DashboardRefreshHelper.refreshPatronCounter('bordereau');

          Get.snackbar(
            'Succès',
            'Bordereau approuvé avec succès',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          throw Exception(
            'Erreur lors de l\'approbation - La réponse du serveur indique un échec',
          );
        }
      } catch (e) {
        // Si le service a lancé une exception, la propager
        rethrow;
      }
    } catch (e, stackTrace) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'approuver le bordereau: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectBordereau(int bordereauId, String commentaire) async {
    try {
      isLoading.value = true;
      try {
        final success = await _bordereauService.rejectBordereau(
          bordereauId,
          commentaire,
        );

        if (success) {
          await loadBordereaux();

          // Rafraîchir les compteurs du dashboard patron
          DashboardRefreshHelper.refreshPatronCounter('bordereau');

          Get.snackbar(
            'Succès',
            'Bordereau rejeté avec succès',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        } else {
          throw Exception(
            'Erreur lors du rejet - La réponse du serveur indique un échec',
          );
        }
      } catch (e) {
        // Si le service a lancé une exception, la propager
        rethrow;
      }
    } catch (e, stackTrace) {
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter le bordereau: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
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
    } catch (e) {}
  }

  void selectClient(Client client) {
    selectedClient.value = client;
    // Charger les devis validés pour ce client
    onClientChanged(client);
  }

  void clearSelectedClient() {
    selectedClient.value = null;
  }

  /// Effacer toutes les données du formulaire
  void clearForm() {
    selectedClient.value = null;
    selectedDevis.value = null;
    availableDevis.clear();
    items.clear();
  }

  // Chargement des devis validés pour le client sélectionné
  Future<void> loadValidatedDevisForClient(int clientId) async {
    try {
      isLoadingDevis.value = true;
      final devis = await _devisService.getDevis();

      // Filtrer par client et statut côté client
      final devisForClient =
          devis.where((d) => d.clientId == clientId && d.status == 2).toList();
      availableDevis.value = devisForClient;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les devis validés',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingDevis.value = false;
    }
  }

  // Générer automatiquement la référence du bordereau basée sur le devis
  Future<String> generateBordereauReference(int? devisId) async {
    if (devisId == null) {
      // Si pas de devis, générer une référence par défaut
      return 'BL-${DateTime.now().millisecondsSinceEpoch}';
    }

    // Trouver le devis sélectionné
    final devis = selectedDevis.value;
    if (devis == null) {
      return 'BL-${DateTime.now().millisecondsSinceEpoch}';
    }

    // Recharger les bordereaux pour avoir le comptage à jour
    await loadBordereaux();

    // Compter combien de bordereaux existent déjà pour ce devis
    final existingBordereaux =
        bordereaux.where((b) => b.devisId == devisId).toList();
    final increment = existingBordereaux.length + 1;

    // Générer la référence : [référence_devis]-BL[incrément]
    return '${devis.reference}-BL$increment';
  }

  // Sélection d'un devis
  Future<void> selectDevis(Devis devis) async {
    selectedDevis.value = devis;

    // Générer automatiquement la référence
    final ref = await generateBordereauReference(devis.id);
    generatedReference.value = ref;
    print('📋 [BORDEREAU] Référence générée: $ref');

    // Pré-remplir les items du bordereau avec les items du devis (sans les prix)
    items.clear();
    for (final devisItem in devis.items) {
      final bordereauItem = BordereauItem(
        designation: devisItem.designation,
        unite: 'unité', // Valeur par défaut
        quantite: devisItem.quantite,
        description: 'Basé sur le devis ${devis.reference}',
      );
      items.add(bordereauItem);
    }
  }

  // Effacer la sélection du devis
  void clearSelectedDevis() {
    selectedDevis.value = null;
    generatedReference.value = '';
    items.clear();
  }

  // Recharger les devis quand le client change
  void onClientChanged(Client? client) {
    if (client != null) {
      loadValidatedDevisForClient(client.id!);
    } else {
      availableDevis.clear();
      selectedDevis.value = null;
      items.clear();
    }
  }

  /// Générer un PDF pour un bordereau
  Future<void> generatePDF(int bordereauId) async {
    try {
      isLoading.value = true;

      // Trouver le bordereau
      final bordereau = bordereaux.firstWhere((b) => b.id == bordereauId);

      // Charger les données nécessaires
      final clients = await _clientService.getClients();
      final client = clients.firstWhere((c) => c.id == bordereau.clientId);
      final items =
          bordereau.items
              .map(
                (item) => {
                  'designation': item.designation,
                  'unite': item.unite,
                  'quantite': item.quantite,
                  'montant_total': item.montantTotal,
                },
              )
              .toList();

      // Générer le PDF
      await PdfService().generateBordereauPdf(
        bordereau: {
          'reference': bordereau.reference,
          'date_creation': bordereau.dateCreation,
          'montant_ht': bordereau.montantHT,
          'total_ttc': bordereau.montantTTC,
        },
        items: items,
        client: {
          'nom': client.nom ?? '',
          'prenom': client.prenom ?? '',
          'nom_entreprise': client.nomEntreprise,
          'email': client.email,
          'contact': client.contact,
          'adresse': client.adresse,
        },
        commercial: {'nom': 'Commercial', 'prenom': '', 'email': ''},
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
