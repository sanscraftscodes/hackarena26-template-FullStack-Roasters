import 'package:flutter/material.dart';

import '../../../models/local_expense.dart';

/// Simple list of recent expenses. Replace with real data source.
class ExpenseList extends StatelessWidget {
  final List<LocalExpense> expenses;
  const ExpenseList({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Center(child: Text('No recent expenses'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final e = expenses[index];
        return Card(
          child: ListTile(
            title: Text(e.vendorName),
            subtitle: Text('\$${e.total.toStringAsFixed(2)}'),
          ),
        );
      },
    );
  }
}
