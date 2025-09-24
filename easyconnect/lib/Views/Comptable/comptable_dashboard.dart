import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:flutter/material.dart';
import 'package:easyconnect/Views/Components/base_dashboard.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/Views/Components/favorites_bar.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Controllers/comptable_dashboard_controller.dart';
import 'package:easyconnect/utils/dashboard_filters.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:get/get.dart';

class ComptableDashboard extends BaseDashboard<ComptableDashboardController> {
  const ComptableDashboard({super.key});

  @override
  String get title => 'Espace Comptabilité';

  @override
  Color get primaryColor => Colors.green;

  @override
  List<Filter> get availableFilters =>
      DashboardFilters.getFiltersForRole(Roles.COMPTABLE);

  @override
  List<FavoriteItem> get favoriteItems => [
    FavoriteItem(
      id: 'new_invoice',
      label: 'Nouvelle facture',
      icon: Icons.receipt,
      onTap: () => controller.createNewInvoice(),
    ),
    FavoriteItem(
      id: 'expenses',
      label: 'Dépenses',
      icon: Icons.money_off,
      onTap: () => controller.showExpenses(),
    ),
    FavoriteItem(
      id: 'balance',
      label: 'Balance',
      icon: Icons.account_balance,
      onTap: () => controller.showBalance(),
    ),
    FavoriteItem(
      id: 'reports',
      label: 'Rapports',
      icon: Icons.assessment,
      onTap: () => controller.showReports(),
    ),
    FavoriteItem(
      id: 'invoices',
      label: 'Factures',
      icon: Icons.receipt_long,
      route: '/invoices',
    ),
    FavoriteItem(
      id: 'payments',
      label: 'Paiements',
      icon: Icons.payment,
      route: '/payments',
    ),
  ];

  @override
  List<StatCard> get statsCards => [
    StatCard(
      title: "Chiffre d'affaires",
      value: "103.5k €",
      icon: Icons.euro,
      color: Colors.green,
      requiredPermission: Permissions.VIEW_FINANCES,
      subtitle: "Ce mois-ci",
    ),
    StatCard(
      title: "Dépenses",
      value: "45.2k €",
      icon: Icons.money_off,
      color: Colors.red,
      requiredPermission: Permissions.MANAGE_EXPENSES,
      subtitle: "Ce mois-ci",
    ),
    StatCard(
      title: "Factures impayées",
      value: "12",
      icon: Icons.warning,
      color: Colors.orange,
      requiredPermission: Permissions.MANAGE_INVOICES,
      onTap: () => Get.toNamed('/invoices'),
    ),
    StatCard(
      title: "Trésorerie",
      value: "58.3k €",
      icon: Icons.account_balance,
      color: Colors.blue,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
    StatCard(
      title: "Factures en attente",
      value: "3",
      icon: Icons.pending,
      color: Colors.purple,
      requiredPermission: Permissions.MANAGE_INVOICES,
      onTap: () => Get.toNamed('/invoices'),
    ),
    StatCard(
      title: "Paiements à traiter",
      value: "5",
      icon: Icons.payment,
      color: Colors.teal,
      requiredPermission: Permissions.MANAGE_PAYMENTS,
      onTap: () => Get.toNamed('/payments'),
    ),
  ];

  @override
  Map<String, ChartConfig> get charts => {
    'revenue': ChartConfig(
      title: "Évolution du CA",
      type: ChartType.line,
      color: Colors.green,
      subtitle: "12 derniers mois",
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
    'expenses': ChartConfig(
      title: "Répartition des dépenses",
      type: ChartType.pie,
      color: Colors.red,
      subtitle: "Par catégorie",
      requiredPermission: Permissions.MANAGE_EXPENSES,
    ),
    'cashflow': ChartConfig(
      title: "Flux de trésorerie",
      type: ChartType.bar,
      color: Colors.blue,
      subtitle: "6 derniers mois",
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
    'invoices': ChartConfig(
      title: "État des factures",
      type: ChartType.pie,
      color: Colors.orange,
      subtitle: "Par statut",
      requiredPermission: Permissions.MANAGE_INVOICES,
    ),
  };

  @override
  Widget buildCustomContent(BuildContext context) {
    return Container(); // Contenu spécifique comptable si nécessaire
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
        leading: const Icon(Icons.receipt),
        title: const Text('Factures'),
        onTap: () => controller.showInvoices(),
      ),
      ListTile(
        leading: const Icon(Icons.money_off),
        title: const Text('Dépenses'),
        onTap: () => controller.showExpenses(),
      ),
      ListTile(
        leading: const Icon(Icons.account_balance),
        title: const Text('Trésorerie'),
        onTap: () => controller.showBalance(),
      ),
      ListTile(
        leading: const Icon(Icons.assessment),
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
      onPressed: () => controller.createNewInvoice(),
      icon: const Icon(Icons.receipt),
      label: const Text('Nouvelle facture'),
    );
  }
}
