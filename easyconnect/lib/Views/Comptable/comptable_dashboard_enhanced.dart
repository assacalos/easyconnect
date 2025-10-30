import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/comptable_dashboard_controller.dart';
import 'package:easyconnect/Views/Components/base_dashboard.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/favorites_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/dashboard_filters.dart';

class ComptableDashboardEnhanced
    extends BaseDashboard<ComptableDashboardController> {
  const ComptableDashboardEnhanced({super.key});

  @override
  String get title => 'Tableau de Bord Comptable';

  @override
  Color get primaryColor => Colors.green.shade700;

  @override
  List<Filter> get availableFilters =>
      DashboardFilters.getFiltersForRole(Roles.COMPTABLE);

  @override
  List<FavoriteItem> get favoriteItems => [
    FavoriteItem(
      id: 'factures',
      label: 'Factures',
      icon: Icons.receipt,
      route: '/factures',
    ),
    FavoriteItem(
      id: 'paiements',
      label: 'Paiements',
      icon: Icons.payment,
      route: '/paiements',
    ),
    FavoriteItem(
      id: 'depenses',
      label: 'Dépenses',
      icon: Icons.money_off,
      route: '/depenses',
    ),
    FavoriteItem(
      id: 'salaires',
      label: 'Salaires',
      icon: Icons.account_balance_wallet,
      route: '/salaires',
    ),
  ];

  @override
  List<StatCard> get statsCards => controller.enhancedStats;

  @override
  Map<String, ChartConfig> get charts => {};

  @override
  Widget buildCustomContent(BuildContext context) {
    return Obx(
      () => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Première partie - Entités en attente
            _buildPendingSection(),

            const SizedBox(height: 24),

            // Deuxième partie - Entités validées
            _buildValidatedSection(),

            const SizedBox(height: 24),

            // Troisième partie - Statistiques montants
            _buildStatisticsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pending_actions, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'Entités en Attente',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: Get.width > 800 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _buildPendingCard(
                title: 'Factures',
                count: controller.pendingFactures.value,
                icon: Icons.receipt,
                color: Colors.red,
                onTap: () => Get.toNamed('/factures'),
              ),
              _buildPendingCard(
                title: 'Paiements',
                count: controller.pendingPaiements.value,
                icon: Icons.payment,
                color: Colors.teal,
                onTap: () => Get.toNamed('/paiements'),
              ),
              _buildPendingCard(
                title: 'Dépenses',
                count: controller.pendingDepenses.value,
                icon: Icons.money_off,
                color: Colors.orange,
                onTap: () => Get.toNamed('/depenses'),
              ),
              _buildPendingCard(
                title: 'Salaires',
                count: controller.pendingSalaires.value,
                icon: Icons.account_balance_wallet,
                color: Colors.purple,
                onTap: () => Get.toNamed('/salaires'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValidatedSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'Entités Validées',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: Get.width > 800 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _buildValidatedCard(
                title: 'Factures Validées',
                count: controller.validatedFactures.value,
                icon: Icons.receipt,
                color: Colors.red,
                subtitle: 'Factures traitées',
              ),
              _buildValidatedCard(
                title: 'Paiements Validés',
                count: controller.validatedPaiements.value,
                icon: Icons.payment,
                color: Colors.teal,
                subtitle: 'Paiements confirmés',
              ),
              _buildValidatedCard(
                title: 'Dépenses Validées',
                count: controller.validatedDepenses.value,
                icon: Icons.money_off,
                color: Colors.orange,
                subtitle: 'Dépenses approuvées',
              ),
              _buildValidatedCard(
                title: 'Salaires Validés',
                count: controller.validatedSalaires.value,
                icon: Icons.account_balance_wallet,
                color: Colors.purple,
                subtitle: 'Salaires payés',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'Statistiques Montants',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: Get.width > 800 ? 3 : 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _buildStatisticCard(
                title: 'Chiffre d\'Affaires',
                value:
                    '${controller.totalRevenue.value.toStringAsFixed(0)} FCFA',
                icon: Icons.euro,
                color: Colors.green,
                subtitle: 'Montant total des factures',
              ),
              _buildStatisticCard(
                title: 'Paiements Reçus',
                value:
                    '${controller.totalPayments.value.toStringAsFixed(0)} FCFA',
                icon: Icons.payment,
                color: Colors.blue,
                subtitle: 'Montant des paiements reçus',
              ),
              _buildStatisticCard(
                title: 'Dépenses Total',
                value:
                    '${controller.totalExpenses.value.toStringAsFixed(0)} FCFA',
                icon: Icons.money_off,
                color: Colors.red,
                subtitle: 'Montant total des dépenses',
              ),
              _buildStatisticCard(
                title: 'Salaires Payés',
                value:
                    '${controller.totalSalaries.value.toStringAsFixed(0)} FCFA',
                icon: Icons.account_balance_wallet,
                color: Colors.purple,
                subtitle: 'Montant des salaires payés',
              ),
              _buildStatisticCard(
                title: 'Bénéfice Net',
                value: '${controller.netProfit.value.toStringAsFixed(0)} FCFA',
                icon: Icons.trending_up,
                color: Colors.green,
                subtitle: 'Bénéfice après dépenses',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidatedCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  List<Widget> buildDrawerItems() {
    return [
      ListTile(
        leading: const Icon(Icons.dashboard, color: Colors.white70),
        title: const Text(
          'Tableau de bord',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () {},
      ),
      ListTile(
        leading: const Icon(Icons.receipt, color: Colors.white70),
        title: const Text('Factures', style: TextStyle(color: Colors.white70)),
        onTap: () => Get.toNamed('/factures'),
      ),
      ListTile(
        leading: const Icon(Icons.payment, color: Colors.white70),
        title: const Text('Paiements', style: TextStyle(color: Colors.white70)),
        onTap: () => Get.toNamed('/paiements'),
      ),
      ListTile(
        leading: const Icon(Icons.money_off, color: Colors.white70),
        title: const Text('Dépenses', style: TextStyle(color: Colors.white70)),
        onTap: () => Get.toNamed('/depenses'),
      ),
      ListTile(
        leading: const Icon(
          Icons.account_balance_wallet,
          color: Colors.white70,
        ),
        title: const Text('Salaires', style: TextStyle(color: Colors.white70)),
        onTap: () => Get.toNamed('/salaires'),
      ),
    ];
  }

  @override
  Widget? buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => Get.toNamed('/factures/create'),
      child: const Icon(Icons.add),
    );
  }
}
