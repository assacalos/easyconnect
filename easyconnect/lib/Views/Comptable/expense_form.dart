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
              Obx(
                () => DropdownButtonFormField<String>(
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
                  onChanged:
                      (value) => controller.selectedCategoryForm.value = value!,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La catégorie est obligatoire';
                    }
                    return null;
                  },
                ),
              ),

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
                        TextButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text('Supprimer'),
                          onPressed:
                              () => controller.selectedReceiptPath.value = null,
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
    if (expense == null) {
      await controller.createExpense();
    } else {
      await controller.updateExpense(expense!);
    }
    Get.back(); // Retour automatique à la liste
  }

  void _selectReceipt(ExpenseController controller) {
    // Implémentation de la sélection de justificatif
    Get.snackbar(
      'Justificatif',
      'Fonctionnalité de sélection de justificatif à implémenter',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
