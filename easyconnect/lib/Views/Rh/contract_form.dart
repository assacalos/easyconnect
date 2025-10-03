import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/contract_controller.dart';
import 'package:easyconnect/Models/contract_model.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';

class ContractForm extends StatefulWidget {
  final Contract? contract;

  const ContractForm({super.key, this.contract});

  @override
  State<ContractForm> createState() => _ContractFormState();
}

class _ContractFormState extends State<ContractForm> {
  final ContractController controller = Get.put(ContractController());
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.contract != null) {
      controller.fillForm(widget.contract!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.contract == null ? 'Nouveau Contrat' : 'Modifier le Contrat',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => _saveContract(),
            child: const Text(
              'Enregistrer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations générales
              _buildSectionTitle('Informations Générales'),
              _buildGeneralInfoSection(),

              const SizedBox(height: 24),

              // Informations employé
              _buildSectionTitle('Informations Employé'),
              _buildEmployeeInfoSection(),

              const SizedBox(height: 24),

              // Détails du contrat
              _buildSectionTitle('Détails du Contrat'),
              _buildContractDetailsSection(),

              const SizedBox(height: 24),

              // Conditions de travail
              _buildSectionTitle('Conditions de Travail'),
              _buildWorkConditionsSection(),

              const SizedBox(height: 24),

              // Avantages et bénéfices
              _buildSectionTitle('Avantages et Bénéfices'),
              _buildBenefitsSection(),

              const SizedBox(height: 24),

              // Documents et notes
              _buildSectionTitle('Documents et Notes'),
              _buildDocumentsSection(),

              const SizedBox(height: 32),

              // Boutons d'action
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildGeneralInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: controller.contractNumberController,
              decoration: const InputDecoration(
                labelText: 'Numéro du contrat *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le numéro du contrat est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.selectedContractType.value,
                decoration: const InputDecoration(
                  labelText: 'Type de contrat *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                items:
                    controller.contractTypeOptions
                        .map<DropdownMenuItem<String>>((type) {
                          return DropdownMenuItem<String>(
                            value: type['value']!,
                            child: Text(type['label']!),
                          );
                        })
                        .toList(),
                onChanged: (value) => controller.setContractType(value!),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le type de contrat est requis';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.departmentController,
              decoration: const InputDecoration(
                labelText: 'Département *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le département est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.jobTitleController,
              decoration: const InputDecoration(
                labelText: 'Poste *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le poste est requis';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Obx(
              () => DropdownButtonFormField<int>(
                value: controller.selectedEmployeeId.value,
                decoration: const InputDecoration(
                  labelText: 'Employé *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items:
                    controller.employees.map<DropdownMenuItem<int>>((employee) {
                      return DropdownMenuItem<int>(
                        value: employee['id']!,
                        child: Text(employee['name']!),
                      );
                    }).toList(),
                onChanged: (value) => controller.setEmployee(value!),
                validator: (value) {
                  if (value == null) {
                    return 'L\'employé est requis';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.employeeNameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet de l\'employé',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.employeeEmailController,
              decoration: const InputDecoration(
                labelText: 'Email de l\'employé',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.employeePhoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone de l\'employé',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.startDateController,
                    decoration: const InputDecoration(
                      labelText: 'Date de début *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap:
                        () => _selectDate(controller.startDateController, true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La date de début est requise';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: controller.endDateController,
                    decoration: const InputDecoration(
                      labelText: 'Date de fin',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.event),
                    ),
                    readOnly: true,
                    onTap:
                        () => _selectDate(controller.endDateController, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.grossSalaryController,
                    decoration: const InputDecoration(
                      labelText: 'Salaire brut *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le salaire brut est requis';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Veuillez entrer un montant valide';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(
                    () => DropdownButtonFormField<String>(
                      value: controller.selectedPaymentFrequency.value,
                      decoration: const InputDecoration(
                        labelText: 'Fréquence de paiement *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      items:
                          controller.paymentFrequencyOptions
                              .map<DropdownMenuItem<String>>((freq) {
                                return DropdownMenuItem<String>(
                                  value: freq['value']!,
                                  child: Text(freq['label']!),
                                );
                              })
                              .toList(),
                      onChanged:
                          (value) => controller.setPaymentFrequency(value!),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La fréquence de paiement est requise';
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
                    controller: controller.weeklyHoursController,
                    decoration: const InputDecoration(
                      labelText: 'Heures par semaine *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Les heures par semaine sont requises';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Veuillez entrer un nombre valide';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: controller.probationPeriodController,
                    decoration: const InputDecoration(
                      labelText: 'Période d\'essai (mois)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkConditionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: controller.workLocationController,
              decoration: const InputDecoration(
                labelText: 'Lieu de travail *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le lieu de travail est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.workScheduleController,
              decoration: const InputDecoration(
                labelText: 'Horaires de travail',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.reportingManagerController,
              decoration: const InputDecoration(
                labelText: 'Superviseur direct',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.supervisor_account),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.jobDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Description du poste',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: controller.healthInsuranceController,
              decoration: const InputDecoration(
                labelText: 'Assurance maladie',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.health_and_safety),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.retirementPlanController,
              decoration: const InputDecoration(
                labelText: 'Plan de retraite',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.vacationDaysController,
              decoration: const InputDecoration(
                labelText: 'Jours de congé par an',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.otherBenefitsController,
              decoration: const InputDecoration(
                labelText: 'Autres avantages',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.card_giftcard),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: controller.notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.attachmentsController,
              decoration: const InputDecoration(
                labelText: 'Pièces jointes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_file),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return UniformFormButtons(
      onCancel: () => Get.back(),
      onSubmit: () => _saveContract(),
      submitText: 'Soumettre',
    );
  }

  Future<void> _selectDate(
    TextEditingController controller,
    bool isStartDate,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isStartDate
              ? DateTime.now()
              : DateTime.now().add(const Duration(days: 365)),
      firstDate: isStartDate ? DateTime.now() : DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  void _saveContract() async {
    if (_formKey.currentState!.validate()) {
      if (widget.contract == null) {
        await controller.createContract();
      } else {
        await controller.updateContract(widget.contract!);
      }
      Get.back(); // Retour automatique à la liste
    }
  }
}
