import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/expense_controller.dart';
import 'package:easyconnect/Models/expense_model.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';

class ExpenseForm extends StatelessWidget {
  final Expense? expense;

  const ExpenseForm({super.key, this.expense});

  @override
  Widget build(BuildContext context) {
    final ExpenseController controller = Get.put(ExpenseController());

    // S'assurer que les catégories sont chargées
    if (controller.expenseCategories.isEmpty) {
      controller.loadExpenseCategories();
    }

    // Si on édite une dépense existante, remplir le formulaire
    if (expense != null) {
      controller.fillForm(expense!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          expense == null ? 'Nouvelle Dépense' : 'Modifier la Dépense',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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
                  labelText: 'Titre de la dépense *',
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

              // Catégorie
              Obx(() {
                // Toujours utiliser les catégories par défaut pour garantir une liste complète
                // Les catégories par défaut sont toujours disponibles et complètes
                return DropdownButtonFormField<String>(
                  value: controller.selectedCategoryForm.value,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items:
                      controller.expenseCategoriesList
                          .map<DropdownMenuItem<String>>((category) {
                            return DropdownMenuItem<String>(
                              value: category['value'] as String,
                              child: Text(category['label'] as String),
                            );
                          })
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedCategoryForm.value = value;
                      // Si on a des catégories API, essayer de trouver l'ID correspondant
                      if (controller.expenseCategories.isNotEmpty) {
                        final apiCategory = controller.expenseCategories
                            .firstWhereOrNull(
                              (cat) =>
                                  cat.name.toLowerCase() ==
                                      value.toLowerCase() ||
                                  cat.name.toLowerCase().contains(
                                    value.toLowerCase(),
                                  ),
                            );
                        if (apiCategory != null) {
                          controller.selectedCategoryId.value =
                              apiCategory.id ?? 0;
                        }
                      }
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La catégorie est obligatoire';
                    }
                    return null;
                  },
                );
              }),

              const SizedBox(height: 16),

              // Montant
              TextFormField(
                controller: controller.amountController,
                decoration: const InputDecoration(
                  labelText: 'Montant (fcfa) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_franc),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le montant est obligatoire';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Le montant doit être un nombre';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Le montant doit être positif';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Date de dépense
              Obx(
                () => InkWell(
                  onTap: () => controller.selectExpenseDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date de la dépense *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      controller.selectedExpenseDate.value != null
                          ? DateFormat(
                            'dd/MM/yyyy',
                          ).format(controller.selectedExpenseDate.value!)
                          : 'Sélectionner une date',
                      style: TextStyle(
                        color:
                            controller.selectedExpenseDate.value != null
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
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Description de la dépense (optionnel)',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Informations supplémentaires
              _buildSectionTitle('Informations supplémentaires'),
              const SizedBox(height: 16),

              // Justificatif
              Obx(
                () => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt,
                        size: 48,
                        color:
                            controller.selectedReceiptPath.value != null
                                ? Colors.green
                                : Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.selectedReceiptPath.value != null
                            ? 'Justificatif ajouté'
                            : 'Aucun justificatif',
                        style: TextStyle(
                          color:
                              controller.selectedReceiptPath.value != null
                                  ? Colors.green
                                  : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: Icon(
                          controller.selectedReceiptPath.value != null
                              ? Icons.edit
                              : Icons.add,
                        ),
                        label: Text(
                          controller.selectedReceiptPath.value != null
                              ? 'Modifier le justificatif'
                              : 'Ajouter un justificatif',
                        ),
                        onPressed: () => _selectReceipt(controller),
                      ),
                      if (controller.selectedReceiptPath.value != null) ...[
                        const SizedBox(height: 8),
                        // Afficher un aperçu de l'image
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(controller.selectedReceiptPath.value!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.delete),
                              label: const Text('Supprimer'),
                              onPressed:
                                  () =>
                                      controller.selectedReceiptPath.value =
                                          null,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Notes
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
                onSubmit: () => _saveExpense(controller),
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

  void _saveExpense(ExpenseController controller) async {
    bool success = false;
    if (expense == null) {
      success = await controller.createExpense();
    } else {
      success = await controller.updateExpense(expense!);
    }
    if (success) {
      Get.back();
    }
  }

  void _selectReceipt(ExpenseController controller) {
    controller.selectReceipt();
  }
}
