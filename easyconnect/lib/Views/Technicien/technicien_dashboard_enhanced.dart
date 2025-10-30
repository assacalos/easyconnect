import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/technicien_dashboard_controller.dart';
import 'package:easyconnect/Views/Components/base_dashboard.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/favorites_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/dashboard_filters.dart';

class TechnicienDashboardEnhanced
    extends BaseDashboard<TechnicienDashboardController> {
  const TechnicienDashboardEnhanced({super.key});

  @override
  String get title => 'Tableau de Bord Technicien';

  @override
  Color get primaryColor => Colors.orange.shade700;

  @override
  List<Filter> get availableFilters =>
      DashboardFilters.getFiltersForRole(Roles.TECHNICIEN);

  @override
  List<FavoriteItem> get favoriteItems => [
    FavoriteItem(
      id: 'interventions',
      label: 'Interventions',
      icon: Icons.build,
      route: '/interventions',
    ),
    FavoriteItem(
      id: 'equipments',
      label: 'Équipements',
      icon: Icons.settings,
      route: '/equipments',
    ),
    FavoriteItem(
      id: 'maintenance',
      label: 'Maintenance',
      icon: Icons.engineering,
      route: '/maintenance',
    ),
    FavoriteItem(
      id: 'reports',
      label: 'Rapports',
      icon: Icons.analytics,
      route: '/reports',
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
                title: 'Interventions',
                count: controller.pendingInterventions.value,
                icon: Icons.build,
                color: Colors.orange,
                onTap: () => Get.toNamed('/interventions'),
              ),
              _buildPendingCard(
                title: 'Maintenance',
                count: controller.pendingMaintenance.value,
                icon: Icons.engineering,
                color: Colors.blue,
                onTap: () => Get.toNamed('/maintenance'),
              ),
              _buildPendingCard(
                title: 'Rapports',
                count: controller.pendingReports.value,
                icon: Icons.analytics,
                color: Colors.green,
                onTap: () => Get.toNamed('/reports'),
              ),
              _buildPendingCard(
                title: 'Équipements',
                count: controller.pendingEquipments.value,
                icon: Icons.settings,
                color: Colors.purple,
                onTap: () => Get.toNamed('/equipments'),
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
                title: 'Interventions Terminées',
                count: controller.completedInterventions.value,
                icon: Icons.build,
                color: Colors.orange,
                subtitle: 'Interventions réalisées',
              ),
              _buildValidatedCard(
                title: 'Maintenance Effectuée',
                count: controller.completedMaintenance.value,
                icon: Icons.engineering,
                color: Colors.blue,
                subtitle: 'Maintenance réalisée',
              ),
              _buildValidatedCard(
                title: 'Rapports Validés',
                count: controller.validatedReports.value,
                icon: Icons.analytics,
                color: Colors.green,
                subtitle: 'Rapports approuvés',
              ),
              _buildValidatedCard(
                title: 'Équipements Opérationnels',
                count: controller.operationalEquipments.value,
                icon: Icons.settings,
                color: Colors.purple,
                subtitle: 'Équipements fonctionnels',
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
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.teal.shade700, size: 24),
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
                title: 'Coût Interventions',
                value:
                    '${controller.interventionCost.value.toStringAsFixed(0)} FCFA',
                icon: Icons.build,
                color: Colors.orange,
                subtitle: 'Coût total des interventions',
              ),
              _buildStatisticCard(
                title: 'Coût Maintenance',
                value:
                    '${controller.maintenanceCost.value.toStringAsFixed(0)} FCFA',
                icon: Icons.engineering,
                color: Colors.blue,
                subtitle: 'Coût total de la maintenance',
              ),
              _buildStatisticCard(
                title: 'Valeur Équipements',
                value:
                    '${controller.equipmentValue.value.toStringAsFixed(0)} FCFA',
                icon: Icons.settings,
                color: Colors.purple,
                subtitle: 'Valeur totale des équipements',
              ),
              _buildStatisticCard(
                title: 'Économies Réalisées',
                value: '${controller.savings.value.toStringAsFixed(0)} FCFA',
                icon: Icons.savings,
                color: Colors.green,
                subtitle: 'Économies grâce à la maintenance',
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
        leading: const Icon(Icons.build, color: Colors.white70),
        title: const Text(
          'Interventions',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/interventions'),
      ),
      ListTile(
        leading: const Icon(Icons.engineering, color: Colors.white70),
        title: const Text(
          'Maintenance',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/maintenance'),
      ),
      ListTile(
        leading: const Icon(Icons.settings, color: Colors.white70),
        title: const Text(
          'Équipements',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/equipments'),
      ),
      ListTile(
        leading: const Icon(Icons.analytics, color: Colors.white70),
        title: const Text('Rapports', style: TextStyle(color: Colors.white70)),
        onTap: () => Get.toNamed('/reports'),
      ),
    ];
  }

  @override
  Widget? buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => Get.toNamed('/interventions/create'),
      child: const Icon(Icons.add),
    );
  }
}
