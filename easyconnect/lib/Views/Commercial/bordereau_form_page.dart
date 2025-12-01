import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/bordereau_controller.dart';
import 'package:easyconnect/Models/bordereau_model.dart';
import 'package:easyconnect/Views/Components/devis_selection_dialog.dart';
import 'package:intl/intl.dart';

class BordereauFormPage extends StatefulWidget {
  final bool isEditing;
  final int? bordereauId;

  const BordereauFormPage({
    super.key,
    this.isEditing = false,
    this.bordereauId,
  });

  @override
  State<BordereauFormPage> createState() => _BordereauFormPageState();
}

class _BordereauFormPageState extends State<BordereauFormPage> {
  final BordereauxController controller = Get.put(BordereauxController());

  // Contrôleurs de formulaire
  late final TextEditingController referenceController;
  late final TextEditingController notesController;

  final formKey = GlobalKey<FormState>();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Toujours réinitialiser les contrôleurs pour avoir des champs vides
    referenceController = TextEditingController();
    notesController = TextEditingController();

    // S'assurer que le formulaire du contrôleur est aussi réinitialisé
    if (!widget.isEditing) {
      controller.clearForm();
    }

    // Écouter les changements de la référence générée pour mettre à jour le champ
    ever(controller.generatedReference, (String ref) {
      if (ref.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (referenceController.text != ref) {
            referenceController.text = ref;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    referenceController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _initializeFormIfNeeded() {
    if (!_isInitialized && widget.isEditing && widget.bordereauId != null) {
      try {
        final bordereau = controller.bordereaux.firstWhere(
          (b) => b.id == widget.bordereauId,
        );
        referenceController.text = bordereau.reference;
        notesController.text = bordereau.notes ?? '';
        controller.items.value = bordereau.items;
        _isInitialized = true;
      } catch (e) {
        // Le bordereau n'est pas encore chargé, on réessayera plus tard
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _initializeFormIfNeeded();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Modifier le bordereau' : 'Nouveau bordereau',
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
                                selectedClient.nomEntreprise?.isNotEmpty == true
                                    ? selectedClient.nomEntreprise!
                                    : '${selectedClient.nom ?? ''} ${selectedClient.prenom ?? ''}'
                                        .trim()
                                        .isNotEmpty
                                    ? '${selectedClient.nom ?? ''} ${selectedClient.prenom ?? ''}'
                                        .trim()
                                    : 'Client #${selectedClient.id}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (selectedClient.nomEntreprise?.isNotEmpty ==
                                      true &&
                                  '${selectedClient.nom ?? ''} ${selectedClient.prenom ?? ''}'
                                      .trim()
                                      .isNotEmpty)
                                Text(
                                  'Contact: ${selectedClient.nom ?? ''} ${selectedClient.prenom ?? ''}'
                                      .trim(),
                                ),
                              if (selectedClient.email != null)
                                Text(selectedClient.email ?? ''),
                              if (selectedClient.contact != null)
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
                      Obx(() {
                        // Si un devis est sélectionné, générer automatiquement la référence
                        if (controller.selectedDevis.value != null) {
                          // Mettre à jour le contrôleur avec la référence générée
                          final generatedRef =
                              controller.generatedReference.value;
                          if (generatedRef.isNotEmpty &&
                              referenceController.text != generatedRef) {
                            referenceController.text = generatedRef;
                          }
                          return TextFormField(
                            controller: referenceController,
                            decoration: const InputDecoration(
                              labelText: 'Référence (générée automatiquement)',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey,
                              helperText: 'Référence générée automatiquement',
                            ),
                            readOnly: true,
                            enabled: false,
                            validator: (value) {
                              // Utiliser la valeur générée si le champ est vide
                              final refValue =
                                  (value == null || value.isEmpty)
                                      ? controller.generatedReference.value
                                      : value;
                              if (refValue.isEmpty) {
                                return 'La référence est requise';
                              }
                              return null;
                            },
                          );
                        }
                        // Sinon, permettre la saisie manuelle
                        return TextFormField(
                          controller: referenceController,
                          decoration: const InputDecoration(
                            labelText: 'Référence',
                            border: OutlineInputBorder(),
                            helperText:
                                'Saisissez une référence ou sélectionnez un devis',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'La référence est requise';
                            }
                            return null;
                          },
                        );
                      }),
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
        onPressed: () async {
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

            // Vérifier qu'il y a des items
            if (controller.items.isEmpty) {
              Get.snackbar(
                'Erreur',
                'Veuillez ajouter au moins un article',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              return;
            }

            // Utiliser la référence générée si disponible, sinon celle du contrôleur
            final reference =
                controller.generatedReference.value.isNotEmpty
                    ? controller.generatedReference.value
                    : referenceController.text.trim();

            if (reference.isEmpty) {
              Get.snackbar(
                'Erreur',
                'La référence est requise',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              return;
            }

            final data = {
              'reference': reference,
              'notes': notesController.text,
            };

            if (widget.isEditing && widget.bordereauId != null) {
              final success = await controller.updateBordereau(
                widget.bordereauId!,
                data,
              );
              if (success) {
                await Future.delayed(const Duration(milliseconds: 500));
                Get.offNamed('/bordereaux');
              }
            } else {
              final success = await controller.createBordereau(data);
              if (success) {
                await Future.delayed(const Duration(milliseconds: 500));
                Get.offNamed('/bordereaux');
              }
            }
          }
        },
        icon: const Icon(Icons.save),
        label: Text(widget.isEditing ? 'Modifier le bordereau' : 'Enregistrer'),
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
    return Card(
      child: ListTile(
        title: Text(item.designation),
        subtitle: Text('${item.quantite} ${item.unite}'),
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
                          client.nomEntreprise?.isNotEmpty == true
                              ? client.nomEntreprise!
                              : '${client.nom ?? ''} ${client.prenom ?? ''}'
                                  .trim()
                                  .isNotEmpty
                              ? '${client.nom ?? ''} ${client.prenom ?? ''}'
                                  .trim()
                              : 'Client #${client.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (client.nomEntreprise?.isNotEmpty == true &&
                                '${client.nom ?? ''} ${client.prenom ?? ''}'
                                    .trim()
                                    .isNotEmpty)
                              Text(
                                'Contact: ${client.nom ?? ''} ${client.prenom ?? ''}'
                                    .trim(),
                              ),
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
            onDevisSelected: (devis) async {
              await controller.selectDevis(devis);
              // Le dialog se ferme déjà automatiquement avec Get.back() dans DevisSelectionDialog
              // Pas besoin de fermer ici pour éviter de fermer la page principale
            },
          ),
    );
  }
}
