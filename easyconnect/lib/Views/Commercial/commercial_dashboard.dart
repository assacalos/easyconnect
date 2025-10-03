import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:flutter/material.dart';
import 'package:easyconnect/Views/Components/base_dashboard.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/Views/Components/favorites_bar.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/dashboard_wrapper.dart';
import 'package:easyconnect/Controllers/commercial_dashboard_controller.dart';
import 'package:easyconnect/utils/dashboard_filters.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:get/get.dart';

class CommercialDashboard extends BaseDashboard<CommercialDashboardController> {
  const CommercialDashboard({super.key});

  @override
  String get title => 'Espace Commercial';

  @override
  Color get primaryColor => Colors.blue;

  @override
  List<Filter> get availableFilters =>
      DashboardFilters.getFiltersForRole(Roles.COMMERCIAL);

  @override
  List<FavoriteItem> get favoriteItems => [
    FavoriteItem(
      id: 'new_client',
      label: 'Nouveau client',
      icon: Icons.person_add,
      onTap: () => controller.createNewClient(),
    ),
    FavoriteItem(
      id: 'new_devis',
      label: 'Nouveau devis',
      icon: Icons.description,
      route: '/devis/new',
    ),
    FavoriteItem(
      id: 'new_bordereau',
      label: 'Nouveau bordereau',
      icon: Icons.assignment,
      route: '/bordereaux/new',
    ),
    FavoriteItem(
      id: 'attendance_punch',
      label: 'Pointage avec Photo',
      icon: Icons.camera_alt,
      route: '/attendance-punch',
    ),
    FavoriteItem(
      id: 'new_bon_commande',
      label: 'Nouveau bon de commande',
      icon: Icons.shopping_cart,
      route: '/bon-commandes/new',
    ),
    FavoriteItem(
      id: 'attendance',
      label: 'Pointage',
      icon: Icons.access_time,
      route: '/attendance',
    ),
    FavoriteItem(
      id: 'reporting',
      label: 'Rapports',
      icon: Icons.assessment,
      route: '/reporting',
    ),
  ];

  @override
  List<StatCard> get statsCards => [
    StatCard(
      title: "Chiffre d'affaires",
      value: "45.2k fcfa",
      icon: Icons.currency_franc,
      color: Colors.green,
      requiredPermission: Permissions.VIEW_SALES,
      subtitle: "Ce mois-ci",
    ),
    StatCard(
      title: "Nouveaux clients",
      value: "8",
      icon: Icons.person_add,
      color: Colors.blue,
      requiredPermission: Permissions.MANAGE_CLIENTS,
      subtitle: "Cette semaine",
    ),
    StatCard(
      title: "Prospects actifs",
      value: "15",
      icon: Icons.people_outline,
      color: Colors.orange,
      requiredPermission: Permissions.MANAGE_CLIENTS,
    ),
    StatCard(
      title: "Taux de conversion",
      value: "68%",
      icon: Icons.trending_up,
      color: Colors.purple,
      requiredPermission: Permissions.VIEW_SALES,
      subtitle: "Dernier trimestre",
    ),
  ];

  @override
  Map<String, ChartConfig> get charts => {
    'sales': ChartConfig(
      title: "Évolution des ventes",
      type: ChartType.line,
      color: Colors.green,
      subtitle: "6 derniers mois",
      requiredPermission: Permissions.VIEW_SALES,
    ),
    'clients': ChartConfig(
      title: "Répartition des clients",
      type: ChartType.pie,
      color: Colors.blue,
      subtitle: "Par secteur",
      requiredPermission: Permissions.MANAGE_CLIENTS,
    ),
    'opportunities': ChartConfig(
      title: "Pipeline commercial",
      type: ChartType.bar,
      color: Colors.orange,
      subtitle: "Par étape",
      requiredPermission: Permissions.MANAGE_CLIENTS,
    ),
    'conversion': ChartConfig(
      title: "Taux de conversion",
      type: ChartType.line,
      color: Colors.purple,
      subtitle: "Par source",
      requiredPermission: Permissions.VIEW_SALES,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return DashboardWrapper(
      currentIndex: 0, // Index pour le dashboard commercial
      child: super.build(context),
    );
  }

  @override
  Widget buildCustomContent(BuildContext context) {
    return Container(); // Contenu spécifique commercial si nécessaire
  }

  @override
  List<Widget> buildDrawerItems() {
    return [
      ListTile(
        leading: const Icon(Icons.dashboard),
        title: const Text('Tableau de bord'),
        onTap: () {
          Get.off(() => CommercialDashboard());
        },
      ),
      ListTile(
        leading: const Icon(Icons.people),
        title: const Text('Gestion des Clients'),
        onTap: () => Get.toNamed('/clients'),
      ),
      ListTile(
        leading: const Icon(Icons.description),
        title: const Text('Devis'),
        onTap: () => Get.toNamed('/devis'),
      ),
      ListTile(
        leading: const Icon(Icons.assignment),
        title: const Text('Bordereaux'),
        onTap: () => Get.toNamed('/bordereaux'),
      ),
      ListTile(
        leading: const Icon(Icons.shopping_cart),
        title: const Text('Bons de commande'),
        onTap: () => Get.toNamed('/bon-commandes'),
      ),
      /*  ListTile(
        leading: const Icon(Icons.analytics),
        title: const Text('Rapports'),
        onTap: () {},
      ), */
      ListTile(
        leading: const Icon(Icons.settings),
        title: const Text('Paramètres'),
        onTap: () {},
      ),
    ];
  }

  @override
  Widget? buildFloatingActionButton() {
    return null; // Suppression des boutons flottants
  }
}
