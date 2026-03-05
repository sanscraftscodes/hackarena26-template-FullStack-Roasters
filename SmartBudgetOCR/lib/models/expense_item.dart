/// Line item for an expense/receipt.
class ExpenseItem {
  const ExpenseItem({
    required this.name,
    this.quantity = 1.0,
    required this.unitPrice,
    required this.totalPrice,
    required this.category,
    this.confidenceScore = 1.0,
  });

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    return ExpenseItem(
      name: json['name'] as String? ?? 'Unknown',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? 'Other',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 1.0,
    );
  }

  final String name;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final String category;
  final double confidenceScore;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
        'category': category,
        'confidence_score': confidenceScore,
      };

  ExpenseItem copyWith({
    String? name,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
    String? category,
    double? confidenceScore,
  }) =>
      ExpenseItem(
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        totalPrice: totalPrice ?? this.totalPrice,
        category: category ?? this.category,
        confidenceScore: confidenceScore ?? this.confidenceScore,
      );
}
