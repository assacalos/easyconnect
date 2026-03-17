import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

/// Donnée pour une barre du graphique (label en bas, valeur en hauteur, couleur).
class DashboardBarItem {
  final String label;
  final double value;
  final Color color;

  const DashboardBarItem(this.label, this.value, this.color);
}

/// Donnée pour une carte KPI compacte (260 px, bordure colorée).
class DashboardKpiCardItem {
  final String title;
  final String valueText;
  final IconData icon;
  final Color color;
  final String? route;

  const DashboardKpiCardItem({
    required this.title,
    required this.valueText,
    required this.icon,
    required this.color,
    this.route,
  });
}

/// Section web : à gauche un BarChart dans une carte blanche, à droite des cartes KPI compactes (260 px).
/// Utiliser avec [kIsWeb] pour n'afficher qu'en web.
class DashboardWebChartSection extends StatelessWidget {
  final List<DashboardBarItem> barItems;
  final List<DashboardKpiCardItem> cardItems;
  final bool isLoading;

  const DashboardWebChartSection({
    super.key,
    required this.barItems,
    required this.cardItems,
    this.isLoading = false,
  });

  static const double kCardWidth = 260.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildChartCard(context),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: kCardWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < cardItems.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _buildCompactCard(context, cardItems[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isLoading
          ? const SizedBox(
              height: 220,
              child: SkeletonCard(height: 220),
            )
          : SizedBox(
              height: 220,
              child: barItems.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune donnée',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    )
                  : _buildBarChart(),
            ),
    );
  }

  Widget _buildBarChart() {
    assert(barItems.isNotEmpty);
    final maxVal = barItems.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minVal = barItems.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final hasNegative = minVal < 0;
    final maxY = (maxVal * 1.15).clamp(1.0, double.infinity);
    final minY = hasNegative ? (minVal * 1.15).clamp(double.negativeInfinity, -0.5) : 0.0;
    final range = maxY - minY;
    final interval = range > 0 && range.isFinite ? range / 5 : 1.0;
    final safeInterval = interval;
    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: minY,
        groupsSpace: 12,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          horizontalInterval: safeInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                _shortFormat(value),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i >= 0 && i < barItems.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      barItems[i].label,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barItems.asMap().entries.map((entry) {
          final item = entry.value;
          final y = item.value;
          final fromY = hasNegative && y < 0 ? y : 0.0;
          final toY = hasNegative && y < 0 ? 0.0 : y.clamp(0.0, double.infinity);
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                fromY: fromY,
                toY: toY,
                color: item.color,
                width: 20,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(y >= 0 ? 4 : 0),
                  bottom: Radius.circular(y < 0 ? 4 : 0),
                ),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.grey.shade800,
            tooltipBorderRadius: BorderRadius.circular(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex >= barItems.length) return null;
              final item = barItems[groupIndex];
              return BarTooltipItem(
                '${item.label}\n${_formatValue(item.value)}',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
      duration: const Duration(milliseconds: 300),
    );
  }

  static String _shortFormat(double v) {
    final absV = v.abs();
    if (absV >= 1e6) return '${(v / 1e6).toStringAsFixed(0)}M';
    if (absV >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}k';
    return v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);
  }

  static String _formatValue(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)} M FCFA';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)} k FCFA';
    return '${v.toStringAsFixed(0)} FCFA';
  }

  Widget _buildCompactCard(BuildContext context, DashboardKpiCardItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.route != null ? () => context.go(item.route!) : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: kCardWidth,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: item.color, width: 4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 20, color: item.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    isLoading
                        ? Shimmer(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Text(
                              item.valueText,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: item.color),
                            ),
                          )
                        : Text(
                            item.valueText,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: item.color),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
