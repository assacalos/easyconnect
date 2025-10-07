import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:easyconnect/services/devis_service.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';

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

  @override
  void onInit() {
    super.onInit();
    loadDevis();
    // loadStats(); // Temporairement désactivé
  }

  Future<void> loadDevis({int? status}) async {
    try {
      isLoading.value = true;
      final loadedDevis = await _devisService.getDevis(status: status);
      devis.value = loadedDevis;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les devis',
        snackPosition: SnackPosition.BOTTOM,
      );
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
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
    }
  }

  Future<void> createDevis(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;

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

      final createdDevis = await _devisService.createDevis(newDevis);
      await loadDevis();

      // Effacer le formulaire
      clearForm();

      Get.back();
      Get.snackbar(
        'Succès',
        'Devis créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer le devis',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateDevis(int devisId, Map<String, dynamic> data) async {
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
      Get.back();
      Get.snackbar(
        'Succès',
        'Devis mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
      loadDevis();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le devis',
        snackPosition: SnackPosition.BOTTOM,
      );
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
        Get.snackbar(
          'Succès',
          'Devis accepté avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de l\'acceptation');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'accepter le devis',
        snackPosition: SnackPosition.BOTTOM,
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

  /// Effacer toutes les données du formulaire
  void clearForm() {
    selectedClient.value = null;
    items.clear();
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
