// App configuration. Do NOT hardcode backend URL.
// TODO: Replace BASE_URL - e.g. flutter run --dart-define=BASE_URL=https://api.example.com
// ENV CONFIG REQUIRED

class AppConfig {
  AppConfig._();

  /// Backend base URL. Set via environment/flavor.
  /// TODO: Replace BASE_URL - e.g. from --dart-define=BASE_URL=https://api.example.com
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static String get ocrScanUrl => '$baseUrl${_Paths.ocrScan}';
  static String get expensesUrl => '$baseUrl${_Paths.expenses}';
  static String get analyticsUrl => '$baseUrl${_Paths.analytics}';
  static String get predictionUrl => '$baseUrl${_Paths.prediction}';
  static String get reportUrl => '$baseUrl${_Paths.report}';
}

abstract class _Paths {
  static const ocrScan = '/ocr/scan';
  static const expenses = '/expenses';
  static const analytics = '/analytics';
  static const prediction = '/prediction';
  static const report = '/report';
}
