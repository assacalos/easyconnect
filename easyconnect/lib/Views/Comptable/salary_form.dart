import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/salary_controller.dart';
import 'package:easyconnect/Models/salary_model.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';

class SalaryForm extends StatelessWidget {
  final Salary? salary;

  const SalaryForm({super.key, this.salary});

  @override
  Widget build(BuildContext context) {
    final SalaryController controller = Get.put(SalaryController());

    // Si on édite un salaire existant, remplir le formulaire
    if (salary != null) {
      controller.fillForm(salary!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(salary == null ? 'Nouveau Salaire' : 'Modifier le Salaire'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveSalary(controller),
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

              // Sélection de l'employé
              Obx(
                () => InkWell(
                  onTap: () => _showEmployeeDialog(controller),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Employé *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    child: Text(
                      controller.selectedEmployeeName.value.isNotEmpty
                          ? controller.selectedEmployeeName.value
                          : 'Sélectionner un employé',
                      style: TextStyle(
                        color:
                            controller.selectedEmployeeName.value.isNotEmpty
                                ? Colors.black
                                : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Période
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField<String>(
                        value:
                            controller.selectedMonthForm.value.isNotEmpty
                                ? controller.selectedMonthForm.value
                                : null,
                        decoration: const InputDecoration(
                          labelText: 'Mois *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                        items:
                            controller.months.map<DropdownMenuItem<String>>((
                              month,
                            ) {
                              return DropdownMenuItem<String>(
                                value: month['value'] as String,
                                child: Text(month['label'] as String),
                              );
                            }).toList(),
                        onChanged: (value) => controller.selectMonth(value!),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le mois est obligatoire';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField<int>(
                        value: controller.selectedYearForm.value,
                        decoration: const InputDecoration(
                          labelText: 'Année *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        items:
                            controller.years.map<DropdownMenuItem<int>>((year) {
                              return DropdownMenuItem<int>(
                                value: year,
                                child: Text(year.toString()),
                              );
                            }).toList(),
                        onChanged: (value) => controller.selectYear(value!),
                        validator: (value) {
                          if (value == null) {
                            return 'L\'année est obligatoire';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Détails du salaire
              _buildSectionTitle('Détails du salaire'),
              const SizedBox(height: 16),

              TextFormField(
                controller: controller.baseSalaryController,
                decoration: const InputDecoration(
                  labelText: 'Salaire de base (fcfa) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le salaire de base est obligatoire';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Le salaire doit être un nombre';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Le salaire doit être positif';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: controller.bonusController,
                decoration: const InputDecoration(
                  labelText: 'Prime (fcfa)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star),
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: controller.deductionsController,
                decoration: const InputDecoration(
                  labelText: 'Déductions (fcfa)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.remove_circle),
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              // Calcul automatique du salaire net
              Obx(() {
                final baseSalary =
                    double.tryParse(controller.baseSalaryController.text) ??
                    0.0;
                final bonus =
                    double.tryParse(controller.bonusController.text) ?? 0.0;
                final deductions =
                    double.tryParse(controller.deductionsController.text) ??
                    0.0;
                final netSalary = baseSalary + bonus - deductions;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.calculate, color: Colors.blue, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        'Salaire net calculé',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(
                          locale: 'fr_FR',
                          symbol: 'fcfa',
                        ).format(netSalary),
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Notes
              _buildSectionTitle('Informations supplémentaires'),
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
                onSubmit: () => _saveSalary(controller),
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

  void _saveSalary(SalaryController controller) async {
    if (salary == null) {
      await controller.createSalary();
    } else {
      await controller.updateSalary(salary!);
    }
    Get.back(); // Retour automatique à la liste
  }

  void _showEmployeeDialog(SalaryController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Sélectionner un employé'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Obx(() {
            if (controller.employees.isEmpty) {
              return const Center(child: Text('Aucun employé disponible'));
            }

            return ListView.builder(
              itemCount: controller.employees.length,
              itemBuilder: (context, index) {
                final employee = controller.employees[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(employee['name']),
                  subtitle: Text(employee['email']),
                  onTap: () {
                    controller.selectEmployee(employee);
                    Get.back();
                  },
                );
              },
            );
          }),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
        ],
      ),
    );
  }
}
