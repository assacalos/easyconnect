import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Controllers/commercial_dashboard_controller.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Views/Components/base_dashboard.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/favorites_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/dashboard_filters.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class CommercialDashboardEnhanced
    extends BaseDashboard<CommercialDashboardController> {
  const CommercialDashboardEnhanced({super.key});

  @override
  String get title => 'Commercial';

  @override
  Color get primaryColor => const Color(0xFF0F172A); // Slate 900

  @override
  Future<void> Function()? get onRefresh => () => controller.refreshPendingEntities();

  @override
  List<Filter> get availableFilters =>
      DashboardFilters.getFiltersForRole(Roles.COMMERCIAL);

  @override
  List<FavoriteItem> get favoriteItems => [
    FavoriteItem(id: 'clients', label: 'Clients', icon: Icons.people, route: '/clients'),
    FavoriteItem(id: 'devis', label: 'Devis', icon: Icons.description, route: '/devis'),
    FavoriteItem(id: 'bordereaux', label: 'Bordereaux', icon: Icons.assignment_turned_in, route: '/bordereaux'),
    FavoriteItem(id: 'bon_commandes', label: 'Bons de Commande', icon: Icons.shopping_cart, route: '/bon-commandes'),
    FavoriteItem(id: 'bon_commandes_fournisseur', label: 'Bons Fournisseur', icon: Icons.inventory_2, route: '/bons-de-commande-fournisseur'),
    FavoriteItem(id: 'tasks', label: 'Mes tâches', icon: Icons.task_alt, route: '/tasks'),
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
          _buildSectionLabel('En attente', Icons.schedule, const Color(0xFFF59E0B)),
          const SizedBox(height: 12),
          _buildPendingSection(context),
          const SizedBox(height: 28),
          _buildSectionLabel('Validés', Icons.check_circle_outline, const Color(0xFF10B981)),
          const SizedBox(height: 12),
          _buildValidatedSection(context),
          const SizedBox(height: 28),
          _buildSectionLabel('Montants', Icons.trending_up, const Color(0xFF8B5CF6)),
          const SizedBox(height: 12),
          _buildStatisticsSection(context),
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
      final prenom = user?.prenom?.trim().isNotEmpty == true ? user!.prenom! : 'Commercial';
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
      _QuickAction(label: 'Clients', icon: Icons.people, route: '/clients', color: const Color(0xFF3B82F6)),
      _QuickAction(label: 'Devis', icon: Icons.description, route: '/devis', color: const Color(0xFF10B981)),
      _QuickAction(label: 'Bordereaux', icon: Icons.assignment_turned_in, route: '/bordereaux', color: const Color(0xFFF59E0B)),
      _QuickAction(label: 'Bons', icon: Icons.shopping_cart, route: '/bon-commandes', color: const Color(0xFF8B5CF6)),
    ];
    return SizedBox(
      height: 48,
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

  Widget _buildPendingSection(BuildContext context) {
    final items = [
      _PendingItem('Clients', () => controller.pendingClients.value, Icons.people, const Color(0xFF3B82F6), '/clients'),
      _PendingItem('Devis', () => controller.pendingDevis.value, Icons.description, const Color(0xFF10B981), '/devis'),
      _PendingItem('Bordereaux', () => controller.pendingBordereaux.value, Icons.assignment_turned_in, const Color(0xFFF59E0B), '/bordereaux'),
      _PendingItem('Bons de Commande', () => controller.pendingBonCommandes.value, Icons.shopping_cart, const Color(0xFF8B5CF6), '/bon-commandes'),
      _PendingItem('Bons Fournisseur', () => controller.pendingBonCommandesFournisseur.value, Icons.inventory_2, const Color(0xFF6366F1), '/bons-de-commande-fournisseur'),
      _PendingItem('Tâches', () => controller.pendingTasks.value, Icons.task_alt, const Color(0xFF7C3AED), '/tasks'),
    ];
    final crossCount = Get.width > 800 ? 4 : 2;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: items.map((e) => _buildModernCard(
        title: e.title,
        count: e.count,
        icon: e.icon,
        color: e.color,
        onTap: () => Get.toNamed(e.route),
        badgeColor: const Color(0xFFF59E0B),
      )).toList(),
    );
  }

  Widget _buildValidatedSection(BuildContext context) {
    final items = [
      _ValidatedItem('Clients', () => controller.validatedClients.value, Icons.verified_user, const Color(0xFF3B82F6), 'Actifs', '/clients?tab=1'),
      _ValidatedItem('Devis', () => controller.validatedDevis.value, Icons.assignment, const Color(0xFF10B981), 'Approuvés', '/devis?tab=2'),
      _ValidatedItem('Bordereaux', () => controller.validatedBordereaux.value, Icons.assignment_turned_in, const Color(0xFFF59E0B), 'Traités', '/bordereaux?tab=2'),
      _ValidatedItem('Bons', () => controller.validatedBonCommandes.value, Icons.shopping_cart, const Color(0xFF8B5CF6), 'Confirmés', '/bon-commandes?tab=2'),
    ];
    final crossCount = Get.width > 800 ? 4 : 2;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: items.map((e) => _buildModernCard(
        title: e.title,
        count: e.count,
        icon: e.icon,
        color: e.color,
        subtitle: e.subtitle,
        onTap: () => Get.toNamed(e.route),
        badgeColor: const Color(0xFF10B981),
      )).toList(),
    );
  }

  Widget _buildStatisticsSection(BuildContext context) {
    return Column(
      children: [
        _buildStatRow(
          'Chiffre d\'affaires',
          () => _formatAmount(controller.totalRevenue.value),
          Icons.euro,
          const Color(0xFF10B981),
          'Ventes totales',
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          'Devis en cours',
          () => _formatAmount(controller.pendingDevisAmount.value),
          Icons.description,
          const Color(0xFFF59E0B),
          'En attente',
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          'Bordereaux payés',
          () => _formatAmount(controller.paidBordereauxAmount.value),
          Icons.payment,
          const Color(0xFF3B82F6),
          'Montant payé',
        ),
      ],
    );
  }

  Widget _buildStatRow(String title, String Function() valueBuilder, IconData icon, Color color, String subtitle) {
    return Obx(() {
      final value = valueBuilder();
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
    required int Function() count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required Color badgeColor,
    String? subtitle,
  }) {
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 22, color: color),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Obx(() {
                      final c = count();
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
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
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
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  List<Widget> buildDrawerItems(BuildContext context) {
    return [
      _drawerItem(Icons.people, 'Clients', () => _nav(context, '/clients')),
      _drawerItem(Icons.description, 'Devis', () => _nav(context, '/devis')),
      _drawerItem(Icons.assignment_turned_in, 'Bordereaux', () => _nav(context, '/bordereaux')),
      _drawerItem(Icons.shopping_cart, 'Bons de Commande', () => _nav(context, '/bon-commandes')),
      _drawerItem(Icons.inventory_2, 'Bons Fournisseur', () => _nav(context, '/bons-de-commande-fournisseur')),
      Obx(() {
        final userRole = Get.find<AuthController>().userAuth.value?.role;
        if (userRole == 1) {
          return _drawerItem(Icons.settings, 'Paramètres', () {
            Navigator.pop(context);
            Get.toNamed('/admin/settings');
          });
        }
        return const SizedBox.shrink();
      }),
    ];
  }

  void _nav(BuildContext context, String route) {
    Navigator.pop(context);
    Get.toNamed(route);
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
      onTap: onTap,
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
  _QuickAction({required this.label, required this.icon, required this.route, required this.color});
}

class _PendingItem {
  final String title;
  final int Function() count;
  final IconData icon;
  final Color color;
  final String route;
  _PendingItem(this.title, this.count, this.icon, this.color, this.route);
}

class _ValidatedItem {
  final String title;
  final int Function() count;
  final IconData icon;
  final Color color;
  final String subtitle;
  final String route;
  _ValidatedItem(this.title, this.count, this.icon, this.color, this.subtitle, this.route);
}
