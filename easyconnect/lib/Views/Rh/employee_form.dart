import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/employee_controller.dart';
import 'package:easyconnect/Models/employee_model.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';

class EmployeeForm extends StatelessWidget {
  final Employee? employee;

  const EmployeeForm({super.key, this.employee});

  @override
  Widget build(BuildContext context) {
    final EmployeeController controller = Get.put(EmployeeController());

    // Utiliser addPostFrameCallback pour éviter les erreurs "setState during build"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Charger les départements si la liste est vide
      if (controller.departments.isEmpty) {
        controller.loadDepartments();
      }

      // Charger les employés si la liste est vide (pour le sélecteur)
      if (employee == null && controller.employees.isEmpty) {
        controller.loadEmployees(loadAll: true);
      }

      // Si on édite un employé existant, remplir le formulaire
      if (employee != null) {
        controller.fillForm(employee!);
        controller.selectedEmployeeForForm.value = employee;
      } else {
        // Si on crée un nouvel employé, réinitialiser le formulaire
        controller.clearForm();
        controller.selectedEmployeeForForm.value = null;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          employee == null ? 'Nouvel Employé' : 'Modifier l\'Employé',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveEmployee(controller),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sélection d'un employé existant (seulement si on crée un nouvel employé)
              if (employee == null) ...[
                Obx(
                  () => DropdownButtonFormField<Employee?>(
                    value: controller.selectedEmployeeForForm.value,
                    decoration: const InputDecoration(
                      labelText: 'Sélectionner un employé existant (optionnel)',
                      hintText:
                          'Choisir un employé pour pré-remplir le formulaire',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      helperText:
                          'Sélectionnez un employé pour remplir automatiquement les champs',
                    ),
                    items: [
                      const DropdownMenuItem<Employee?>(
                        value: null,
                        child: Text('Aucun (nouvel employé)'),
                      ),
                      ...controller.employees.map<DropdownMenuItem<Employee?>>((
                        emp,
                      ) {
                        return DropdownMenuItem<Employee?>(
                          value: emp,
                          child: Text(
                            '${emp.firstName} ${emp.lastName} - ${emp.email}',
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (Employee? selectedEmp) {
                      controller.selectEmployeeForForm(selectedEmp);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Informations personnelles
              _buildSectionTitle('Informations personnelles'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le prénom est obligatoire';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: controller.lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est obligatoire';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: controller.emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'L\'email est obligatoire';
                  }
                  if (!GetUtils.isEmail(value)) {
                    return 'Format d\'email invalide';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.phoneController,
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
                    child: Obx(
                      () => DropdownButtonFormField<String>(
                        value:
                            controller.selectedGender.value.isNotEmpty
                                ? controller.selectedGender.value
                                : null,
                        decoration: const InputDecoration(
                          labelText: 'Genre',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items:
                            controller.genders.map<DropdownMenuItem<String>>((
                              gender,
                            ) {
                              return DropdownMenuItem<String>(
                                value: gender['value'] as String,
                                child: Text(gender['label'] as String),
                              );
                            }).toList(),
                        onChanged:
                            (value) => controller.selectedGender.value = value!,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: controller.addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => InkWell(
                        onTap:
                            () => controller.selectDate(
                              context,
                              controller.selectedBirthDate,
                            ),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date de naissance',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.cake),
                          ),
                          child: Text(
                            controller.selectedBirthDate.value != null
                                ? DateFormat(
                                  'dd/MM/yyyy',
                                ).format(controller.selectedBirthDate.value!)
                                : 'Sélectionner une date',
                            style: TextStyle(
                              color:
                                  controller.selectedBirthDate.value != null
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
                      () => DropdownButtonFormField<String>(
                        value:
                            controller.selectedMaritalStatus.value.isNotEmpty
                                ? controller.selectedMaritalStatus.value
                                : null,
                        decoration: const InputDecoration(
                          labelText: 'Statut matrimonial',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.favorite),
                        ),
                        items:
                            controller.maritalStatuses
                                .map<DropdownMenuItem<String>>((status) {
                                  return DropdownMenuItem<String>(
                                    value: status['value'] as String,
                                    child: Text(status['label'] as String),
                                  );
                                })
                                .toList(),
                        onChanged:
                            (value) =>
                                controller.selectedMaritalStatus.value = value!,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Informations professionnelles
              _buildSectionTitle('Informations professionnelles'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.positionController,
                      decoration: const InputDecoration(
                        labelText: 'Poste',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() {
                      final departments = controller.departments;
                      final currentValue = controller.selectedDepartment.value;
                      // S'assurer que la valeur actuelle est valide (soit '', soit dans la liste des départements)
                      final validValue =
                          (currentValue == '' ||
                                      departments.contains(currentValue)) &&
                                  currentValue != 'all'
                              ? currentValue
                              : null;

                      return DropdownButtonFormField<String>(
                        value: validValue,
                        decoration: const InputDecoration(
                          labelText: 'Département',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Sélectionner'),
                          ),
                          ...departments.map<DropdownMenuItem<String>>((dept) {
                            return DropdownMenuItem<String>(
                              value: dept,
                              child: Text(dept),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          controller.selectedDepartment.value = value ?? '';
                        },
                      );
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: controller.managerController,
                decoration: const InputDecoration(
                  labelText: 'Manager',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.supervisor_account),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => InkWell(
                        onTap:
                            () => controller.selectDate(
                              context,
                              controller.selectedHireDate,
                            ),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date d\'embauche',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.event),
                          ),
                          child: Text(
                            controller.selectedHireDate.value != null
                                ? DateFormat(
                                  'dd/MM/yyyy',
                                ).format(controller.selectedHireDate.value!)
                                : 'Sélectionner une date',
                            style: TextStyle(
                              color:
                                  controller.selectedHireDate.value != null
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
                      () => DropdownButtonFormField<String>(
                        value:
                            controller.selectedContractType.value.isNotEmpty
                                ? controller.selectedContractType.value
                                : null,
                        decoration: const InputDecoration(
                          labelText: 'Type de contrat',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        items:
                            controller.contractTypes
                                .map<DropdownMenuItem<String>>((type) {
                                  return DropdownMenuItem<String>(
                                    value: type['value'] as String,
                                    child: Text(type['label'] as String),
                                  );
                                })
                                .toList(),
                        onChanged:
                            (value) =>
                                controller.selectedContractType.value = value!,
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
                            () => controller.selectDate(
                              context,
                              controller.selectedContractStartDate,
                            ),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Début du contrat',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.play_arrow),
                          ),
                          child: Text(
                            controller.selectedContractStartDate.value != null
                                ? DateFormat('dd/MM/yyyy').format(
                                  controller.selectedContractStartDate.value!,
                                )
                                : 'Sélectionner une date',
                            style: TextStyle(
                              color:
                                  controller.selectedContractStartDate.value !=
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
                            () => controller.selectDate(
                              context,
                              controller.selectedContractEndDate,
                            ),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fin du contrat',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.stop),
                          ),
                          child: Text(
                            controller.selectedContractEndDate.value != null
                                ? DateFormat('dd/MM/yyyy').format(
                                  controller.selectedContractEndDate.value!,
                                )
                                : 'Sélectionner une date',
                            style: TextStyle(
                              color:
                                  controller.selectedContractEndDate.value !=
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

              // Informations financières
              _buildSectionTitle('Informations financières'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.salaryController,
                      decoration: const InputDecoration(
                        labelText: 'Salaire',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.euro),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField<String>(
                        value: controller.selectedCurrency.value,
                        decoration: const InputDecoration(
                          labelText: 'Devise',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        items:
                            controller.currencies.map<DropdownMenuItem<String>>(
                              (currency) {
                                return DropdownMenuItem<String>(
                                  value: currency['value'] as String,
                                  child: Text(currency['label'] as String),
                                );
                              },
                            ).toList(),
                        onChanged:
                            (value) =>
                                controller.selectedCurrency.value = value!,
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
                            controller.selectedWorkSchedule.value.isNotEmpty
                                ? controller.selectedWorkSchedule.value
                                : null,
                        decoration: const InputDecoration(
                          labelText: 'Horaires de travail',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        items:
                            controller.workSchedules
                                .map<DropdownMenuItem<String>>((schedule) {
                                  return DropdownMenuItem<String>(
                                    value: schedule['value'] as String,
                                    child: Text(schedule['label'] as String),
                                  );
                                })
                                .toList(),
                        onChanged:
                            (value) =>
                                controller.selectedWorkSchedule.value = value!,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() {
                      final statuses = controller.employeeStatuses;
                      final currentValue = controller.selectedStatus.value;
                      // S'assurer que la valeur actuelle est valide
                      final validValue =
                          statuses.any(
                                (status) => status['value'] == currentValue,
                              )
                              ? currentValue
                              : null;

                      return DropdownButtonFormField<String>(
                        value: validValue,
                        decoration: const InputDecoration(
                          labelText: 'Statut',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.info),
                        ),
                        items:
                            statuses.map<DropdownMenuItem<String>>((status) {
                              return DropdownMenuItem<String>(
                                value: status['value'] as String,
                                child: Text(status['label'] as String),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            controller.selectedStatus.value = value;
                          }
                        },
                      );
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Informations supplémentaires
              _buildSectionTitle('Informations supplémentaires'),
              const SizedBox(height: 16),

              TextFormField(
                controller: controller.idNumberController,
                decoration: const InputDecoration(
                  labelText: 'Numéro d\'identité',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: controller.socialSecurityController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de sécurité sociale',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
              ),

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
                onSubmit: () => _saveEmployee(controller),
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

  void _saveEmployee(EmployeeController controller) async {
    bool success = false;
    if (employee == null) {
      success = await controller.createEmployee();
    } else {
      success = await controller.updateEmployee(employee!);
    }
    if (success) {
      Get.back(); // Retour automatique à la liste après succès
    }
  }
}
