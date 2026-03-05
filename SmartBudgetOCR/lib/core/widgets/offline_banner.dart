import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/tokens.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.isOffline});

  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.14),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppTokens.r16),
          bottomRight: Radius.circular(AppTokens.r16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 18, color: Colors.amber),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              'You\'re offline. New expenses will sync when you\'re back online.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

