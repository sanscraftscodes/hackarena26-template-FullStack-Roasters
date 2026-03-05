import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/expense_create.dart';
import '../models/expense_item.dart';
import '../models/local_expense.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'firestore_service.dart';

/// Background sync when internet returns. Syncs unsynced SQLite expenses.
class SyncService {
  SyncService({
    required AuthService authService,
    required DatabaseService databaseService,
    required FirestoreService firestoreService,
    Connectivity? connectivity,
  })  : _auth = authService,
        _db = databaseService,
        _firestore = firestoreService,
        _connectivity = connectivity ?? Connectivity();

  final AuthService _auth;
  final DatabaseService _db;
  final FirestoreService _firestore;
  final Connectivity _connectivity;

  /// Start listening for connectivity changes. Call from main.
  void startConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((_) => syncIfOnline());
  }

  /// Call when app resumes or connectivity returns.
  Future<void> syncIfOnline() async {
    if (_auth.currentUser == null) return;

    final results = await _connectivity.checkConnectivity();
    final isOnline = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);

    if (!isOnline) return;

    final unsynced = await _db.getUnsyncedExpenses();
    for (final local in unsynced) {
      try {
        final items = _db.parseItems(local.itemsJson);
        final expense = ExpenseCreate(
          vendorName: local.vendorName,
          items: items,
          categoryTotals: _parseCategoryTotals(local.itemsJson),
          subtotal: local.subtotal,
          tax: local.tax,
          total: local.total,
          source: local.source,
          mode: 'offline',
        );
        await _firestore.saveReceipt(expense, _auth.currentUser!.uid);
        if (local.id != null) {
          await _db.updateSynced(local.id!);
        }
      } catch (_) {
        // Retry on next sync
      }
    }
  }

  /// Build ExpenseCreate from LocalExpense
  static ExpenseCreate toExpenseCreate(LocalExpense local, List<ExpenseItem> items) {
    return ExpenseCreate(
      vendorName: local.vendorName,
      items: items,
      categoryTotals: _parseCategoryTotals(local.itemsJson),
      subtotal: local.subtotal,
      tax: local.tax,
      total: local.total,
      source: local.source,
      mode: 'offline',
    );
  }

  static Map<String, dynamic> _parseCategoryTotals(String itemsJson) {
    try {
      final list = jsonDecode(itemsJson) as List<dynamic>;
      final map = <String, double>{};
      for (final e in list) {
        final m = e as Map<String, dynamic>;
        final cat = m['category'] as String? ?? 'Other';
        final total = (m['total_price'] as num?)?.toDouble() ?? 0;
        map[cat] = (map[cat] ?? 0) + total;
      }
      return map;
    } catch (_) {
      return {};
    }
  }
}
