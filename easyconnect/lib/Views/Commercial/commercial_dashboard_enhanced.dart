import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/commercial_dashboard_controller.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Views/Components/base_dashboard.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/favorites_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/dashboard_filters.dart';

class CommercialDashboardEnhanced
    extends BaseDashboard<CommercialDashboardController> {
  const CommercialDashboardEnhanced({super.key});

  @override
  String get title => 'Tableau de Bord Commercial';

  @override
  Color get primaryColor => Colors.blue.shade700;

  @override
  List<Filter> get availableFilters =>
      DashboardFilters.getFiltersForRole(Roles.COMMERCIAL);

  @override
  List<FavoriteItem> get favoriteItems => [
    FavoriteItem(
      id: 'clients',
      label: 'Clients',
      icon: Icons.people,
      route: '/clients',
    ),
    FavoriteItem(
      id: 'devis',
      label: 'Devis',
      icon: Icons.description,
      route: '/devis',
    ),
    FavoriteItem(
      id: 'bordereaux',
      label: 'Bordereaux',
      icon: Icons.assignment_turned_in,
      route: '/bordereaux',
    ),
    FavoriteItem(
      id: 'bon_commandes',
      label: 'Bons de Commande',
      icon: Icons.shopping_cart,
      route: '/bon-commandes',
    ),
    FavoriteItem(
      id: 'bon_commandes_fournisseur',
      label: 'Bons de Commande Fournisseur',
      icon: Icons.inventory_2,
      route: '/bons-de-commande-fournisseur',
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pending_actions,
                color: Colors.orange.shade700,
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
                title: 'Clients',
                count: controller.pendingClients.value,
                icon: Icons.people,
                color: Colors.blue,
                onTap: () => Get.toNamed('/clients'),
              ),
              _buildPendingCard(
                title: 'Devis',
                count: controller.pendingDevis.value,
                icon: Icons.description,
                color: Colors.green,
                onTap: () => Get.toNamed('/devis'),
              ),
              _buildPendingCard(
                title: 'Bordereaux',
                count: controller.pendingBordereaux.value,
                icon: Icons.assignment_turned_in,
                color: Colors.orange,
                onTap: () => Get.toNamed('/bordereaux'),
              ),
              _buildPendingCard(
                title: 'Bons de Commande',
                count: controller.pendingBonCommandes.value,
                icon: Icons.shopping_cart,
                color: Colors.purple,
                onTap: () => Get.toNamed('/bon-commandes'),
              ),
              _buildPendingCard(
                title: 'Bons de Commande Fournisseur',
                count: controller.pendingBonCommandesFournisseur.value,
                icon: Icons.inventory_2,
                color: Colors.indigo,
                onTap: () => Get.toNamed('/bons-de-commande-fournisseur'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValidatedSection() {
    return Container(
      padding: const EdgeInsets.all(12),
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
                title: 'Clients Validés',
                count: controller.validatedClients.value,
                icon: Icons.verified_user,
                color: Colors.blue,
                subtitle: 'Clients actifs',
                onTap: () => Get.toNamed('/clients?tab=1'),
              ),
              _buildValidatedCard(
                title: 'Devis Validés',
                count: controller.validatedDevis.value,
                icon: Icons.assignment,
                color: Colors.green,
                subtitle: 'Devis approuvés',
                onTap: () => Get.toNamed('/devis?tab=2'),
              ),
              _buildValidatedCard(
                title: 'Bordereaux Validés',
                count: controller.validatedBordereaux.value,
                icon: Icons.assignment_turned_in,
                color: Colors.orange,
                subtitle: 'Bordereaux traités',
                onTap: () => Get.toNamed('/bordereaux?tab=2'),
              ),
              _buildValidatedCard(
                title: 'Bons Validés',
                count: controller.validatedBonCommandes.value,
                icon: Icons.shopping_cart,
                color: Colors.purple,
                subtitle: 'Commandes confirmées',
                onTap: () => Get.toNamed('/bon-commandes?tab=2'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.purple.shade700, size: 24),
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
                subtitle: 'Montant total des ventes',
              ),
              _buildStatisticCard(
                title: 'Devis en Cours',
                value:
                    '${controller.pendingDevisAmount.value.toStringAsFixed(0)} FCFA',
                icon: Icons.description,
                color: Colors.orange,
                subtitle: 'Montant des devis en attente',
              ),
              _buildStatisticCard(
                title: 'Bordereaux Payés',
                value:
                    '${controller.paidBordereauxAmount.value.toStringAsFixed(0)} FCFA',
                icon: Icons.payment,
                color: Colors.blue,
                subtitle: 'Montant des bordereaux payés',
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
  List<Widget> buildDrawerItems(BuildContext context) {
    return [
      ListTile(
        leading: const Icon(Icons.people, color: Colors.white70),
        title: const Text('Clients', style: TextStyle(color: Colors.white70)),
        onTap: () {
          Navigator.pop(context);
          Get.toNamed('/clients');
        },
      ),
      ListTile(
        leading: const Icon(Icons.description, color: Colors.white70),
        title: const Text('Devis', style: TextStyle(color: Colors.white70)),
        onTap: () {
          Navigator.pop(context);
          Get.toNamed('/devis');
        },
      ),
      ListTile(
        leading: const Icon(Icons.assignment_turned_in, color: Colors.white70),
        title: const Text(
          'Bordereaux',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () {
          Navigator.pop(context);
          Get.toNamed('/bordereaux');
        },
      ),
      ListTile(
        leading: const Icon(Icons.shopping_cart, color: Colors.white70),
        title: const Text(
          'Bons de Commande',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () {
          Navigator.pop(context);
          Get.toNamed('/bon-commandes');
        },
      ),
      // Bouton Paramètres (visible pour tous, mais accès restreint aux admins)
      Obx(() {
        final userRole = Get.find<AuthController>().userAuth.value?.role;
        if (userRole == 1) {
          return ListTile(
            leading: const Icon(Icons.settings, color: Colors.white70),
            title: const Text(
              'Paramètres',
              style: TextStyle(color: Colors.white70),
            ),
            onTap: () {
              Navigator.pop(context);
              Get.toNamed('/admin/settings');
            },
          );
        }
        return const SizedBox.shrink();
      }),
    ];
  }

  @override
  Widget? buildFloatingActionButton() {
    return null;
  }
}
