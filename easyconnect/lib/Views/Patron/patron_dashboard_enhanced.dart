import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Controllers/patron_dashboard_controller.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Views/Components/base_dashboard.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/favorites_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/dashboard_filters.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class PatronDashboardEnhanced extends BaseDashboard<PatronDashboardController> {
  const PatronDashboardEnhanced({super.key});

  @override
  String get title => 'Direction';

  @override
  Color get primaryColor => const Color(0xFF0F172A); // Slate 900

  @override
  Future<void> Function()? get onRefresh => () => controller.loadData();

  @override
  List<Filter> get availableFilters =>
      DashboardFilters.getFiltersForRole(Roles.PATRON);

  @override
  List<FavoriteItem> get favoriteItems => [
    FavoriteItem(id: 'validation_inscriptions', label: 'Validation Inscriptions', icon: Icons.person_add, route: '/patron/registrations/validation'),
    FavoriteItem(id: 'validation_clients', label: 'Validation Clients', icon: Icons.approval, route: '/clients/validation'),
    FavoriteItem(id: 'validation_devis', label: 'Validation Devis', icon: Icons.assignment, route: '/devis/validation'),
    FavoriteItem(id: 'validation_factures', label: 'Validation Factures', icon: Icons.receipt, route: '/factures/validation'),
    FavoriteItem(id: 'validation_pointages', label: 'Validation Pointages', icon: Icons.camera_alt, route: '/attendance-validation'),
    FavoriteItem(id: 'presence_summary', label: 'Présences par employé', icon: Icons.calendar_view_month, route: '/pointage/presence-summary'),
    FavoriteItem(id: 'validation_bon_commandes_fournisseur', label: 'Validation Bons Fournisseur', icon: Icons.inventory_2, route: '/bons-de-commande-fournisseur/validation'),
    FavoriteItem(id: 'tasks', label: 'Tâches', icon: Icons.task_alt, route: '/tasks'),
  ];

  @override
  List<StatCard> get statsCards => controller.enhancedStats;

  @override
  Map<String, ChartConfig> get charts => {};

  static String _formatAmount(double value) {
    if (value >= 1e6) return '${NumberFormat('#,##0', 'fr_FR').format(value ~/ 1e6)} M FCFA';
    if (value >= 1e3) return '${NumberFormat('#,##0', 'fr_FR').format(value ~/ 1e3)} k FCFA';
    return '${NumberFormat('#,##0', 'fr_FR').format(value)} FCFA';
  }

  @override
  Widget buildCustomContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(context),
          const SizedBox(height: 24),
          _buildQuickActions(context),
          const SizedBox(height: 28),
          _buildSectionLabel('Validations en attente', Icons.approval, const Color(0xFFF59E0B)),
          const SizedBox(height: 12),
          _buildValidationSection(context),
          const SizedBox(height: 28),
          _buildSectionLabel('Métriques', Icons.trending_up, const Color(0xFF059669)),
          const SizedBox(height: 12),
          _buildPerformanceSection(context),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Obx(() {
      final user = Get.find<AuthController>().userAuth.value;
      final prenom = user?.prenom?.trim().isNotEmpty == true ? user!.prenom! : 'Direction';
      final hour = DateTime.now().hour;
      final greeting = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F172A),
              const Color(0xFF1E293B),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, $prenom',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now()),
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction('Inscriptions', Icons.person_add, '/patron/registrations/validation', const Color(0xFFEA580C)),
      _QuickAction('Clients', Icons.people, '/clients/validation', const Color(0xFF3B82F6)),
      _QuickAction('Devis', Icons.description, '/devis/validation', const Color(0xFF10B981)),
      _QuickAction('Factures', Icons.receipt, '/factures/validation', const Color(0xFFDC2626)),
      _QuickAction('Pointages', Icons.access_time, '/pointage/validation', const Color(0xFFF59E0B)),
      _QuickAction('Présences', Icons.calendar_view_month, '/pointage/presence-summary', const Color(0xFF059669)),
      _QuickAction('Tâches', Icons.task_alt, '/tasks', const Color(0xFF7C3AED)),
    ];
    final screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      height: 48,
      width: screenWidth - 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final a = actions[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.toNamed(a.route),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: a.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: a.color.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(a.icon, size: 20, color: a.color),
                    const SizedBox(width: 8),
                    Text(
                      a.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildValidationSection(BuildContext context) {
    final items = [
      _ValItem('Inscriptions', controller.pendingRegistrations, Icons.person_add, const Color(0xFFEA580C), '/patron/registrations/validation'),
      _ValItem('Clients', controller.pendingClients, Icons.people, const Color(0xFF3B82F6), '/clients/validation'),
      _ValItem('Devis', controller.pendingDevis, Icons.description, const Color(0xFF10B981), '/devis/validation'),
      _ValItem('Bordereaux', controller.pendingBordereaux, Icons.assignment_turned_in, const Color(0xFFF59E0B), '/bordereaux/validation'),
      _ValItem('Bons de Commande', controller.pendingBonCommandes, Icons.shopping_cart, const Color(0xFF7C3AED), '/bon-commandes/validation'),
      _ValItem('Bons Fournisseur', null, Icons.inventory_2, const Color(0xFF6366F1), '/bons-de-commande-fournisseur/validation'),
      _ValItem('Factures', controller.pendingFactures, Icons.receipt, const Color(0xFFDC2626), '/factures/validation'),
      _ValItem('Paiements', controller.pendingPaiements, Icons.payment, const Color(0xFF0D9488), '/paiements/validation'),
      _ValItem('Dépenses', controller.pendingDepenses, Icons.money_off, const Color(0xFF7C3AED), '/depenses/validation'),
      _ValItem('Salaires', controller.pendingSalaires, Icons.account_balance_wallet, const Color(0xFFEAB308), '/salaires/validation'),
      _ValItem('Reporting', controller.pendingReporting, Icons.analytics, const Color(0xFF6366F1), '/reporting/validation'),
      _ValItem('Pointages', controller.pendingPointages, Icons.access_time, const Color(0xFF78716C), '/pointage/validation'),
      _ValItem('Employés', null, Icons.people, const Color(0xFF06B6D4), '/employees/validation'),
      _ValItem('Tâches', controller.pendingTasks, Icons.task_alt, const Color(0xFF7C3AED), '/tasks'),
    ];
    final crossCount = Get.width > 1200 ? 4 : Get.width > 800 ? 3 : 2;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: items.map((e) => _buildModernCard(
        title: e.title,
        countRx: e.countRx,
        icon: e.icon,
        color: e.color,
        onTap: () => Get.toNamed(e.route),
        badgeColor: const Color(0xFFF59E0B),
      )).toList(),
    );
  }

  Widget _buildPerformanceSection(BuildContext context) {
    return Column(
      children: [
        _buildStatRow<int>(
          'Clients validés',
          controller.validatedClients,
          (v) => v.toString(),
          Icons.verified_user,
          const Color(0xFF059669),
          'Clients actifs',
        ),
        const SizedBox(height: 12),
        _buildStatRow<int>(
          'Fournisseurs',
          controller.totalSuppliers,
          (v) => v.toString(),
          Icons.business,
          const Color(0xFFEA580C),
          'Partenaires',
        ),
        const SizedBox(height: 12),
        _buildStatRow<double>(
          'Chiffre d\'affaires',
          controller.totalRevenue,
          _formatAmount,
          Icons.euro,
          const Color(0xFF7C3AED),
          'Montant total des factures',
        ),
      ],
    );
  }

  Widget _buildStatRow<T>(String title, Rx<T> valueRx, String Function(T) valueFormat, IconData icon, Color color, String subtitle) {
    return Obx(() {
      final value = valueFormat(valueRx.value);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildModernCard({
    required String title,
    required RxInt? countRx,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required Color badgeColor,
  }) {
    final badge = countRx != null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Obx(() {
              final c = countRx.value;
              final loading = controller.isLoading.value;
              final textWidget = Text(
                c.toString(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              );
              return loading
                  ? Shimmer(
                      baseColor: badgeColor.withOpacity(0.25),
                      highlightColor: badgeColor.withOpacity(0.5),
                      child: textWidget,
                    )
                  : textWidget;
            }),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '0',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 22, color: color),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: badge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  List<Widget> buildDrawerItems(BuildContext context) {
    // Les validations ne sont plus dans le menu : le patron y accède via le dashboard (section « Validations en attente »).
    return [
      const Divider(color: Colors.white54),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'NAVIGATION',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ),
      _drawerItem(context, Icons.list, 'Liste des Clients', '/clients'),
      _drawerItem(context, Icons.euro, 'Finances', '/patron/finances'),
      _drawerItem(context, Icons.book, 'Journal des comptes', '/journal'),
      _drawerItem(context, Icons.analytics, 'Rapports', '/patron/reports'),
      _drawerItem(context, Icons.notifications_active, 'Besoins / Rappels techniciens', '/besoins'),
      Obx(() {
        final userRole = Get.find<AuthController>().userAuth.value?.role;
        if (userRole == 1) {
          return _drawerItem(context, Icons.settings_applications, 'Paramètres', '/admin/settings');
        }
        return const SizedBox.shrink();
      }),
    ];
  }

  Widget _drawerItem(BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
      onTap: () {
        Navigator.pop(context);
        Get.toNamed(route);
      },
    );
  }

  @override
  Widget? buildFloatingActionButton() => null;
}

class _QuickAction {
  final String label;
  final IconData icon;
  final String route;
  final Color color;
  _QuickAction(this.label, this.icon, this.route, this.color);
}

class _ValItem {
  final String title;
  final RxInt? countRx;
  final IconData icon;
  final Color color;
  final String route;
  _ValItem(this.title, this.countRx, this.icon, this.color, this.route);
}
