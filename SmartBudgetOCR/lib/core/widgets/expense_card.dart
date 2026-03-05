import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/tokens.dart';

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    super.key,
    required this.vendorName,
    required this.dateLabel,
    required this.amountLabel,
    required this.categoryLabel,
    required this.categoryIcon,
    this.onTap,
  });

  final String vendorName;
  final String dateLabel;
  final String amountLabel;
  final String categoryLabel;
  final IconData categoryIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return InkWell(
      borderRadius: AppTokens.cardRadius,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTokens.s16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTokens.cardRadius,
          boxShadow: AppTokens.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: t.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(categoryIcon, color: t.colorScheme.primary),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendorName,
                    style: t.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTokens.s4),
                  Text(
                    '$dateLabel • $categoryLabel',
                    style: t.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Text(
              amountLabel,
              style: t.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

