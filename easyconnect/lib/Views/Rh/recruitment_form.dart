import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/recruitment_controller.dart';
import 'package:easyconnect/Models/recruitment_model.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';

class RecruitmentForm extends StatelessWidget {
  final RecruitmentRequest? request;

  const RecruitmentForm({super.key, this.request});

  @override
  Widget build(BuildContext context) {
    final RecruitmentController controller = Get.put(RecruitmentController());

    // Charger les départements et postes si les listes sont vides
    if (controller.departments.isEmpty) {
      controller.loadDepartments();
    }
    if (controller.positions.isEmpty) {
      controller.loadPositions();
    }

    // Si on édite une demande existante, remplir le formulaire
    if (request != null) {
      // TODO: Implémenter la méthode fillForm
      // controller.fillForm(request!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          request == null
              ? 'Nouvelle Demande de Recrutement'
              : 'Modifier la Demande',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveRecruitmentRequest(controller),
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
                  labelText: 'Titre de l\'offre *',
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

              // Sélection multiple des départements
              Obx(
                () => InkWell(
                  onTap:
                      () => _showMultiSelectDialog(
                        context,
                        'Sélectionner les départements',
                        controller.departmentOptions
                            .where((dept) => dept['value'] != 'all')
                            .map(
                              (dept) => {
                                'value': dept['value']!,
                                'label': dept['label']!,
                              },
                            )
                            .toList(),
                        controller.selectedDepartmentsForm,
                        (value) => controller.toggleDepartment(value),
                        (value) => controller.isDepartmentSelected(value),
                      ),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Départements *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.business),
                      errorText:
                          controller.selectedDepartmentsForm.isEmpty
                              ? 'Au moins un département est obligatoire'
                              : null,
                    ),
                    child:
                        controller.selectedDepartmentsForm.isEmpty
                            ? Text(
                              'Sélectionner les départements',
                              style: TextStyle(color: Colors.grey[600]),
                            )
                            : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  controller.selectedDepartmentsForm.map((
                                    dept,
                                  ) {
                                    final deptLabel =
                                        controller.departmentOptions.firstWhere(
                                          (d) => d['value'] == dept,
                                          orElse: () => {'label': dept},
                                        )['label']!;
                                    return Chip(
                                      label: Text(deptLabel),
                                      onDeleted:
                                          () =>
                                              controller.toggleDepartment(dept),
                                      deleteIcon: const Icon(
                                        Icons.close,
                                        size: 18,
                                      ),
                                    );
                                  }).toList(),
                            ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sélection multiple des postes
              Obx(
                () => InkWell(
                  onTap:
                      () => _showMultiSelectDialog(
                        context,
                        'Sélectionner les postes',
                        controller.positionOptions
                            .where((pos) => pos['value'] != 'all')
                            .map(
                              (pos) => {
                                'value': pos['value']!,
                                'label': pos['label']!,
                              },
                            )
                            .toList(),
                        controller.selectedPositionsForm,
                        (value) => controller.togglePosition(value),
                        (value) => controller.isPositionSelected(value),
                      ),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Postes *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.work),
                      errorText:
                          controller.selectedPositionsForm.isEmpty
                              ? 'Au moins un poste est obligatoire'
                              : null,
                    ),
                    child:
                        controller.selectedPositionsForm.isEmpty
                            ? Text(
                              'Sélectionner les postes',
                              style: TextStyle(color: Colors.grey[600]),
                            )
                            : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  controller.selectedPositionsForm.map((pos) {
                                    final posLabel =
                                        controller.positionOptions.firstWhere(
                                          (p) => p['value'] == pos,
                                          orElse: () => {'label': pos},
                                        )['label']!;
                                    return Chip(
                                      label: Text(posLabel),
                                      onDeleted:
                                          () => controller.togglePosition(pos),
                                      deleteIcon: const Icon(
                                        Icons.close,
                                        size: 18,
                                      ),
                                    );
                                  }).toList(),
                            ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField<String>(
                        value:
                            controller.selectedEmploymentTypeForm.value.isEmpty
                                ? null
                                : controller.selectedEmploymentTypeForm.value,
                        decoration: const InputDecoration(
                          labelText: 'Type d\'emploi *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        items:
                            controller.employmentTypeOptions
                                .map<DropdownMenuItem<String>>((type) {
                                  return DropdownMenuItem<String>(
                                    value: type['value']!,
                                    child: Text(type['label']!),
                                  );
                                })
                                .toList(),
                        onChanged:
                            (value) => controller.selectEmploymentType(value!),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le type d\'emploi est obligatoire';
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
                        value:
                            controller.selectedExperienceLevelForm.value.isEmpty
                                ? null
                                : controller.selectedExperienceLevelForm.value,
                        decoration: const InputDecoration(
                          labelText: 'Niveau d\'expérience *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.trending_up),
                        ),
                        items:
                            controller.experienceLevelOptions
                                .map<DropdownMenuItem<String>>((level) {
                                  return DropdownMenuItem<String>(
                                    value: level['value']!,
                                    child: Text(level['label']!),
                                  );
                                })
                                .toList(),
                        onChanged:
                            (value) => controller.selectExperienceLevel(value!),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le niveau d\'expérience est obligatoire';
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
                      controller: controller.salaryRangeController,
                      decoration: const InputDecoration(
                        labelText: 'Fourchette salariale *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La fourchette salariale est obligatoire';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: controller.locationController,
                      decoration: const InputDecoration(
                        labelText: 'Localisation *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La localisation est obligatoire';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Nombre de postes
              Obx(
                () => Row(
                  children: [
                    const Text('Nombre de postes: '),
                    IconButton(
                      onPressed: () {
                        if (controller.numberOfPositionsForm.value > 1) {
                          controller.numberOfPositionsForm.value--;
                        }
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${controller.numberOfPositionsForm.value}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        controller.numberOfPositionsForm.value++;
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Date d'échéance
              Obx(
                () => InkWell(
                  onTap: () => controller.selectDeadline(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date d\'échéance *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      controller.selectedDeadlineForm.value != null
                          ? DateFormat(
                            'dd/MM/yyyy',
                          ).format(controller.selectedDeadlineForm.value!)
                          : 'Sélectionner une date',
                      style: TextStyle(
                        color:
                            controller.selectedDeadlineForm.value != null
                                ? Colors.black
                                : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Description du poste
              _buildSectionTitle('Description du poste'),
              const SizedBox(height: 16),

              TextFormField(
                controller: controller.descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description du poste *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText:
                      'Décrivez le poste et ses responsabilités principales',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La description est obligatoire';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: controller.requirementsController,
                decoration: const InputDecoration(
                  labelText: 'Exigences et qualifications *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.checklist),
                  hintText: 'Listez les exigences et qualifications requises',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Les exigences sont obligatoires';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: controller.responsibilitiesController,
                decoration: const InputDecoration(
                  labelText: 'Responsabilités principales *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.assignment),
                  hintText:
                      'Détaillez les responsabilités principales du poste',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Les responsabilités sont obligatoires';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Boutons d'action uniformes
              UniformFormButtons(
                onCancel: () => Get.back(),
                onSubmit: () => _saveRecruitmentRequest(controller),
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

  // Afficher un dialogue de sélection multiple
  void _showMultiSelectDialog(
    BuildContext context,
    String title,
    List<Map<String, String>> options,
    RxList<String> selectedValues,
    Function(String) onToggle,
    bool Function(String) isSelected,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final value = option['value']!;
                final label = option['label']!;
                final selected = isSelected(value);

                return CheckboxListTile(
                  title: Text(label),
                  value: selected,
                  onChanged: (bool? checked) {
                    onToggle(value);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  void _saveRecruitmentRequest(RecruitmentController controller) async {
    if (controller.titleController.text.trim().isEmpty ||
        controller.selectedDepartmentsForm.isEmpty ||
        controller.selectedPositionsForm.isEmpty ||
        controller.descriptionController.text.trim().isEmpty ||
        controller.requirementsController.text.trim().isEmpty ||
        controller.responsibilitiesController.text.trim().isEmpty ||
        controller.selectedEmploymentTypeForm.value.isEmpty ||
        controller.selectedExperienceLevelForm.value.isEmpty ||
        controller.salaryRangeController.text.trim().isEmpty ||
        controller.locationController.text.trim().isEmpty ||
        controller.selectedDeadlineForm.value == null) {
      Get.snackbar('Erreur', 'Veuillez remplir tous les champs obligatoires');
      return;
    }

    if (request == null) {
      final success = await controller.createRecruitmentRequest();
      if (success) {
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offNamed(
          '/recruitment',
        ); // Redirection automatique vers la liste après succès
      }
    } else {
      // TODO: Implémenter la mise à jour
      Get.snackbar('Info', 'Mise à jour à implémenter');
    }
  }
}
