import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A styled button that matches the app's primary design language.
class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: AppTokens.cardRadius),
        elevation: 0,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: loading ? 0 : 1, child: child),
          if (loading)
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
