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
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
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
      bottomNavigationBar: buildBottomNavigationBar(),
      floatingActionButton: buildFloatingActionButton(),
    );
  }

  List<Widget> buildAppBarActions() {
    return [
      IconButton(
        icon: const Icon(Icons.notifications, color: Colors.white),
        onPressed: () {
          // Afficher les notifications
        },
      ),
      IconButton(
        icon: const Icon(Icons.refresh, color: Colors.white),
        onPressed: () => controller.loadInitialData(),
      ),
    ];
  }

  Widget? buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Rechercher'),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
      onTap: (index) {
        // Navigation basée sur l'index
        switch (index) {
          case 0:
            // Accueil - déjà sur le dashboard
            break;
          case 1:
            // Rechercher
            break;
          case 2:
            // Notifications
            break;
          case 3:
            // Chat
            break;
          case 4:
            // Profil
            break;
        }
      },
    );
  }

  Widget? buildFloatingActionButton() => null;

  Widget buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.grey.shade900,
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
            ...buildDrawerItems(context),

            // Séparateur
            const Divider(color: Colors.white54),

            // Boutons communs
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.white70),
              title: const Text(
                'Pointage',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed('/attendance-punch');
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.white70),
              title: const Text(
                'Reporting',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed('/reporting');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white70),
              title: const Text(
                'Paramètres',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Ajouter la route des paramètres
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> buildDrawerItems(BuildContext context);
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
