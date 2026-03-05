import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

/// A pie chart widget showing spending by category. Accepts a map of
/// category name to value.
class CategoryChart extends StatelessWidget {
  final Map<String, double> data;
  const CategoryChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      const Color(0xFFF97316), // orange
      const Color(0xFF8B5CF6), // purple
      const Color(0xFF22C55E), // green
    ];
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sections = entries.asMap().entries.map((e) {
      final idx = e.key;
      final item = e.value;
      return PieChartSectionData(
        value: item.value,
        title: '',
        radius: 70,
        color: colors[idx % colors.length],
      );
    }).toList();
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 42,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: entries.take(5).toList().asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors[idx % colors.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
