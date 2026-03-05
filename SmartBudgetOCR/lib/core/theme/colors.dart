import 'package:flutter/material.dart';

/// Centralized color palette for the application.
/// These colors follow the design guidelines provided by the user:
/// * Primary: teal/emerald
/// * Accent: indigo
/// * Background: light grey
class AppColors {
  AppColors._();

  /// Primary Color: #0F766E (Emerald teal)
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryContainer = Color(0xFF99F6E4);

  /// Accent Color: #4F46E5 (Indigo)
  static const Color secondary = Color(0xFF4F46E5);
  static const Color secondaryContainer = Color(0xFFC7D2FE);

  /// Background: #F8FAFC
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;
  static const Color divider = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF1E293B); // Dark slate
  static const Color textMuted = Color(0xFF475569); // Darker muted shade

  static const Color error = Color(0xFFB00020);

  // Add any additional semantic colors here as needed.
}
