import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/expense_controller.dart';
import 'package:easyconnect/Models/expense_model.dart';
import 'package:easyconnect/Views/Comptable/expense_form.dart';
import 'package:intl/intl.dart';

class ExpenseDetail extends StatelessWidget {
  final Expense expense;

  const ExpenseDetail({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final ExpenseController controller = Get.put(ExpenseController());
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'fcfa',
    );
    final formatDate = DateFormat('dd/MM/yyyy à HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(expense.title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (controller.canManageExpenses && expense.status == 'pending')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Get.to(() => ExpenseForm(expense: expense)),
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareExpense(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            _buildHeaderCard(),
            const SizedBox(height: 16),

            // Informations de base
            _buildInfoCard('Informations de base', [
              _buildInfoRow(Icons.title, 'Titre', expense.title),
              _buildInfoRow(Icons.category, 'Catégorie', expense.categoryText),
              _buildInfoRow(
                Icons.currency_franc,
                'Montant',
                formatCurrency.format(expense.amount),
              ),
              _buildInfoRow(
                Icons.calendar_today,
                'Date de dépense',
                DateFormat('dd/MM/yyyy').format(expense.expenseDate),
              ),
              _buildInfoRow(
                Icons.description,
                'Description',
                expense.description,
              ),
            ]),

            // Justificatif si disponible
            if (expense.receiptPath != null) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Justificatif', [
                _buildInfoRow(Icons.receipt, 'Fichier', 'Justificatif joint'),
              ]),
            ],

            // Notes si disponibles
            if (expense.notes != null && expense.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Notes', [
                _buildInfoRow(Icons.note, 'Notes', expense.notes!),
              ]),
            ],

            // Historique des actions
            const SizedBox(height: 16),
            _buildHistoryCard(),

            const SizedBox(height: 16),

            // Actions
            _buildActionButtons(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: expense.statusColor.withOpacity(0.1),
              child: Icon(
                expense.statusIcon,
                size: 30,
                color: expense.statusColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(),
                  const SizedBox(height: 8),
                  Text(
                    'Créé le ${DateFormat('dd/MM/yyyy').format(expense.createdAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: expense.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: expense.statusColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(expense.statusIcon, size: 16, color: expense.statusColor),
          const SizedBox(width: 4),
          Text(
            expense.statusText,
            style: TextStyle(
              color: expense.statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historique',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            _buildHistoryItem(
              Icons.add,
              'Créé',
              DateFormat('dd/MM/yyyy à HH:mm').format(expense.createdAt),
              Colors.blue,
            ),
            if (expense.status == 'approved' && expense.approvedAt != null)
              _buildHistoryItem(
                Icons.check_circle,
                'Approuvé',
                DateFormat(
                  'dd/MM/yyyy à HH:mm',
                ).format(DateTime.parse(expense.approvedAt!)),
                Colors.green,
              ),
            if (expense.status == 'rejected')
              _buildHistoryItem(
                Icons.cancel,
                'Rejeté',
                DateFormat('dd/MM/yyyy à HH:mm').format(expense.updatedAt),
                Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    IconData icon,
    String action,
    String date,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ExpenseController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (expense.status == 'pending' &&
                    controller.canManageExpenses) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier'),
                      onPressed:
                          () => Get.to(() => ExpenseForm(expense: expense)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (expense.status == 'pending' &&
                    controller.canApproveExpenses) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Approuver'),
                      onPressed: () => _showApproveDialog(controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Rejeter'),
                      onPressed: () => _showRejectDialog(controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (expense.status == 'approved' ||
                    expense.status == 'rejected') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text('Voir détails'),
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _shareExpense() {
    // Implémentation du partage
    Get.snackbar(
      'Partage',
      'Fonctionnalité de partage à implémenter',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showApproveDialog(ExpenseController controller) {
    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Approuver la dépense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Êtes-vous sûr de vouloir approuver cette dépense ?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.notesController.text = notesController.text;
              controller.approveExpense(expense);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(ExpenseController controller) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter la dépense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez indiquer la raison du rejet :'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                controller.rejectExpense(expense, reasonController.text.trim());
                Get.back();
              } else {
                Get.snackbar('Erreur', 'Veuillez indiquer la raison du rejet');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}
