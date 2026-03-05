import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense_create.dart';
import '../models/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveReceipt(ExpenseCreate expense, String uid) async {
    final now = DateTime.now();
    final monthId = '${now.year}_${now.month.toString().padLeft(2, '0')}';

    final receiptRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('receipts')
        .doc();

    final analyticsRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('analytics')
        .doc(monthId);

    await _firestore.runTransaction((transaction) async {
      // Create receipt document
      transaction.set(receiptRef, {
        'vendor_name': expense.vendorName,
        'subtotal': expense.subtotal,
        'tax': expense.tax,
        'total': expense.total,
        'created_at': FieldValue.serverTimestamp(),
        'items': expense.items
            .map((e) => {
                  'name': e.name,
                  'quantity': e.quantity,
                  'unit_price': e.unitPrice,
                  'total_price': e.totalPrice,
                  'category': e.category,
                })
            .toList(),
        'category_totals': expense.categoryTotals,
      });

      // Update analytics document
      final analyticsSnapshot = await transaction.get(analyticsRef);

      if (!analyticsSnapshot.exists) {
        transaction.set(analyticsRef, {
          'total_spent': expense.total,
          'receipt_count': 1,
          'category_spending': expense.categoryTotals,
          'vendor_spending': {expense.vendorName: expense.total},
        });
      } else {
        final data = analyticsSnapshot.data()!;
        final currentTotalSpent =
            (data['total_spent'] as num?)?.toDouble() ?? 0.0;
        final currentReceiptCount = (data['receipt_count'] as int?) ?? 0;

        final Map<String, dynamic> currentCategorySpending =
            Map<String, dynamic>.from(data['category_spending'] as Map? ?? {});

        final Map<String, dynamic> currentVendorSpending =
            Map<String, dynamic>.from(data['vendor_spending'] as Map? ?? {});

        // Update categories
        expense.categoryTotals.forEach((key, value) {
          final current =
              (currentCategorySpending[key] as num?)?.toDouble() ?? 0.0;
          currentCategorySpending[key] = current + value;
        });

        // Update vendors
        final currentVendor = (currentVendorSpending[expense.vendorName]
                as num?)?.toDouble() ??
            0.0;
        currentVendorSpending[expense.vendorName] = currentVendor + expense.total;

        transaction.update(analyticsRef, {
          'total_spent': currentTotalSpent + expense.total,
          'receipt_count': currentReceiptCount + 1,
          'category_spending': currentCategorySpending,
          'vendor_spending': currentVendorSpending,
        });
      }
    });
  }

  Future<Map<String, dynamic>?> getAnalytics(String uid, String monthId) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('analytics')
        .doc(monthId)
        .get();
    return doc.data();
  }

  Stream<Map<String, dynamic>?> streamAnalytics(String uid, String monthId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('analytics')
        .doc(monthId)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  // --- User Profile ---

  Future<void> saveUserProfile(String uid, UserProfile profile) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .set(profile.toJson(), SetOptions(merge: true));
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return UserProfile.fromJson(doc.data()!);
  }
}

