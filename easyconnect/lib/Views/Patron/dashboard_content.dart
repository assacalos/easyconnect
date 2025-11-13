import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/patron_dashboard_controller.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/favorites_bar.dart';
import 'package:easyconnect/utils/permissions.dart';

class DashboardContent extends StatelessWidget {
  final PatronDashboardController controller;

  const DashboardContent({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de favoris
          FavoritesBar(
            items: [
              FavoriteItem(
                id: 'revenue',
                label: "Chiffre d'affaires",
                icon: Icons.euro,
                onTap: () => Get.toNamed('/patron/finances'),
              ),
              FavoriteItem(
                id: 'employees',
                label: 'Employés',
                icon: Icons.people,
                onTap: () => Get.toNamed('/admin/users'),
              ),
              FavoriteItem(
                id: 'tickets',
                label: 'Tickets',
                icon: Icons.build,
                onTap: () => Get.toNamed('/technicien'),
              ),
            ],
          ),

          // Barre de filtres
          FilterBar(
            filters: controller.filters,
            activeFilters: controller.activeFilters,
            onFilterChanged: controller.onFilterChanged,
          ),

          // Statistiques
          Obx(
            () => StatsGrid(
              stats: controller.stats,
              isLoading: controller.isLoading.value,
              crossAxisCount: Get.width > 1200 ? 3 : 2,
            ),
          ),

          // Graphiques
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Chiffre d'affaires
                Obx(
                  () => DataChart(
                    title: "Évolution du chiffre d'affaires",
                    data: controller.revenueData,
                    type: ChartType.line,
                    isLoading: controller.isLoading.value,
                    color: Colors.green,
                    requiredPermission: Permissions.VIEW_FINANCES,
                    subtitle: "6 derniers mois",
                  ),
                ),
                const SizedBox(height: 16),

                // Répartition des employés
                Obx(
                  () => DataChart(
                    title: "Répartition des employés",
                    data: controller.employeeData,
                    type: ChartType.pie,
                    isLoading: controller.isLoading.value,
                    color: Colors.blue,
                    requiredPermission: Permissions.MANAGE_EMPLOYEES,
                    subtitle: "Par département",
                  ),
                ),
                const SizedBox(height: 16),

                // Tickets
                Obx(
                  () => DataChart(
                    title: "État des tickets",
                    data: controller.ticketData,
                    type: ChartType.bar,
                    isLoading: controller.isLoading.value,
                    color: Colors.orange,
                    requiredPermission: Permissions.MANAGE_TICKETS,
                    subtitle: "Répartition par statut",
                  ),
                ),
                const SizedBox(height: 16),

                // Congés
                Obx(
                  () => DataChart(
                    title: "Demandes de congés",
                    data: controller.leaveData,
                    type: ChartType.line,
                    isLoading: controller.isLoading.value,
                    color: Colors.purple,
                    requiredPermission: Permissions.MANAGE_LEAVES,
                    subtitle: "Cette semaine",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
