import '../core/api/api_response.dart';
import '../models/ocr_scan_result.dart';
import 'api_client.dart';

/// High-level service for manual free-form expenses.
///
/// The UI sends text like "Milk 50, Bread 30" and this service calls the
/// FastAPI `/manual_expense` endpoint and returns structured items.
class ManualService {
  ManualService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<OcrScanResult> parseManualText(String text) async {
    final ApiResponse<OcrScanResult> res = await _api.manualExpense(text);
    if (!res.success || res.data == null) {
      throw Exception(res.error?['message'] ?? 'Failed to parse manual expense');
    }
    return res.data!;
  }
}

