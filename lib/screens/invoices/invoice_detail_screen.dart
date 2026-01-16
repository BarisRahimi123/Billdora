import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Invoice #INV-$invoiceId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share invoice
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            onSelected: (value) {
              // TODO: Handle actions
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.pending_actions, color: Colors.orange),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Payment',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      Text(
                        'Due in 7 days',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Client Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bill To',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Acme Corporation',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Text('123 Business St'),
                    const Text('New York, NY 10001'),
                    const Text('contact@acme.com'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Invoice Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow('Invoice Date', 'Jan 15, 2026'),
                    const Divider(),
                    _buildDetailRow('Due Date', 'Jan 30, 2026'),
                    const Divider(),
                    _buildDetailRow('Invoice Number', 'INV-$invoiceId'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Line Items
            Text(
              'Items',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  _buildLineItem('Web Design Services', 'Design and development', 1500.00, currencyFormat),
                  const Divider(height: 1),
                  _buildLineItem('Monthly Hosting', '3 months', 150.00, currencyFormat),
                  const Divider(height: 1),
                  _buildLineItem('Domain Registration', '1 year', 50.00, currencyFormat),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Totals
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTotalRow('Subtotal', currencyFormat.format(1700), colorScheme),
                    const SizedBox(height: 8),
                    _buildTotalRow('Tax (10%)', currencyFormat.format(170), colorScheme),
                    const Divider(),
                    _buildTotalRow('Total', currencyFormat.format(1870), colorScheme, isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Send invoice / record payment
        },
        icon: const Icon(Icons.send),
        label: const Text('Send Invoice'),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLineItem(String title, String description, double amount, NumberFormat format) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(description, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          Text(format.format(amount), style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, ColorScheme colorScheme, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 20 : 14,
            color: isTotal ? colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}
