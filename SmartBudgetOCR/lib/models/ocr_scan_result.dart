import 'expense_item.dart';

/// Result from POST /ocr/scan - editable preview before confirming expense.
class OcrScanResult {
  const OcrScanResult({
    required this.vendorName,
    required this.items,
    this.categoryTotals = const {},
    required this.subtotal,
    this.tax = 0,
    required this.total,
  });

  factory OcrScanResult.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return OcrScanResult(
      vendorName: json['vendor_name'] as String? ?? 'Unknown',
      items: itemsList
          .map((e) => ExpenseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      categoryTotals:
          Map<String, dynamic>.from(json['category_totals'] as Map? ?? {}),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }

  final String vendorName;
  final List<ExpenseItem> items;
  final Map<String, dynamic> categoryTotals;
  final double subtotal;
  final double tax;
  final double total;

  Map<String, dynamic> toJson() => {
        'vendor_name': vendorName,
        'items': items.map((e) => e.toJson()).toList(),
        'category_totals': categoryTotals,
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
      };

  OcrScanResult copyWith({
    String? vendorName,
    List<ExpenseItem>? items,
    Map<String, dynamic>? categoryTotals,
    double? subtotal,
    double? tax,
    double? total,
  }) =>
      OcrScanResult(
        vendorName: vendorName ?? this.vendorName,
        items: items ?? this.items,
        categoryTotals: categoryTotals ?? this.categoryTotals,
        subtotal: subtotal ?? this.subtotal,
        tax: tax ?? this.tax,
        total: total ?? this.total,
      );
}
