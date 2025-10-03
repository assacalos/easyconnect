import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/expense_controller.dart';
import 'package:easyconnect/Models/expense_model.dart';
import 'package:easyconnect/Views/Comptable/expense_form.dart';
import 'package:easyconnect/Views/Comptable/expense_detail.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';

class ExpenseList extends StatefulWidget {
  const ExpenseList({super.key});

  @override
  State<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList>
    with SingleTickerProviderStateMixin {
  final ExpenseController controller = Get.put(ExpenseController());
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Dépenses'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadExpenses(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Toutes', icon: Icon(Icons.list)),
            Tab(text: 'En attente', icon: Icon(Icons.pending)),
            Tab(text: 'Validées', icon: Icon(Icons.check_circle)),
            Tab(text: 'Rejetées', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Barre de recherche
              _buildSearchBar(),

              // Statistiques rapides
              _buildQuickStats(controller),

              // Liste des dépenses avec onglets
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExpenseList(controller, null), // Toutes
                    _buildExpenseList(controller, 'pending'), // En attente
                    _buildExpenseList(controller, 'approved'), // Validées
                    _buildExpenseList(controller, 'rejected'), // Rejetées
                  ],
                ),
              ),
            ],
          ),
          // Bouton d'ajout uniforme en bas à droite
          if (controller.canManageExpenses)
            UniformAddButton(
              onPressed: () => Get.to(() => const ExpenseForm()),
              label: 'Nouvelle Dépense',
              icon: Icons.money_off,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher par titre ou description...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() => _searchQuery = '');
                    },
                  )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildQuickStats(ExpenseController controller) {
    return Obx(() {
      if (controller.expenseStats.value == null) {
        return const SizedBox.shrink();
      }

      final stats = controller.expenseStats.value!;
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                '${stats.totalExpenses}',
                Icons.receipt,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'En attente',
                '${stats.pendingExpenses}',
                Icons.schedule,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Approuvées',
                '${stats.approvedExpenses}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Rejetées',
                '${stats.rejectedExpenses}',
                Icons.cancel,
                Colors.red,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(ExpenseController controller, String? status) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // Filtrer les dépenses par statut et recherche
      List<Expense> filteredExpenses =
          controller.expenses.where((expense) {
            // Filtre par statut
            if (status != null && expense.status != status) {
              return false;
            }

            // Filtre par recherche
            if (_searchQuery.isNotEmpty) {
              return expense.title.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  expense.description.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
            }

            return true;
          }).toList();

      if (filteredExpenses.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucune dépense trouvée',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Commencez par ajouter une dépense',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredExpenses.length,
        itemBuilder: (context, index) {
          final expense = filteredExpenses[index];
          return _buildExpenseCard(expense, controller);
        },
      );
    });
  }

  Widget _buildExpenseCard(Expense expense, ExpenseController controller) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'fcfa',
    );
    final formatDate = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Get.to(() => ExpenseDetail(expense: expense)),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec titre et statut
              Row(
                children: [
                  Expanded(
                    child: Text(
                      expense.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(expense),
                ],
              ),

              const SizedBox(height: 8),

              // Catégorie et montant
              Row(
                children: [
                  Icon(
                    expense.categoryIcon,
                    size: 16,
                    color: expense.categoryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    expense.categoryText,
                    style: TextStyle(
                      color: expense.categoryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatCurrency.format(expense.amount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Date de dépense
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Date: ${formatDate.format(expense.expenseDate)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Description
              if (expense.description.isNotEmpty) ...[
                Text(
                  expense.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (expense.status == 'pending' &&
                      controller.canManageExpenses) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      onPressed:
                          () => Get.to(() => ExpenseForm(expense: expense)),
                    ),
                  ],
                  if (expense.status == 'pending' &&
                      controller.canApproveExpenses) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approuver'),
                      onPressed: () => _showApproveDialog(expense, controller),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rejeter'),
                      onPressed: () => _showRejectDialog(expense, controller),
                    ),
                  ],
                  if (expense.status == 'approved' ||
                      expense.status == 'rejected') ...[
                    TextButton.icon(
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Voir détails'),
                      onPressed:
                          () => Get.to(() => ExpenseDetail(expense: expense)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(Expense expense) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: expense.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: expense.statusColor.withOpacity(0.5)),
      ),
      child: Text(
        expense.statusText,
        style: TextStyle(
          color: expense.statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showApproveDialog(Expense expense, ExpenseController controller) {
    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Approuver la dépense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Êtes-vous sûr de vouloir approuver cette dépense ?'),
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

  void _showRejectDialog(Expense expense, ExpenseController controller) {
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
