import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A reusable text input field with consistent styling.
class TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType keyboardType;
  final List<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const TextInput({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.autofillHints,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      onChanged: onChanged,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: AppTokens.inputRadius),
      ),
    );
  }
}
