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

              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField<String>(
                        value:
                            controller.selectedDepartmentForm.value.isEmpty
                                ? null
                                : controller.selectedDepartmentForm.value,
                        decoration: const InputDecoration(
                          labelText: 'Département *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        items:
                            controller.departmentOptions
                                .where((dept) => dept['value'] != 'all')
                                .map<DropdownMenuItem<String>>((dept) {
                                  return DropdownMenuItem<String>(
                                    value: dept['value']!,
                                    child: Text(dept['label']!),
                                  );
                                })
                                .toList(),
                        onChanged:
                            (value) => controller.selectDepartment(value!),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le département est obligatoire';
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
                            controller.selectedPositionForm.value.isEmpty
                                ? null
                                : controller.selectedPositionForm.value,
                        decoration: const InputDecoration(
                          labelText: 'Poste *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.work),
                        ),
                        items:
                            controller.positionOptions
                                .where((pos) => pos['value'] != 'all')
                                .map<DropdownMenuItem<String>>((pos) {
                                  return DropdownMenuItem<String>(
                                    value: pos['value']!,
                                    child: Text(pos['label']!),
                                  );
                                })
                                .toList(),
                        onChanged: (value) => controller.selectPosition(value!),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le poste est obligatoire';
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

  void _saveRecruitmentRequest(RecruitmentController controller) async {
    if (controller.titleController.text.trim().isEmpty ||
        controller.selectedDepartmentForm.value.isEmpty ||
        controller.selectedPositionForm.value.isEmpty ||
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
      await controller.createRecruitmentRequest();
    } else {
      // TODO: Implémenter la mise à jour
      Get.snackbar('Info', 'Mise à jour à implémenter');
    }
    Get.back(); // Retour automatique à la liste
  }
}
