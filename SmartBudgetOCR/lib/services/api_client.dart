import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/api/api_response.dart';
import '../core/config/app_config.dart';
import '../models/ocr_scan_result.dart';
import 'auth_service.dart';

/// API client. Always sends Authorization: Bearer [Firebase ID token].
/// Never sends user_id manually.
class ApiClient {
  ApiClient({required AuthService authService})
      : _auth = authService,
        _dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl)) {
    _dio.interceptors.add(_AuthInterceptor(_auth));
  }

  final AuthService _auth;
  final Dio _dio;

  /// POST /scan_receipt - returns structured receipt for editable preview
  Future<ApiResponse<OcrScanResult>> ocrScan(List<int> imageBytes) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        imageBytes,
        filename: 'receipt.jpg',
      ),
    });
    final response = await _dio.post(
      AppConfig.ocrScanUrl,
      data: formData,
    );
    return _parseResponse(
      response,
      (data) => OcrScanResult.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST /voice_expense - parse free‑form voice text into structured receipt.
  Future<ApiResponse<OcrScanResult>> voiceExpense(String text) async {
    final response = await _dio.post(
      AppConfig.voiceExpenseUrl,
      data: {'text': text},
    );
    return _parseResponse(
      response,
      (data) => OcrScanResult.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST /manual_expense - parse manual free‑form entry into structured receipt.
  Future<ApiResponse<OcrScanResult>> manualExpense(String text) async {
    final response = await _dio.post(
      AppConfig.manualExpenseUrl,
      data: {'text': text},
    );
    return _parseResponse(
      response,
      (data) => OcrScanResult.fromJson(data as Map<String, dynamic>),
    );
  }

  /// GET /health - simple health check.
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get(AppConfig.healthUrl);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  ApiResponse<T> _parseResponse<T>(
    Response<dynamic> response,
    T Function(dynamic) fromJson,
  ) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      return ApiResponse.fromJson(body, (v) => fromJson(v));
    }
    if (body is String) {
      final map = jsonDecode(body) as Map<String, dynamic>;
      return ApiResponse.fromJson(map, (v) => fromJson(v));
    }
    return ApiResponse(success: false, error: {'message': 'Invalid response'});
  }
}

/// Interceptor that adds Authorization: Bearer [token] to every request.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._auth);

  final AuthService _auth;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _auth.getIdToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
