import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/bordereau_controller.dart';
import 'package:easyconnect/Models/bordereau_model.dart';
import 'package:easyconnect/Views/Components/devis_selection_dialog.dart';
import 'package:intl/intl.dart';

class BordereauFormPage extends StatelessWidget {
  final BordereauxController controller = Get.put(BordereauxController());
  final bool isEditing;
  final int? bordereauId;

  // Contrôleurs de formulaire
  final referenceController = TextEditingController();
  final notesController = TextEditingController();
  final remiseController = TextEditingController();
  final tvaController = TextEditingController(text: '20.0');
  final conditionsController = TextEditingController();

  BordereauFormPage({super.key, this.isEditing = false, this.bordereauId});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    if (isEditing && bordereauId != null) {
      final bordereau = controller.bordereaux.firstWhere(
        (b) => b.id == bordereauId,
      );
      referenceController.text = bordereau.reference;
      notesController.text = bordereau.notes ?? '';
      remiseController.text = bordereau.remiseGlobale?.toString() ?? '';
      tvaController.text = bordereau.tva?.toString() ?? '20.0';
      conditionsController.text = bordereau.conditions ?? '';
      controller.items.value = bordereau.items;
      // TODO: Charger le client si nécessaire
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le bordereau' : 'Nouveau bordereau'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sélection du client
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Client',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Text(
                              'Validés uniquement',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Obx(() {
                        final selectedClient = controller.selectedClient.value;
                        if (selectedClient != null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${selectedClient.nom}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(selectedClient.email ?? ''),
                              Text(selectedClient.contact ?? ''),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: controller.clearSelectedClient,
                                child: const Text('Changer de client'),
                              ),
                            ],
                          );
                        }
                        return ElevatedButton(
                          onPressed: () => _showClientSelection(context),
                          child: const Text('Sélectionner un client'),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Section Devis
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Devis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: const Text(
                              'Validés uniquement',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Obx(() {
                            if (controller.selectedClient.value == null) {
                              return const Text(
                                'Sélectionnez d\'abord un client',
                                style: TextStyle(color: Colors.grey),
                              );
                            }
                            return ElevatedButton.icon(
                              onPressed:
                                  controller.availableDevis.isEmpty
                                      ? null
                                      : () => _showDevisSelection(context),
                              icon: const Icon(Icons.description, size: 16),
                              label: const Text('Sélectionner'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Obx(() {
                        final selectedDevis = controller.selectedDevis.value;
                        if (selectedDevis != null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Devis ${selectedDevis.reference + ' -B'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Date: ${DateFormat('dd/MM/yyyy').format(selectedDevis.dateCreation)}',
                              ),
                              Text('Articles: ${selectedDevis.items.length}'),
                              Text(
                                'Total HT: ${selectedDevis.totalHT.toStringAsFixed(2)} FCFA',
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: controller.clearSelectedDevis,
                                child: const Text('Changer de devis'),
                              ),
                            ],
                          );
                        }
                        return const Text(
                          'Aucun devis sélectionné',
                          style: TextStyle(color: Colors.grey),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Informations générales
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations générales',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: referenceController,
                        decoration: const InputDecoration(
                          labelText: 'Référence',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La référence est requise';
                          }
                          return null;
                        },
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Liste des items
              Card(
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showItemForm(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        if (controller.items.isEmpty) {
                          return const Center(
                            child: Text('Aucun article ajouté'),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.items.length,
                          itemBuilder: (context, index) {
                            final item = controller.items[index];
                            return _buildItemCard(item, index);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Totaux et conditions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Totaux et conditions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: remiseController,
                        decoration: const InputDecoration(
                          labelText: 'Remise globale (%)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: tvaController,
                        decoration: const InputDecoration(
                          labelText: 'TVA (%)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
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
              ),
              const SizedBox(height: 24),
              _buildSaveButton(formKey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(GlobalKey<FormState> formKey) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          if (formKey.currentState!.validate()) {
            // Vérifier qu'un client validé est sélectionné
            if (controller.selectedClient.value == null) {
              Get.snackbar(
                'Erreur',
                'Veuillez sélectionner un client validé',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              return;
            }

            // Vérifier que le client sélectionné est bien validé
            if (controller.selectedClient.value!.status != 1) {
              Get.snackbar(
                'Erreur',
                'Seuls les clients validés peuvent être sélectionnés',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              return;
            }

            // Vérifier qu'un devis validé est sélectionné
            if (controller.selectedDevis.value == null) {
              Get.snackbar(
                'Erreur',
                'Veuillez sélectionner un devis validé',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              return;
            }

            // Vérifier que le devis sélectionné est bien validé (status = 2)
            if (controller.selectedDevis.value!.status != 2) {
              Get.snackbar(
                'Erreur',
                'Seuls les devis validés peuvent être utilisés',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              return;
            }

            final data = {
              'reference': referenceController.text,
              'notes': notesController.text,
              'remise_globale': double.tryParse(remiseController.text),
              'tva': double.tryParse(tvaController.text),
              'conditions': conditionsController.text,
            };

            if (isEditing && bordereauId != null) {
              controller.updateBordereau(bordereauId!, data);
            } else {
              // Pour la création
              controller.createBordereau(data);
            }
          }
        },
        icon: const Icon(Icons.save),
        label: Text(isEditing ? 'Modifier le bordereau' : 'Enregistrer'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildItemCard(BordereauItem item, int index) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'fcfa',
    );

    return Card(
      child: ListTile(
        title: Text(item.designation),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.quantite} ${item.unite}'),
            Text('Prix unitaire: ${formatCurrency.format(item.prixUnitaire)}'),
            Text('Total: ${formatCurrency.format(item.montantTotal)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed:
                  () => _showItemForm(Get.context!, item: item, index: index),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => controller.removeItem(index),
            ),
          ],
        ),
      ),
    );
  }

  void _showClientSelection(BuildContext context) {
    // Charger les clients validés si pas encore fait
    if (controller.availableClients.isEmpty) {
      controller.loadValidatedClients();
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sélectionner un client'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Obx(() {
                if (controller.isLoadingClients.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.availableClients.isEmpty) {
                  return const Center(
                    child: Text('Aucun client validé disponible'),
                  );
                }

                return ListView.builder(
                  itemCount: controller.availableClients.length,
                  itemBuilder: (context, index) {
                    final client = controller.availableClients[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: client.statusColor,
                          child: Icon(client.statusIcon, color: Colors.white),
                        ),
                        title: Text(
                          '${client.nom ?? ''} ${client.prenom ?? ''}'.trim(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (client.nomEntreprise != null)
                              Text('Entreprise: ${client.nomEntreprise}'),
                            if (client.email != null)
                              Text('Email: ${client.email}'),
                            if (client.contact != null)
                              Text('Contact: ${client.contact}'),
                            Text(
                              'Statut: ${client.statusText}',
                              style: TextStyle(
                                color: client.statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          controller.selectClient(client);
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                );
              }),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
            ],
          ),
    );
  }

  void _showItemForm(BuildContext context, {BordereauItem? item, int? index}) {
    final formKey = GlobalKey<FormState>();
    final designationController = TextEditingController(
      text: item?.designation,
    );
    final uniteController = TextEditingController(text: item?.unite);
    final quantiteController = TextEditingController(
      text: item?.quantite.toString(),
    );
    final prixController = TextEditingController(
      text: item?.prixUnitaire.toString(),
    );
    final descriptionController = TextEditingController(
      text: item?.description,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              item == null ? 'Ajouter un article' : 'Modifier l\'article',
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: designationController,
                      decoration: const InputDecoration(
                        labelText: 'Désignation',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La désignation est requise';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: uniteController,
                      decoration: const InputDecoration(labelText: 'Unité'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'L\'unité est requise';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: quantiteController,
                      decoration: const InputDecoration(labelText: 'Quantité'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La quantité est requise';
                        }
                        if (int.tryParse(value) == null) {
                          return 'La quantité doit être un nombre';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: prixController,
                      decoration: const InputDecoration(
                        labelText: 'Prix unitaire',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le prix unitaire est requis';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Le prix unitaire doit être un nombre';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final newItem = BordereauItem(
                      designation: designationController.text,
                      unite: uniteController.text,
                      quantite: int.parse(quantiteController.text),
                      prixUnitaire: double.parse(prixController.text),
                      description: descriptionController.text,
                    );

                    if (index != null) {
                      controller.updateItem(index, newItem);
                    } else {
                      controller.addItem(newItem);
                    }
                    Get.back();
                  }
                },
                child: Text(item == null ? 'Ajouter' : 'Modifier'),
              ),
            ],
          ),
    );
  }

  void _showDevisSelection(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => DevisSelectionDialog(
            devis: controller.availableDevis,
            isLoading: controller.isLoadingDevis.value,
            onDevisSelected: (devis) {
              controller.selectDevis(devis);
              Navigator.of(
                context,
              ).pop(); // Fermer seulement le dialog, pas la page
            },
          ),
    );
  }
}
