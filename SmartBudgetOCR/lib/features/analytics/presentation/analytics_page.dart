import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton.dart';
import '../../dashboard/widgets/category_chart.dart';

/// Analytics page showing category breakdown and trends.
class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(analyticsProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTokens.s16),
          children: [
            analyticsAsync.when(
              loading: () => Column(
                children: const [
                  SkeletonBox(height: 260),
                  SizedBox(height: AppTokens.s16),
                  SkeletonBox(height: 220),
                  SizedBox(height: AppTokens.s16),
                  SkeletonBox(height: 220),
                ],
              ),
              error: (err, _) => EmptyState(
                title: 'Couldn’t load analytics',
                message: err.toString(),
                icon: Icons.query_stats,
              ),
              data: (data) {
                if (data == null || data.isEmpty) {
                  return const EmptyState(
                    title: 'No analytics yet',
                    message: 'Scan receipts to see category breakdowns and trends.',
                    icon: Icons.query_stats,
                  );
                }

                final byCategory = Map<String, double>.from(
                  (data['by_category'] as Map?)?.map(
                        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
                      ) ??
                      {},
                );
                final trends = List<double>.from(data['trend'] as List? ?? []);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Card(
                      title: 'Category spending',
                      child: SizedBox(
                        height: 220,
                        child: byCategory.isEmpty
                            ? const EmptyState(
                                title: 'No category data',
                                message: 'Add a few expenses first.',
                                icon: Icons.pie_chart_outline,
                              )
                            : CategoryChart(data: byCategory),
                      ),
                    ),
                    const SizedBox(height: AppTokens.s16),
                    _Card(
                      title: 'Monthly trend',
                      child: SizedBox(
                        height: 200,
                        child: _LineChart(trends: trends),
                      ),
                    ),
                    const SizedBox(height: AppTokens.s16),
                    _Card(
                      title: 'Budget progress',
                      subtitle: 'Set budgets per category to track usage.',
                      child: _BudgetProgressList(byCategory: byCategory),
                    ),
                    const SizedBox(height: AppTokens.s24),
                    Text(
                      'TODO: connect backend API',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppTokens.s32),
          ],
        ),
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  final List<double> trends;
  const _LineChart({required this.trends});

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return const EmptyState(
        title: 'No trend data',
        message: 'We’ll show monthly trend after a few expenses.',
        icon: Icons.show_chart,
      );
    }
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: trends
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTokens.cardRadius,
        boxShadow: AppTokens.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: AppTokens.s4),
            Text(
              subtitle!,
              style: t.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: AppTokens.s12),
          child,
        ],
      ),
    );
  }
}

class _BudgetProgressList extends StatelessWidget {
  const _BudgetProgressList({required this.byCategory});

  final Map<String, double> byCategory;

  @override
  Widget build(BuildContext context) {
    if (byCategory.isEmpty) {
      return const EmptyState(
        title: 'No budgets set',
        message: 'Add categories to start tracking budget usage.',
        icon: Icons.savings_outlined,
      );
    }

    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Placeholder budgets until backend is connected.
    // TODO: connect backend API
    double budgetFor(String _) => 500;

    return Column(
      children: entries.take(5).map((e) {
        final budget = budgetFor(e.key);
        final progress =
            (budget <= 0) ? 0.0 : (e.value / budget).clamp(0, 1).toDouble();
        final over = e.value > budget;
        final color = over
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      e.key,
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '\$${e.value.toStringAsFixed(0)} / \$${budget.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
