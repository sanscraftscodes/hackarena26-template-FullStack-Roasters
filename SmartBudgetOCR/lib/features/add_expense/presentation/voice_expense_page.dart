import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/di/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/ocr_scan_result.dart';
import '../../../services/voice_service.dart';

class VoiceExpensePage extends ConsumerStatefulWidget {
  const VoiceExpensePage({super.key});

  @override
  ConsumerState<VoiceExpensePage> createState() => _VoiceExpensePageState();
}

class _VoiceExpensePageState extends ConsumerState<VoiceExpensePage> {
  final _controller = TextEditingController();
  bool _loading = false;
  bool _listening = false;
  String? _error;
  late stt.SpeechToText _speechToText;

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    try {
      await _speechToText.initialize(
        onError: (error) {
          setState(() {
            _error = 'Microphone error: ${error.errorMsg}';
            _listening = false;
          });
        },
        onStatus: (status) {
          print('Speech status: $status');
        },
      );
    } catch (e) {
      setState(() => _error = 'Could not initialize microphone: $e');
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechToText.isAvailable) {
      setState(() => _error = 'Microphone not available on this device');
      return;
    }

    if (_listening) {
      await _speechToText.stop();
      final text = _speechToText.lastRecognizedWords;
      if (text.isNotEmpty) {
        _controller.text += (_controller.text.isEmpty ? '' : ' ') + text;
      }
    } else {
      setState(() => _error = null);
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            if (result.finalResult) {
              // Final result from speech recognition
              if (result.recognizedWords.isNotEmpty) {
                _controller.text +=
                    (_controller.text.isEmpty ? '' : ' ') +
                    result.recognizedWords;
              }
              _listening = false;
            } else {
              // Interim result
              print('Interim: ${result.recognizedWords}');
            }
          });
        },
        localeId: 'en_US',
      );
    }

    setState(() => _listening = !_listening);
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Describe your expenses first.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final service = VoiceService(apiClient: api);
      final OcrScanResult result = await service.parseVoiceText(text);
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
  void dispose() {
    _controller.dispose();
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Voice expense')),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.s16),
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTokens.s12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: t.textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.s16),
          ],
          Text('Describe your expenses', style: t.textTheme.titleMedium),
          const SizedBox(height: AppTokens.s8),
          Text(
            'Tap the microphone to speak or type your expenses directly.\nExample: "I bought milk for 50 and vegetables for 120".',
            style: t.textTheme.bodySmall,
          ),
          const SizedBox(height: AppTokens.s16),
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Start speaking or type your expenses here...',
              suffixIcon: _listening
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Row(
            children: [
              FloatingActionButton.extended(
                heroTag: null,
                onPressed: _loading ? null : _toggleListening,
                icon: Icon(_listening ? Icons.mic : Icons.mic_none),
                label: Text(_listening ? 'Listening...' : 'Record'),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: PrimaryButton(
                  onPressed: _loading ? null : _submit,
                  loading: _loading,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
