import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/patron_reports_controller.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class PatronReportsPage extends StatelessWidget {
  const PatronReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PatronReportsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports Financiers'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadReports(),
          ),
        ],
      ),
      body: Obx(
        () =>
            controller.isLoading.value
                ? const SkeletonPage(listItemCount: 8)
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sélecteur de période
                      _buildPeriodSelector(controller),

                      const SizedBox(height: 24),

                      // Résumé financier
                      _buildFinancialSummary(controller),

                      const SizedBox(height: 24),

                      // Statistiques détaillées
                      _buildDetailedStats(controller),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildPeriodSelector(PatronReportsController controller) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blueGrey.shade900),
                const SizedBox(width: 8),
                const Text(
                  'Période',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: Get.context!,
                        initialDate: controller.startDate.value,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        await controller.updateDateRange(
                          date,
                          controller.endDate.value,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date de début',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'dd/MM/yyyy',
                            ).format(controller.startDate.value),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: Get.context!,
                        initialDate: controller.endDate.value,
                        firstDate: controller.startDate.value,
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        await controller.updateDateRange(
                          controller.startDate.value,
                          date,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date de fin',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'dd/MM/yyyy',
                            ).format(controller.endDate.value),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: Get.context!,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: DateTimeRange(
                      start: controller.startDate.value,
                      end: controller.endDate.value,
                    ),
                  );
                  if (range != null) {
                    await controller.updateDateRange(range.start, range.end);
                  }
                },
                icon: const Icon(Icons.date_range),
                label: const Text('Sélectionner une période'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(PatronReportsController controller) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, color: Colors.blueGrey.shade900),
                const SizedBox(width: 8),
                const Text(
                  'Résumé Financier',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Revenus',
                    value:
                        controller.facturesTotal.value +
                        controller.paiementsTotal.value,
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Dépenses',
                    value:
                        controller.depensesTotal.value +
                        controller.salairesTotal.value,
                    icon: Icons.trending_down,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    controller.beneficeNet.value >= 0
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      controller.beneficeNet.value >= 0
                          ? Colors.green
                          : Colors.red,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        controller.beneficeNet.value >= 0
                            ? Icons.check_circle
                            : Icons.warning,
                        color:
                            controller.beneficeNet.value >= 0
                                ? Colors.green
                                : Colors.red,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bénéfice Net',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${controller.beneficeNet.value.toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color:
                                  controller.beneficeNet.value >= 0
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(0)} FCFA',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(PatronReportsController controller) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blueGrey.shade900),
                const SizedBox(width: 8),
                const Text(
                  'Statistiques Détaillées',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              title: 'Devis',
              count: controller.devisCount.value,
              total: controller.devisTotal.value,
              icon: Icons.description,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Bordereaux',
              count: controller.bordereauxCount.value,
              total: controller.bordereauxTotal.value,
              icon: Icons.assignment_turned_in,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Factures',
              count: controller.facturesCount.value,
              total: controller.facturesTotal.value,
              icon: Icons.receipt,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Paiements',
              count: controller.paiementsCount.value,
              total: controller.paiementsTotal.value,
              icon: Icons.payment,
              color: Colors.teal,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Dépenses',
              count: controller.depensesCount.value,
              total: controller.depensesTotal.value,
              icon: Icons.money_off,
              color: Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Salaires',
              count: controller.salairesCount.value,
              total: controller.salairesTotal.value,
              icon: Icons.account_balance_wallet,
              color: Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required double total,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Nombre: ',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: ${total.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
