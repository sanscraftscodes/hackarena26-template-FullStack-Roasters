import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Lightweight shimmer-like skeleton without extra dependencies.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.height,
    this.width,
    this.radius = AppTokens.r16,
  });

  final double? height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlight = Theme.of(context).colorScheme.surfaceContainerLow;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final dx = -1.0 + (2.0 * t);
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: CustomPaint(
            painter: _ShimmerPainter(
              base: base,
              highlight: highlight,
              dx: dx,
            ),
            child: SizedBox(
              height: widget.height,
              width: widget.width,
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({
    required this.base,
    required this.highlight,
    required this.dx,
  });

  final Color base;
  final Color highlight;
  final double dx;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..color = base;
    canvas.drawRect(rect, paint);

    final shimmerWidth = math.max(48.0, size.width * 0.35);
    final startX = dx * size.width - shimmerWidth;
    final gradientRect = Rect.fromLTWH(startX, 0, shimmerWidth * 2, size.height);

    final g = LinearGradient(
      colors: [
        base.withValues(alpha: 0.0),
        highlight.withValues(alpha: 0.55),
        base.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final shimmerPaint = Paint()..shader = g.createShader(gradientRect);
    canvas.drawRect(rect, shimmerPaint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) {
    return oldDelegate.dx != dx ||
        oldDelegate.base != base ||
        oldDelegate.highlight != highlight;
  }
}

