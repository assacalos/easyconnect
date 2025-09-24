import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Views/Components/role_based_widget.dart';
import 'package:easyconnect/Views/Components/user_profile_card.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/Views/Patron/patron_permissions.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/permissions.dart';

class PatronDashboardController extends GetxController {
  var currentSection = PatronSection.dashboard.obs;
  final AuthController authController = Get.find<AuthController>();
  var isLoading = false.obs;

  // Statistiques globales
  final stats = <StatCard>[
    StatCard(
      title: "Employés actifs",
      value: "85",
      icon: Icons.people,
      color: Colors.blue,
      requiredPermission: Permissions.MANAGE_EMPLOYEES,
      onTap: () => Get.toNamed('/rh'),
    ),
    StatCard(
      title: "Chiffre d'affaires",
      value: "1.2M €",
      icon: Icons.euro,
      color: Colors.green,
      requiredPermission: Permissions.VIEW_FINANCES,
      subtitle: "Ce mois-ci",
      onTap: () => Get.toNamed('/comptable'),
    ),
    StatCard(
      title: "Clients actifs",
      value: "45",
      icon: Icons.business,
      color: Colors.orange,
      requiredPermission: Permissions.VIEW_SALES,
      onTap: () => Get.toNamed('/commercial'),
    ),
    StatCard(
      title: "Tickets en attente",
      value: "12",
      icon: Icons.report_problem,
      color: Colors.red,
      requiredPermission: Permissions.MANAGE_TICKETS,
      onTap: () => Get.toNamed('/technicien'),
    ),
    StatCard(
      title: "Congés à valider",
      value: "3",
      icon: Icons.event_busy,
      color: Colors.purple,
      requiredPermission: Permissions.MANAGE_LEAVES,
      onTap: () => Get.toNamed('/rh'),
    ),
    StatCard(
      title: "Factures impayées",
      value: "8",
      icon: Icons.receipt_long,
      color: Colors.deepOrange,
      requiredPermission: Permissions.VIEW_FINANCES,
      onTap: () => Get.toNamed('/comptable'),
    ),
    StatCard(
      title: "Pointage",
      value: "Voir",
      icon: Icons.access_time,
      color: Colors.teal,
      requiredPermission: Permissions.VIEW_ATTENDANCE,
      onTap: () => Get.toNamed('/attendance'),
    ),
    StatCard(
      title: "Factures à approuver",
      value: "3",
      icon: Icons.receipt_long,
      color: Colors.indigo,
      requiredPermission: Permissions.VIEW_INVOICES,
      onTap: () => Get.toNamed('/invoices'),
    ),
    StatCard(
      title: "Paiements à approuver",
      value: "2",
      icon: Icons.payment,
      color: Colors.cyan,
      requiredPermission: Permissions.VIEW_PAYMENTS,
      onTap: () => Get.toNamed('/payments'),
    ),
  ];

  void switchSection(PatronSection section) {
    currentSection.value = section;
  }

  bool canAccessSection(PatronSection section) {
    final userRole = authController.userAuth.value?.role;
    if (userRole == null) return false;

    final requiredPermissions = PatronPermissions.getRequiredPermissions(
      section,
    );
    final allowedRoles =
        requiredPermissions
            .map((permission) => PatronPermissions.getAllowedRoles(permission))
            .expand((roles) => roles)
            .toSet()
            .toList();

    return allowedRoles.contains(userRole);
  }
}

class PatronDashboardPage extends StatelessWidget {
  final PatronDashboardController controller = Get.put(
    PatronDashboardController(),
  );

  PatronDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(getSectionTitle(controller.currentSection.value)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => controller.authController.logout(),
          ),
        ],
      ),
      drawer: isDesktop ? null : _buildDrawer(),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                // Carte de profil utilisateur
                UserProfileCard(showPermissions: false),
                // Contenu principal
                Expanded(
                  child: Obx(() {
                    final section = controller.currentSection.value;
                    if (!controller.canAccessSection(section)) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              "Accès non autorisé",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Vous n'avez pas les permissions nécessaires pour accéder à cette section",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // En-tête de la section
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              getSectionTitle(section),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          // Contenu de la section
                          _buildSectionContent(section),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(PatronSection section) {
    switch (section) {
      case PatronSection.dashboard:
        return StatsGrid(
          stats: controller.stats,
          isLoading: controller.isLoading.value,
          crossAxisCount: Get.width > 1200 ? 3 : 2,
        );
      case PatronSection.employees:
        return const Center(child: Text("Gestion des employés"));
      case PatronSection.leaves:
        return const Center(child: Text("Validation des congés"));
      case PatronSection.attendance:
        return const Center(child: Text("Suivi des présences"));
      case PatronSection.payroll:
        return const Center(child: Text("Gestion de la paie"));
      case PatronSection.training:
        return const Center(child: Text("Suivi des formations"));
      case PatronSection.reports:
        return const Center(child: Text("Rapports et analyses"));
      case PatronSection.approvals:
        return const Center(child: Text("Approbations en attente"));
      case PatronSection.chat:
        return const Center(child: Text("Chat avec les équipes"));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.blueGrey.shade900,
      child: Column(
        children: [
          // En-tête du sidebar
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blueGrey.shade800,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Espace Direction",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Obx(
                  () => Text(
                    "Rôle: ${Roles.getRoleName(controller.authController.userAuth.value?.role)}",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          // Menu de navigation
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _buildMenuItems(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueGrey.shade800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Espace Direction",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Obx(
                  () => Text(
                    "Rôle: ${Roles.getRoleName(controller.authController.userAuth.value?.role)}",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          ..._buildMenuItems(),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    return [
      _buildMenuItem(
        Icons.dashboard,
        "Tableau de bord",
        PatronSection.dashboard,
      ),
      RoleBasedWidget(
        allowedRoles: PatronPermissions.getAllowedRoles(
          PatronPermissions.MANAGE_EMPLOYEES,
        ),
        child: _buildMenuItem(
          Icons.people,
          "Gestion des employés",
          PatronSection.employees,
        ),
      ),
      RoleBasedWidget(
        allowedRoles: PatronPermissions.getAllowedRoles(
          PatronPermissions.MANAGE_LEAVES,
        ),
        child: _buildMenuItem(
          Icons.event,
          "Gestion des congés",
          PatronSection.leaves,
        ),
      ),
      RoleBasedWidget(
        allowedRoles: PatronPermissions.getAllowedRoles(
          PatronPermissions.VIEW_ATTENDANCE,
        ),
        child: _buildMenuItem(
          Icons.access_time,
          "Pointage / Présences",
          PatronSection.attendance,
        ),
      ),
      RoleBasedWidget(
        allowedRoles: PatronPermissions.getAllowedRoles(
          PatronPermissions.MANAGE_PAYROLL,
        ),
        child: _buildMenuItem(
          Icons.payments,
          "Gestion de la paie",
          PatronSection.payroll,
        ),
      ),
      RoleBasedWidget(
        allowedRoles: PatronPermissions.getAllowedRoles(
          PatronPermissions.MANAGE_TRAINING,
        ),
        child: _buildMenuItem(
          Icons.school,
          "Formations",
          PatronSection.training,
        ),
      ),
      RoleBasedWidget(
        allowedRoles: PatronPermissions.getAllowedRoles(
          PatronPermissions.VIEW_REPORTS,
        ),
        child: _buildMenuItem(
          Icons.bar_chart,
          "Reporting",
          PatronSection.reports,
        ),
      ),
      RoleBasedWidget(
        allowedRoles: PatronPermissions.getAllowedRoles(
          PatronPermissions.APPROVE_DECISIONS,
        ),
        child: _buildMenuItem(
          Icons.gavel,
          "Approbations",
          PatronSection.approvals,
        ),
      ),
      RoleBasedWidget(
        allowedRoles: PatronPermissions.getAllowedRoles(
          PatronPermissions.USE_CHAT,
        ),
        child: _buildMenuItem(Icons.chat, "Chat interne", PatronSection.chat),
      ),
    ];
  }

  Widget _buildMenuItem(IconData icon, String text, PatronSection section) {
    return Obx(
      () => ListTile(
        leading: Icon(
          icon,
          color:
              controller.currentSection.value == section
                  ? Colors.white
                  : Colors.grey[400],
        ),
        title: Text(
          text,
          style: TextStyle(
            color:
                controller.currentSection.value == section
                    ? Colors.white
                    : Colors.grey[400],
          ),
        ),
        selected: controller.currentSection.value == section,
        onTap: () {
          if (controller.canAccessSection(section)) {
            controller.switchSection(section);
            if (!Get.width.isGreaterThan(900)) Get.back();
          } else {
            if (!Get.width.isGreaterThan(900)) Get.back();
            Get.snackbar(
              "Accès refusé",
              "Vous n'avez pas les permissions nécessaires pour accéder à cette section",
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
      ),
    );
  }

  String getSectionTitle(PatronSection section) {
    switch (section) {
      case PatronSection.dashboard:
        return "Tableau de bord Direction";
      case PatronSection.employees:
        return "Gestion des employés";
      case PatronSection.leaves:
        return "Gestion des congés";
      case PatronSection.attendance:
        return "Pointage / Présences";
      case PatronSection.payroll:
        return "Gestion de la paie";
      case PatronSection.training:
        return "Formations & Développement";
      case PatronSection.reports:
        return "Reporting global";
      case PatronSection.approvals:
        return "Approbations";
      case PatronSection.chat:
        return "Chat interne";
      default:
        return "";
    }
  }
}
