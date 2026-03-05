import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/expense_item.dart';
import '../models/local_expense.dart';

/// SQLite database for offline storage. Includes is_synced flag.
class DatabaseService {
  static const String _dbName = 'snapbudget.db';
  static const int _version = 1;

  static const String _tableExpenses = 'expenses';

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = await getDatabasesPath();
    return openDatabase(
      join(path, _dbName),
      version: _version,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableExpenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vendor_name TEXT NOT NULL,
        items_json TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        total REAL NOT NULL,
        source TEXT NOT NULL DEFAULT 'OCR',
        mode TEXT NOT NULL DEFAULT 'offline',
        is_synced INTEGER NOT NULL DEFAULT 0,
        synced_at INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertExpense(LocalExpense expense) async {
    final db = await _database;
    return db.insert(_tableExpenses, {
      'vendor_name': expense.vendorName,
      'items_json': expense.itemsJson,
      'subtotal': expense.subtotal,
      'tax': expense.tax,
      'total': expense.total,
      'source': expense.source,
      'mode': expense.mode,
      'is_synced': expense.isSynced ? 1 : 0,
      'synced_at': expense.syncedAt?.millisecondsSinceEpoch,
      'created_at': (expense.createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    });
  }

  Future<void> updateSynced(int id) async {
    final db = await _database;
    await db.update(
      _tableExpenses,
      {'is_synced': 1, 'synced_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<LocalExpense>> getUnsyncedExpenses() async {
    final db = await _database;
    final rows = await db.query(
      _tableExpenses,
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    return rows.map(_rowToExpense).toList();
  }

  Future<List<LocalExpense>> getAllExpenses() async {
    final db = await _database;
    final rows = await db.query(_tableExpenses, orderBy: 'created_at DESC');
    return rows.map(_rowToExpense).toList();
  }

  LocalExpense _rowToExpense(Map<String, dynamic> row) {
    return LocalExpense(
      id: row['id'] as int?,
      vendorName: row['vendor_name'] as String,
      itemsJson: row['items_json'] as String,
      subtotal: (row['subtotal'] as num).toDouble(),
      tax: (row['tax'] as num).toDouble(),
      total: (row['total'] as num).toDouble(),
      source: row['source'] as String? ?? 'OCR',
      mode: row['mode'] as String? ?? 'offline',
      isSynced: (row['is_synced'] as int) == 1,
      syncedAt: row['synced_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['synced_at'] as int)
          : null,
      createdAt: row['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int)
          : null,
    );
  }

  /// Convert items_json to list of ExpenseItem
  List<ExpenseItem> parseItems(String itemsJson) {
    try {
      final list = jsonDecode(itemsJson) as List<dynamic>;
      return list
          .map((e) => ExpenseItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
