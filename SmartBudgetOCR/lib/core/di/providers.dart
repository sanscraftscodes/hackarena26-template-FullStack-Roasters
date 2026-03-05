import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_locator.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/local_expense.dart';

final authServiceProvider = Provider<AuthService>((ref) => ServiceLocator.auth);
final apiClientProvider = Provider<ApiClient>((ref) => ServiceLocator.api);
final databaseServiceProvider = Provider<DatabaseService>(
  (ref) => ServiceLocator.database,
);

/// Streams the current Firebase user. UI can watch and react accordingly.
final authStateProvider = StreamProvider.autoDispose((ref) {
  return ServiceLocator.auth.authStateChanges;
});

/// A provider that fetches analytics from the backend. Used on dashboard/
/// analytics pages.
final analyticsProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((
  ref,
) async {
  final response = await ServiceLocator.api.getAnalytics();
  if (response.success) return response.data;
  throw Exception(response.errorMessage ?? 'Failed to load analytics');
});

/// Recent transactions (local/offline-first).
final recentExpensesProvider =
    FutureProvider.autoDispose<List<LocalExpense>>((ref) async {
  final db = ref.read(databaseServiceProvider);
  // TODO: connect backend API (merge online + offline transactions)
  return db.getAllExpenses();
});

// TODO: add additional providers like expenses, report generation, etc.
