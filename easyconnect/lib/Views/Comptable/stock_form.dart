import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/stock_controller.dart';
import 'package:easyconnect/Models/stock_model.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';

class StockForm extends StatefulWidget {
  final Stock? stock;

  const StockForm({super.key, this.stock});

  @override
  State<StockForm> createState() => _StockFormState();
}

class _StockFormState extends State<StockForm> {
  final StockController controller = Get.put(StockController());
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Si on édite un stock existant, remplir le formulaire
    if (widget.stock != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fillForm(widget.stock!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.stock == null ? 'Nouveau Produit' : 'Modifier le Produit',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveStock(controller),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations de base
              _buildSectionTitle('Informations de base'),
              const SizedBox(height: 16),

              TextFormField(
                controller: controller.nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est obligatoire';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: controller.descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Description du produit (optionnel)',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // Catégorie
              Obx(
                () => DropdownButtonFormField<String>(
                  value:
                      controller.selectedCategoryForm.value.isNotEmpty
                          ? controller.selectedCategoryForm.value
                          : null,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items:
                      controller.stockCategories.map<DropdownMenuItem<String>>((
                        category,
                      ) {
                        return DropdownMenuItem<String>(
                          value: category['value'] as String,
                          child: Text(category['label'] as String),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectCategory(value);
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La catégorie est obligatoire';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: controller.skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU (Code produit) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                  hintText: 'Code unique du produit',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le SKU est obligatoire';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Informations de stock
              _buildSectionTitle('Informations de stock'),
              const SizedBox(height: 16),

              TextFormField(
                controller: controller.quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantité initiale *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La quantité est obligatoire';
                  }
                  if (double.tryParse(value) == null) {
                    return 'La quantité doit être un nombre';
                  }
                  if (double.parse(value) < 0) {
                    return 'La quantité ne peut pas être négative';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.minQuantityController,
                      decoration: const InputDecoration(
                        labelText: 'Seuil minimum *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.warning),
                        hintText: 'Alerte stock faible',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le seuil minimum est obligatoire';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Le seuil minimum doit être un nombre';
                        }
                        if (double.parse(value) < 0) {
                          return 'Le seuil minimum ne peut pas être négatif';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: controller.maxQuantityController,
                      decoration: const InputDecoration(
                        labelText: 'Seuil maximum *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.trending_up),
                        hintText: 'Alerte surstock',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le seuil maximum est obligatoire';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Le seuil maximum doit être un nombre';
                        }
                        if (double.parse(value) < 0) {
                          return 'Le seuil maximum ne peut pas être négatif';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: controller.unitPriceController,
                decoration: const InputDecoration(
                  labelText: 'Prix unitaire (fcfa) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.euro),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le prix unitaire est obligatoire';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Le prix unitaire doit être un nombre';
                  }
                  if (double.parse(value) < 0) {
                    return 'Le prix unitaire ne peut pas être négatif';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: controller.notesController,
                decoration: const InputDecoration(
                  labelText: 'Commentaire',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  hintText: 'Commentaire optionnel',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Boutons d'action uniformes
              UniformFormButtons(
                onCancel: () => Get.back(),
                onSubmit: () => _saveStock(controller),
                submitText: 'Soumettre',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
      ),
    );
  }

  void _saveStock(StockController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success =
        widget.stock == null
            ? await controller.createStock()
            : await controller.updateStock(widget.stock!);

    if (success && mounted) {
      // Rediriger vers la page de liste après enregistrement réussi
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offNamed('/stocks');
    }
  }
}
