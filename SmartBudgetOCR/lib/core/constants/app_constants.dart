// App-wide constants. ENV CONFIG REQUIRED: BASE_URL loaded from AppConfig.

class AppConstants {
  AppConstants._();

  static const String appName = 'SnapBudget';

  /// API paths - relative to BASE_URL
  static const String ocrScanPath = '/ocr/scan';
  static const String expensesPath = '/expenses';
  static const String analyticsPath = '/analytics';
  static const String predictionPath = '/prediction';
  static const String reportPath = '/report';
}
