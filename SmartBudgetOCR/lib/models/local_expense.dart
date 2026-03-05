/// Local expense for offline storage. Has is_synced flag for background sync.
class LocalExpense {
  const LocalExpense({
    required this.id,
    required this.vendorName,
    required this.itemsJson,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.source,
    required this.mode,
    required this.isSynced,
    this.syncedAt,
    this.createdAt,
  });

  final int? id;
  final String vendorName;
  final String itemsJson;
  final double subtotal;
  final double tax;
  final double total;
  final String source;
  final String mode;
  final bool isSynced;
  final DateTime? syncedAt;
  final DateTime? createdAt;
}
