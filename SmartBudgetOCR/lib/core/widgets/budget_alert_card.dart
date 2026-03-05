import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/tokens.dart';

/// Shows a small budget status banner on the dashboard.
class BudgetAlertCard extends StatelessWidget {
  const BudgetAlertCard({
    super.key,
    required this.totalSpent,
    required this.monthlyBudget,
  });

  final double totalSpent;
  final double monthlyBudget;

  @override
  Widget build(BuildContext context) {
    if (monthlyBudget <= 0) return const SizedBox.shrink();

    final t = Theme.of(context);
    final ratio = (totalSpent / monthlyBudget).clamp(0.0, 2.0);
    final pct = (ratio * 100).clamp(0, 999).toStringAsFixed(0);

    Color tint;
    String title;
    String subtitle;
    IconData icon;

    if (ratio >= 1.0) {
      tint = t.colorScheme.error;
      icon = Icons.error_outline;
      title = 'Budget exceeded';
      subtitle = 'You\'ve used $pct% of your monthly limit.';
    } else if (ratio >= 0.8) {
      tint = Colors.orange;
      icon = Icons.warning_amber_rounded;
      title = 'Close to your budget';
      subtitle = 'You\'ve already used $pct% of your monthly limit.';
    } else if (ratio >= 0.4) {
      tint = t.colorScheme.primary;
      icon = Icons.check_circle_outline;
      title = 'On track this month';
      subtitle = 'You\'ve used $pct% of your monthly budget.';
    } else {
      tint = AppColors.textMuted;
      icon = Icons.savings_outlined;
      title = 'Plenty of runway';
      subtitle = 'You\'ve used only $pct% of your monthly limit.';
    }

    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        borderRadius: AppTokens.cardRadius,
        gradient: LinearGradient(
          colors: [
            tint.withValues(alpha: 0.22),
            tint.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: tint.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint.withValues(alpha: 0.18),
            ),
            child: Icon(icon, color: tint),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: t.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

