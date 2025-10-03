import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:flutter/material.dart';
import 'package:easyconnect/Views/Components/base_dashboard.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/Views/Components/favorites_bar.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Controllers/patron_dashboard_controller.dart';
import 'package:easyconnect/utils/dashboard_filters.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/bindings/app_bindings.dart';
import 'package:get/get.dart';

class PatronDashboard extends BaseDashboard<PatronDashboardController> {
  const PatronDashboard({super.key});

  @override
  String get title => 'Espace Direction';

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
      id: 'validation_bon_commandes',
      label: 'Validation Bons',
      icon: Icons.shopping_cart,
      route: '/bon-commandes/validation',
    ),
    FavoriteItem(
      id: 'validation_pointages',
      label: 'Validation Pointages',
      icon: Icons.camera_alt,
      route: '/attendance-validation',
    ),
    FavoriteItem(
      id: 'employees',
      label: 'Employés',
      icon: Icons.people,
      route: '/rh',
    ),
    FavoriteItem(
      id: 'finances',
      label: "Finances",
      icon: Icons.euro,
      route: '/comptable',
    ),
  ];

  @override
  List<StatCard> get statsCards => controller.stats;

  @override
  Map<String, ChartConfig> get charts => {
    'revenue': ChartConfig(
      title: "Chiffre d'affaires",
      type: ChartType.line,
      color: Colors.green,
      subtitle: "6 derniers mois",
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
    'employees': ChartConfig(
      title: "Répartition des employés",
      type: ChartType.pie,
      color: Colors.blue,
      subtitle: "Par département",
      requiredPermission: Permissions.MANAGE_EMPLOYEES,
    ),
    'tickets': ChartConfig(
      title: "État des tickets",
      type: ChartType.bar,
      color: Colors.orange,
      subtitle: "Par statut",
      requiredPermission: Permissions.MANAGE_TICKETS,
    ),
    'leaves': ChartConfig(
      title: "Demandes de congés",
      type: ChartType.line,
      color: Colors.purple,
      subtitle: "Cette semaine",
      requiredPermission: Permissions.MANAGE_LEAVES,
    ),
  };

  @override
  Widget buildCustomContent(BuildContext context) {
    return Container(); // Contenu spécifique au patron si nécessaire
  }

  @override
  List<Widget> buildDrawerItems() {
    return [
      ListTile(
        leading: const Icon(Icons.dashboard),
        title: const Text('Tableau de bord'),
        onTap: () {},
      ),
      // Section Validations
      const Divider(),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'VALIDATIONS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.people, color: Colors.blue),
        title: const Text('Validation Clients'),
        onTap: () => Get.toNamed('/clients/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.assignment, color: Colors.purple),
        title: const Text('Validation Devis'),
        onTap: () => Get.toNamed('/devis/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.description, color: Colors.green),
        title: const Text('Validation Bordereaux'),
        onTap: () => Get.toNamed('/bordereaux/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.shopping_cart, color: Colors.orange),
        title: const Text('Validation Bons de Commande'),
        onTap: () => Get.toNamed('/bon-commandes/validation'),
      ),

      ListTile(
        leading: const Icon(Icons.receipt, color: Colors.red),
        title: const Text('Validation Factures'),
        onTap: () => Get.toNamed('/factures/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.payment, color: Colors.teal),
        title: const Text('Validation Paiements'),
        onTap: () => Get.toNamed('/paiements/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.inventory, color: Colors.deepPurple),
        title: const Text('Validation Stock'),
        onTap: () => Get.toNamed('/stock/validation'),
      ),

      ListTile(
        leading: const Icon(Icons.account_balance_wallet, color: Colors.amber),
        title: const Text('Validation Salaires'),
        onTap: () => Get.toNamed('/salaires/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.account_balance, color: Colors.deepOrange),
        title: const Text('Validation Taxes'),
        onTap: () => Get.toNamed('/taxes/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.person_add, color: Colors.cyan),
        title: const Text('Validation Recrutement'),
        onTap: () => Get.toNamed('/recrutement/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.build, color: Colors.indigo),
        title: const Text('Validation Interventions'),
        onTap: () => Get.toNamed('/interventions/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.access_time, color: Colors.brown),
        title: const Text('Validation Pointage'),
        onTap: () => Get.toNamed('/pointage/validation'),
      ),

      ListTile(
        leading: const Icon(Icons.analytics, color: Colors.pink),
        title: const Text('Validation Reporting'),
        onTap: () => Get.toNamed('/reporting/validation'),
      ),
      // Section Navigation générale
      const Divider(),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'NAVIGATION',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.list),
        title: const Text('Liste des Clients'),
        onTap: () => Get.toNamed('/clients'),
      ),
      ListTile(
        leading: const Icon(Icons.people),
        title: const Text('Employés'),
        onTap: () => Get.toNamed('/rh'),
      ),
      ListTile(
        leading: const Icon(Icons.euro),
        title: const Text('Finances'),
        onTap: () => Get.toNamed('/comptable'),
      ),
      ListTile(
        leading: const Icon(Icons.analytics),
        title: const Text('Rapports'),
        onTap: () {},
      ),
      ListTile(
        leading: const Icon(Icons.settings),
        title: const Text('Paramètres'),
        onTap: () {},
      ),
    ];
  }

  @override
  Widget? buildFloatingActionButton() {
    // Les boutons de validation ont été déplacés dans la sidebar
    return null;
  }
}
