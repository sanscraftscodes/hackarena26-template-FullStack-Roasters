import 'package:flutter/material.dart';

/// A full-screen loading overlay that can be displayed on top of any
/// scaffold or container. Useful for blocking UI during async operations.
class LoadingOverlay extends StatelessWidget {
  final bool visible;
  final Widget child;

  const LoadingOverlay({super.key, required this.visible, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (visible)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
