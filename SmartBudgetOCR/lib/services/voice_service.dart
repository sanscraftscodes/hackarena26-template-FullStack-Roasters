import '../core/api/api_response.dart';
import '../models/ocr_scan_result.dart';
import 'api_client.dart';

/// High-level service for voice-based expenses.
///
/// The UI sends transcribed text, this service calls the FastAPI
/// `/voice_expense` endpoint via [ApiClient] and returns structured data.
class VoiceService {
  VoiceService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<OcrScanResult> parseVoiceText(String text) async {
    final ApiResponse<OcrScanResult> res = await _api.voiceExpense(text);
    if (!res.success || res.data == null) {
      throw Exception(res.error?['message'] ?? 'Failed to parse voice expense');
    }
    return res.data!;
  }
}

