import 'expense_item.dart';

/// Input for POST /expenses. Never includes user_id - backend uses Firebase UID.
/// FUTURE: Add SMS parsing (source: SMS)
class ExpenseCreate {
  const ExpenseCreate({
    required this.vendorName,
    required this.items,
    this.categoryTotals = const {},
    required this.subtotal,
    this.tax = 0,
    required this.total,
    this.source = 'OCR',
    this.mode = 'online',
  });

  final String vendorName;
  final List<ExpenseItem> items;
  final Map<String, dynamic> categoryTotals;
  final double subtotal;
  final double tax;
  final double total;
  final String source;
  final String mode;

  Map<String, dynamic> toJson() => {
        'vendor_name': vendorName,
        'items': items.map((e) => e.toJson()).toList(),
        'category_totals': categoryTotals,
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'source': source,
        'mode': mode,
      };
}
