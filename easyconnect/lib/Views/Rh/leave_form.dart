import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/leave_controller.dart';
import 'package:easyconnect/Models/leave_model.dart';
import 'package:easyconnect/services/leave_service.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';

class LeaveForm extends StatelessWidget {
  final LeaveRequest? request;

  const LeaveForm({super.key, this.request});

  @override
  Widget build(BuildContext context) {
    final LeaveController controller = Get.put(LeaveController());

    // Si on édite une demande existante, remplir le formulaire
    if (request != null) {
      // TODO: Implémenter la méthode fillForm
      // controller.fillForm(request!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          request == null ? 'Nouvelle Demande de Congé' : 'Modifier la Demande',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveLeaveRequest(controller),
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

              // Sélection de l'employé (si RH/Patron)
              if (controller.canViewAllLeaves.value) ...[
                Obx(
                  () => DropdownButtonFormField<String>(
                    value:
                        controller.selectedEmployeeForm.value.isEmpty
                            ? null
                            : controller.selectedEmployeeForm.value,
                    decoration: const InputDecoration(
                      labelText: 'Employé *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items:
                        controller.employeeOptions
                            .where((emp) => emp['value'] != 'all')
                            .map<DropdownMenuItem<String>>((emp) {
                              return DropdownMenuItem<String>(
                                value: emp['value']!,
                                child: Text(emp['label']!),
                              );
                            })
                            .toList(),
                    onChanged: (value) => controller.selectEmployee(value!),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner un employé';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Type de congé
              Obx(
                () => DropdownButtonFormField<String>(
                  value:
                      controller.selectedLeaveTypeForm.value.isEmpty
                          ? null
                          : controller.selectedLeaveTypeForm.value,
                  decoration: const InputDecoration(
                    labelText: 'Type de congé *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event),
                  ),
                  items:
                      controller.leaveTypes.map<DropdownMenuItem<String>>((
                        type,
                      ) {
                        return DropdownMenuItem<String>(
                          value: type.value,
                          child: Text(type.label),
                        );
                      }).toList(),
                  onChanged: (value) => controller.selectLeaveType(value!),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner un type de congé';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Dates
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => InkWell(
                        onTap: () => controller.selectStartDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date de début *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            controller.selectedStartDateForm.value != null
                                ? DateFormat('dd/MM/yyyy').format(
                                  controller.selectedStartDateForm.value!,
                                )
                                : 'Sélectionner une date',
                            style: TextStyle(
                              color:
                                  controller.selectedStartDateForm.value != null
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
                        onTap: () => controller.selectEndDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date de fin *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            controller.selectedEndDateForm.value != null
                                ? DateFormat(
                                  'dd/MM/yyyy',
                                ).format(controller.selectedEndDateForm.value!)
                                : 'Sélectionner une date',
                            style: TextStyle(
                              color:
                                  controller.selectedEndDateForm.value != null
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

              const SizedBox(height: 8),

              // Affichage du nombre de jours
              Obx(() {
                final totalDays = controller.calculateTotalDays();
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Nombre de jours: $totalDays',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Raison
              TextFormField(
                controller: controller.reasonController,
                decoration: const InputDecoration(
                  labelText: 'Raison du congé *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.help_outline),
                  hintText: 'Expliquez la raison de votre demande de congé',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La raison est obligatoire';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Commentaires
              TextFormField(
                controller: controller.commentsController,
                decoration: const InputDecoration(
                  labelText: 'Commentaires',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.comment),
                  hintText: 'Commentaires supplémentaires (optionnel)',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Vérification des conflits
              _buildConflictCheck(controller),

              const SizedBox(height: 24),

              // Informations sur le solde de congés
              _buildLeaveBalanceInfo(controller),

              const SizedBox(height: 32),

              // Boutons d'action uniformes
              UniformFormButtons(
                onCancel: () => Get.back(),
                onSubmit: () => _saveLeaveRequest(controller),
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

  Widget _buildConflictCheck(LeaveController controller) {
    return Obx(() {
      if (controller.selectedEmployeeForm.value.isEmpty ||
          controller.selectedStartDateForm.value == null ||
          controller.selectedEndDateForm.value == null) {
        return const SizedBox.shrink();
      }

      return FutureBuilder<bool>(
        future: controller.checkConflicts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Vérification des conflits...',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasData && snapshot.data == true) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attention: Des conflits de congés ont été détectés pour cette période.',
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Aucun conflit détecté pour cette période.',
                  style: TextStyle(color: Colors.green[700], fontSize: 12),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildLeaveBalanceInfo(LeaveController controller) {
    return Obx(() {
      if (controller.selectedEmployeeForm.value.isEmpty) {
        return const SizedBox.shrink();
      }

      return FutureBuilder<LeaveBalance>(
        future: LeaveService.to.getEmployeeLeaveBalance(
          int.parse(controller.selectedEmployeeForm.value),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final balance = snapshot.data!;
          return Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Solde de congés',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBalanceItem(
                          'Congés payés',
                          '${balance.remainingAnnualLeave}/${balance.annualLeaveDays}',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildBalanceItem(
                          'Congés maladie',
                          '${balance.remainingSickLeave}/${balance.sickLeaveDays}',
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildBalanceItem(
                    'Congés personnels',
                    '${balance.remainingPersonalLeave}/${balance.personalLeaveDays}',
                    Colors.green,
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildBalanceItem(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _saveLeaveRequest(LeaveController controller) async {
    if (controller.selectedEmployeeForm.value.isEmpty ||
        controller.selectedLeaveTypeForm.value.isEmpty ||
        controller.selectedStartDateForm.value == null ||
        controller.selectedEndDateForm.value == null ||
        controller.reasonController.text.trim().isEmpty) {
      Get.snackbar('Erreur', 'Veuillez remplir tous les champs obligatoires');
      return;
    }

    if (request == null) {
      final success = await controller.createLeaveRequest();
      if (success) {
        Get.back(); // Retour automatique à la liste après succès
      }
    } else {
      // TODO: Implémenter la mise à jour
      Get.snackbar('Info', 'Mise à jour à implémenter');
    }
  }
}
