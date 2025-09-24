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
      id: 'validation_bon_commandes',
      label: 'Validation Bons',
      icon: Icons.shopping_cart,
      route: '/bon-commandes/validation',
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
      ListTile(
        leading: const Icon(Icons.approval),
        title: const Text('Validation des Clients'),
        onTap: () => Get.toNamed('/clients/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.assignment_turned_in),
        title: const Text('Validation des Bordereaux'),
        onTap: () => Get.toNamed('/bordereaux/validation'),
      ),
      ListTile(
        leading: const Icon(Icons.shopping_cart),
        title: const Text('Validation des Bons'),
        onTap: () => Get.toNamed('/bon-commandes/validation'),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: 'validation_clients',
          onPressed: () => Get.toNamed('/clients/validation'),
          icon: const Icon(Icons.approval),
          label: const Text('Clients en attente'),
        ),
        const SizedBox(width: 16),
        FloatingActionButton.extended(
          heroTag: 'validation_bordereaux',
          onPressed: () => Get.toNamed('/bordereaux/validation'),
          icon: const Icon(Icons.assignment_turned_in),
          label: const Text('Bordereaux en attente'),
        ),
        const SizedBox(width: 16),
        FloatingActionButton.extended(
          heroTag: 'validation_bon_commandes',
          onPressed: () => Get.toNamed('/bon-commandes/validation'),
          icon: const Icon(Icons.shopping_cart),
          label: const Text('Bons en attente'),
        ),
      ],
    );
  }
}
