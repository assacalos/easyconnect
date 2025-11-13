import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/salary_controller.dart';
import 'package:easyconnect/Models/salary_model.dart';
import 'package:easyconnect/Views/Comptable/salary_form.dart';
import 'package:easyconnect/Views/Comptable/salary_detail.dart';
import 'package:intl/intl.dart';

class SalaryList extends StatefulWidget {
  const SalaryList({super.key});

  @override
  State<SalaryList> createState() => _SalaryListState();
}

class _SalaryListState extends State<SalaryList>
    with SingleTickerProviderStateMixin {
  final SalaryController controller = Get.put(SalaryController());
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Rafraîchir l'interface quand l'onglet change
        setState(() {});
      }
    });
    controller.loadSalaries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Salary> get _filteredSalaries {
    List<Salary> filtered = controller.salaries;

    // Filtrer par statut selon l'onglet actif
    switch (_tabController.index) {
      case 0: // Tous
        break;
      case 1: // En attente (inclut 'pending' et 'draft')
        filtered =
            filtered.where((s) {
              final status = s.status?.toLowerCase() ?? '';
              return status == 'pending' || status == 'draft';
            }).toList();
        break;
      case 2: // Approuvés
        filtered =
            filtered
                .where((s) => s.status?.toLowerCase() == 'approved')
                .toList();
        break;
      case 3: // Payés
        filtered =
            filtered.where((s) => s.status?.toLowerCase() == 'paid').toList();
        break;
      case 4: // Rejetés
        filtered =
            filtered
                .where((s) => s.status?.toLowerCase() == 'rejected')
                .toList();
        break;
    }

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (salary) =>
                    (salary.employeeName ?? '').toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    (salary.employeeEmail ?? '').toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'fcfa',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salaires'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadSalaries,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Tous', icon: Icon(Icons.list)),
            Tab(text: 'En attente', icon: Icon(Icons.pending)),
            Tab(text: 'Approuvés', icon: Icon(Icons.check_circle)),
            Tab(text: 'Payés', icon: Icon(Icons.payment)),
            Tab(text: 'Rejetés', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher par employé...',
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Liste des salaires
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return _filteredSalaries.isEmpty
                  ? const Center(child: Text('Aucun salaire trouvé'))
                  : ListView.builder(
                    itemCount: _filteredSalaries.length,
                    itemBuilder: (context, index) {
                      final salary = _filteredSalaries[index];
                      return _buildSalaryCard(salary, formatCurrency);
                    },
                  );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const SalaryForm()),
        tooltip: 'Nouveau salaire',
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSalaryCard(Salary salary, NumberFormat formatCurrency) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(salary.status ?? 'pending'),
          child: Icon(
            _getStatusIcon(salary.status ?? 'pending'),
            color: Colors.white,
          ),
        ),
        title: Text(
          salary.employeeName ?? 'Sans nom',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (salary.employeeEmail != null)
              Text('Email: ${salary.employeeEmail}'),
            Text('Période: ${salary.periodText}'),
            Text('Salaire net: ${formatCurrency.format(salary.netSalary)}'),
            if (salary.status == 'rejected' &&
                salary.rejectionReason != null &&
                salary.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.report, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Raison du rejet: ${salary.rejectionReason}',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton Détail
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.blue),
              onPressed: () => Get.to(() => SalaryDetail(salary: salary)),
              tooltip: 'Voir détails',
            ),
            // Bouton Modifier (seulement si pending)
            if (salary.status == 'pending' && controller.canManageSalaries)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange),
                onPressed: () => Get.to(() => SalaryForm(salary: salary)),
                tooltip: 'Modifier',
              ),
            // Menu pour actions supplémentaires
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'approve' && controller.canApproveSalaries) {
                  _showApproveDialog(salary);
                } else if (value == 'reject' && controller.canApproveSalaries) {
                  _showRejectDialog(salary);
                } else if (value == 'mark_paid' &&
                    controller.canApproveSalaries) {
                  _showMarkPaidDialog(salary);
                }
              },
              itemBuilder: (context) {
                final items = <PopupMenuEntry<String>>[];
                if (salary.status == 'pending' &&
                    controller.canApproveSalaries) {
                  items.add(
                    const PopupMenuItem(
                      value: 'approve',
                      child: ListTile(
                        leading: Icon(Icons.check, color: Colors.green),
                        title: Text('Approuver'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  );
                  items.add(
                    const PopupMenuItem(
                      value: 'reject',
                      child: ListTile(
                        leading: Icon(Icons.close, color: Colors.red),
                        title: Text('Rejeter'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  );
                }
                if (salary.status == 'approved' &&
                    controller.canApproveSalaries) {
                  items.add(
                    const PopupMenuItem(
                      value: 'mark_paid',
                      child: ListTile(
                        leading: Icon(Icons.payment, color: Colors.blue),
                        title: Text('Marquer payé'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  );
                }
                return items;
              },
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      salary.status ?? 'pending',
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(salary.status ?? 'pending'),
                    style: TextStyle(
                      color: _getStatusColor(salary.status ?? 'pending'),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency.format(salary.netSalary),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => Get.to(() => SalaryDetail(salary: salary)),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'paid':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'paid':
        return Icons.payment;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvé';
      case 'paid':
        return 'Payé';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  void _showApproveDialog(Salary salary) {
    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Approuver le salaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Approuver le salaire de ${salary.employeeName ?? 'l\'employé'} ?',
            ),
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
              controller.approveSalary(salary);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Salary salary) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter le salaire'),
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
                controller.rejectSalary(salary, reasonController.text.trim());
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

  void _showMarkPaidDialog(Salary salary) {
    Get.dialog(
      AlertDialog(
        title: const Text('Marquer comme payé'),
        content: Text(
          'Marquer le salaire de ${salary.employeeName ?? 'l\'employé'} comme payé ?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.markSalaryAsPaid(salary);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
