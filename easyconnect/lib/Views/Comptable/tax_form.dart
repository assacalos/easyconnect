import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/tax_controller.dart';
import 'package:easyconnect/Models/tax_model.dart';
import 'package:easyconnect/services/tax_service.dart';

class TaxForm extends StatefulWidget {
  final Tax? tax;

  const TaxForm({super.key, this.tax});

  @override
  State<TaxForm> createState() => _TaxFormState();
}

class _TaxFormState extends State<TaxForm> {
  final _formKey = GlobalKey<FormState>();
  final TaxController controller = Get.put(TaxController());
  final TaxService taxService = TaxService();

  // Liste statique des catégories de taxes
  static const List<String> taxCategories = [
    'TVA', // Taxe sur la Valeur Ajoutée
    'IS', // Impôt sur les Sociétés
    'IRPP', // Impôt sur le Revenu des Personnes Physiques
    'TFP', // Taxe Foncière sur les Propriétés
    'CFCE', // Contribution Forfaitaire à la Charge des Employeurs
    'CNPS', // Caisse Nationale de Prévoyance Sociale
    'TA', // Taxe d\'Abattage
    'Droit de Timbre',
    'Autre',
  ];

  // Contrôleurs
  final TextEditingController baseAmountController = TextEditingController();
  final TextEditingController taxRateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  // Variables pour les sélections
  String? selectedCategory;
  DateTime? selectedPeriodStart;
  DateTime? selectedPeriodEnd;
  DateTime? selectedDueDate;
  String? selectedMonth;
  int? selectedYear;

  @override
  void initState() {
    super.initState();

    // Pré-remplir le formulaire si on modifie une taxe existante
    if (widget.tax != null) {
      _fillForm(widget.tax!);
    } else {
      // Valeurs par défaut pour une nouvelle taxe
      final now = DateTime.now();
      selectedMonth = '${now.month.toString().padLeft(2, '0')}';
      selectedYear = now.year;
      _updatePeriodDates();
      selectedDueDate = DateTime(
        now.year,
        now.month + 1,
        15,
      ); // 15 du mois suivant
    }
  }

