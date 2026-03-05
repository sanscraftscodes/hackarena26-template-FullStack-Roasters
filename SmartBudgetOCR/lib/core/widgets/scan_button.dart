import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class ScanButton extends StatelessWidget {
  const ScanButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTokens.cardRadius,
        boxShadow: AppTokens.softShadow,
      ),
      padding: const EdgeInsets.all(AppTokens.s24),
      child: Column(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: FloatingActionButton(
              heroTag: 'scan_button',
              onPressed: loading ? null : onPressed,
              child: loading
                  ? const SizedBox.square(
                      dimension: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.camera_alt, size: 32),
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Text(
            'Scan receipt',
            style: t.textTheme.titleMedium,
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            'Capture and extract items instantly.',
            style: t.textTheme.bodyMedium?.copyWith(
              color: t.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

