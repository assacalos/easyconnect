import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/contract_controller.dart';
import 'package:easyconnect/Models/contract_model.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

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
    // Charger les employés et départements si nécessaire
    if (controller.employees.isEmpty) {
      controller.loadEmployees();
    }
    if (controller.departments.isEmpty) {
      controller.loadDepartments();
    }
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
            Obx(() {
              final contractTypeOptionsFiltered =
                  controller.contractTypeOptions
                      .where((type) => type['value'] != 'all')
                      .toList();
              final currentValue = controller.selectedContractTypeForm.value;
              final validValue =
                  currentValue.isNotEmpty &&
                          currentValue != 'all' &&
                          contractTypeOptionsFiltered.any(
                            (type) => type['value'] == currentValue,
                          )
                      ? currentValue
                      : null;

              return DropdownButtonFormField<String>(
                value: validValue,
                decoration: const InputDecoration(
                  labelText: 'Type de contrat *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                items:
                    contractTypeOptionsFiltered.map<DropdownMenuItem<String>>((
                      type,
                    ) {
                      return DropdownMenuItem<String>(
                        value: type['value']!,
                        child: Text(type['label']!),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.setContractType(value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le type de contrat est requis';
                  }
                  return null;
                },
              );
            }),
            const SizedBox(height: 16),
            Obx(
              () => DropdownButtonFormField<String>(
                value:
                    controller.selectedDepartmentForm.value.isNotEmpty
                        ? controller.selectedDepartmentForm.value
                        : null,
                decoration: const InputDecoration(
                  labelText: 'Département *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Sélectionner'),
                  ),
                  ...controller.departmentOptionsForForm
                      .map<DropdownMenuItem<String>>((dept) {
                        return DropdownMenuItem<String>(
                          value: dept,
                          child: Text(dept),
                        );
                      })
                      .toList(),
                ],
                onChanged: (value) {
                  controller.selectedDepartmentForm.value = value ?? '';
                  controller.departmentController.text = value ?? '';
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le département est requis';
                  }
                  return null;
                },
              ),
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
            Obx(() {
              final employees = controller.employees;
              final currentValue = controller.selectedEmployeeId.value;
              // S'assurer que la valeur actuelle est dans la liste des employés
              final validValue =
                  employees.any((emp) => emp.id == currentValue) &&
                          currentValue != 0
                      ? currentValue
                      : null;

              return DropdownButtonFormField<int>(
                value: validValue,
                decoration: const InputDecoration(
                  labelText: 'Employé *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Sélectionner un employé'),
                  ),
                  ...employees.map<DropdownMenuItem<int>>((employee) {
                    return DropdownMenuItem<int>(
                      value: employee.id,
                      child: Text(
                        '${employee.firstName} ${employee.lastName} - ${employee.email}',
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (value) => controller.setEmployee(value),
                validator: (value) {
                  if (value == null || value == 0) {
                    return 'L\'employé est requis';
                  }
                  return null;
                },
              );
            }),
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
                      value:
                          controller
                                      .selectedPaymentFrequency
                                      .value
                                      .isNotEmpty &&
                                  controller.paymentFrequencyOptions.any(
                                    (freq) =>
                                        freq['value'] ==
                                        controller
                                            .selectedPaymentFrequency
                                            .value,
                                  )
                              ? controller.selectedPaymentFrequency.value
                              : null,
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
                      onChanged: (value) {
                        if (value != null) {
                          controller.setPaymentFrequency(value);
                        }
                      },
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
                  child: Obx(
                    () => DropdownButtonFormField<String>(
                      value:
                          controller.selectedProbationPeriod.value.isNotEmpty
                              ? controller.selectedProbationPeriod.value
                              : 'none',
                      decoration: const InputDecoration(
                        labelText: 'Période d\'essai',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                      ),
                      items:
                          controller.probationPeriodOptions
                              .map<DropdownMenuItem<String>>((option) {
                                return DropdownMenuItem<String>(
                                  value: option['value'],
                                  child: Text(option['label']!),
                                );
                              })
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.selectedProbationPeriod.value = value;
                          controller.selectProbationPeriod(value);
                        }
                      },
                    ),
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
            DropdownButtonFormField<String>(
              value:
                  controller.workScheduleController.text.trim().isNotEmpty &&
                          ['full_time', 'part_time', 'flexible'].contains(
                            controller.workScheduleController.text.trim(),
                          )
                      ? controller.workScheduleController.text.trim()
                      : null,
              decoration: const InputDecoration(
                labelText: 'Horaire de travail *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: 'full_time',
                  child: Text('Temps plein'),
                ),
                const DropdownMenuItem<String>(
                  value: 'part_time',
                  child: Text('Temps partiel'),
                ),
                const DropdownMenuItem<String>(
                  value: 'flexible',
                  child: Text('Flexible'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  controller.workScheduleController.text = value;
                  controller.selectWorkSchedule(value);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'L\'horaire de travail est requis';
                }
                return null;
              },
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
            // Affichage des fichiers sélectionnés
            Obx(() {
              if (controller.selectedAttachments.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fichiers sélectionnés:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...controller.selectedAttachments.asMap().entries.map((
                    entry,
                  ) {
                    final index = entry.key;
                    final file = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          _getFileIcon(file['type'] ?? ''),
                          color: Colors.blue,
                        ),
                        title: Text(
                          file['name'] ?? 'Fichier',
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle:
                            file['size'] != null
                                ? Text(
                                  _formatFileSize(file['size']),
                                  style: const TextStyle(fontSize: 12),
                                )
                                : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => controller.removeAttachment(index),
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                ],
              );
            }),
            // Bouton pour sélectionner des fichiers
            ElevatedButton.icon(
              onPressed: () => _selectFiles(controller),
              icon: const Icon(Icons.attach_file),
              label: const Text('Sélectionner des fichiers'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Formats acceptés: PDF, Images, Documents (max 10 MB par fichier)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
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

  Future<void> _selectFiles(ContractController controller) async {
    try {
      // Proposer de choisir le type de sélection
      final String? selectionType = await Get.dialog<String>(
        AlertDialog(
          title: const Text('Sélectionner des fichiers'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Fichiers (PDF, Documents, etc.)'),
                onTap: () => Get.back(result: 'file'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Image depuis la galerie'),
                onTap: () => Get.back(result: 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                onTap: () => Get.back(result: 'camera'),
              ),
            ],
          ),
        ),
      );

      if (selectionType == null) return;

      if (selectionType == 'file') {
        // Sélectionner des fichiers avec file_picker
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: true,
        );

        if (result != null && result.files.isNotEmpty) {
          for (var platformFile in result.files) {
            if (platformFile.path != null) {
              final file = File(platformFile.path!);
              final fileSize = await file.length();

              // Vérifier la taille (max 10 MB)
              if (fileSize > 10 * 1024 * 1024) {
                Get.snackbar(
                  'Erreur',
                  'Le fichier "${platformFile.name}" est trop volumineux (max 10 MB)',
                  snackPosition: SnackPosition.BOTTOM,
                );
                continue;
              }

              // Déterminer le type de fichier
              String fileType = 'document';
              final extension = platformFile.extension?.toLowerCase() ?? '';
              if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
                fileType = 'image';
              } else if (extension == 'pdf') {
                fileType = 'pdf';
              }

              // Ajouter le fichier à la liste
              controller.selectedAttachments.add({
                'name': platformFile.name,
                'path': platformFile.path!,
                'size': fileSize,
                'type': fileType,
                'extension': extension,
              });
            }
          }
          controller.updateAttachmentsDisplay();

          Get.snackbar(
            'Succès',
            '${result.files.length} fichier(s) sélectionné(s)',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        // Utiliser image_picker pour les images
        final ImagePicker picker = ImagePicker();
        final ImageSource source =
            selectionType == 'camera'
                ? ImageSource.camera
                : ImageSource.gallery;

        final XFile? pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          final file = File(pickedFile.path);
          final fileSize = await file.length();

          // Vérifier la taille (max 10 MB)
          if (fileSize > 10 * 1024 * 1024) {
            Get.snackbar(
              'Erreur',
              'Le fichier est trop volumineux (max 10 MB)',
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }

          // Ajouter le fichier à la liste
          controller.selectedAttachments.add({
            'name': pickedFile.name,
            'path': pickedFile.path,
            'size': fileSize,
            'type': 'image',
            'extension': 'jpg',
          });
          controller.updateAttachmentsDisplay();

          Get.snackbar(
            'Succès',
            'Fichier sélectionné',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la sélection du fichier: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  IconData _getFileIcon(String fileType) {
    if (fileType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (fileType.contains('image')) {
      return Icons.image;
    } else if (fileType.contains('word') || fileType.contains('document')) {
      return Icons.description;
    } else {
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
}
