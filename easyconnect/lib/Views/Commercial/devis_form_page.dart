import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/devis_controller.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:intl/intl.dart';

class DevisFormPage extends StatelessWidget {
  final DevisController controller = Get.put(DevisController());
  final bool isEditing;
  final int? devisId;

  final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa');
  final formatDate = DateFormat('dd/MM/yyyy');

  // Contrôleurs de formulaire
  final referenceController = TextEditingController();
  final notesController = TextEditingController();
  final conditionsController = TextEditingController();
  final remiseGlobaleController = TextEditingController();
  final tvaController = TextEditingController();
  final dateValiditeController = TextEditingController();

  DevisFormPage({super.key, this.isEditing = false, this.devisId});

  @override
  Widget build(BuildContext context) {
    // Charger les clients au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.searchClients('');
    });

    // Pré-remplir le formulaire si édition
    if (isEditing && devisId != null) {
      final devis = controller.devis.firstWhere(
        (d) => d.id == devisId,
        orElse:
            () => Devis(
              id: 0,
              clientId: 0,
              reference: '',
              dateCreation: DateTime.now(),
              items: [],
              remiseGlobale: 0,
              tva: 0,
              commercialId: 0,
            ),
      );

      referenceController.text = devis.reference;
      notesController.text = devis.notes ?? '';
      conditionsController.text = devis.conditions ?? '';
      remiseGlobaleController.text = devis.remiseGlobale?.toString() ?? '';
      tvaController.text = devis.tva?.toString() ?? '';
      if (devis.dateValidite != null) {
        dateValiditeController.text = formatDate.format(devis.dateValidite!);
      }
      controller.items.value = devis.items;
      if (controller.clients.isNotEmpty) {
        final client = controller.clients.firstWhere(
          (c) => c.id == devis.clientId,
          orElse: () => controller.clients.first,
        );
        controller.selectClient(client);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le devis' : 'Nouveau devis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClientSection(),
            const SizedBox(height: 16),
            _buildInformationsGenerales(),
            const SizedBox(height: 16),
            _buildArticlesSection(),
            const SizedBox(height: 16),
            _buildTotauxSection(),
            const SizedBox(height: 16),
            _buildNotesConditionsSection(),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Client',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final selectedClient = controller.selectedClient.value;
              if (selectedClient == null) {
                return ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Sélectionner un client'),
                  onPressed: _showClientSearchDialog,
                );
              }
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    selectedClient.nom?.substring(0, 1).toUpperCase() ?? '',
                  ),
                ),
                title: Text(selectedClient.nom ?? ''),
                subtitle: Text(selectedClient.email ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: controller.clearSelectedClient,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationsGenerales() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations générales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: referenceController,
              decoration: const InputDecoration(
                labelText: 'Référence',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: dateValiditeController,
              decoration: InputDecoration(
                labelText: 'Date de validité',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: Get.context!,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      dateValiditeController.text = formatDate.format(date);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Articles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un article'),
                  onPressed: () => _showItemDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.items.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucun article ajouté',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.items.length,
                itemBuilder: (context, index) {
                  final item = controller.items[index];
                  return Card(
                    child: ListTile(
                      title: Text(item.designation),
                      subtitle: Text(
                        '${item.quantite} x ${formatCurrency.format(item.prixUnitaire)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.remise != null && item.remise! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '-${item.remise}%',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            formatCurrency.format(item.total),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed:
                                () => _showItemDialog(index: index, item: item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => controller.removeItem(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTotauxSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Totaux',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: remiseGlobaleController,
                    decoration: const InputDecoration(
                      labelText: 'Remise globale (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: tvaController,
                    decoration: const InputDecoration(
                      labelText: 'TVA (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              final devis = Devis(
                clientId: controller.selectedClient.value?.id ?? 0,
                reference: referenceController.text,
                dateCreation: DateTime.now(),
                items: controller.items,
                remiseGlobale:
                    double.tryParse(remiseGlobaleController.text) ?? 0,
                tva: double.tryParse(tvaController.text) ?? 0,
                commercialId: 0,
              );

              return Column(
                children: [
                  _buildTotalRow('Sous-total', devis.sousTotal),
                  if (devis.remise > 0)
                    _buildTotalRow('Remise', -devis.remise, color: Colors.red),
                  _buildTotalRow('Total HT', devis.totalHT, bold: true),
                  if (devis.montantTVA > 0)
                    _buildTotalRow('TVA', devis.montantTVA),
                  _buildTotalRow(
                    'Total TTC',
                    devis.totalTTC,
                    bold: true,
                    large: true,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesConditionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes et conditions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: conditionsController,
              decoration: const InputDecoration(
                labelText: 'Conditions',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double montant, {
    bool bold = false,
    bool large = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: large ? 18 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            formatCurrency.format(montant),
            style: TextStyle(
              fontSize: large ? 18 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showClientSearchDialog() {
    final searchController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Sélectionner un client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Rechercher un client',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => controller.searchClients(value),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              width: double.maxFinite,
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.clients.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucun client validé trouvé',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Veuillez d\'abord créer et valider des clients',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: controller.clients.length,
                  itemBuilder: (context, index) {
                    final client = controller.clients[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                      ),
                      title: Text(client.nom ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(client.email ?? ''),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Validé',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        controller.selectClient(client);
                        Get.back();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Get.back();
              Get.toNamed('/clients/new');
            },
            child: const Text('Nouveau client'),
          ),
        ],
      ),
    );
  }

  void _showItemDialog({int? index, DevisItem? item}) {
    final designationController = TextEditingController(
      text: item?.designation ?? '',
    );
    final quantiteController = TextEditingController(
      text: item?.quantite.toString() ?? '',
    );
    final prixUnitaireController = TextEditingController(
      text: item?.prixUnitaire.toString() ?? '',
    );
    final remiseController = TextEditingController(
      text: item?.remise?.toString() ?? '',
    );

    Get.dialog(
      AlertDialog(
        title: Text(item == null ? 'Nouvel article' : 'Modifier l\'article'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: designationController,
              decoration: const InputDecoration(
                labelText: 'Désignation',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: quantiteController,
                    decoration: const InputDecoration(
                      labelText: 'Quantité',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: prixUnitaireController,
                    decoration: const InputDecoration(
                      labelText: 'Prix unitaire',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: remiseController,
              decoration: const InputDecoration(
                labelText: 'Remise (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final newItem = DevisItem(
                id: item?.id,
                designation: designationController.text,
                quantite: int.tryParse(quantiteController.text) ?? 0,
                prixUnitaire: double.tryParse(prixUnitaireController.text) ?? 0,
                remise: double.tryParse(remiseController.text),
              );
              if (index != null) {
                controller.updateItem(index, newItem);
              } else {
                controller.addItem(newItem);
              }
              Get.back();
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  /// Effacer tous les champs du formulaire
  void _clearForm() {
    referenceController.clear();
    notesController.clear();
    conditionsController.clear();
    remiseGlobaleController.clear();
    tvaController.clear();
    dateValiditeController.clear();
    controller.clearForm();
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saveDevis,
        icon: const Icon(Icons.save),
        label: Text(isEditing ? 'Modifier le devis' : 'Créer le devis'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _saveDevis() {
    if (controller.selectedClient.value == null) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner un client',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (controller.items.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez ajouter au moins un article',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (referenceController.text.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez saisir une référence',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final data = {
      'reference': referenceController.text,
      'date_validite':
          dateValiditeController.text.isNotEmpty
              ? DateFormat('dd/MM/yyyy').parse(dateValiditeController.text)
              : null,
      'notes': notesController.text,
      'conditions': conditionsController.text,
      'remise_globale': double.tryParse(remiseGlobaleController.text),
      'tva': double.tryParse(tvaController.text),
    };

    if (isEditing && devisId != null) {
      controller.updateDevis(devisId!, data);
    } else {
      // Pour la création, effacer le formulaire après la création
      controller.createDevis(data).then((_) {
        _clearForm();
      });
    }
  }
}
