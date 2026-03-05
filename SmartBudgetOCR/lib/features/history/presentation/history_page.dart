import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/expense_card.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String _query = '';
  String? _categoryFilter;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authServiceProvider);
    final user = auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view history.')),
      );
    }

    final receiptsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('receipts')
        .orderBy('created_at', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: Column(
        children: [
          _buildFilters(context),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: receiptsRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return EmptyState(
                    title: 'Couldn’t load receipts',
                    message: snapshot.error.toString(),
                    icon: Icons.error_outline,
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const EmptyState(
                    title: 'No receipts yet',
                    message: 'Scan a receipt or add an expense to see it here.',
                    icon: Icons.receipt_long,
                  );
                }

                final filtered = docs.where(_matchesFilters).toList();
                if (filtered.isEmpty) {
                  return const EmptyState(
                    title: 'No receipts match filters',
                    message: 'Try adjusting your filters or search query.',
                    icon: Icons.filter_alt_off_outlined,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppTokens.s16),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();
                    final vendor = (data['vendor_name'] as String?) ?? 'Unknown';
                    final total =
                        (data['total'] as num?)?.toDouble() ?? 0.0;
                    final ts = data['created_at'] as Timestamp?;
                    final createdAt = ts?.toDate();
                    final categoryTotals =
                        Map<String, dynamic>.from(data['category_totals'] as Map? ?? {});
                    final topCategory = _topCategory(categoryTotals);

                    return Dismissible(
                      key: ValueKey(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding:
                            const EdgeInsets.symmetric(horizontal: AppTokens.s16),
                        color: Colors.redAccent,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async =>
                          await _confirmDelete(context, vendor),
                      onDismissed: (_) => doc.reference.delete(),
                      child: ExpenseCard(
                        vendorName: vendor,
                        dateLabel: _formatDate(createdAt),
                        amountLabel: _formatMoney(total),
                        categoryLabel: topCategory ?? '—',
                        categoryIcon: Icons.receipt_long_outlined,
                      ),
                    );
                  },
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppTokens.s12),
                  itemCount: filtered.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s16,
        AppTokens.s8,
        AppTokens.s16,
        AppTokens.s8,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search vendor or items',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              IconButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final lastMonth =
                      DateTime(now.year, now.month - 1, now.day);
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 2),
                    lastDate: now,
                    initialDateRange:
                        _dateRange ?? DateTimeRange(start: lastMonth, end: now),
                  );
                  if (picked != null) {
                    setState(() => _dateRange = picked);
                  }
                },
                icon: const Icon(Icons.date_range_outlined),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: _categoryFilter == null,
                  onTap: () => setState(() => _categoryFilter = null),
                ),
                const SizedBox(width: AppTokens.s8),
                for (final cat in const [
                  'Food',
                  'Grocery',
                  'Travel',
                  'Entertainment',
                  'Other'
                ]) ...[
                  _CategoryChip(
                    label: cat,
                    selected: _categoryFilter == cat,
                    onTap: () => setState(() => _categoryFilter = cat),
                  ),
                  const SizedBox(width: AppTokens.s8),
                ],
                if (_dateRange != null)
                  Padding(
                    padding: const EdgeInsets.only(left: AppTokens.s4),
                    child: ActionChip(
                      label: Text(
                        '${_dateRange!.start.day}/${_dateRange!.start.month} — '
                        '${_dateRange!.end.day}/${_dateRange!.end.month}',
                        style: t.textTheme.bodySmall,
                      ),
                      onPressed: () {
                        setState(() => _dateRange = null);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesFilters(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final vendor = (data['vendor_name'] as String?) ?? '';
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => (e as Map<String, dynamic>)['name'] as String? ?? '')
        .join(' ')
        .toLowerCase();
    final haystack = '$vendor $items'.toLowerCase();

    if (_query.isNotEmpty && !haystack.contains(_query.toLowerCase())) {
      return false;
    }

    final ts = data['created_at'] as Timestamp?;
    final createdAt = ts?.toDate();
    if (_dateRange != null && createdAt != null) {
      if (createdAt.isBefore(_dateRange!.start) ||
          createdAt.isAfter(_dateRange!.end)) {
        return false;
      }
    }

    if (_categoryFilter != null) {
      final categoryTotals =
          Map<String, dynamic>.from(data['category_totals'] as Map? ?? {});
      if (!categoryTotals.keys
          .map((k) => k.toString().toLowerCase())
          .any((k) => k.contains(_categoryFilter!.toLowerCase()))) {
        return false;
      }
    }

    return true;
  }

  Future<bool> _confirmDelete(BuildContext context, String vendor) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete receipt'),
              content: Text(
                'Delete receipt from "$vendor"? This cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

String _formatMoney(double amount) => '\$${amount.toStringAsFixed(2)}';

String _formatDate(DateTime? dt) {
  if (dt == null) return '—';
  return '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

String? _topCategory(Map<String, dynamic> categoryTotals) {
  if (categoryTotals.isEmpty) return null;
  String? bestKey;
  double bestValue = -1;
  categoryTotals.forEach((key, value) {
    final v = (value as num?)?.toDouble() ?? 0;
    if (v > bestValue) {
      bestKey = key.toString();
      bestValue = v;
    }
  });
  return bestKey;
}

