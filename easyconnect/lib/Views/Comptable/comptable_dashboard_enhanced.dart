import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/providers/comptable_dashboard_notifier.dart';
import 'package:easyconnect/providers/comptable_dashboard_state.dart';
import 'package:easyconnect/providers/dashboard_refresh_callback.dart';
import 'package:easyconnect/Views/Components/notification_badge_icon.dart';
import 'package:easyconnect/Views/Components/user_profile_card.dart';
import 'package:easyconnect/Views/Components/paginated_data_view.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/dashboard_entity_colors.dart';
import 'package:easyconnect/utils/responsive_helper.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/Views/Components/dashboard_web_chart_section.dart';
import 'package:easyconnect/Views/Components/rendements_et_alertes_card.dart';

/// Dashboard Comptable migré vers Riverpod.
class ComptableDashboardEnhanced extends ConsumerStatefulWidget {
  const ComptableDashboardEnhanced({super.key});

  static const String title = 'Comptable';
  static const Color primaryColor = Color(0xFF065F46);

  @override
  ConsumerState<ComptableDashboardEnhanced> createState() =>
      _ComptableDashboardEnhancedState();
}

class _ComptableDashboardEnhancedState
    extends ConsumerState<ComptableDashboardEnhanced> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DashboardRefreshCallback.instance.refreshComptable = () {
        ref.read(comptableDashboardProvider.notifier).refresh();
      };
    });
  }

  @override
  void dispose() {
    DashboardRefreshCallback.instance.refreshComptable = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(comptableDashboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(ComptableDashboardEnhanced.title),
        backgroundColor: ComptableDashboardEnhanced.primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () =>
                ref.read(comptableDashboardProvider.notifier).refresh(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: asyncState.when(
        data: (state) => RefreshIndicator(
          onRefresh: () =>
              ref.read(comptableDashboardProvider.notifier).refresh(),
          child: _buildBody(context, state),
        ),
        loading: () => _buildBody(
          context,
          const ComptableDashboardState(isLoading: true),
        ),
        error: (e, _) => _buildErrorBody(context, e, () => ref.read(comptableDashboardProvider.notifier).refresh()),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildErrorBody(BuildContext context, Object error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger le dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ComptableDashboardState state) {
    return PaginatedDataView(
      scrollController: _scrollController,
      onLoadMore: () {},
      hasMoreData: false,
      isLoading: state.isLoading,
      children: [
        const UserProfileCard(showPermissions: false),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(context),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildRendementsEtAlertes(context, state),
              const SizedBox(height: 28),
              _buildSectionLabel(
                  'En attente', Icons.schedule, const Color(0xFFDC2626)),
              const SizedBox(height: 12),
              _buildPendingSection(context, state),
              const SizedBox(height: 28),
              _buildSectionLabel(
                  'Validés', Icons.check_circle_outline, const Color(0xFF059669)),
              const SizedBox(height: 12),
              _buildValidatedSection(context, state),
              const SizedBox(height: 28),
              _buildSectionLabel(
                  'Montants', Icons.trending_up, const Color(0xFF7C3AED)),
              const SizedBox(height: 12),
              ResponsiveHelper.isMobile(context) ? _buildStatisticsSection(context, state) : _buildMontantsWeb(context, state),
            ],
          ),
        ),
      ],
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
    final user = ref.watch(authProvider).user;
    final prenom = user?.prenom?.trim().isNotEmpty == true
        ? user!.prenom!
        : 'Comptable';
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF065F46), Color(0xFF047857)],
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
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
          label: 'Factures',
          icon: Icons.receipt,
          route: '/invoices',
          color: DashboardEntityColors.factures),
      _QuickAction(
          label: 'Paiements',
          icon: Icons.payment,
          route: '/payments',
          color: DashboardEntityColors.paiements),
      _QuickAction(
          label: 'Dépenses',
          icon: Icons.money_off,
          route: '/expenses',
          color: DashboardEntityColors.expenses),
      _QuickAction(
          label: 'Salaires',
          icon: Icons.account_balance_wallet,
          route: '/salaries',
          color: DashboardEntityColors.salaries),
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
              onTap: () => context.go(a.route),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: a.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: a.color.withOpacity(0.2), width: 1),
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

  Widget _buildRendementsEtAlertes(
    BuildContext context,
    ComptableDashboardState state,
  ) {
    final rendements = <RendementItem>[
      RendementItem(
        label: 'Factures validées',
        value: state.validatedFactures.toString(),
        route: '/invoices',
        icon: Icons.receipt,
        color: DashboardEntityColors.factures,
      ),
      RendementItem(
        label: 'Paiements validés',
        value: state.validatedPaiements.toString(),
        route: '/payments',
        icon: Icons.payment,
        color: DashboardEntityColors.paiements,
      ),
      RendementItem(
        label: 'Dépenses validées',
        value: state.validatedDepenses.toString(),
        route: '/expenses',
        icon: Icons.money_off,
        color: DashboardEntityColors.expenses,
      ),
      RendementItem(
        label: 'Salaires validés',
        value: state.validatedSalaires.toString(),
        route: '/salaries',
        icon: Icons.account_balance_wallet,
        color: DashboardEntityColors.salaries,
      ),
    ];
    final alertes = <AlerteItem>[
      if (state.pendingFactures > 0)
        AlerteItem(
          message: '${state.pendingFactures} facture(s) en attente',
          route: '/invoices',
          icon: Icons.receipt,
          color: const Color(0xFFDC2626),
        ),
      if (state.pendingPaiements > 0)
        AlerteItem(
          message: '${state.pendingPaiements} paiement(s) en attente',
          route: '/payments',
          icon: Icons.payment,
          color: const Color(0xFFF59E0B),
        ),
      if (state.pendingDepenses > 0)
        AlerteItem(
          message: '${state.pendingDepenses} dépense(s) en attente',
          route: '/expenses',
          icon: Icons.money_off,
          color: const Color(0xFFF59E0B),
        ),
      if (state.pendingSalaires > 0)
        AlerteItem(
          message: '${state.pendingSalaires} salaire(s) en attente',
          route: '/salaries',
          icon: Icons.account_balance_wallet,
          color: const Color(0xFFF59E0B),
        ),
      if (state.pendingTasks > 0)
        AlerteItem(
          message: '${state.pendingTasks} tâche(s) à traiter',
          route: '/tasks',
          icon: Icons.task_alt,
          color: const Color(0xFFDC2626),
        ),
    ];
    return RendementsEtAlertesCard(
      titleRendements: 'Mes rendements',
      rendements: rendements,
      titleAlertes: 'À faire / Ce qui ne va pas',
      alertes: alertes,
    );
  }

  Widget _buildPendingSection(
      BuildContext context, ComptableDashboardState state) {
    final items = [
      _Item('Factures', state.pendingFactures, Icons.receipt,
          DashboardEntityColors.factures, '/invoices'),
      _Item('Paiements', state.pendingPaiements, Icons.payment,
          DashboardEntityColors.paiements, '/payments'),
      _Item('Dépenses', state.pendingDepenses, Icons.money_off,
          DashboardEntityColors.expenses, '/expenses'),
      _Item('Salaires', state.pendingSalaires, Icons.account_balance_wallet,
          DashboardEntityColors.salaries, '/salaries'),
      _Item('Tâches', state.pendingTasks, Icons.task_alt,
          DashboardEntityColors.tasks, '/tasks'),
    ];
    final crossCount = MediaQuery.of(context).size.width > 800 ? 4 : 2;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: items
          .map((e) => _buildModernCard(
                title: e.title,
                count: e.count,
                icon: e.icon,
                color: e.color,
                onTap: () => context.go(e.route),
                badgeColor: const Color(0xFFDC2626),
                isLoading: state.isLoading,
              ))
          .toList(),
    );
  }

  Widget _buildValidatedSection(
      BuildContext context, ComptableDashboardState state) {
    final items = [
      _ValidatedItem('Factures', state.validatedFactures, Icons.receipt,
          DashboardEntityColors.factures, 'Traitées', '/invoices?tab=2'),
      _ValidatedItem('Paiements', state.validatedPaiements, Icons.payment,
          DashboardEntityColors.paiements, 'Confirmés', '/payments?tab=2'),
      _ValidatedItem('Dépenses', state.validatedDepenses, Icons.money_off,
          DashboardEntityColors.expenses, 'Approuvées', '/expenses?tab=2'),
      _ValidatedItem('Salaires', state.validatedSalaires,
          Icons.account_balance_wallet, DashboardEntityColors.salaries, 'Payés',
          '/salaries?tab=2'),
    ];
    final crossCount = MediaQuery.of(context).size.width > 800 ? 4 : 2;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: items
          .map((e) => _buildModernCard(
                title: e.title,
                count: e.count,
                icon: e.icon,
                color: e.color,
                subtitle: e.subtitle,
                onTap: () => context.go(e.route),
                badgeColor: const Color(0xFF059669),
                isLoading: state.isLoading,
              ))
          .toList(),
    );
  }

  Widget _buildMontantsWeb(BuildContext context, ComptableDashboardState state) {
    const green = Color(0xFF059669);
    const teal = Color(0xFF0D9488);
    const red = Color(0xFFDC2626);
    const purple = Color(0xFF7C3AED);
    return DashboardWebChartSection(
      isLoading: state.isLoading,
      barItems: [
        DashboardBarItem('CA', state.totalRevenue, green),
        DashboardBarItem('Paiements', state.totalPayments, teal),
        DashboardBarItem('Dépenses', state.totalExpenses, red),
        DashboardBarItem('Salaires', state.totalSalaries, purple),
        DashboardBarItem('Bénéfice', state.netProfit, green),
      ],
      cardItems: [
        DashboardKpiCardItem(
          title: 'Chiffre d\'affaires',
          valueText: _formatAmount(state.totalRevenue),
          icon: Icons.euro,
          color: green,
          route: '/invoices',
        ),
        DashboardKpiCardItem(
          title: 'Paiements reçus',
          valueText: _formatAmount(state.totalPayments),
          icon: Icons.payment,
          color: teal,
          route: '/payments',
        ),
        DashboardKpiCardItem(
          title: 'Dépenses total',
          valueText: _formatAmount(state.totalExpenses),
          icon: Icons.money_off,
          color: red,
          route: '/expenses',
        ),
        DashboardKpiCardItem(
          title: 'Salaires payés',
          valueText: _formatAmount(state.totalSalaries),
          icon: Icons.account_balance_wallet,
          color: purple,
          route: '/salaries',
        ),
        DashboardKpiCardItem(
          title: 'Bénéfice net',
          valueText: _formatAmount(state.netProfit),
          icon: Icons.trending_up,
          color: green,
          route: '/invoices',
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(
      BuildContext context, ComptableDashboardState state) {
    return Column(
      children: [
        _buildStatRow(
          'Chiffre d\'affaires',
          _formatAmount(state.totalRevenue),
          Icons.euro,
          const Color(0xFF059669),
          'Montant total des factures',
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          'Paiements reçus',
          _formatAmount(state.totalPayments),
          Icons.payment,
          const Color(0xFF0D9488),
          'Montant des paiements',
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          'Dépenses total',
          _formatAmount(state.totalExpenses),
          Icons.money_off,
          const Color(0xFFDC2626),
          'Montant total des dépenses',
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          'Salaires payés',
          _formatAmount(state.totalSalaries),
          Icons.account_balance_wallet,
          const Color(0xFF7C3AED),
          'Montant des salaires',
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          'Bénéfice net',
          _formatAmount(state.netProfit),
          Icons.trending_up,
          const Color(0xFF059669),
          'Après dépenses',
        ),
      ],
    );
  }

  static String _formatAmount(double value) {
    if (value >= 1e6) {
      return '${NumberFormat('#,##0', 'fr_FR').format(value ~/ 1e6)} M FCFA';
    }
    if (value >= 1e3) {
      return '${NumberFormat('#,##0', 'fr_FR').format(value ~/ 1e3)} k FCFA';
    }
    return '${NumberFormat('#,##0', 'fr_FR').format(value)} FCFA';
  }

  Widget _buildStatRow(
      String title, String value, IconData icon, Color color, String subtitle) {
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
  }

  Widget _buildModernCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required Color badgeColor,
    String? subtitle,
    bool isLoading = false,
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
            border: Border(
              left: BorderSide(color: color, width: 4),
            ),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isLoading
                        ? Shimmer(
                            baseColor: badgeColor.withOpacity(0.25),
                            highlightColor: badgeColor.withOpacity(0.5),
                            child: Text(
                              count.toString(),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: badgeColor,
                              ),
                            ),
                          )
                        : Text(
                            count.toString(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
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
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500),
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

  Widget _buildDrawer(BuildContext context) {
    final userRole = ref.watch(authProvider).user?.role;
    return Drawer(
      child: Container(
        color: Colors.grey.shade900,
        child: ListView(
          children: [
            DrawerHeader(
              decoration:
                  BoxDecoration(color: ComptableDashboardEnhanced.primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    ComptableDashboardEnhanced.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rôle: ${Roles.getRoleName(userRole)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            _drawerItem(
                Icons.receipt, 'Factures', DashboardEntityColors.factures,
                () => _nav(context, '/invoices')),
            _drawerItem(
                Icons.payment, 'Paiements', DashboardEntityColors.paiements,
                () => _nav(context, '/payments')),
            _drawerItem(
                Icons.money_off, 'Dépenses', DashboardEntityColors.expenses,
                () => _nav(context, '/expenses')),
            _drawerItem(
                Icons.account_balance_wallet, 'Salaires',
                DashboardEntityColors.salaries, () => _nav(context, '/salaries')),
            _drawerItem(Icons.book, 'Journal des comptes',
                DashboardEntityColors.journal, () => _nav(context, '/journal')),
            _drawerItem(Icons.account_balance, 'Impôts et Taxes',
                DashboardEntityColors.taxes, () => _nav(context, '/taxes')),
            _drawerItem(
                Icons.inventory, 'Stock', DashboardEntityColors.stock,
                () => _nav(context, '/stocks')),
            _drawerItem(
                Icons.inventory_2, 'Inventaire physique', DashboardEntityColors.stock,
                () => _nav(context, '/comptable/inventaire')),
            _drawerItem(Icons.business, 'Fournisseurs',
                DashboardEntityColors.fournisseurs,
                () => _nav(context, '/suppliers')),
            if (userRole == 1)
              _drawerItem(Icons.settings, 'Paramètres',
                  DashboardEntityColors.parametres, () {
                Navigator.pop(context);
                context.go('/admin/settings');
              }),
            ListTile(
              leading: Icon(Icons.beach_access,
                  color: DashboardEntityColors.conges, size: 22),
              title: const Text('Demande de congé',
                  style: TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(context);
                context.go('/leaves');
              },
            ),
            const Divider(color: Colors.white54),
            ListTile(
              leading: Icon(Icons.access_time,
                  color: DashboardEntityColors.pointages, size: 22),
              title: const Text('Pointage',
                  style: TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(context);
                context.go('/attendance-punch');
              },
            ),
            ListTile(
              leading: Icon(Icons.task_alt,
                  color: DashboardEntityColors.tasks, size: 22),
              title:
                  const Text('Mes tâches', style: TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(context);
                context.go('/tasks');
              },
            ),
            const Divider(color: Colors.white54),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent, size: 22),
              title: const Text('Déconnexion', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: ComptableDashboardEnhanced.primaryColor,
      unselectedItemColor: Colors.grey,
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.home), label: 'Accueil'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.search), label: 'Rechercher'),
        const BottomNavigationBarItem(
            icon: NotificationBadgeIcon(), label: 'Notifications'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person), label: 'Profil'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.photo_library), label: 'Médias'),
      ],
      onTap: (index) {
        switch (index) {
          case 1:
            context.go('/search');
            break;
          case 2:
            context.go('/notifications');
            break;
          case 3:
            context.go('/profile');
            break;
          case 4:
            context.go('/media');
            break;
        }
      },
    );
  }

  void _nav(BuildContext context, String route) {
    Navigator.pop(context);
    context.go(route);
  }

  Widget _drawerItem(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 15)),
      onTap: onTap,
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final String route;
  final Color color;
  _QuickAction(
      {required this.label,
      required this.icon,
      required this.route,
      required this.color});
}

class _Item {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final String route;
  _Item(this.title, this.count, this.icon, this.color, this.route);
}

class _ValidatedItem {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final String subtitle;
  final String route;
  _ValidatedItem(
      this.title, this.count, this.icon, this.color, this.subtitle, this.route);
}
