import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:flutter/material.dart';
import 'package:easyconnect/Views/Components/base_dashboard.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/Views/Components/favorites_bar.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Controllers/technicien_dashboard_controller.dart';
import 'package:easyconnect/utils/dashboard_filters.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:get/get.dart';

class TechnicienDashboard extends BaseDashboard<TechnicienDashboardController> {
  const TechnicienDashboard({super.key});

  @override
  String get title => 'Espace Technicien';

  @override
  Color get primaryColor => Colors.indigo;

  @override
  List<Filter> get availableFilters =>
      DashboardFilters.getFiltersForRole(Roles.TECHNICIEN);

  @override
  List<FavoriteItem> get favoriteItems => [
    FavoriteItem(
      id: 'new_ticket',
      label: 'Nouveau ticket',
      icon: Icons.add_task,
      onTap: () => controller.createNewTicket(),
    ),
    FavoriteItem(
      id: 'maintenance',
      label: 'Maintenance',
      icon: Icons.build,
      onTap: () => controller.scheduleMaintenance(),
    ),
    FavoriteItem(
      id: 'inventory',
      label: 'Inventaire',
      icon: Icons.inventory,
      onTap: () => controller.checkInventory(),
    ),
    FavoriteItem(
      id: 'equipment',
      label: 'Équipements',
      icon: Icons.devices,
      onTap: () => controller.manageEquipment(),
    ),
  ];

  @override
  List<StatCard> get statsCards => [
    StatCard(
      title: "Tickets ouverts",
      value: "12",
      icon: Icons.report_problem,
      color: Colors.orange,
      requiredPermission: Permissions.MANAGE_TICKETS,
    ),
    StatCard(
      title: "En cours",
      value: "5",
      icon: Icons.engineering,
      color: Colors.blue,
      requiredPermission: Permissions.MANAGE_TICKETS,
    ),
    StatCard(
      title: "Équipements",
      value: "156",
      icon: Icons.devices,
      color: Colors.green,
      requiredPermission: Permissions.MANAGE_EQUIPMENT,
    ),
    StatCard(
      title: "Taux de résolution",
      value: "92%",
      icon: Icons.check_circle,
      color: Colors.purple,
      requiredPermission: Permissions.MANAGE_TICKETS,
    ),
  ];

  @override
  Map<String, ChartConfig> get charts => {
    'tickets': ChartConfig(
      title: "Évolution des tickets",
      type: ChartType.line,
      color: Colors.orange,
      subtitle: "30 derniers jours",
      requiredPermission: Permissions.MANAGE_TICKETS,
    ),
    'categories': ChartConfig(
      title: "Tickets par catégorie",
      type: ChartType.pie,
      color: Colors.blue,
      subtitle: "Répartition actuelle",
      requiredPermission: Permissions.MANAGE_TICKETS,
    ),
    'resolution': ChartConfig(
      title: "Temps de résolution",
      type: ChartType.bar,
      color: Colors.green,
      subtitle: "Par priorité",
      requiredPermission: Permissions.MANAGE_TICKETS,
    ),
    'equipment': ChartConfig(
      title: "État du matériel",
      type: ChartType.pie,
      color: Colors.purple,
      subtitle: "Par statut",
      requiredPermission: Permissions.MANAGE_EQUIPMENT,
    ),
  };

  @override
  Widget buildCustomContent(BuildContext context) {
    return Container(); // Contenu spécifique technicien si nécessaire
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
        leading: const Icon(Icons.report_problem),
        title: const Text('Tickets'),
        onTap: () => controller.showTickets(),
      ),
      ListTile(
        leading: const Icon(Icons.build),
        title: const Text('Maintenance'),
        onTap: () => controller.scheduleMaintenance(),
      ),
      ListTile(
        leading: const Icon(Icons.devices),
        title: const Text('Équipements'),
        onTap: () => controller.manageEquipment(),
      ),
      ListTile(
        leading: const Icon(Icons.inventory),
        title: const Text('Inventaire'),
        onTap: () => controller.checkInventory(),
      ),
      ListTile(
        leading: const Icon(Icons.analytics),
        title: const Text('Rapports'),
        onTap: () => controller.showReports(),
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
    return FloatingActionButton.extended(
      onPressed: () => controller.createNewTicket(),
      icon: const Icon(Icons.add_task),
      label: const Text('Nouveau ticket'),
    );
  }
}
