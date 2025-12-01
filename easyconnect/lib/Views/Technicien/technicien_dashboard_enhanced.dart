import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/technicien_dashboard_controller.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Views/Components/base_dashboard.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/favorites_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/dashboard_filters.dart';

class TechnicienDashboardEnhanced
    extends BaseDashboard<TechnicienDashboardController> {
  const TechnicienDashboardEnhanced({super.key});

  @override
  String get title => 'Tableau de Bord Technicien';

  @override
  Color get primaryColor => Colors.orange.shade700;

  @override
  List<Filter> get availableFilters =>
      DashboardFilters.getFiltersForRole(Roles.TECHNICIEN);

  @override
  List<FavoriteItem> get favoriteItems => [
    FavoriteItem(
      id: 'interventions',
      label: 'Interventions',
      icon: Icons.build,
      route: '/interventions',
    ),
    FavoriteItem(
      id: 'equipments',
      label: 'Équipements',
      icon: Icons.settings,
      route: '/equipments',
    ),
    // FavoriteItem(
    //   id: 'reports',
    //   label: 'Rapports',
    //   icon: Icons.analytics,
    //   route: '/reports',
    // ),
  ];

  @override
  List<StatCard> get statsCards => controller.enhancedStats;

  @override
  Map<String, ChartConfig> get charts => {};

  @override
  Widget build(BuildContext context) {
    // Utiliser un widget avec un lifecycle pour détecter quand on revient
    return _LifecycleAwareWidget(
      child: super.build(context),
      onResumed: () {
        // Recharger les entités en attente quand on revient sur le dashboard
        controller.refreshPendingEntities();
      },
    );
  }

  @override
  Widget buildCustomContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Première partie - Entités en attente
          _buildPendingSection(),

          const SizedBox(height: 24),

          // Deuxième partie - Entités validées
          _buildValidatedSection(),

          const SizedBox(height: 24),

          // Troisième partie - Statistiques montants
          _buildStatisticsSection(),
        ],
      ),
    );
  }

  Widget _buildPendingSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.orange.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'Entités en attente',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return Obx(
                () => GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: Get.width > 800 ? 2 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                  children: [
                    _buildPendingCard(
                      title: 'Interventions',
                      count: controller.pendingInterventions.value,
                      icon: Icons.build,
                      color: Colors.orange,
                      onTap: () async {
                        await Get.toNamed('/interventions');
                        // Recharger les données après retour
                        controller.refreshPendingEntities();
                      },
                    ),
                    // _buildPendingCard(
                    //   title: 'Rapports',
                    //   count: controller.pendingReports.value,
                    //   icon: Icons.analytics,
                    //   color: Colors.green,
                    //   onTap: () async {
                    //     await Get.toNamed('/reports');
                    //     // Recharger les données après retour
                    //     controller.refreshPendingEntities();
                    //   },
                    // ),
                    _buildPendingCard(
                      title: 'Équipements',
                      count: controller.pendingEquipments.value,
                      icon: Icons.settings,
                      color: Colors.purple,
                      onTap: () async {
                        await Get.toNamed('/equipments');
                        // Recharger les données après retour
                        controller.refreshPendingEntities();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildValidatedSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'Entités Validées',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return Obx(
                () => GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: Get.width > 800 ? 2 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                  children: [
                    _buildValidatedCard(
                      title: 'Interventions Terminées',
                      count: controller.completedInterventions.value,
                      icon: Icons.build,
                      color: Colors.orange,
                      onTap: () => Get.toNamed('/interventions?tab=2'),
                    ),
                    // _buildValidatedCard(
                    //   title: 'Rapports Validés',
                    //   count: controller.validatedReports.value,
                    //   icon: Icons.analytics,
                    //   color: Colors.green,
                    // ),
                    _buildValidatedCard(
                      title: 'Équipements Opérationnels',
                      count: controller.operationalEquipments.value,
                      icon: Icons.settings,
                      color: Colors.purple,
                      onTap: () => Get.toNamed('/equipments?tab=2'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.teal.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'Statistiques Montants',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return Obx(
                () => GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: Get.width > 800 ? 3 : 1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    _buildStatisticCard(
                      title: 'Coût Interventions',
                      value:
                          '${controller.interventionCost.value.toStringAsFixed(0)} FCFA',
                      icon: Icons.build,
                      color: Colors.orange,
                      subtitle: 'Coût total des interventions',
                    ),
                    _buildStatisticCard(
                      title: 'Valeur Équipements',
                      value:
                          '${controller.equipmentValue.value.toStringAsFixed(0)} FCFA',
                      icon: Icons.settings,
                      color: Colors.purple,
                      subtitle: 'Valeur totale des équipements',
                    ),
                    _buildStatisticCard(
                      title: 'Économies Réalisées',
                      value:
                          '${controller.savings.value.toStringAsFixed(0)} FCFA',
                      icon: Icons.savings,
                      color: Colors.green,
                      subtitle: 'Économies réalisées',
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidatedCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  List<Widget> buildDrawerItems(BuildContext context) {
    return [
      ListTile(
        leading: const Icon(Icons.build, color: Colors.white70),
        title: const Text(
          'Interventions',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () {
          Navigator.pop(context);
          Get.toNamed('/interventions');
        },
      ),
      ListTile(
        leading: const Icon(Icons.settings, color: Colors.white70),
        title: const Text(
          'Équipements',
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () {
          Navigator.pop(context);
          Get.toNamed('/equipments');
        },
      ),
      // Bouton Paramètres (visible pour tous, mais accès restreint aux admins)
      Obx(() {
        final userRole = Get.find<AuthController>().userAuth.value?.role;
        if (userRole == 1) {
          return ListTile(
            leading: const Icon(Icons.settings, color: Colors.white70),
            title: const Text(
              'Paramètres',
              style: TextStyle(color: Colors.white70),
            ),
            onTap: () {
              Navigator.pop(context);
              Get.toNamed('/admin/settings');
            },
          );
        }
        return const SizedBox.shrink();
      }),
      // ListTile(
      //   leading: const Icon(Icons.analytics, color: Colors.white70),
      //   title: const Text('Rapports', style: TextStyle(color: Colors.white70)),
      //   onTap: () {
      //     Navigator.pop(context);
      //     Get.toNamed('/reporting');
      //   },
      // ),
    ];
  }

  @override
  Widget? buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => Get.toNamed('/interventions/create'),
      child: const Icon(Icons.add),
    );
  }
}

// Widget pour détecter le lifecycle de la page
class _LifecycleAwareWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onResumed;

  const _LifecycleAwareWidget({required this.child, required this.onResumed});

  @override
  State<_LifecycleAwareWidget> createState() => _LifecycleAwareWidgetState();
}

class _LifecycleAwareWidgetState extends State<_LifecycleAwareWidget> {
  bool _hasCalledResumed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger les données quand on revient sur cette page, mais seulement une fois
    if (!_hasCalledResumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onResumed();
        _hasCalledResumed = true;
        // Réinitialiser après un délai pour permettre un nouveau rafraîchissement
        Future.delayed(const Duration(seconds: 2), () {
          _hasCalledResumed = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
