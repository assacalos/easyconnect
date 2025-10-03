import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/intervention_controller.dart';
import 'package:easyconnect/Models/intervention_model.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';

class InterventionForm extends StatelessWidget {
  final Intervention? intervention;

  const InterventionForm({super.key, this.intervention});

  @override
  Widget build(BuildContext context) {
    final InterventionController controller = Get.put(InterventionController());

    // Si on édite une intervention existante, remplir le formulaire
    if (intervention != null) {
      controller.fillForm(intervention!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          intervention == null
              ? 'Nouvelle Intervention'
              : 'Modifier l\'Intervention',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveIntervention(controller),
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
                controller: controller.titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre de l\'intervention *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le titre est obligatoire';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Type d'intervention
              Obx(
                () => DropdownButtonFormField<String>(
                  value: controller.selectedTypeForm.value,
                  decoration: const InputDecoration(
                    labelText: 'Type d\'intervention *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items:
                      controller.interventionTypes
                          .map<DropdownMenuItem<String>>((type) {
                            return DropdownMenuItem<String>(
                              value: type['value'] as String,
                              child: Text(type['label'] as String),
                            );
                          })
                          .toList(),
                  onChanged: (value) => controller.selectType(value!),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le type est obligatoire';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Priorité
              Obx(
                () => DropdownButtonFormField<String>(
                  value: controller.selectedPriorityForm.value,
                  decoration: const InputDecoration(
                    labelText: 'Priorité *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.priority_high),
                  ),
                  items:
                      controller.priorities.map<DropdownMenuItem<String>>((
                        priority,
                      ) {
                        return DropdownMenuItem<String>(
                          value: priority['value'] as String,
                          child: Text(priority['label'] as String),
                        );
                      }).toList(),
                  onChanged: (value) => controller.selectPriority(value!),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La priorité est obligatoire';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Date programmée
              Obx(
                () => InkWell(
                  onTap: () => _selectScheduledDate(context, controller),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date programmée *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      controller.selectedScheduledDate.value != null
                          ? DateFormat(
                            'dd/MM/yyyy',
                          ).format(controller.selectedScheduledDate.value!)
                          : 'Sélectionner une date',
                      style: TextStyle(
                        color:
                            controller.selectedScheduledDate.value != null
                                ? Colors.black
                                : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
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

              // Informations client
              _buildSectionTitle('Informations client'),
              const SizedBox(height: 16),

              TextFormField(
                controller: controller.clientNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du client',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.clientPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: controller.clientEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Informations techniques
              _buildSectionTitle('Informations techniques'),
              const SizedBox(height: 16),

              TextFormField(
                controller: controller.equipmentController,
                decoration: const InputDecoration(
                  labelText: 'Équipement',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.build),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: controller.problemController,
                decoration: const InputDecoration(
                  labelText: 'Description du problème',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // Localisation
              Obx(
                () => Visibility(
                  visible: controller.selectedTypeForm.value == 'external',
                  child: TextFormField(
                    controller: controller.locationController,
                    decoration: const InputDecoration(
                      labelText: 'Localisation',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Planification
              _buildSectionTitle('Planification'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.estimatedDurationController,
                      decoration: const InputDecoration(
                        labelText: 'Durée estimée (heures)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: controller.costController,
                      decoration: const InputDecoration(
                        labelText: 'Coût estimé (€)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.euro),
                      ),
                      keyboardType: TextInputType.number,
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
                onSubmit: () => _saveIntervention(controller),
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

  void _selectScheduledDate(
    BuildContext context,
    InterventionController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedScheduledDate.value ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.selectScheduledDate(picked);
    }
  }

  void _saveIntervention(InterventionController controller) async {
    if (intervention == null) {
      await controller.createIntervention();
    } else {
      await controller.updateIntervention(intervention!);
    }
    Get.back(); // Retour automatique à la liste
  }
}
