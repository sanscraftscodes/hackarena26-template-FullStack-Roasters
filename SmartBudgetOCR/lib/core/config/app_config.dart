// App configuration. Do NOT hardcode backend URL.
// TODO: Replace BASE_URL - e.g. flutter run --dart-define=BASE_URL=https://api.example.com
// ENV CONFIG REQUIRED

class AppConfig {
  AppConfig._();

  /// Backend base URL. Set via environment/flavor.
  /// To run locally: flutter run --dart-define=BASE_URL=http://localhost:8000
  /// To run with ngrok: flutter run --dart-define=BASE_URL=https://gasifiable-troublous-waltraud.ngrok-free.dev
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://gasifiable-troublous-waltraud.ngrok-free.dev',
  );

  // Receipt / expense APIs
  static String get ocrScanUrl => '$baseUrl${_Paths.scanReceipt}';
  static String get voiceExpenseUrl => '$baseUrl${_Paths.voiceExpense}';
  static String get manualExpenseUrl => '$baseUrl${_Paths.manualExpense}';

  // Health
  static String get healthUrl => '$baseUrl${_Paths.health}';
}

abstract class _Paths {
  static const scanReceipt = '/scan_receipt';
  static const voiceExpense = '/voice_expense';
  static const manualExpense = '/manual_expense';
  static const health = '/health';
}
