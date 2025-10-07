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
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
    }
  }

  Future<void> createBordereau(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;

      final newBordereau = Bordereau(
        clientId: selectedClient.value!.id!,
        devisId: selectedDevis.value?.id,
        reference: data['reference'],
        dateCreation: DateTime.now(),
        notes: data['notes'],
        status: 1, // Forcer le statut à 1 (En attente)
        items: items,
        remiseGlobale: data['remise_globale'],
        tva: data['tva'],
        conditions: data['conditions'],
        commercialId: userId,
      );

      final createdBordereau = await _bordereauService.createBordereau(
        newBordereau,
      );

      // Effacer le formulaire
      clearForm();

      // Recharger la liste des bordereaux
      await loadBordereaux();

      // Fermer le formulaire et afficher le message de succès
      Get.back();
      Get.snackbar(
        'Succès',
        'Bordereau créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
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
      print('🔍 BordereauxController.approveBordereau - Début');
      print('📊 Paramètres: bordereauId=$bordereauId');

      isLoading.value = true;
      final success = await _bordereauService.approveBordereau(bordereauId);

      print('📊 Résultat service: $success');

      if (success) {
        print('✅ Approbation réussie, rechargement des bordereaux');
        await loadBordereaux();
        Get.snackbar(
          'Succès',
          'Bordereau approuvé avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        print('❌ Échec de l\'approbation');
        throw Exception('Erreur lors de l\'approbation');
      }
    } catch (e) {
      print('❌ Erreur détaillée: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'approuver le bordereau: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectBordereau(int bordereauId, String commentaire) async {
    try {
      print('🔍 BordereauxController.rejectBordereau - Début');
      print(
        '📊 Paramètres: bordereauId=$bordereauId, commentaire=$commentaire',
      );

      isLoading.value = true;
      final success = await _bordereauService.rejectBordereau(
        bordereauId,
        commentaire,
      );

      print('📊 Résultat service: $success');

      if (success) {
        print('✅ Rejet réussi, rechargement des bordereaux');
        await loadBordereaux();
        Get.snackbar(
          'Succès',
          'Bordereau rejeté avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        print('❌ Échec du rejet');
        throw Exception('Erreur lors du rejet');
      }
    } catch (e) {
      print('❌ Erreur détaillée: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter le bordereau: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
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
    } catch (e) {
      print('Erreur lors de la recherche des clients: $e');
    }
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

  // Sélection d'un devis
  void selectDevis(Devis devis) {
    selectedDevis.value = devis;

    // Pré-remplir les items du bordereau avec les items du devis (sans les prix)
    items.clear();
    for (final devisItem in devis.items) {
      final bordereauItem = BordereauItem(
        designation: devisItem.designation,
        unite: 'unité', // Valeur par défaut
        quantite: devisItem.quantite,
        prixUnitaire: 0.0, // Prix à saisir manuellement
        description: 'Basé sur le devis ${devis.reference}',
      );
      items.add(bordereauItem);
    }
  }

  // Effacer la sélection du devis
  void clearSelectedDevis() {
    selectedDevis.value = null;
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
                  'prix_unitaire': item.prixUnitaire,
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
          'tva': bordereau.tva,
          'total_ttc': bordereau.montantTTC,
        },
        items: items,
        client: {
          'nom': client?.nom ?? '',
          'prenom': client?.prenom ?? '',
          'nom_entreprise': client?.nomEntreprise,
          'email': client?.email,
          'contact': client?.contact,
          'adresse': client?.adresse,
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
