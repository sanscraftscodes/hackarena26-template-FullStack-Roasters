import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/tokens.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTokens.cardRadius,
            boxShadow: AppTokens.softShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: AppColors.textMuted),
              const SizedBox(height: AppTokens.s16),
              Text(
                title,
                style: t.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: AppTokens.s8),
                Text(
                  message!,
                  style: t.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppTokens.s16),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

