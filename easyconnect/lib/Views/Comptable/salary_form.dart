import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/salary_controller.dart';
import 'package:easyconnect/Models/salary_model.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';

class SalaryForm extends StatefulWidget {
  final Salary? salary;

  const SalaryForm({super.key, this.salary});

  @override
  State<SalaryForm> createState() => _SalaryFormState();
}

class _SalaryFormState extends State<SalaryForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final SalaryController controller = Get.put(SalaryController());

    // Si on édite un salaire existant, remplir le formulaire
    if (widget.salary != null) {
      controller.fillForm(widget.salary!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.salary == null ? 'Nouveau Salaire' : 'Modifier le Salaire',
        ),
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
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations de base
              _buildSectionTitle('Informations de base'),
              const SizedBox(height: 16),

              // Sélection de l'employé
              InkWell(
                onTap: () => _showEmployeeDialog(controller),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Employé *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.selectedEmployeeName.value.isNotEmpty
                              ? controller.selectedEmployeeName.value
                              : 'Sélectionner un employé',
                          style: TextStyle(
                            color:
                                controller.selectedEmployeeName.value.isNotEmpty
                                    ? Colors.black
                                    : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (controller
                            .selectedEmployeeEmail
                            .value
                            .isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            controller.selectedEmployeeEmail.value,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
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
                onChanged: (_) => controller.updateNetSalary(),
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
                onChanged: (_) => controller.updateNetSalary(),
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
                onChanged: (_) => controller.updateNetSalary(),
              ),

              const SizedBox(height: 16),

              // Calcul automatique du salaire net
              Container(
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
                    Obx(
                      () => Text(
                        NumberFormat.currency(
                          locale: 'fr_FR',
                          symbol: 'fcfa',
                        ).format(controller.netSalary.value),
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Justificatifs
              _buildSectionTitle('Justificatifs'),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fichiers justificatifs',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        if (controller.selectedFiles.isEmpty) {
                          return const Text('Aucun fichier sélectionné.');
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.selectedFiles.length,
                          itemBuilder: (context, index) {
                            final file = controller.selectedFiles[index];
                            final String fileName =
                                file['name'] ?? 'Fichier inconnu';
                            final String fileType = file['type'] ?? 'document';
                            final int fileSize = file['size'] ?? 0;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: Icon(_getFileIcon(fileType)),
                                title: Text(fileName),
                                subtitle: Text(_formatFileSize(fileSize)),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => controller.removeFile(index),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => controller.selectFiles(),
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Ajouter des justificatifs'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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
              Obx(
                () => UniformFormButtons(
                  onCancel: () => Get.back(),
                  onSubmit: () => _saveSalary(controller),
                  submitText: 'Soumettre',
                  isLoading: controller.isLoading.value,
                ),
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

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  void _saveSalary(SalaryController controller) async {
    // Valider le formulaire avant de soumettre
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        'Erreur de validation',
        'Veuillez remplir tous les champs obligatoires',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Vérifier que l'employé est sélectionné
    if (controller.selectedEmployeeId.value == 0 ||
        controller.selectedEmployeeName.value.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner un employé',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Vérifier que le mois est sélectionné
    if (controller.selectedMonthForm.value.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner un mois',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    bool success = false;
    if (widget.salary == null) {
      success = await controller.createSalary();
    } else {
      success = await controller.updateSalary(widget.salary!);
    }

    // Rediriger vers la page de liste seulement en cas de succès
    if (success) {
      // Attendre un peu pour que le snackbar de succès s'affiche
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offNamed('/salaries');
      // Note: loadSalaries() est déjà appelé dans createSalary() et updateSalary()
    }
    // Si erreur, ne pas fermer pour permettre à l'utilisateur de corriger
  }

  void _showEmployeeDialog(SalaryController controller) {
    // Recharger les employés si la liste est vide
    if (controller.employees.isEmpty) {
      controller.loadEmployees();
    }
    
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
                final employeeName =
                    employee['name'] ??
                    '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'
                        .trim();
                final employeeEmail = employee['email'] ?? '';
                final employeePosition = employee['position'] ?? '';
                final employeeDepartment = employee['department'] ?? '';
                final employeeSalary = employee['salary'];
                final salaryText =
                    employeeSalary != null
                        ? 'Salaire: ${NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa', decimalDigits: 0).format(employeeSalary is String ? double.tryParse(employeeSalary) ?? 0 : (employeeSalary is num ? employeeSalary.toDouble() : 0))}'
                        : '';

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(employeeName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (employeeEmail.isNotEmpty) Text(employeeEmail),
                      if (employeePosition.isNotEmpty ||
                          employeeDepartment.isNotEmpty)
                        Text(
                          '${employeePosition.isNotEmpty ? employeePosition : ''}${employeePosition.isNotEmpty && employeeDepartment.isNotEmpty ? ' - ' : ''}${employeeDepartment.isNotEmpty ? employeeDepartment : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                          ),
                        ),
                      if (salaryText.isNotEmpty)
                        Text(
                          salaryText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: true,
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
