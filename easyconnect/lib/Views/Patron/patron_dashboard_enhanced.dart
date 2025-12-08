import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/patron_dashboard_controller.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Views/Components/base_dashboard.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/favorites_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/dashboard_filters.dart';

class PatronDashboardEnhanced extends BaseDashboard<PatronDashboardController> {
  const PatronDashboardEnhanced({super.key});

  @override
  String get title => 'Tableau de Bord Direction';

  @override
  Color get primaryColor => Colors.blueGrey.shade900;

  @override
  List<Filter> get availableFilters =>
      DashboardFilters.getFiltersForRole(Roles.PATRON);

  @override
  List<FavoriteItem> get favoriteItems => [
    FavoriteItem(
      id: 'validation_clients',
      label: 'Validation Clients',
      icon: Icons.approval,
      route: '/clients/validation',
    ),
    FavoriteItem(
      id: 'validation_bordereaux',
      label: 'Validation Bordereaux',
      icon: Icons.assignment_turned_in,
      route: '/bordereaux/validation',
    ),
    FavoriteItem(
      id: 'validation_devis',
      label: 'Validation Devis',
      icon: Icons.assignment,
      route: '/devis/validation',
    ),
    FavoriteItem(
      id: 'validation_factures',
      label: 'Validation Factures',
      icon: Icons.receipt,
      route: '/factures/validation',
    ),
    FavoriteItem(
      id: 'validation_paiements',
      label: 'Validation Paiements',
      icon: Icons.payment,
      route: '/paiements/validation',
    ),
    FavoriteItem(
      id: 'validation_pointages',
      label: 'Validation Pointages',
      icon: Icons.camera_alt,
      route: '/attendance-validation',
    ),
    FavoriteItem(
      id: 'validation_bon_commandes_fournisseur',
      label: 'Validation Bons de Commande Fournisseur',
      icon: Icons.inventory_2,
      route: '/bons-de-commande-fournisseur/validation',
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
            // Première partie - Cases stylées pour les validations
            _buildValidationSection(),

            const SizedBox(height: 24),

            // Deuxième partie - Métriques de performance
            _buildPerformanceSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.approval, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 10),
              Text(
                'Validations en Attente',
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
            crossAxisCount:
                Get.width > 1200
                    ? 4
                    : Get.width > 800
                    ? 3
                    : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildValidationCard(
                title: 'Clients',
                count: controller.pendingClients.value,
                icon: Icons.people,
                color: Colors.blue,
                onTap: () => Get.toNamed('/clients/validation'),
              ),
              _buildValidationCard(
                title: 'Devis',
                count: controller.pendingDevis.value,
                icon: Icons.description,
                color: Colors.green,
                onTap: () => Get.toNamed('/devis/validation'),
              ),
              _buildValidationCard(
                title: 'Bordereaux',
                count: controller.pendingBordereaux.value,
                icon: Icons.assignment_turned_in,
                color: Colors.orange,
                onTap: () => Get.toNamed('/bordereaux/validation'),
              ),
              _buildValidationCard(
                title: 'Bons de Commande',
                count: controller.pendingBonCommandes.value,
                icon: Icons.shopping_cart,
                color: Colors.purple,
                onTap: () => Get.toNamed('/bon-commandes/validation'),
              ),
              _buildValidationCard(
                title: 'Bons de Commande Fournisseur',
                count: 0, // TODO: Ajouter le compteur dans le contrôleur
                icon: Icons.inventory_2,
                color: Colors.indigo,
                onTap:
                    () =>
                        Get.toNamed('/bons-de-commande-fournisseur/validation'),
              ),
              _buildValidationCard(
                title: 'Factures',
                count: controller.pendingFactures.value,
                icon: Icons.receipt,
                color: Colors.red,
                onTap: () => Get.toNamed('/factures/validation'),
              ),
              _buildValidationCard(
                title: 'Paiements',
                count: controller.pendingPaiements.value,
                icon: Icons.payment,
                color: Colors.teal,
                onTap: () => Get.toNamed('/paiements/validation'),
              ),
              _buildValidationCard(
                title: 'Dépenses',
                count: controller.pendingDepenses.value,
                icon: Icons.money_off,
                color: Colors.purple,
                onTap: () => Get.toNamed('/depenses/validation'),
              ),
              _buildValidationCard(
                title: 'Salaires',
                count: controller.pendingSalaires.value,
                icon: Icons.account_balance_wallet,
                color: Colors.amber,
                onTap: () => Get.toNamed('/salaires/validation'),
              ),
              _buildValidationCard(
                title: 'Reporting',
                count: controller.pendingReporting.value,
                icon: Icons.analytics,
                color: Colors.indigo,
                onTap: () => Get.toNamed('/reporting/validation'),
              ),
              _buildValidationCard(
                title: 'Pointages',
                count: controller.pendingPointages.value,
                icon: Icons.access_time,
                color: Colors.brown,
                onTap: () => Get.toNamed('/pointage/validation'),
              ),
              _buildValidationCard(
                title: 'Employés',
                count: 0, // TODO: Ajouter le compteur dans le contrôleur
                icon: Icons.people,
                color: Colors.cyan,
                onTap: () => Get.toNamed('/employees/validation'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValidationCard({
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.12), color.withOpacity(0.06)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
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

  Widget _buildPerformanceSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green.shade700, size: 28),
              const SizedBox(width: 12),
              Text(
                'Métriques de Performance',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount:
                Get.width > 1200
                    ? 4
                    : Get.width > 800
                    ? 2
                    : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              _buildPerformanceCard(
                title: 'Clients Validés',
                value: controller.validatedClients.value.toString(),
                icon: Icons.verified_user,
                color: Colors.green,
                subtitle: 'Clients actifs',
              ),
              _buildPerformanceCard(
                title: 'Fournisseurs',
                value: controller.totalSuppliers.value.toString(),
                icon: Icons.business,
                color: Colors.orange,
                subtitle: 'Partenaires',
              ),
              _buildPerformanceCard(
                title: 'Chiffre d\'Affaires',
                value:
                    '${controller.totalRevenue.value.toStringAsFixed(0)} FCFA',
                icon: Icons.euro,
                color: Colors.purple,
                subtitle: 'Montant total des factures',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard({
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
            colors: [color.withOpacity(0.05), color.withOpacity(0.02)],
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
                      fontSize: 24,
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
  List<Widget> buildDrawerItems(BuildContext context) {
    return [
      /*  ListTile(
        leading: const Icon(Icons.dashboard, color: Colors.white70),
        title: const Text(
          'Tableau de bord',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () {},
      ), */
      // Section Validations
      const Divider(color: Colors.white54),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'VALIDATIONS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.people, color: Colors.white70),
        title: const Text(
          'Validation Clients',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/clients/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.assignment, color: Colors.white70),
        title: const Text(
          'Validation Devis',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/devis/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.description, color: Colors.white70),
        title: const Text(
          'Validation Bordereaux',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/bordereaux/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.receipt, color: Colors.white70),
        title: const Text(
          'Validation Factures',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/factures/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.payment, color: Colors.white70),
        title: const Text(
          'Validation Paiements',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/paiements/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.shopping_cart, color: Colors.white70),
        title: const Text(
          'Validation Bons de Commande',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/bon-commandes/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.money_off, color: Colors.white70),
        title: const Text(
          'Validation Dépenses',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/depenses/validation'),
      ),
      ListTile(
        leading: const Icon(
          Icons.account_balance_wallet,
          color: Colors.white70,
        ),
        title: const Text(
          'Validation Salaires',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/salaires/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.analytics, color: Colors.white70),
        title: const Text(
          'Validation Reporting',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/reporting/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.build, color: Colors.white70),
        title: const Text(
          'Validation Interventions',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/interventions/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.account_balance, color: Colors.white70),
        title: const Text(
          'Validation Taxes',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/taxes/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.business, color: Colors.white70),
        title: const Text(
          'Validation Fournisseurs',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/suppliers/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.inventory, color: Colors.white70),
        title: const Text(
          'Validation Stock',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/stock/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.access_time, color: Colors.white70),
        title: const Text(
          'Validation Pointage',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/pointage/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.work, color: Colors.white70),
        title: const Text(
          'Validation Recrutements',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/recrutement/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.description, color: Colors.white70),
        title: const Text(
          'Validation Contrats',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/contrats/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.event_busy, color: Colors.white70),
        title: const Text(
          'Validation Congés',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/conges/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.people, color: Colors.white70),
        title: const Text(
          'Validation Employés',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/employees/validation'),
      ),
      // Section Navigation générale
      const Divider(color: Colors.white54),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'NAVIGATION',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.list, color: Colors.white70),
        title: const Text(
          'Liste des Clients',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () => Get.toNamed('/clients'),
      ),
      ListTile(
        leading: const Icon(Icons.euro, color: Colors.white70),
        title: const Text('Finances', style: TextStyle(color: Colors.white70)),
        onTap: () => Get.toNamed('/patron/finances'),
      ),
      ListTile(
        leading: const Icon(Icons.analytics, color: Colors.white70),
        title: const Text('Rapports', style: TextStyle(color: Colors.white70)),
        onTap: () => Get.toNamed('/patron/reports'),
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
