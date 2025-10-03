import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/stock_controller.dart';
import 'package:easyconnect/Models/stock_model.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';

class StockForm extends StatelessWidget {
  final Stock? stock;

  const StockForm({super.key, this.stock});

  @override
  Widget build(BuildContext context) {
    final StockController controller = Get.put(StockController());

    // Si on édite un stock existant, remplir le formulaire
    if (stock != null) {
      controller.fillForm(stock!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(stock == null ? 'Nouveau Produit' : 'Modifier le Produit'),
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
                  onChanged: (value) => controller.selectCategory(value!),
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

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField<String>(
                        value: controller.selectedUnit.value,
                        decoration: const InputDecoration(
                          labelText: 'Unité *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.straighten),
                        ),
                        items:
                            controller.units.map<DropdownMenuItem<String>>((
                              unit,
                            ) {
                              return DropdownMenuItem<String>(
                                value: unit['value'] as String,
                                child: Text(unit['label'] as String),
                              );
                            }).toList(),
                        onChanged: (value) => controller.selectUnit(value!),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'L\'unité est obligatoire';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
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

              const SizedBox(height: 24),

              // Informations supplémentaires
              _buildSectionTitle('Informations supplémentaires'),
              const SizedBox(height: 16),

              TextFormField(
                controller: controller.locationController,
                decoration: const InputDecoration(
                  labelText: 'Emplacement',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'Emplacement dans l\'entrepôt (optionnel)',
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: controller.supplierController,
                decoration: const InputDecoration(
                  labelText: 'Fournisseur',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                  hintText: 'Fournisseur principal (optionnel)',
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: controller.barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Code-barres',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code_scanner),
                  hintText: 'Code-barres du produit (optionnel)',
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: controller.imageController,
                decoration: const InputDecoration(
                  labelText: 'Image',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                  hintText: 'URL de l\'image du produit (optionnel)',
                ),
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
    if (stock == null) {
      await controller.createStock();
    } else {
      await controller.updateStock(stock!);
    }
    Get.back(); // Retour automatique à la liste
  }
}
