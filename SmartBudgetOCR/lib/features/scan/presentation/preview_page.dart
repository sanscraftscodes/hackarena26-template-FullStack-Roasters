import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../models/ocr_scan_result.dart';
import '../../../models/expense_create.dart';
import '../../../models/local_expense.dart';
import '../../../models/expense_item.dart';

/// Preview page after OCR scan. Data is passed via the router's `extra` map.
/// Shows editable items with category dropdown, then confirms to save expense.
class PreviewPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? data;
  const PreviewPage({super.key, this.data});

  @override
  ConsumerState<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends ConsumerState<PreviewPage> {
  late OcrScanResult _result;
  late final TextEditingController _vendorController;
  late final List<TextEditingController> _nameControllers;
  late final List<TextEditingController> _priceControllers;
  late final List<String?> _categoryValues;
  bool _loading = false;
  String? _error;

  // TODO: Replace with backend endpoint for categories
  final List<String> _categories = [
    'Food',
    'Transport',
    'Entertainment',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _result = OcrScanResult.fromJson(widget.data ?? {});
    _vendorController = TextEditingController(text: _result.vendorName);
    _nameControllers = _result.items
        .map((e) => TextEditingController(text: e.name))
        .toList();
    _priceControllers = _result.items
        .map((e) => TextEditingController(text: e.unitPrice.toStringAsFixed(2)))
        .toList();
    _categoryValues = _result.items
        .map((e) => e.category.isEmpty ? null : e.category)
        .toList();
  }

  @override
  void dispose() {
    _vendorController.dispose();
    for (final c in _nameControllers) {
      c.dispose();
    }
    for (final c in _priceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final rebuilt = _rebuildResultFromControllers();
    final expense = ExpenseCreate(
      vendorName: rebuilt.vendorName,
      items: rebuilt.items,
      categoryTotals: rebuilt.categoryTotals,
      subtotal: rebuilt.subtotal,
      tax: rebuilt.tax,
      total: rebuilt.total,
      source: 'OCR',
      mode: 'online', // FUTURE: Add offline detection
    );
    try {
      // TODO: connect backend API
      final api = ref.read(apiClientProvider);
      final response = await api.createExpense(expense);
      if (!mounted) return;
      if (response.success) {
        // ENV CONFIG REQUIRED: Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense saved successfully')),
        );
        context.go(AppRouter.homeDashboard);
      } else {
        setState(() {
          _error = response.errorMessage ?? 'Failed to save';
          _loading = false;
        });
      }
    } catch (e) {
      // Offline fallback
      await _saveOffline(expense);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved offline')));
        context.go(AppRouter.homeDashboard);
      }
    }
  }

  Future<void> _saveOffline(ExpenseCreate expense) async {
    final itemsJson = jsonEncode(expense.items.map((e) => e.toJson()).toList());
    final local = LocalExpense(
      id: null,
      vendorName: expense.vendorName,
      itemsJson: itemsJson,
      subtotal: expense.subtotal,
      tax: expense.tax,
      total: expense.total,
      source: expense.source,
      mode: 'offline',
      isSynced: false,
      createdAt: DateTime.now(),
    );
    final db = ref.read(databaseServiceProvider);
    await db.insertExpense(local);
  }

  @override
  Widget build(BuildContext context) {
    final rebuilt = _rebuildResultFromControllers(allowSetState: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.s16),
        children: [
          if (_error != null) ...[
            EmptyState(
              title: 'Couldn’t save expense',
              message: _error,
              icon: Icons.error_outline,
            ),
            const SizedBox(height: AppTokens.s16),
          ],
          Container(
            padding: const EdgeInsets.all(AppTokens.s16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppTokens.cardRadius,
              boxShadow: AppTokens.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Receipt details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTokens.s12),
                TextField(
                  controller: _vendorController,
                  enabled: !_loading,
                  decoration: const InputDecoration(labelText: 'Vendor'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppTokens.s12),
                Row(
                  children: [
                    Expanded(
                      child: _StatPill(
                        label: 'Items',
                        value: rebuilt.items.length.toString(),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: _StatPill(
                        label: 'Total',
                        value: _formatMoney(rebuilt.total),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Text(
            'Extracted items',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTokens.s12),
          if (_nameControllers.isEmpty)
            const EmptyState(
              title: 'No items found',
              message: 'Try rescanning with a clearer photo.',
              icon: Icons.search_off,
            )
          else
            Column(
              children: List.generate(_nameControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.s12),
                  child: Container(
                    padding: const EdgeInsets.all(AppTokens.s16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppTokens.cardRadius,
                      boxShadow: AppTokens.softShadow,
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameControllers[index],
                          enabled: !_loading,
                          decoration: const InputDecoration(labelText: 'Item'),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AppTokens.s12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _priceControllers[index],
                                enabled: !_loading,
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                  prefixText: '\$',
                                ),
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: AppTokens.s12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _categoryValues[index],
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                ),
                                items: _categories
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _loading
                                    ? null
                                    : (v) => setState(
                                          () => _categoryValues[index] = v,
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          const SizedBox(height: AppTokens.s8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : () => context.go(AppRouter.homeScan),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: PrimaryButton(
                  onPressed: _loading ? null : _confirm,
                  loading: _loading,
                  child: const Text('Save Expense'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s32),
          Text(
            'ENV CONFIG REQUIRED: Set `BASE_URL` via --dart-define.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }

  OcrScanResult _rebuildResultFromControllers({bool allowSetState = true}) {
    final items = <ExpenseItem>[];
    for (var i = 0; i < _nameControllers.length; i++) {
      final name = _nameControllers[i].text.trim();
      final unit = double.tryParse(_priceControllers[i].text.trim()) ?? 0;
      final cat = _categoryValues[i] ?? 'Other';
      items.add(
        ExpenseItem(
          name: name.isEmpty ? 'Item' : name,
          unitPrice: unit,
          totalPrice: unit,
          category: cat,
          quantity: 1.0,
        ),
      );
    }

    final total = items.fold<double>(0, (s, it) => s + it.totalPrice);
    final totals = <String, dynamic>{};
    for (final it in items) {
      totals[it.category] = (totals[it.category] ?? 0) + it.totalPrice;
    }

    final rebuilt = _result.copyWith(
      vendorName: _vendorController.text.trim(),
      items: items,
      subtotal: total,
      tax: 0,
      total: total,
      categoryTotals: totals,
    );
    if (allowSetState && rebuilt != _result) {
      _result = rebuilt;
    }
    return rebuilt;
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color: t.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: t.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          Text(
            value,
            style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

String _formatMoney(double amount) => '\$${amount.toStringAsFixed(2)}';
