import 'package:flutter/material.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';

class StatsGrid extends StatelessWidget {
  final List<StatCard> stats;
  final int crossAxisCount;
  final bool isLoading;

  const StatsGrid({
    super.key,
    required this.stats,
    this.crossAxisCount = 2,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: List.generate(
          4,
          (index) =>
              const Card(child: Center(child: CircularProgressIndicator())),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: stats.map((stat) => StatCardWidget(stat: stat)).toList(),
    );
  }
}

class StatCard {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Permission? requiredPermission;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.requiredPermission,
    this.subtitle,
    this.onTap,
  });
}

class StatCardWidget extends StatelessWidget {
  final StatCard stat;

  const StatCardWidget({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Obx(() {
      final userRole = authController.userAuth.value?.role;

      if (stat.requiredPermission != null &&
          !Permissions.hasPermission(userRole, stat.requiredPermission!)) {
        return Card(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 32, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  "Accès restreint",
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: stat.onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(stat.icon, size: 40, color: stat.color),
                  const SizedBox(height: 16),
                  Text(
                    stat.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stat.value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: stat.color,
                    ),
                  ),
                  if (stat.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      stat.subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