  @override
  void dispose() {
    baseAmountController.dispose();
    taxRateController.dispose();
    descriptionController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _fillForm(Tax tax) {
    selectedCategory = tax.category;
    baseAmountController.text = tax.baseAmount.toString();
    if (tax.taxRate != null) {
      taxRateController.text = tax.taxRate.toString();
    }
    descriptionController.text = tax.description ?? '';
    notesController.text = tax.notes ?? '';

    if (tax.periodStart != null) {
      selectedPeriodStart = DateTime.parse(tax.periodStart!);
      final date = DateTime.parse(tax.periodStart!);
      selectedMonth = '${date.month.toString().padLeft(2, '0')}';
      selectedYear = date.year;
    }
    if (tax.periodEnd != null) {
      selectedPeriodEnd = DateTime.parse(tax.periodEnd!);
    }
    if (tax.dueDate != null) {
      selectedDueDate = DateTime.parse(tax.dueDate!);
    }
  }

  void _updatePeriodDates() {
    if (selectedMonth != null && selectedYear != null) {
      final month = int.parse(selectedMonth!);
      // Premier jour du mois
      selectedPeriodStart = DateTime(selectedYear!, month, 1);
      // Dernier jour du mois
      selectedPeriodEnd = DateTime(selectedYear!, month + 1, 0);
      setState(() {});
    }
  }

  Future<void> _selectPeriod() async {
    // Sélectionner le mois et l'année
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sélectionner la période'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sélection du mois
                DropdownButtonFormField<String>(
                  value: selectedMonth,
                  decoration: const InputDecoration(labelText: 'Mois'),
                  items: List.generate(12, (index) {
                    final month = (index + 1).toString().padLeft(2, '0');
                    final monthNames = [
                      'Janvier',
                      'Février',
                      'Mars',
                      'Avril',
                      'Mai',
                      'Juin',
                      'Juillet',
                      'Août',
                      'Septembre',
                      'Octobre',
                      'Novembre',
                      'Décembre',
                    ];
                    return DropdownMenuItem(
                      value: month,
                      child: Text(monthNames[index]),
                    );
                  }),
                  onChanged: (value) {
                    setState(() => selectedMonth = value);
                  },
                ),
                const SizedBox(height: 16),
                // Sélection de l'année
                DropdownButtonFormField<int>(
                  value: selectedYear ?? DateTime.now().year,
                  decoration: const InputDecoration(labelText: 'Année'),
                  items: List.generate(5, (index) {
                    final year = DateTime.now().year - 2 + index;
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }),
                  onChanged: (value) {
                    setState(() => selectedYear = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedMonth != null && selectedYear != null) {
                    Get.back(
                      result: {'month': selectedMonth, 'year': selectedYear},
                    );
                  }
                },
                child: const Text('Valider'),
              ),
            ],
          ),
    );

    if (result != null) {
      setState(() {
        selectedMonth = result['month'];
        selectedYear = result['year'];
      });
      _updatePeriodDates();
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          selectedDueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDueDate) {
      setState(() => selectedDueDate = picked);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non sélectionnée';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _saveTax() async {
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

    // Validation des champs requis
    if (selectedCategory == null || selectedCategory!.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner une catégorie de taxe',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (selectedPeriodStart == null || selectedPeriodEnd == null) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner une période',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (selectedDueDate == null) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner une date d\'échéance',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final baseAmount = double.tryParse(baseAmountController.text) ?? 0.0;
    if (baseAmount <= 0) {
      Get.snackbar(
        'Erreur',
        'Le montant de base doit être supérieur à 0',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Construire la période au format YYYY-MM
    final period = '${selectedYear}-${selectedMonth}';

    // Construire les dates au format YYYY-MM-DD
    final periodStart = selectedPeriodStart!.toIso8601String().split('T')[0];
    final periodEnd = selectedPeriodEnd!.toIso8601String().split('T')[0];
    final dueDate = selectedDueDate!.toIso8601String().split('T')[0];

    final tax = Tax(
      id: widget.tax?.id,
      category: selectedCategory!,
      baseAmount: baseAmount,
      period: period,
      periodStart: periodStart,
      periodEnd: periodEnd,
      dueDate: dueDate,
      taxRate:
          taxRateController.text.isNotEmpty
              ? double.tryParse(taxRateController.text)
              : null,
      description:
          descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
      notes:
          notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
    );

    try {
      controller.isLoading.value = true;

      bool success = false;
      if (widget.tax == null) {
        await taxService.createTax(tax);
        success = true;
        Get.snackbar(
          'Succès',
          'Taxe créée avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        await taxService.updateTax(tax);
        success = true;
        Get.snackbar(
          'Succès',
          'Taxe mise à jour avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }

      // Attendre un peu pour que le snackbar s'affiche
      await Future.delayed(const Duration(milliseconds: 500));

      // Recharger les taxes
      await controller.loadTaxes();

      // Fermer automatiquement le formulaire après succès
      if (success && mounted) {
        Get.back();
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de sauvegarder la taxe: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      controller.isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tax == null ? 'Nouvelle taxe' : 'Modifier la taxe'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Catégorie de taxe (requis)
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie de taxe *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items:
                    taxCategories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner une catégorie';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Montant de base (requis)
              TextFormField(
                controller: baseAmountController,
                decoration: const InputDecoration(
                  labelText: 'Montant de base (FCFA) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le montant de base est obligatoire';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Le montant doit être supérieur à 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Taux de taxe (optionnel)
              TextFormField(
                controller: taxRateController,
                decoration: const InputDecoration(
                  labelText: 'Taux de taxe (%)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.percent),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final rate = double.tryParse(value);
                    if (rate == null || rate < 0 || rate > 100) {
                      return 'Le taux doit être entre 0 et 100';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Période (requis)
              InkWell(
                onTap: _selectPeriod,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Période *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_month),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    selectedMonth != null && selectedYear != null
                        ? '${_getMonthName(selectedMonth!)} $selectedYear'
                        : 'Sélectionner la période',
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Dates de période (affichage)
              if (selectedPeriodStart != null && selectedPeriodEnd != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 16),
                  child: Text(
                    'Du ${_formatDate(selectedPeriodStart)} au ${_formatDate(selectedPeriodEnd)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),

              const SizedBox(height: 16),

              // Date d'échéance (requis)
              InkWell(
                onTap: _selectDueDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date d\'échéance *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event),
                  ),
                  child: Text(_formatDate(selectedDueDate)),
                ),
              ),

              const SizedBox(height: 16),

              // Description (optionnel)
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Notes (optionnel)
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Boutons
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value ? null : _saveTax,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child:
                            controller.isLoading.value
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : Text(
                                  widget.tax == null ? 'Créer' : 'Modifier',
                                ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(String month) {
    final monthNames = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    final index = int.parse(month) - 1;
    return monthNames[index >= 0 && index < 12 ? index : 0];
  }
}
