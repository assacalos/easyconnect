import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:flutter/material.dart';
import 'package:easyconnect/Views/Components/base_dashboard.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/Views/Components/favorites_bar.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/dashboard_wrapper.dart';
import 'package:easyconnect/Controllers/rh_dashboard_controller.dart';
import 'package:easyconnect/utils/dashboard_filters.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:get/get.dart';

class RhDashboard extends BaseDashboard<RhDashboardController> {
  const RhDashboard({super.key});

  @override
  String get title => 'Espace Ressources Humaines';

  @override
  Color get primaryColor => Colors.purple;

  @override
  List<Filter> get availableFilters =>
      DashboardFilters.getFiltersForRole(Roles.RH);

  @override
  List<FavoriteItem> get favoriteItems => [
    FavoriteItem(
      id: 'new_employee',
      label: 'Nouvel employé',
      icon: Icons.person_add,
      onTap: () => controller.createNewEmployee(),
    ),
    FavoriteItem(
      id: 'employees',
      label: 'Employés',
      icon: Icons.people,
      route: '/employees',
    ),
    FavoriteItem(
      id: 'leaves',
      label: 'Congés',
      icon: Icons.event,
      route: '/leaves',
    ),
    FavoriteItem(
      id: 'validation_pointages',
      label: 'Validation Pointages',
      icon: Icons.camera_alt,
      route: '/attendance-validation',
    ),
    FavoriteItem(
      id: 'recruitment',
      label: 'Recrutement',
      icon: Icons.work,
      route: '/recruitment',
    ),
    FavoriteItem(
      id: 'contracts',
      label: 'Contrats',
      icon: Icons.description,
      route: '/contracts',
    ),
    FavoriteItem(
      id: 'attendance',
      label: 'Présences',
      icon: Icons.access_time,
      onTap: () => controller.showAttendance(),
    ),
    FavoriteItem(
      id: 'training',
      label: 'Formations',
      icon: Icons.school,
      onTap: () => controller.showTraining(),
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
      title: "Effectif total",
      value: "85",
      icon: Icons.people,
      color: Colors.blue,
      requiredPermission: Permissions.MANAGE_EMPLOYEES,
      onTap: () => Get.toNamed('/employees'),
    ),
    StatCard(
      title: "Nouveaux employés",
      value: "3",
      icon: Icons.person_add,
      color: Colors.green,
      requiredPermission: Permissions.MANAGE_EMPLOYEES,
      onTap: () => Get.toNamed('/employees'),
    ),
    StatCard(
      title: "Congés en attente",
      value: "5",
      icon: Icons.event,
      color: Colors.orange,
      requiredPermission: Permissions.MANAGE_LEAVES,
      onTap: () => Get.toNamed('/leaves'),
    ),
    StatCard(
      title: "Offres publiées",
      value: "3",
      icon: Icons.work,
      color: Colors.blue,
      requiredPermission: Permissions.MANAGE_RECRUITMENT,
      onTap: () => Get.toNamed('/recruitment'),
    ),
    StatCard(
      title: "Candidatures",
      value: "12",
      icon: Icons.people_alt,
      color: Colors.green,
      requiredPermission: Permissions.VIEW_RECRUITMENT,
      onTap: () => Get.toNamed('/recruitment'),
    ),
    StatCard(
      title: "Contrats actifs",
      value: "78",
      icon: Icons.description,
      color: Colors.blue,
      requiredPermission: Permissions.VIEW_CONTRACTS,
      onTap: () => Get.toNamed('/contracts'),
    ),
    StatCard(
      title: "Contrats en attente",
      value: "5",
      icon: Icons.schedule,
      color: Colors.orange,
      requiredPermission: Permissions.MANAGE_CONTRACTS,
      onTap: () => Get.toNamed('/contracts'),
    ),
    StatCard(
      title: "Présents aujourd'hui",
      value: "78",
      icon: Icons.access_time,
      color: Colors.green,
      requiredPermission: Permissions.VIEW_ATTENDANCE,
    ),
    StatCard(
      title: "Recrutements en cours",
      value: "3",
      icon: Icons.person_search,
      color: Colors.purple,
      requiredPermission: Permissions.MANAGE_RECRUITMENT,
    ),
    StatCard(
      title: "Employés actifs",
      value: "82",
      icon: Icons.check_circle,
      color: Colors.green,
      requiredPermission: Permissions.VIEW_EMPLOYEES,
      onTap: () => Get.toNamed('/employees'),
    ),
  ];

  @override
  Map<String, ChartConfig> get charts => {
    'headcount': ChartConfig(
      title: "Évolution des effectifs",
      type: ChartType.line,
      color: Colors.blue,
      subtitle: "12 derniers mois",
      requiredPermission: Permissions.MANAGE_EMPLOYEES,
    ),
    'departments': ChartConfig(
      title: "Répartition par service",
      type: ChartType.pie,
      color: Colors.purple,
      subtitle: "Effectifs actuels",
      requiredPermission: Permissions.MANAGE_EMPLOYEES,
    ),
    'attendance': ChartConfig(
      title: "Taux de présence",
      type: ChartType.bar,
      color: Colors.green,
      subtitle: "Par service",
      requiredPermission: Permissions.VIEW_ATTENDANCE,
    ),
    'leaves': ChartConfig(
      title: "Congés",
      type: ChartType.bar,
      color: Colors.orange,
      subtitle: "Par type",
      requiredPermission: Permissions.MANAGE_LEAVES,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return DashboardWrapper(
      currentIndex: 0, // Index pour le dashboard RH
      child: super.build(context),
    );
  }

  @override
  Widget buildCustomContent(BuildContext context) {
    return Container(); // Contenu spécifique RH si nécessaire
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
        leading: const Icon(Icons.people),
        title: const Text('Employés'),
        onTap: () => Get.toNamed('/employees'),
      ),
      ListTile(
        leading: const Icon(Icons.event),
        title: const Text('Congés'),
        onTap: () => Get.toNamed('/leaves'),
      ),
      ListTile(
        leading: const Icon(Icons.work),
        title: const Text('Recrutement'),
        onTap: () => Get.toNamed('/recruitment'),
      ),
      ListTile(
        leading: const Icon(Icons.description),
        title: const Text('Contrats'),
        onTap: () => Get.toNamed('/contracts'),
      ),
      ListTile(
        leading: const Icon(Icons.access_time),
        title: const Text('Présences'),
        onTap: () => controller.showAttendance(),
      ),
      ListTile(
        leading: const Icon(Icons.school),
        title: const Text('Formations'),
        onTap: () => controller.showTraining(),
      ),
      ListTile(
        leading: const Icon(Icons.person_search),
        title: const Text('Recrutement'),
        onTap: () => controller.showRecruitment(),
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
      onPressed: () => Get.toNamed('/employees/new'),
      icon: const Icon(Icons.person_add),
      label: const Text('Nouvel employé'),
    );
  }
}
