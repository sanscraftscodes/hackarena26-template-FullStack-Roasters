import 'package:flutter/material.dart';

/// Design tokens for consistent spacing, radii and shadows.
/// Spacing follows an 8px grid.
class AppTokens {
  AppTokens._();

  // Spacing (8px grid)
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;

  // Radius
  static const double r16 = 16;
  static const double r12 = 12;

  static BorderRadius get cardRadius => BorderRadius.circular(r16);
  static BorderRadius get inputRadius => BorderRadius.circular(r16);

  // Soft shadows
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
}

