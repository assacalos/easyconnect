import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FilterBar extends StatelessWidget {
  final List<Filter> filters;
  final Function(Filter) onFilterChanged;
  final RxList<Filter> activeFilters;

  const FilterBar({
    super.key,
    required this.filters,
    required this.onFilterChanged,
    required this.activeFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtres',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Obx(
                  () => TextButton(
                    onPressed: activeFilters.isEmpty
                        ? null
                        : () => activeFilters.clear(),
                    child: const Text('Réinitialiser'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filters.map((filter) {
                return Obx(
                  () => FilterChip(
                    label: Text(filter.label),
                    selected: activeFilters.contains(filter),
                    onSelected: (selected) {
                      if (selected) {
                        activeFilters.add(filter);
                      } else {
                        activeFilters.remove(filter);
                      }
                      onFilterChanged(filter);
                    },
                    avatar: filter.icon != null ? Icon(filter.icon) : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class Filter {
  final String id;
  final String label;
  final IconData? icon;
  final FilterType type;
  final dynamic value;

  const Filter({
    required this.id,
    required this.label,
    this.icon,
    required this.type,
    this.value,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Filter && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum FilterType {
  date,
  status,
  category,
  user,
  department,
  custom,
}
