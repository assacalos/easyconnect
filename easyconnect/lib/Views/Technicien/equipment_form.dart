import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/equipment_controller.dart';
import 'package:easyconnect/Models/equipment_model.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';

class EquipmentForm extends StatelessWidget {
  final Equipment? equipment;

  const EquipmentForm({super.key, this.equipment});

  @override
  Widget build(BuildContext context) {
    final EquipmentController controller = Get.put(EquipmentController());

    // Si on édite un équipement existant, remplir le formulaire
    if (equipment != null) {
      controller.fillForm(equipment!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          equipment == null ? 'Nouvel Équipement' : 'Modifier l\'Équipement',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveEquipment(controller),
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
                  labelText: 'Nom de l\'équipement *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.devices),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est obligatoire';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Catégorie
              Obx(
                () => DropdownButtonFormField<String>(
                  value: controller.selectedCategoryForm.value,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items:
                      controller.equipmentCategoriesList
                          .map<DropdownMenuItem<String>>((category) {
                            return DropdownMenuItem<String>(
                              value: category['value'] as String,
                              child: Text(category['label'] as String),
                            );
                          })
                          .toList(),
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

              // Statut et état
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField<String>(
                        value: controller.selectedStatusForm.value,
                        decoration: const InputDecoration(
                          labelText: 'Statut *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.info),
                        ),
                        items:
                            controller.statuses.map<DropdownMenuItem<String>>((
                              status,
                            ) {
                              return DropdownMenuItem<String>(
                                value: status['value'] as String,
                                child: Text(status['label'] as String),
                              );
                            }).toList(),
                        onChanged: (value) => controller.selectStatus(value!),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le statut est obligatoire';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField<String>(
                        value: controller.selectedConditionForm.value,
                        decoration: const InputDecoration(
                          labelText: 'État *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.star),
                        ),
                        items:
                            controller.conditions.map<DropdownMenuItem<String>>(
                              (condition) {
                                return DropdownMenuItem<String>(
                                  value: condition['value'] as String,
                                  child: Text(condition['label'] as String),
                                );
                              },
                            ).toList(),
                        onChanged:
                            (value) => controller.selectCondition(value!),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'L\'état est obligatoire';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: controller.descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La description est obligatoire';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Informations techniques
              _buildSectionTitle('Informations techniques'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.serialNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de série',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: controller.modelController,
                      decoration: const InputDecoration(
                        labelText: 'Modèle',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.model_training),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: controller.brandController,
                decoration: const InputDecoration(
                  labelText: 'Marque',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.branding_watermark),
                ),
              ),

              const SizedBox(height: 24),

              // Localisation et assignation
              _buildSectionTitle('Localisation et assignation'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.locationController,
                      decoration: const InputDecoration(
                        labelText: 'Localisation',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: controller.departmentController,
                      decoration: const InputDecoration(
                        labelText: 'Département',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: controller.assignedToController,
                decoration: const InputDecoration(
                  labelText: 'Assigné à',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 24),

              // Informations financières
              _buildSectionTitle('Informations financières'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.purchasePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Prix d\'achat (fcfa)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.euro),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: controller.currentValueController,
                      decoration: const InputDecoration(
                        labelText: 'Valeur actuelle (fcfa)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: controller.supplierController,
                decoration: const InputDecoration(
                  labelText: 'Fournisseur',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
              ),

              const SizedBox(height: 24),

              // Dates importantes
              _buildSectionTitle('Dates importantes'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => InkWell(
                        onTap: () => _selectPurchaseDate(context, controller),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date d\'achat',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.shopping_cart),
                          ),
                          child: Text(
                            controller.selectedPurchaseDate.value != null
                                ? DateFormat(
                                  'dd/MM/yyyy',
                                ).format(controller.selectedPurchaseDate.value!)
                                : 'Sélectionner une date',
                            style: TextStyle(
                              color:
                                  controller.selectedPurchaseDate.value != null
                                      ? Colors.black
                                      : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(
                      () => InkWell(
                        onTap: () => _selectWarrantyExpiry(context, controller),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Expiration garantie',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.security),
                          ),
                          child: Text(
                            controller.selectedWarrantyExpiry.value != null
                                ? DateFormat('dd/MM/yyyy').format(
                                  controller.selectedWarrantyExpiry.value!,
                                )
                                : 'Sélectionner une date',
                            style: TextStyle(
                              color:
                                  controller.selectedWarrantyExpiry.value !=
                                          null
                                      ? Colors.black
                                      : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => InkWell(
                        onTap:
                            () => _selectLastMaintenance(context, controller),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Dernière maintenance',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.build),
                          ),
                          child: Text(
                            controller.selectedLastMaintenance.value != null
                                ? DateFormat('dd/MM/yyyy').format(
                                  controller.selectedLastMaintenance.value!,
                                )
                                : 'Sélectionner une date',
                            style: TextStyle(
                              color:
                                  controller.selectedLastMaintenance.value !=
                                          null
                                      ? Colors.black
                                      : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(
                      () => InkWell(
                        onTap:
                            () => _selectNextMaintenance(context, controller),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Prochaine maintenance',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.schedule),
                          ),
                          child: Text(
                            controller.selectedNextMaintenance.value != null
                                ? DateFormat('dd/MM/yyyy').format(
                                  controller.selectedNextMaintenance.value!,
                                )
                                : 'Sélectionner une date',
                            style: TextStyle(
                              color:
                                  controller.selectedNextMaintenance.value !=
                                          null
                                      ? Colors.black
                                      : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Notes
              _buildSectionTitle('Notes'),
              const SizedBox(height: 16),

              TextFormField(
                controller: controller.notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  hintText: 'Notes internes (optionnel)',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Boutons d'action uniformes
              UniformFormButtons(
                onCancel: () => Get.back(),
                onSubmit: () => _saveEquipment(controller),
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

  void _selectPurchaseDate(
    BuildContext context,
    EquipmentController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedPurchaseDate.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)), // 10 ans
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.selectPurchaseDate(picked);
    }
  }

  void _selectWarrantyExpiry(
    BuildContext context,
    EquipmentController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedWarrantyExpiry.value ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 ans
    );
    if (picked != null) {
      controller.selectWarrantyExpiry(picked);
    }
  }

  void _selectLastMaintenance(
    BuildContext context,
    EquipmentController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedLastMaintenance.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)), // 10 ans
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.selectLastMaintenance(picked);
    }
  }

  void _selectNextMaintenance(
    BuildContext context,
    EquipmentController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedNextMaintenance.value ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 ans
    );
    if (picked != null) {
      controller.selectNextMaintenance(picked);
    }
  }

  void _saveEquipment(EquipmentController controller) async {
    bool success = false;
    if (equipment == null) {
      success = await controller.createEquipment();
    } else {
      success = await controller.updateEquipment(equipment!);
    }
    if (success) {
      Get.back();
    }
  }
}
