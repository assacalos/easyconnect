import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Controllers/journal_controller.dart';
import 'package:easyconnect/Views/Components/journal_form_page.dart';
import 'package:easyconnect/Views/Components/journal_detail_page.dart';

class JournalListPage extends StatelessWidget {
  const JournalListPage({super.key});

  static final _formatNumber = NumberFormat('#,##0', 'fr_FR');

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(JournalController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal des comptes'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadJournal(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.lignes.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return RefreshIndicator(
                onRefresh: () => controller.loadJournal(),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSummaryCard(context, controller),
                    const SizedBox(height: 16),
                    ...controller.lignes.map((l) => _buildLineTile(context, controller, l)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await Get.to<bool>(() => const JournalFormPage());
          if (ok == true) {
            controller.loadJournal();
          }
        },
        backgroundColor: Colors.teal.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, JournalController controller) {
    final now = DateTime.now();
    final month = controller.selectedMonth ?? now.month;
    final year = controller.selectedYear ?? now.year;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<int>(
              value: month,
              isExpanded: true,
              items: List.generate(12, (i) => i + 1).map((m) {
                final name = DateFormat('MMMM', 'fr_FR').format(DateTime(2000, m));
                return DropdownMenuItem(value: m, child: Text(name));
              }).toList(),
              onChanged: (v) {
                if (v != null) controller.setMonthYear(v, year);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<int>(
              value: year,
              isExpanded: true,
              items: [now.year, now.year - 1, now.year - 2]
                  .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                  .toList(),
              onChanged: (v) {
                if (v != null) controller.setMonthYear(month, v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, JournalController controller) {
    final now = DateTime.now();
    final month = controller.selectedMonth ?? now.month;
    final year = controller.selectedYear ?? now.year;
    final lastDayPrev = DateTime(year, month, 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Solde initial', style: TextStyle(color: Colors.grey.shade700)),
                    Text(
                      '${_formatNumber.format(controller.soldeInitial)} FCFA',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showSoldeOuvertureDialog(context, controller, lastDayPrev),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Définir solde d\'ouverture'),
                  style: TextButton.styleFrom(foregroundColor: Colors.teal.shade700),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total entrées', style: TextStyle(color: Colors.green.shade700)),
                Text('${_formatNumber.format(controller.totalEntrees)} FCFA', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade700)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total sorties', style: TextStyle(color: Colors.red.shade700)),
                Text('${_formatNumber.format(controller.totalSorties)} FCFA', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade700)),
              ],
            ),
            const Divider(),
            Text('Solde final', style: TextStyle(color: Colors.grey.shade700)),
            Text(
              '${_formatNumber.format(controller.soldeFinal)} FCFA',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineTile(BuildContext context, JournalController controller, dynamic line) {
    final id = line['id'];
    final date = line['date']?.toString() ?? '';
    final libelle = line['libelle']?.toString() ?? '';
    final entree = (line['entree'] is num) ? (line['entree'] as num).toDouble() : 0.0;
    final sortie = (line['sortie'] is num) ? (line['sortie'] as num).toDouble() : 0.0;
    final solde = (line['solde'] is num) ? (line['solde'] as num).toDouble() : 0.0;

    final entryId = id is int ? id : int.tryParse(id.toString());
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: entryId != null
            ? () => Get.to(() => JournalDetailPage(entryId: entryId))?.then((_) => controller.loadJournal())
            : null,
        title: Text(libelle, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(date),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entree > 0) Text('+${_formatNumber.format(entree)}', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
            if (sortie > 0) Text('-${_formatNumber.format(sortie)}', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text('${_formatNumber.format(solde)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (entryId != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () async {
                  final ok = await Get.to<bool>(() => JournalFormPage(entryId: entryId));
                  if (ok == true) controller.loadJournal();
                },
              ),
            if (entryId != null)
              IconButton(
                icon: Icon(Icons.delete, size: 20, color: Colors.red.shade700),
                onPressed: () async {
                  final confirm = await Get.dialog<bool>(
                    AlertDialog(
                      title: const Text('Supprimer'),
                      content: const Text('Supprimer cette écriture ?'),
                      actions: [
                        TextButton(onPressed: () => Get.back(result: false), child: const Text('Annuler')),
                        TextButton(onPressed: () => Get.back(result: true), child: Text('Supprimer', style: TextStyle(color: Colors.red.shade700))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await controller.deleteEntry(entryId);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  static void _showSoldeOuvertureDialog(
    BuildContext context,
    JournalController controller,
    DateTime defaultDate,
  ) {
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(defaultDate),
    );
    final montantController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: const Text('Solde d\'ouverture'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Le solde initial affiché correspond au cumul des écritures avant la période. '
                  'Pour fixer un solde d\'ouverture, enregistrez une écriture avec la date souhaitée '
                  '(ex. dernier jour du mois précédent). Montant positif = entrée, négatif = sortie (découvert).',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(dateController.text) ?? defaultDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      dateController.text = DateFormat('yyyy-MM-dd').format(date);
                    }
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Date requise' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: montantController,
                  decoration: const InputDecoration(
                    labelText: 'Montant (FCFA). Positif = entrée, Négatif = découvert',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Montant requis';
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    if (n == null) return 'Montant invalide';
                    if (n == 0) return 'Le montant ne peut pas être zéro';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final montant = double.tryParse(
                montantController.text.trim().replaceAll(',', '.'),
              );
              if (montant == null || montant == 0) return;
              final entree = montant > 0 ? montant : 0.0;
              final sortie = montant < 0 ? montant.abs() : 0.0;
              final ok = await controller.createEntry({
                'date': dateController.text.trim(),
                'libelle': 'Solde d\'ouverture',
                'mode_paiement': 'especes',
                'entree': entree,
                'sortie': sortie,
              });
              if (ok) Get.back();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.teal.shade700),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
