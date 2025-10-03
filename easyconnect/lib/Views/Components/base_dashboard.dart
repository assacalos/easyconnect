import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/base_dashboard_controller.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Views/Components/interactive_chart.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/Views/Components/favorites_bar.dart';
import 'package:easyconnect/Views/Components/paginated_data_view.dart';
import 'package:easyconnect/Views/Components/user_profile_card.dart';

abstract class BaseDashboard<T extends BaseDashboardController>
    extends GetView<T> {
  const BaseDashboard({super.key});

  String get title;
  Color get primaryColor;
  List<Filter> get availableFilters;
  List<FavoriteItem> get favoriteItems;
  List<StatCard> get statsCards;
  Map<String, ChartConfig> get charts;
  Widget buildCustomContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: primaryColor,
        actions: buildAppBarActions(),
      ),
      drawer: buildDrawer(context),
      body: PaginatedDataView(
        scrollController: ScrollController(),
        onLoadMore: () => controller.loadNextPage(),
        hasMoreData: controller.hasMoreData.value,
        isLoading: controller.isLoading.value,
        children: [
          // Profil utilisateur
          UserProfileCard(showPermissions: false),

          // Barre de favoris
          FavoritesBar(items: favoriteItems),

          // Filtres
          FilterBar(
            filters: availableFilters,
            activeFilters: controller.activeFilters,
            onFilterChanged: controller.onFilterChanged,
          ),

          // Statistiques
          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(
              () => StatsGrid(
                stats: statsCards,
                isLoading: controller.isLoading.value,
                crossAxisCount: Get.width > 1200 ? 3 : 2,
              ),
            ),
          ),

          // Graphiques
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children:
                  charts.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Obx(
                        () => InteractiveChart(
                          title: entry.value.title,
                          data: controller.chartData[entry.key]?.value ?? [],
                          type: entry.value.type,
                          color: entry.value.color,
                          isLoading: controller.isLoading.value,
                          subtitle: entry.value.subtitle,
                          requiredPermission: entry.value.requiredPermission,
                          enableZoom: entry.value.enableZoom,
                          showTooltips: entry.value.showTooltips,
                          showLegend: entry.value.showLegend,
                          onDataPointTap: entry.value.onDataPointTap,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),

          // Contenu personnalisé
          buildCustomContent(context),
        ],
      ),
      floatingActionButton: buildFloatingActionButton(),
    );
  }

  List<Widget> buildAppBarActions() {
    return [
      IconButton(
        icon: const Icon(Icons.notifications),
        onPressed: () {
          // Afficher les notifications
        },
      ),
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => controller.loadInitialData(),
      ),
      IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () => _showLogoutDialog(),
        tooltip: 'Déconnexion',
      ),
    ];
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              final authController = Get.find<AuthController>();
              authController.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  Widget? buildFloatingActionButton() => null;

  Widget buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Text(
                    "Rôle: ${Roles.getRoleName(Get.find<AuthController>().userAuth.value?.role)}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          ...buildDrawerItems(),
        ],
      ),
    );
  }

  List<Widget> buildDrawerItems();
}

class ChartConfig {
  final String title;
  final ChartType type;
  final Color color;
  final String? subtitle;
  final Permission? requiredPermission;
  final bool enableZoom;
  final bool showTooltips;
  final bool showLegend;
  final Function(ChartData)? onDataPointTap;

  const ChartConfig({
    required this.title,
    required this.type,
    required this.color,
    this.subtitle,
    this.requiredPermission,
    this.enableZoom = true,
    this.showTooltips = true,
    this.showLegend = true,
    this.onDataPointTap,
  });
}
