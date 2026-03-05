/// Backend returns: { success: bool, data: object?, error: object? }
/// ApiResponse models this contract with generic data type.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      error: json['error'] as Map<String, dynamic>?,
    );
  }

  final bool success;
  final T? data;
  final Map<String, dynamic>? error;

  String? get errorCode => error?['code'] as String?;
  String? get errorMessage => error?['message'] as String?;
}
