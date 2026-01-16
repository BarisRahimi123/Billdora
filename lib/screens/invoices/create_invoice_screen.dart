import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClient;
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  final List<Map<String, dynamic>> _lineItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addLineItem();
  }

  void _addLineItem() {
    setState(() {
      _lineItems.add({
        'description': TextEditingController(),
        'quantity': TextEditingController(text: '1'),
        'rate': TextEditingController(),
      });
    });
  }

  void _removeLineItem(int index) {
    if (_lineItems.length > 1) {
      setState(() {
        _lineItems[index]['description'].dispose();
        _lineItems[index]['quantity'].dispose();
        _lineItems[index]['rate'].dispose();
        _lineItems.removeAt(index);
      });
    }
  }

  double get _total {
    double sum = 0;
    for (var item in _lineItems) {
      final qty = double.tryParse(item['quantity'].text) ?? 0;
      final rate = double.tryParse(item['rate'].text) ?? 0;
      sum += qty * rate;
    }
    return sum;
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Save to Supabase
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice created successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('New Invoice'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveInvoice,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Client Selection
            Text(
              'Client',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedClient,
              decoration: const InputDecoration(
                hintText: 'Select a client',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: ['Client 1', 'Client 2', 'Client 3'].map((client) {
                return DropdownMenuItem(value: client, child: Text(client));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedClient = value);
              },
            ),
            const SizedBox(height: 24),

            // Dates
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invoice Date', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _invoiceDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() => _invoiceDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            '${_invoiceDate.month}/${_invoiceDate.day}/${_invoiceDate.year}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Due Date', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() => _dueDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            '${_dueDate.month}/${_dueDate.day}/${_dueDate.year}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Line Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Line Items', style: Theme.of(context).textTheme.titleSmall),
                TextButton.icon(
                  onPressed: _addLineItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_lineItems.length, (index) {
              return _buildLineItemCard(index, colorScheme);
            }),
            const SizedBox(height: 24),

            // Total
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '\$${_total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Notes
            Text('Notes', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add any notes or payment instructions...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItemCard(int index, ColorScheme colorScheme) {
    final item = _lineItems[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item['description'],
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                if (_lineItems.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    onPressed: () => _removeLineItem(index),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item['quantity'],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: item['rate'],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Rate',
                      prefixText: '\$ ',
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
