import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/bon_de_commande_fournisseur_controller.dart';
import 'package:easyconnect/Models/bon_de_commande_fournisseur_model.dart';
import 'package:intl/intl.dart';

class BonDeCommandeFournisseurFormPage extends StatefulWidget {
  final bool isEditing;
  final int? bonDeCommandeId;

  const BonDeCommandeFournisseurFormPage({
    super.key,
    this.isEditing = false,
    this.bonDeCommandeId,
  });

  @override
  State<BonDeCommandeFournisseurFormPage> createState() =>
      _BonDeCommandeFournisseurFormPageState();
}

class _BonDeCommandeFournisseurFormPageState
    extends State<BonDeCommandeFournisseurFormPage> {
  final BonDeCommandeFournisseurController controller = Get.put(
    BonDeCommandeFournisseurController(),
  );

  final formKey = GlobalKey<FormState>();
  late final TextEditingController numeroCommandeController;
  late final TextEditingController descriptionController;
  late final TextEditingController commentaireController;
  late final TextEditingController conditionsPaiementController;
  late final TextEditingController delaiLivraisonController;

  @override
  void initState() {
    super.initState();
    numeroCommandeController = TextEditingController();
    descriptionController = TextEditingController();
    commentaireController = TextEditingController();
    conditionsPaiementController = TextEditingController();
    delaiLivraisonController = TextEditingController();

    // Réinitialiser le formulaire si c'est une nouvelle création
    if (!widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.clearForm();
      });
    }

    // Écouter les changements de la référence générée pour mettre à jour le champ
    ever(controller.generatedNumeroCommande, (String ref) {
      if (ref.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (numeroCommandeController.text != ref) {
            numeroCommandeController.text = ref;
          }
        });
      }
    });

    // Pré-remplir si édition
    if (widget.isEditing && widget.bonDeCommandeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadBonDeCommandeData();
      });
    }
  }

  void _loadBonDeCommandeData() {
    try {
      final bonDeCommande = controller.bonDeCommandes.firstWhere(
        (b) => b.id == widget.bonDeCommandeId,
      );
      numeroCommandeController.text = bonDeCommande.numeroCommande;
      descriptionController.text = bonDeCommande.description ?? '';
      commentaireController.text = bonDeCommande.commentaire ?? '';
      conditionsPaiementController.text =
          bonDeCommande.conditionsPaiement ?? '';
      delaiLivraisonController.text =
          bonDeCommande.delaiLivraison?.toString() ?? '';
      controller.items.value = bonDeCommande.items;
    } catch (e) {
      // Le bon de commande n'est pas encore chargé
    }
  }

  @override
  void dispose() {
    numeroCommandeController.dispose();
    descriptionController.dispose();
    commentaireController.dispose();
    conditionsPaiementController.dispose();
    delaiLivraisonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Modifier le bon de commande'
              : 'Nouveau bon de commande fournisseur',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sélection fournisseur
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fournisseur *',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        final selectedSupplier =
                            controller.selectedSupplier.value;
                        if (selectedSupplier != null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fournisseur: ${selectedSupplier.nom}'),
                              Text(selectedSupplier.email),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  controller.selectSupplier(null);
                                },
                                child: const Text('Changer'),
                              ),
                            ],
                          );
                        }
                        return ElevatedButton(
                          onPressed: () => _showSupplierSelection(context),
                          child: const Text('Sélectionner un fournisseur'),
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
                        // Mettre à jour le contrôleur avec le numéro généré si nécessaire
                        final generatedRef =
                            controller.generatedNumeroCommande.value;
                        if (generatedRef.isNotEmpty &&
                            numeroCommandeController.text != generatedRef) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted &&
                                numeroCommandeController.text != generatedRef) {
                              numeroCommandeController.text = generatedRef;
                            }
                          });
                        }
                        return TextFormField(
                          controller: numeroCommandeController,
                          decoration: const InputDecoration(
                            labelText:
                                'Numéro de commande (généré automatiquement) *',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey,
                            helperText: 'Numéro généré automatiquement',
                          ),
                          readOnly: true,
                          enabled: false,
                          validator: (value) {
                            // Utiliser la valeur générée si le champ est vide
                            final refValue =
                                (value == null || value.isEmpty)
                                    ? controller.generatedNumeroCommande.value
                                    : value;
                            if (refValue.isEmpty) {
                              return 'Le numéro de commande est requis';
                            }
                            return null;
                          },
                        );
                      }),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: commentaireController,
                        decoration: const InputDecoration(
                          labelText: 'Commentaire',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: conditionsPaiementController,
                        decoration: const InputDecoration(
                          labelText: 'Conditions de paiement',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: delaiLivraisonController,
                        decoration: const InputDecoration(
                          labelText: 'Délai de livraison (jours)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
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
                            'Articles *',
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
                            return _buildItemCard(context, item, index);
                          },
                        );
                      }),
                      const SizedBox(height: 16),
                      Obx(() {
                        final total = controller.items.fold(
                          0.0,
                          (sum, item) => sum + item.montantTotal,
                        );
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Montant total:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                NumberFormat.currency(
                                  locale: 'fr_FR',
                                  symbol: 'fcfa',
                                ).format(total),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bouton de soumission
              Obx(
                () => ElevatedButton(
                  onPressed:
                      controller.isLoading.value
                          ? null
                          : () async {
                            if (formKey.currentState!.validate()) {
                              if (controller.selectedSupplier.value == null) {
                                Get.snackbar(
                                  'Erreur',
                                  'Veuillez sélectionner un fournisseur',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                                return;
                              }
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
                              final data = {
                                'numero_commande':
                                    controller
                                            .generatedNumeroCommande
                                            .value
                                            .isNotEmpty
                                        ? controller
                                            .generatedNumeroCommande
                                            .value
                                        : numeroCommandeController.text,
                                'date_commande': DateTime.now(),
                                'description':
                                    descriptionController.text.isEmpty
                                        ? null
                                        : descriptionController.text,
                                'commentaire':
                                    commentaireController.text.isEmpty
                                        ? null
                                        : commentaireController.text,
                                'conditions_paiement':
                                    conditionsPaiementController.text.isEmpty
                                        ? null
                                        : conditionsPaiementController.text,
                                'delai_livraison':
                                    delaiLivraisonController.text.isEmpty
                                        ? null
                                        : int.tryParse(
                                          delaiLivraisonController.text,
                                        ),
                              };
                              if (widget.isEditing &&
                                  widget.bonDeCommandeId != null) {
                                final success = await controller
                                    .updateBonDeCommande(
                                      widget.bonDeCommandeId!,
                                      data,
                                    );
                                if (success) {
                                  Get.back();
                                }
                              } else {
                                final success = await controller
                                    .createBonDeCommande(data);
                                if (success) {
                                  Get.back();
                                }
                              }
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      controller.isLoading.value
                          ? const CircularProgressIndicator()
                          : Text(widget.isEditing ? 'Modifier' : 'Créer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    BonDeCommandeItem item,
    int index,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.designation),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.ref != null && item.ref!.isNotEmpty)
              Text('Ref: ${item.ref}'),
            Text('Quantité: ${item.quantite}'),
            Text(
              'Prix unitaire: ${NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa').format(item.prixUnitaire)}',
            ),
            Text(
              'Total: ${NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa').format(item.montantTotal)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (item.description != null && item.description!.isNotEmpty)
              Text('Description: ${item.description}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => controller.removeItem(index),
        ),
        onTap: () => _showItemForm(context, index: index, item: item),
      ),
    );
  }

  void _showItemForm(
    BuildContext context, {
    int? index,
    BonDeCommandeItem? item,
  }) {
    final refController = TextEditingController(text: item?.ref ?? '');
    final designationController = TextEditingController(
      text: item?.designation ?? '',
    );
    final quantiteController = TextEditingController(
      text: item?.quantite.toString() ?? '1',
    );
    final prixController = TextEditingController(
      text: item?.prixUnitaire.toString() ?? '0',
    );
    final descriptionController = TextEditingController(
      text: item?.description ?? '',
    );

    Get.dialog(
      AlertDialog(
        title: Text(
          item == null ? 'Ajouter un article' : 'Modifier l\'article',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: refController,
                decoration: const InputDecoration(
                  labelText: 'Référence',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: designationController,
                decoration: const InputDecoration(
                  labelText: 'Désignation *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La désignation est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantiteController,
                decoration: const InputDecoration(
                  labelText: 'Quantité *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La quantité est requise';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Quantité invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: prixController,
                decoration: const InputDecoration(
                  labelText: 'Prix unitaire *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le prix unitaire est requis';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Prix invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (designationController.text.isEmpty ||
                  quantiteController.text.isEmpty ||
                  prixController.text.isEmpty) {
                Get.snackbar(
                  'Erreur',
                  'Veuillez remplir tous les champs obligatoires',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }

              final newItem = BonDeCommandeItem(
                id: item?.id,
                ref: refController.text.isEmpty ? null : refController.text,
                designation: designationController.text,
                quantite: int.parse(quantiteController.text),
                prixUnitaire: double.parse(prixController.text),
                description:
                    descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text,
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

  void _showSupplierSelection(BuildContext context) async {
    await Get.dialog(
      AlertDialog(
        title: const Text('Sélectionner un fournisseur'),
        content: Obx(() {
          if (controller.isLoadingSuppliers.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.availableSuppliers.isEmpty) {
            return const Text('Aucun fournisseur disponible');
          }
          return SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: controller.availableSuppliers.length,
              itemBuilder: (context, index) {
                final supplier = controller.availableSuppliers[index];
                return ListTile(
                  title: Text(supplier.nom),
                  subtitle: Text(supplier.email),
                  onTap: () {
                    controller.selectSupplier(supplier);
                    controller.selectClient(null);
                    Get.back();
                  },
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
