import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> _invoices = []; // Will be populated from Supabase
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInvoices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    // TODO: Load from Supabase
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Search invoices
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Filter invoices
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Paid'),
            Tab(text: 'Overdue'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInvoiceList('all', colorScheme),
          _buildInvoiceList('pending', colorScheme),
          _buildInvoiceList('paid', colorScheme),
          _buildInvoiceList('overdue', colorScheme),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/invoices/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }

  Widget _buildInvoiceList(String filter, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Demo data
    final demoInvoices = List.generate(10, (index) => {
      'id': 'inv-$index',
      'number': 'INV-${1000 + index}',
      'client': 'Client ${index + 1}',
      'amount': (index + 1) * 250.0,
      'status': index % 3 == 0 ? 'paid' : (index % 3 == 1 ? 'pending' : 'overdue'),
      'date': DateTime.now().subtract(Duration(days: index * 3)),
    });

    final filteredInvoices = filter == 'all'
        ? demoInvoices
        : demoInvoices.where((inv) => inv['status'] == filter).toList();

    if (filteredInvoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No ${filter == 'all' ? '' : filter} invoices',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInvoices,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredInvoices.length,
        itemBuilder: (context, index) {
          final invoice = filteredInvoices[index];
          return _buildInvoiceCard(invoice, colorScheme);
        },
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice, ColorScheme colorScheme) {
    final status = invoice['status'] as String;
    final statusColor = status == 'paid'
        ? Colors.green
        : (status == 'pending' ? Colors.orange : Colors.red);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/invoices/${invoice['id']}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  (invoice['client'] as String).substring(0, 1),
                  style: TextStyle(color: colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice['number'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoice['client'] as String,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat.currency(symbol: '\$').format(invoice['amount']),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
