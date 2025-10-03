import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/salary_controller.dart';
import 'package:easyconnect/Models/salary_model.dart';
import 'package:easyconnect/Views/Comptable/salary_form.dart';
import 'package:easyconnect/Views/Comptable/salary_detail.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';

class SalaryList extends StatelessWidget {
  const SalaryList({super.key});

  @override
  Widget build(BuildContext context) {
    final SalaryController controller = Get.put(SalaryController());
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestion des Salaires'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Tous'),
              Tab(text: 'En attente'),
              Tab(text: 'Approuvés'),
              Tab(text: 'Payés'),
              Tab(text: 'Rejetés'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.loadSalaries(),
            ),
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () {
                print('🐛 DEBUG SALARIES: État du contrôleur');
                print(
                  '📊 allSalaries.length: ${controller.allSalaries.length}',
                );
                print('📊 salaries.length: ${controller.salaries.length}');
                print('📊 selectedStatus: ${controller.selectedStatus.value}');
                print('📅 selectedMonth: ${controller.selectedMonth.value}');
                print('🔍 searchQuery: "${controller.searchQuery.value}"');
                print('📊 isLoading: ${controller.isLoading.value}');
                controller.loadSalaries();
              },
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(controller),
            ),
          ],
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildSalaryList(controller, 'all', formatCurrency),
                _buildSalaryList(controller, 'pending', formatCurrency),
                _buildSalaryList(controller, 'approved', formatCurrency),
                _buildSalaryList(controller, 'paid', formatCurrency),
                _buildSalaryList(controller, 'rejected', formatCurrency),
              ],
            ),
            // Bouton d'ajout uniforme en bas à droite
            UniformAddButton(
              onPressed: () => Get.to(() => const SalaryForm()),
              label: 'Nouveau Salaire',
              icon: Icons.euro,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryList(
    SalaryController controller,
    String status,
    NumberFormat formatCurrency,
  ) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final salaryList =
          status == 'all'
              ? controller.salaries
              : controller.salaries.where((s) => s.status == status).toList();

      if (salaryList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == 'pending'
                    ? Icons.schedule
                    : status == 'approved'
                    ? Icons.check_circle
                    : status == 'paid'
                    ? Icons.payment
                    : Icons.cancel,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                status == 'all'
                    ? 'Aucun salaire trouvé'
                    : status == 'pending'
                    ? 'Aucun salaire en attente'
                    : status == 'approved'
                    ? 'Aucun salaire approuvé'
                    : status == 'paid'
                    ? 'Aucun salaire payé'
                    : 'Aucun salaire rejeté',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: salaryList.length,
        itemBuilder: (context, index) {
          final salary = salaryList[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: salary.statusColor.withOpacity(0.1),
                    child: Icon(salary.statusIcon, color: salary.statusColor),
                  ),
                  title: Text(
                    salary.employeeName ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(salary.employeeEmail ?? ''),
                      const SizedBox(height: 4),
                      Text(
                        '${salary.periodText} - ${formatCurrency.format(salary.netSalary)}',
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: salary.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: salary.statusColor.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      salary.statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: salary.statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  onTap: () => Get.to(() => SalaryDetail(salary: salary)),
                ),
                const Divider(height: 1),
                ButtonBar(
                  alignment: MainAxisAlignment.end,
                  children: [
                    if (status == 'pending' &&
                        controller.canManageSalaries) ...[
                      TextButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifier'),
                        onPressed:
                            () => Get.to(() => SalaryForm(salary: salary)),
                      ),
                    ],
                    if (status == 'pending' &&
                        controller.canApproveSalaries) ...[
                      TextButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Approuver'),
                        onPressed: () => _showApproveDialog(controller, salary),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Rejeter'),
                        onPressed: () => _showRejectDialog(controller, salary),
                      ),
                    ],
                    if (status == 'approved' &&
                        controller.canApproveSalaries) ...[
                      TextButton.icon(
                        icon: const Icon(Icons.payment),
                        label: const Text('Marquer payé'),
                        onPressed:
                            () => _showMarkPaidDialog(controller, salary),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed:
                          () => Get.to(() => SalaryDetail(salary: salary)),
                      tooltip: 'Voir détails',
                    ),
                    if (status == 'pending' && controller.canManageSalaries)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _showDeleteDialog(controller, salary),
                        tooltip: 'Supprimer',
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }

  void _showFilterDialog(SalaryController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Filtrer les salaires'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: controller.selectedStatus.value,
              decoration: const InputDecoration(labelText: 'Statut'),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('Tous')),
                const DropdownMenuItem(
                  value: 'pending',
                  child: Text('En attente'),
                ),
                const DropdownMenuItem(
                  value: 'approved',
                  child: Text('Approuvés'),
                ),
                const DropdownMenuItem(value: 'paid', child: Text('Payés')),
                const DropdownMenuItem(
                  value: 'rejected',
                  child: Text('Rejetés'),
                ),
              ],
              onChanged: (value) => controller.filterByStatus(value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: controller.selectedMonth.value,
              decoration: const InputDecoration(labelText: 'Mois'),
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('Tous les mois'),
                ),
                ...controller.months.map(
                  (month) => DropdownMenuItem(
                    value: month['value'],
                    child: Text(month['label']),
                  ),
                ),
              ],
              onChanged: (value) => controller.filterByMonth(value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: controller.selectedYear.value,
              decoration: const InputDecoration(labelText: 'Année'),
              items:
                  controller.years
                      .map(
                        (year) => DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        ),
                      )
                      .toList(),
              onChanged: (value) => controller.filterByYear(value!),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Fermer')),
        ],
      ),
    );
  }

  void _showApproveDialog(SalaryController controller, Salary salary) {
    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Approuver le salaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Approuver le salaire de ${salary.employeeName} ?'),
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

  void _showRejectDialog(SalaryController controller, Salary salary) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter le salaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rejeter le salaire de ${salary.employeeName} ?'),
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

  void _showMarkPaidDialog(SalaryController controller, Salary salary) {
    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Marquer comme payé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Marquer le salaire de ${salary.employeeName} comme payé ?'),
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

  void _showDeleteDialog(SalaryController controller, Salary salary) {
    Get.dialog(
      AlertDialog(
        title: const Text('Supprimer le salaire'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le salaire de ${salary.employeeName} ?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.deleteSalary(salary);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
