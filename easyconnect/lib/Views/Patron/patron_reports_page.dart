import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/patron_reports_notifier.dart';
import 'package:easyconnect/providers/patron_reports_state.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/Views/Components/export_dialog.dart';
import 'package:easyconnect/utils/export_data_builder.dart';

class PatronReportsPage extends ConsumerStatefulWidget {
  const PatronReportsPage({super.key});

  @override
  ConsumerState<PatronReportsPage> createState() => _PatronReportsPageState();
}

class _PatronReportsPageState extends ConsumerState<PatronReportsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(patronReportsProvider.notifier).loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patronReportsProvider);
    final notifier = ref.read(patronReportsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports Financiers'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exporter',
            onPressed: () {
              final s = state;
              showExportDialog(
                context: context,
                title: 'Exporter les rapports',
                fileName: 'rapports_patron_${DateTime.now().millisecondsSinceEpoch}',
                headers: ExportDataBuilder.patronReportHeaders,
                rows: ExportDataBuilder.patronReportToRows(
                  startDate: s.startDate,
                  endDate: s.endDate,
                  devisCount: s.devisCount,
                  devisTotal: s.devisTotal,
                  bordereauxCount: s.bordereauxCount,
                  bordereauxTotal: s.bordereauxTotal,
                  facturesCount: s.facturesCount,
                  facturesTotal: s.facturesTotal,
                  paiementsCount: s.paiementsCount,
                  paiementsTotal: s.paiementsTotal,
                  depensesCount: s.depensesCount,
                  depensesTotal: s.depensesTotal,
                  salairesCount: s.salairesCount,
                  salairesTotal: s.salairesTotal,
                  beneficeNet: s.beneficeNet,
                  encaissements: s.encaissements,
                  decaissements: s.decaissements,
                  soldeTresorerie: s.soldeTresorerie,
                  receivables0_30: s.receivables0_30,
                  receivables31_60: s.receivables31_60,
                  receivables61_90: s.receivables61_90,
                  receivablesOver90: s.receivablesOver90,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadReports(),
          ),
        ],
      ),
      body: state.isLoading
          ? const SkeletonPage(listItemCount: 8)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(context, state, notifier),
                  const SizedBox(height: 24),
                  _buildFinancialSummary(state),
                  const SizedBox(height: 24),
                  _buildTresorerieSection(state),
                  const SizedBox(height: 24),
                  _buildAgeCreancesSection(state),
                  const SizedBox(height: 24),
                  _buildDetailedStats(state),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector(
    BuildContext context,
    PatronReportsState state,
    PatronReportsNotifier notifier,
  ) {
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
                        context: context,
                        initialDate: state.startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        await notifier.updateDateRange(date, state.endDate);
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
                            DateFormat('dd/MM/yyyy').format(state.startDate),
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
                        context: context,
                        initialDate: state.endDate,
                        firstDate: state.startDate,
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        await notifier.updateDateRange(state.startDate, date);
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
                            DateFormat('dd/MM/yyyy').format(state.endDate),
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
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: DateTimeRange(
                      start: state.startDate,
                      end: state.endDate,
                    ),
                  );
                  if (range != null) {
                    await notifier.updateDateRange(range.start, range.end);
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

  Widget _buildFinancialSummary(PatronReportsState state) {
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
                    value: state.facturesTotal + state.paiementsTotal,
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Dépenses',
                    value: state.depensesTotal + state.salairesTotal,
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
                color: state.beneficeNet >= 0
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: state.beneficeNet >= 0 ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        state.beneficeNet >= 0
                            ? Icons.check_circle
                            : Icons.warning,
                        color:
                            state.beneficeNet >= 0 ? Colors.green : Colors.red,
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
                            '${state.beneficeNet.toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: state.beneficeNet >= 0
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

  Widget _buildTresorerieSection(PatronReportsState state) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, color: Colors.blueGrey.shade900),
                const SizedBox(width: 8),
                const Text(
                  'Trésorerie',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Encaissements et décaissements sur la période',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Encaissements',
                    value: state.encaissements,
                    icon: Icons.arrow_downward,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Décaissements',
                    value: state.decaissements,
                    icon: Icons.arrow_upward,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: state.soldeTresorerie >= 0
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: state.soldeTresorerie >= 0 ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Solde trésorerie',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  Text(
                    '${state.soldeTresorerie.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: state.soldeTresorerie >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeCreancesSection(PatronReportsState state) {
    final totalCreances = state.receivables0_30 +
        state.receivables31_60 +
        state.receivables61_90 +
        state.receivablesOver90;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.blueGrey.shade900),
                const SizedBox(width: 8),
                const Text(
                  'Âge des créances',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Factures non soldées par ancienneté (jours depuis l\'échéance)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _buildCreanceRow('0 – 30 jours', state.receivables0_30, Colors.green),
            const SizedBox(height: 8),
            _buildCreanceRow('31 – 60 jours', state.receivables31_60, Colors.orange),
            const SizedBox(height: 8),
            _buildCreanceRow('61 – 90 jours', state.receivables61_90, Colors.deepOrange),
            const SizedBox(height: 8),
            _buildCreanceRow('> 90 jours', state.receivablesOver90, Colors.red),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total créances',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${totalCreances.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreanceRow(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
          Text(
            '${amount.toStringAsFixed(0)} FCFA',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color),
          ),
        ],
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

  Widget _buildDetailedStats(PatronReportsState state) {
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
              count: state.devisCount,
              total: state.devisTotal,
              icon: Icons.description,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Bordereaux',
              count: state.bordereauxCount,
              total: state.bordereauxTotal,
              icon: Icons.assignment_turned_in,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Factures',
              count: state.facturesCount,
              total: state.facturesTotal,
              icon: Icons.receipt,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Paiements',
              count: state.paiementsCount,
              total: state.paiementsTotal,
              icon: Icons.payment,
              color: Colors.teal,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Dépenses',
              count: state.depensesCount,
              total: state.depensesTotal,
              icon: Icons.money_off,
              color: Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Salaires',
              count: state.salairesCount,
              total: state.salairesTotal,
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
