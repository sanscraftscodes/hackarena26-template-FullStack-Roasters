import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_locator.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/firestore_service.dart';
import '../../models/local_expense.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final authServiceProvider = Provider<AuthService>((ref) => ServiceLocator.auth);
final apiClientProvider = Provider<ApiClient>((ref) => ServiceLocator.api);
final databaseServiceProvider = Provider<DatabaseService>(
  (ref) => ServiceLocator.database,
);
final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => ServiceLocator.firestore,
);

/// Connectivity status for showing offline banners.
final connectivityProvider =
    StreamProvider.autoDispose<List<ConnectivityResult>>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged;
});

/// Streams the current Firebase user. UI can watch and react accordingly.
final authStateProvider = StreamProvider.autoDispose((ref) {
  return ServiceLocator.auth.authStateChanges;
});

/// A provider that fetches analytics from the backend. Used on dashboard/
/// analytics pages.
final analyticsProvider = StreamProvider.autoDispose<Map<String, dynamic>?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final user = authService.currentUser;
  
  if (user == null) return Stream.value(null);
  
  final now = DateTime.now();
  final monthId = '${now.year}_${now.month.toString().padLeft(2, '0')}';
  return firestoreService.streamAnalytics(user.uid, monthId);
});

/// Recent transactions (local/offline-first).
final recentExpensesProvider =
    FutureProvider.autoDispose<List<LocalExpense>>((ref) async {
  final db = ref.read(databaseServiceProvider);
  // TODO: connect backend API (merge online + offline transactions)
  return db.getAllExpenses();
});

// TODO: add additional providers like expenses, report generation, etc.
