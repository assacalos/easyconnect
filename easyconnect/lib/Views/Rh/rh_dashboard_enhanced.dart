import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/rh_dashboard_controller.dart';
import 'package:easyconnect/Views/Components/base_dashboard.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/favorites_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/dashboard_filters.dart';

class RhDashboardEnhanced extends BaseDashboard<RhDashboardController> {
  const RhDashboardEnhanced({super.key});

  @override
  String get title => 'Tableau de Bord RH';

  @override
  Color get primaryColor => Colors.purple.shade700;

  @override
  List<Filter> get availableFilters =>
      DashboardFilters.getFiltersForRole(Roles.RH);

  @override
  List<FavoriteItem> get favoriteItems => [
    FavoriteItem(
      id: 'employees',
      label: 'Employés',
      icon: Icons.people,
      route: '/employees',
    ),
    FavoriteItem(
      id: 'leaves',
      label: 'Congés',
      icon: Icons.beach_access,
      route: '/leaves',
    ),
    FavoriteItem(
      id: 'recruitment',
      label: 'Recrutement',
      icon: Icons.person_add,
      route: '/recruitment',
    ),
    FavoriteItem(
      id: 'salaries',
      label: 'Salaires',
      icon: Icons.account_balance_wallet,
      route: '/salaries',
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
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pending_actions,
                color: Colors.amber.shade700,
                size: 24,
              ),
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
                title: 'Demandes Congés',
                count: controller.pendingLeaves.value,
                icon: Icons.beach_access,
                color: Colors.blue,
                onTap: () => Get.toNamed('/leaves'),
              ),
              _buildPendingCard(
                title: 'Candidatures',
                count: controller.pendingRecruitments.value,
                icon: Icons.person_add,
                color: Colors.green,
                onTap: () => Get.toNamed('/recruitment'),
              ),
              _buildPendingCard(
                title: 'Pointages',
                count: controller.pendingAttendance.value,
                icon: Icons.access_time,
                color: Colors.orange,
                onTap: () => Get.toNamed('/attendance'),
              ),
              _buildPendingCard(
                title: 'Salaires',
                count: controller.pendingSalaries.value,
                icon: Icons.account_balance_wallet,
                color: Colors.purple,
                onTap: () => Get.toNamed('/salaries'),
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
                title: 'Employés Actifs',
                count: controller.activeEmployees.value,
                icon: Icons.people,
                color: Colors.blue,
                subtitle: 'Effectif total',
              ),
              _buildValidatedCard(
                title: 'Congés Approuvés',
                count: controller.approvedLeaves.value,
                icon: Icons.beach_access,
                color: Colors.green,
                subtitle: 'Congés validés',
              ),
              _buildValidatedCard(
                title: 'Recrutements',
                count: controller.completedRecruitments.value,
                icon: Icons.person_add,
                color: Colors.orange,
                subtitle: 'Embauches effectuées',
              ),
              _buildValidatedCard(
                title: 'Salaires Payés',
                count: controller.paidSalaries.value,
                icon: Icons.account_balance_wallet,
                color: Colors.purple,
                subtitle: 'Salaires traités',
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
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.indigo.shade700, size: 24),
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
                title: 'Masse Salariale',
                value:
                    '${controller.totalSalaryMass.value.toStringAsFixed(0)} FCFA',
                icon: Icons.account_balance_wallet,
                color: Colors.purple,
                subtitle: 'Montant total des salaires',
              ),
              _buildStatisticCard(
                title: 'Primes Versées',
                value:
                    '${controller.totalBonuses.value.toStringAsFixed(0)} FCFA',
                icon: Icons.card_giftcard,
                color: Colors.green,
                subtitle: 'Montant des primes distribuées',
              ),
              _buildStatisticCard(
                title: 'Coût Recrutement',
                value:
                    '${controller.recruitmentCost.value.toStringAsFixed(0)} FCFA',
                icon: Icons.person_add,
                color: Colors.orange,
                subtitle: 'Coût total du recrutement',
              ),
              _buildStatisticCard(
                title: 'Coût Formation',
                value:
                    '${controller.trainingCost.value.toStringAsFixed(0)} FCFA',
                icon: Icons.school,
                color: Colors.blue,
                subtitle: 'Investissement formation',
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
                  color: Colors.amber,
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
        leading: const Icon(Icons.people, color: Colors.white70),
        title: const Text('Employés', style: TextStyle(color: Colors.white70)),
        onTap: () => Get.toNamed('/employees'),
      ),
      ListTile(
        leading: const Icon(Icons.beach_access, color: Colors.white70),
        title: const Text('Congés', style: TextStyle(color: Colors.white70)),
        onTap: () => Get.toNamed('/leaves'),
      ),
      ListTile(
        leading: const Icon(Icons.person_add, color: Colors.white70),
        title: const Text(
          'Recrutement',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/recruitment'),
      ),
      ListTile(
        leading: const Icon(
          Icons.account_balance_wallet,
          color: Colors.white70,
        ),
        title: const Text('Salaires', style: TextStyle(color: Colors.white70)),
        onTap: () => Get.toNamed('/salaries'),
      ),
    ];
  }

  @override
  Widget? buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => Get.toNamed('/employees/create'),
      child: const Icon(Icons.add),
    );
  }
}
