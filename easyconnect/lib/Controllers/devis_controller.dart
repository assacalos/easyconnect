import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:easyconnect/services/devis_service.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/utils/reference_generator.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';

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

  // Référence générée automatiquement
  final generatedReference = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadDevis();
    // loadStats(); // Temporairement désactivé
    // Générer automatiquement la référence au démarrage
    initializeGeneratedReference();
  }

  Future<void> loadDevis({int? status}) async {
    try {
      isLoading.value = true;
      final loadedDevis = await _devisService.getDevis(status: status);
      devis.value = loadedDevis;
    } catch (e) {
      // Ne pas afficher de message d'erreur si c'est une erreur d'authentification
      // (elle est déjà gérée par AuthErrorHandler)
      final errorString = e.toString().toLowerCase();
      if (!errorString.contains('session expirée') &&
          !errorString.contains('401')) {
        Get.snackbar(
          'Erreur',
          'Impossible de charger les devis',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
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
    } catch (e) {}
  }

  Future<bool> createDevis(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;

      print('📝 [DEVIS] Début de la création du devis');
      print('📝 [DEVIS] Données reçues: $data');
      print('📝 [DEVIS] Client ID: ${selectedClient.value?.id}');
      print('📝 [DEVIS] User ID: $userId');
      print('📝 [DEVIS] Nombre d\'items: ${items.length}');
      print(
        '📝 [DEVIS] Items: ${items.map((i) => {'designation': i.designation, 'quantite': i.quantite, 'prixUnitaire': i.prixUnitaire, 'total': i.total}).toList()}',
      );

      final newDevis = Devis(
        clientId: selectedClient.value!.id!,
        reference: data['reference'],
        dateCreation: DateTime.now(),
        dateValidite: data['date_validite'],
        notes: data['notes'],
        status: 1, // Forcer le statut à 1 (En attente)
        items: items,
        remiseGlobale: data['remise_globale'],
        tva: data['tva'],
        conditions: data['conditions'],
        commercialId: userId,
      );

      print('📝 [DEVIS] Objet Devis créé:');
      print('📝 [DEVIS] - clientId: ${newDevis.clientId}');
      print('📝 [DEVIS] - reference: ${newDevis.reference}');
      print('📝 [DEVIS] - dateCreation: ${newDevis.dateCreation}');
      print('📝 [DEVIS] - dateValidite: ${newDevis.dateValidite}');
      print('📝 [DEVIS] - notes: ${newDevis.notes}');
      print('📝 [DEVIS] - status: ${newDevis.status}');
      print('📝 [DEVIS] - remiseGlobale: ${newDevis.remiseGlobale}');
      print('📝 [DEVIS] - tva: ${newDevis.tva}');
      print('📝 [DEVIS] - conditions: ${newDevis.conditions}');
      print('📝 [DEVIS] - commercialId: ${newDevis.commercialId}');
      print('📝 [DEVIS] - items count: ${newDevis.items.length}');

      print('📝 [DEVIS] JSON à envoyer: ${newDevis.toJson()}');

      final createdDevis = await _devisService.createDevis(newDevis);

      print('✅ [DEVIS] Devis créé avec succès: ${createdDevis.id}');

      // Si la création réussit, afficher le message de succès
      Get.snackbar(
        'Succès',
        'Devis créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Effacer le formulaire
      clearForm();

      // Essayer de recharger la liste (mais ne pas faire échouer si ça échoue)
      try {
        await loadDevis();
      } catch (e) {
        // Si le rechargement échoue, on ne fait rien car le devis a été créé avec succès
        // L'utilisateur peut recharger manuellement si nécessaire
      }

      return true;
    } catch (e, stackTrace) {
      print('❌ [DEVIS] Erreur lors de la création: $e');
      print('❌ [DEVIS] Stack trace: $stackTrace');
      Get.snackbar(
        'Erreur',
        'Impossible de créer le devis: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateDevis(int devisId, Map<String, dynamic> data) async {
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

      // Si la mise à jour réussit, afficher le message de succès
      Get.snackbar(
        'Succès',
        'Devis mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Essayer de recharger la liste (mais ne pas faire échouer si ça échoue)
      try {
        await loadDevis();
      } catch (e) {
        // Si le rechargement échoue, on ne fait rien car le devis a été mis à jour avec succès
        // L'utilisateur peut recharger manuellement si nécessaire
      }

      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le devis',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
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

        // Rafraîchir les compteurs du dashboard patron
        DashboardRefreshHelper.refreshPatronCounter('devis');

        Get.snackbar(
          'Succès',
          'Devis accepté avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible d\'accepter le devis',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'accepter le devis',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
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

        // Rafraîchir les compteurs du dashboard patron
        DashboardRefreshHelper.refreshPatronCounter('devis');

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
      final clientsList = await _clientService.getClients();
      final validatedClients =
          clientsList.where((client) => client.status == 1).toList();

      if (query.isNotEmpty) {
        clients.value =
            validatedClients.where((client) {
              final nom = client.nom?.toLowerCase() ?? '';
              final email = client.email?.toLowerCase() ?? '';
              final searchQuery = query.toLowerCase();
              return nom.contains(searchQuery) || email.contains(searchQuery);
            }).toList();
      } else {
        clients.value = validatedClients;
      }
    } catch (e) {}
  }

  void selectClient(Client client) {
    selectedClient.value = client;
  }

  void clearSelectedClient() {
    selectedClient.value = null;
  }

  /// Générer automatiquement la référence du devis
  Future<String> generateReference() async {
    // Recharger les devis pour avoir le comptage à jour
    await loadDevis();

    // Extraire toutes les références existantes
    final existingReferences =
        devis.map((d) => d.reference).where((ref) => ref.isNotEmpty).toList();

    // Générer avec incrément
    return ReferenceGenerator.generateReferenceWithIncrement(
      'DEV',
      existingReferences,
    );
  }

  /// Initialiser la référence générée
  Future<void> initializeGeneratedReference() async {
    if (generatedReference.value.isEmpty) {
      generatedReference.value = await generateReference();
    }
  }

  /// Effacer toutes les données du formulaire
  void clearForm() {
    selectedClient.value = null;
    items.clear();
    generatedReference.value = '';
    // Régénérer un nouveau numéro de référence
    initializeGeneratedReference();
  }

  /// Générer un PDF pour un devis
  Future<void> generatePDF(int devisId) async {
    try {
      isLoading.value = true;

      // Trouver le devis
      final selectedDevis = devis.firstWhere((d) => d.id == devisId);

      // Charger les données nécessaires
      final clients = await _clientService.getClients();
      final client = clients.firstWhere((c) => c.id == selectedDevis.clientId);
      final items =
          selectedDevis.items
              .map(
                (item) => {
                  'designation': item.designation,
                  'unite': 'unité',
                  'quantite': item.quantite,
                  'prix_unitaire': item.prixUnitaire,
                  'montant_total': item.total,
                },
              )
              .toList();

      // Générer le PDF
      await PdfService().generateDevisPdf(
        devis: {
          'reference': selectedDevis.reference,
          'date_creation': selectedDevis.dateCreation,
          'montant_ht': selectedDevis.totalHT,
          'tva': selectedDevis.tva,
          'total_ttc': selectedDevis.totalTTC,
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
