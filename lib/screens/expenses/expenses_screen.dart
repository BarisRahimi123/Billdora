import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    final demoExpenses = [
      {'description': 'Office Supplies', 'category': 'Operations', 'amount': 125.50, 'date': DateTime.now()},
      {'description': 'Software Subscription', 'category': 'Technology', 'amount': 49.99, 'date': DateTime.now().subtract(const Duration(days: 2))},
      {'description': 'Client Lunch', 'category': 'Meals', 'amount': 85.00, 'date': DateTime.now().subtract(const Duration(days: 5))},
      {'description': 'Travel - Uber', 'category': 'Transportation', 'amount': 32.50, 'date': DateTime.now().subtract(const Duration(days: 7))},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Month',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '\$2,450.00',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.trending_up, color: Colors.white),
                ),
              ],
            ),
          ),

          // Expenses List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: demoExpenses.length,
              itemBuilder: (context, index) {
                final expense = demoExpenses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.secondaryContainer,
                      child: Icon(
                        _getCategoryIcon(expense['category'] as String),
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: Text(
                      expense['description'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '${expense['category']} • ${DateFormat.MMMd().format(expense['date'] as DateTime)}',
                    ),
                    trailing: Text(
                      currencyFormat.format(expense['amount']),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Add expense
        },
        icon: const Icon(Icons.add_card),
        label: const Text('Add Expense'),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'technology':
        return Icons.computer;
      case 'meals':
        return Icons.restaurant;
      case 'transportation':
        return Icons.directions_car;
      case 'operations':
        return Icons.business;
      default:
        return Icons.receipt;
    }
  }
}
