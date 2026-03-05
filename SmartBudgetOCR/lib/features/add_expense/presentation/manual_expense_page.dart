import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/ocr_scan_result.dart';
import '../../../services/manual_service.dart';

class ManualExpensePage extends ConsumerStatefulWidget {
  const ManualExpensePage({super.key});

  @override
  ConsumerState<ManualExpensePage> createState() => _ManualExpensePageState();
}

class _ManualExpensePageState extends ConsumerState<ManualExpensePage> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Enter at least one expense.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final service = ManualService(apiClient: api);
      final OcrScanResult result = await service.parseManualText(text);
      if (!mounted) return;
      context.go(AppRouter.homePreview, extra: result.toJson());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual expense'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.s16),
        children: [
          if (_error != null) ...[
            EmptyState(
              title: 'Couldn’t parse expense',
              message: _error,
              icon: Icons.error_outline,
            ),
            const SizedBox(height: AppTokens.s16),
          ],
          Text(
            'Enter your expenses',
            style: t.textTheme.titleMedium,
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            'Example: "Spent 200 on groceries and 150 on transport".',
            style: t.textTheme.bodySmall,
          ),
          const SizedBox(height: AppTokens.s16),
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Describe what you spent...',
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          PrimaryButton(
            onPressed: _loading ? null : _submit,
            loading: _loading,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

