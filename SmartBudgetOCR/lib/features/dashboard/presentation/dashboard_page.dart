import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/expense_card.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/summary_card.dart';
import '../../../services/database_service.dart';
import '../widgets/category_chart.dart';

/// Dashboard that fetches analytics using Riverpod provider and displays cards
/// and charts. The heavy lifting is done by providers/services rather than the
/// widget itself.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);
    final expensesAsync = ref.watch(recentExpensesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ServiceLocator.auth.signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(analyticsProvider.future),
            ref.refresh(recentExpensesProvider.future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTokens.s16),
          children: [
            analyticsAsync.when(
              loading: () => const SkeletonBox(height: 108),
              error: (err, _) => EmptyState(
                title: 'Couldn’t load dashboard',
                message: err.toString(),
                icon: Icons.wifi_off,
              ),
              data: (analytics) {
                final total =
                    (analytics?['grand_total'] as num?)?.toDouble() ?? 0;
                return SummaryCard(
                  title: 'Total spent this month',
                  value: _formatMoney(total),
                  subtitle: 'Synced across offline + online expenses',
                  trailing: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.trending_up,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTokens.s16),
            analyticsAsync.when(
              loading: () => const SkeletonBox(height: 260),
              error: (_, __) => const SizedBox.shrink(),
              data: (analytics) {
                final byCategory = Map<String, double>.from(
                  (analytics?['by_category'] as Map?)?.map(
                        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
                      ) ??
                      {},
                );
                if (byCategory.isEmpty) {
                  return const EmptyState(
                    title: 'No category spending yet',
                    message: 'Scan your first receipt to see insights here.',
                    icon: Icons.pie_chart_outline,
                  );
                }
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
                      Text(
                        'Spending by category',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppTokens.s12),
                      SizedBox(height: 210, child: CategoryChart(data: byCategory)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'Recent transactions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.s12),
            expensesAsync.when(
              loading: () => Column(
                children: const [
                  SkeletonBox(height: 80),
                  SizedBox(height: AppTokens.s12),
                  SkeletonBox(height: 80),
                  SizedBox(height: AppTokens.s12),
                  SkeletonBox(height: 80),
                ],
              ),
              error: (err, _) => EmptyState(
                title: 'Couldn’t load transactions',
                message: err.toString(),
                icon: Icons.receipt_long,
              ),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return const EmptyState(
                    title: 'No transactions yet',
                    message: 'Tap the Scan button to add your first expense.',
                    icon: Icons.receipt_long,
                  );
                }
                final db = ref.read(databaseServiceProvider);
                final show = expenses.take(6).toList();
                return Column(
                  children: [
                    for (final e in show) ...[
                      ExpenseCard(
                        vendorName: e.vendorName,
                        dateLabel: _formatDate(e.createdAt),
                        amountLabel: _formatMoney(e.total),
                        categoryLabel: _dominantCategory(db, e.itemsJson),
                        categoryIcon: _categoryIcon(
                          _dominantCategory(db, e.itemsJson),
                        ),
                      ),
                      const SizedBox(height: AppTokens.s12),
                    ],
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

String _formatMoney(double amount) => '\$${amount.toStringAsFixed(2)}';

String _formatDate(DateTime? dt) {
  if (dt == null) return '—';
  final m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][dt.month - 1];
  return '$m ${dt.day}, ${dt.year}';
}

String _dominantCategory(DatabaseService db, String itemsJson) {
  final items = db.parseItems(itemsJson);
  if (items.isEmpty) return 'Other';
  final totals = <String, double>{};
  for (final it in items) {
    final cat = (it.category.isEmpty) ? 'Other' : it.category;
    totals[cat] = (totals[cat] ?? 0) + it.totalPrice;
  }
  return totals.entries.fold<MapEntry<String, double>?>(
        null,
        (best, e) => best == null || e.value > best.value ? e : best,
      )?.key ??
      'Other';
}

IconData _categoryIcon(String category) {
  final c = category.toLowerCase();
  if (c.contains('food')) return Icons.restaurant_outlined;
  if (c.contains('transport') || c.contains('travel')) {
    return Icons.directions_car_outlined;
  }
  if (c.contains('entertain')) return Icons.movie_outlined;
  if (c.contains('grocer')) return Icons.shopping_cart_outlined;
  if (c.contains('health')) return Icons.health_and_safety_outlined;
  return Icons.category_outlined;
}
