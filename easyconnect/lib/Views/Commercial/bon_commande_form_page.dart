import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/bon_commande_controller.dart';
import 'package:easyconnect/Models/bon_commande_model.dart';
import 'package:easyconnect/Views/Components/client_selection_dialog.dart';
import 'package:intl/intl.dart';

class BonCommandeFormPage extends StatelessWidget {
  final BonCommandeController controller = Get.put(BonCommandeController());
  final bool isEditing;
  final int? bonCommandeId;

  BonCommandeFormPage({super.key, this.isEditing = false, this.bonCommandeId});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final referenceController = TextEditingController();
    final notesController = TextEditingController();
    final remiseController = TextEditingController();
    final tvaController = TextEditingController(text: '20.0');
    final conditionsController = TextEditingController();
    final adresseLivraisonController = TextEditingController();
    final dateLivraisonController = TextEditingController();

    if (isEditing && bonCommandeId != null) {
      final bonCommande = controller.bonCommandes.firstWhere(
        (b) => b.id == bonCommandeId,
      );
      referenceController.text = bonCommande.reference;
      notesController.text = bonCommande.notes ?? '';
      remiseController.text = bonCommande.remiseGlobale?.toString() ?? '';
      tvaController.text = bonCommande.tva?.toString() ?? '20.0';
      conditionsController.text = bonCommande.conditions ?? '';
      adresseLivraisonController.text = bonCommande.adresseLivraison ?? '';
      if (bonCommande.dateLivraisonPrevue != null) {
        dateLivraisonController.text = DateFormat(
          'dd/MM/yyyy',
        ).format(bonCommande.dateLivraisonPrevue!);
      }
      controller.items.value = bonCommande.items;
      // TODO: Charger le client si nécessaire
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Modifier le bon de commande' : 'Nouveau bon de commande',
        ),
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
                        controller: dateLivraisonController,
                        decoration: const InputDecoration(
                          labelText: 'Date de livraison prévue',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            dateLivraisonController.text = DateFormat(
                              'dd/MM/yyyy',
                            ).format(date);
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La date de livraison est requise';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: adresseLivraisonController,
                        decoration: const InputDecoration(
                          labelText: 'Adresse de livraison',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'L\'adresse de livraison est requise';
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (formKey.currentState!.validate()) {
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

                  final data = {
                    'reference': referenceController.text,
                    'date_livraison_prevue': DateFormat(
                      'dd/MM/yyyy',
                    ).parse(dateLivraisonController.text),
                    'adresse_livraison': adresseLivraisonController.text,
                    'notes': notesController.text,
                    'remise_globale': double.tryParse(remiseController.text),
                    'tva': double.tryParse(tvaController.text),
                    'conditions': conditionsController.text,
                  };

                  if (isEditing && bonCommandeId != null) {
                    controller.updateBonCommande(bonCommandeId!, data);
                  } else {
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

                    controller.createBonCommande(data);
                  }
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(BonCommandeItem item, int index) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'fcfa',
    );
    final formatDate = DateFormat('dd/MM/yyyy');

    return Card(
      child: ListTile(
        title: Text(item.designation),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.quantite} ${item.unite}'),
            Text('Prix unitaire: ${formatCurrency.format(item.prixUnitaire)}'),
            Text('Total: ${formatCurrency.format(item.montantTotal)}'),
            if (item.dateLivraison != null)
              Text('Livraison: ${formatDate.format(item.dateLivraison!)}'),
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
    showDialog(
      context: context,
      builder:
          (context) => ClientSelectionDialog(
            onClientSelected: (client) {
              controller.selectClient(client);
              // Le dialog se ferme déjà automatiquement avec Navigator.of(context).pop()
              // Pas besoin d'appeler Get.back() ici
            },
          ),
    );
  }

  void _showItemForm(
    BuildContext context, {
    BonCommandeItem? item,
    int? index,
  }) {
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
    final dateLivraisonController = TextEditingController(
      text:
          item?.dateLivraison != null
              ? DateFormat('dd/MM/yyyy').format(item!.dateLivraison!)
              : '',
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
                      controller: dateLivraisonController,
                      decoration: const InputDecoration(
                        labelText: 'Date de livraison',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          dateLivraisonController.text = DateFormat(
                            'dd/MM/yyyy',
                          ).format(date);
                        }
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
                    final newItem = BonCommandeItem(
                      designation: designationController.text,
                      unite: uniteController.text,
                      quantite: int.parse(quantiteController.text),
                      prixUnitaire: double.parse(prixController.text),
                      description: descriptionController.text,
                      dateLivraison:
                          dateLivraisonController.text.isNotEmpty
                              ? DateFormat(
                                'dd/MM/yyyy',
                              ).parse(dateLivraisonController.text)
                              : null,
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
}
