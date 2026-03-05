import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/scan_button.dart';

/// Scan flow: 1) Capture 2) Send to /ocr/scan 3) Editable preview 4) Confirm → POST /expenses 5) Refresh dashboard
class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  final _picker = ImagePicker();
  bool _loading = false;
  String? _error;

  Future<void> _captureAndScan() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // TODO: connect backend API (ensure BASE_URL is configured)
      final xfile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (xfile == null || !mounted) {
        setState(() => _loading = false);
        return;
      }
      final bytes = await xfile.readAsBytes();
      final api = ref.read(apiClientProvider);
      final response = await api.ocrScan(bytes);
      if (!mounted) return;
      if (response.success && response.data != null) {
        // navigate to preview screen
        context.go(AppRouter.homePreview, extra: response.data!.toJson());
      } else {
        setState(() {
          _error = response.errorMessage ?? 'OCR failed';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEFF6FF), AppColors.background],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(AppTokens.s16),
            children: [
              if (_error != null) ...[
                EmptyState(
                  title: 'Scan failed',
                  message: _error,
                  icon: Icons.error_outline,
                  action: TextButton(
                    onPressed: _loading ? null : _captureAndScan,
                    child: const Text('Try again'),
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
              ],
              ScanButton(onPressed: _captureAndScan, loading: _loading),
              const SizedBox(height: AppTokens.s16),
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
                      'How it works',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTokens.s12),
                    const _StepRow(
                      index: 1,
                      title: 'Capture receipt',
                      subtitle: 'Use your camera for best results.',
                      icon: Icons.camera_alt_outlined,
                    ),
                    const SizedBox(height: AppTokens.s12),
                    const _StepRow(
                      index: 2,
                      title: 'Upload & extract',
                      subtitle: 'We send it to `/ocr/scan` and parse line items.',
                      icon: Icons.cloud_upload_outlined,
                    ),
                    const SizedBox(height: AppTokens.s12),
                    const _StepRow(
                      index: 3,
                      title: 'Review & save',
                      subtitle: 'Edit items, set categories, and save expense.',
                      icon: Icons.edit_note_outlined,
                    ),
                    const SizedBox(height: AppTokens.s12),
                    Text(
                      'FUTURE: SMS expense detection',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.s32),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final int index;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: t.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              index.toString(),
              style: t.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: t.colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: t.colorScheme.primary),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: Text(
                      title,
                      style: t.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s4),
              Text(
                subtitle,
                style: t.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
