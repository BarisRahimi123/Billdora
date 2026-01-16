import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../main.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock invoice data
  final Map<String, dynamic> _invoice = {
    'id': 'inv1',
    'number': 'INV-274128',
    'client': 'Barzan Shop',
    'clientAddress': 'Clovis, Ca, 93727',
    'clientPhone': '5128396700',
    'period': 'Current Invoice',
    'poNumber': '',
    'terms': 'Net 30',
    'status': 'Sent',
    'draftDate': DateTime(2026, 1, 13),
    'sentDate': DateTime(2026, 1, 14),
    'dueDate': DateTime(2026, 2, 13),
    'amount': 0.0,
    'company': {
      'name': 'Plansrow LLC',
      'address': '2469 N Pearwood ave',
      'city': 'Fresno, CA, 93727',
      'phone': '5128396700',
    },
    'timeEntries': <Map<String, dynamic>>[],
    'expenses': <Map<String, dynamic>>[],
    'history': <Map<String, dynamic>>[],
    'billingType': 'Milestone',
    'tasks': [
      {'name': 'Design Phase', 'prior': 0.0, 'current': 0.0, 'budget': 1000.0, 'amount': 0.0},
      {'name': 'Development', 'prior': 0.0, 'current': 0.0, 'budget': 2000.0, 'amount': 0.0},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.cardBackground,
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Row(
                          children: [
                            const Icon(Icons.chevron_left, size: 20),
                            Text('Back to\nInvoices', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${_invoice['client']} - Draft Date',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              dateFormat.format(_invoice['draftDate']),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 60),
                    ],
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              color: AppColors.cardBackground,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.accent,
                indicatorWeight: 2,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: [
                  const Tab(text: 'Preview'),
                  const Tab(text: 'Invoice\nDetail'),
                  Tab(text: 'Time\n(\$${_invoice['timeEntries'].fold(0.0, (sum, e) => sum + (e['amount'] ?? 0.0)).toStringAsFixed(0)})'),
                  Tab(text: 'Expenses\n(\$${_invoice['expenses'].fold(0.0, (sum, e) => sum + (e['amount'] ?? 0.0)).toStringAsFixed(0)})'),
                  Tab(text: 'History\n(${_invoice['history'].length})'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPreviewTab(),
                  _buildInvoiceDetailTab(),
                  _buildTimeTab(),
                  _buildExpensesTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_invoice['client'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('Client', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  Text(
                    '\$${_invoice['amount'].toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              color: AppColors.cardBackground,
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ PREVIEW TAB ============
  Widget _buildPreviewTab() {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('M/d/yyyy');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Controls
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Text(_invoice['billingType']),
                    const SizedBox(width: 8),
                    const Icon(Icons.unfold_more, size: 16),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TextButton(onPressed: () {}, child: const Text('Edit')),
              OutlinedButton(onPressed: () {}, child: const Text('Refresh')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () {}, child: const Text('Snapshot')),
            ],
          ),
          const SizedBox(height: 16),

          // Invoice Preview
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('P', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('INVOICE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text('Invoice Date:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(dateFormat.format(_invoice['draftDate']), style: const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('Total Amount: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text(currencyFormat.format(_invoice['amount']), style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        Row(
                          children: [
                            Text('Number: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text(_invoice['number'], style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Row(
                          children: [
                            Text('Terms: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text(_invoice['terms'], style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Company Info
                Text(_invoice['company']['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(_invoice['company']['address']),
                Text(_invoice['company']['city']),
                Text(_invoice['company']['phone']),
                const SizedBox(height: 24),

                // Bill To
                Text('Bill To:', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(_invoice['client'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(_invoice['clientAddress']),
                Text(_invoice['clientPhone']),
                const SizedBox(height: 24),

                // Divider
                const Divider(),
                const SizedBox(height: 16),

                // Milestone Billing Table
                const Text('Milestone Billing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                    4: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      children: [
                        Text('Task', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        Text('Prior', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        Text('Current', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        Text('Budget', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        Text('Amount', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      ],
                    ),
                    ...(_invoice['tasks'] as List).map((task) => TableRow(
                      children: [
                        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(task['name'])),
                        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(currencyFormat.format(task['prior']))),
                        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(currencyFormat.format(task['current']))),
                        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(currencyFormat.format(task['budget']))),
                        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(currencyFormat.format(task['amount']))),
                      ],
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ INVOICE DETAIL TAB ============
  Widget _buildInvoiceDetailTab() {
    final dateFormat = DateFormat('MMM d, yyyy');
    final shortDateFormat = DateFormat('M/d/yyyy');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invoice # and Period
                Row(
                  children: [
                    Expanded(child: _buildFormField('Invoice #', _invoice['number'])),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDropdownField('Period', _invoice['period'], ['Current Invoice', 'Previous Invoice'])),
                  ],
                ),
                const SizedBox(height: 16),

                // PO Number and Terms
                Row(
                  children: [
                    Expanded(child: _buildFormField('PO Number', _invoice['poNumber'], hint: 'Enter PO #')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDropdownField('Terms', _invoice['terms'], ['Net 15', 'Net 30', 'Net 45', 'Net 60', 'Due on Receipt'])),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildDropdownField('Status', _invoice['status'], ['Draft', 'Sent', 'Viewed', 'Paid', 'Overdue'])),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDateField('Sent Date', _invoice['sentDate'])),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Due date calculated from sent date + terms',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // Timeline
                Row(
                  children: [
                    _buildTimelineItem('Drafted', shortDateFormat.format(_invoice['draftDate'])),
                    const SizedBox(width: 16),
                    _buildTimelineItem('Sent', shortDateFormat.format(_invoice['sentDate'])),
                    const SizedBox(width: 16),
                    _buildTimelineItem('Due', shortDateFormat.format(_invoice['dueDate'])),
                  ],
                ),
                const SizedBox(height: 16),

                // Due Date
                _buildDateField('Due Date', _invoice['dueDate']),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment Reminder
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_outlined, color: AppColors.warning),
                    const SizedBox(width: 8),
                    const Text('Payment Reminder', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Set up automatic reminder if payment not received',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined, size: 18),
                    label: const Text('Set Reminder'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: BorderSide(color: AppColors.warning),
                      backgroundColor: AppColors.warningLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, String value, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(value.isEmpty ? (hint ?? '') : value, style: TextStyle(color: value.isEmpty ? AppColors.textSecondary : AppColors.textPrimary)),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value),
              const Icon(Icons.unfold_more, size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime date) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(child: Text(dateFormat.format(date))),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(String label, String date) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.textSecondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text('$label  ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(date, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ============ TIME TAB ============
  Widget _buildTimeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buttons
            Row(
              children: [
                OutlinedButton(onPressed: () {}, child: const Text('Add\nTime')),
                const SizedBox(width: 12),
                OutlinedButton(onPressed: () {}, child: const Text('Update\nRates')),
              ],
            ),
            const SizedBox(height: 24),

            // Table Header
            Row(
              children: [
                Expanded(flex: 2, child: Text('STAFF\nMEMBER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(child: Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(child: Text('CATEGORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(child: Text('NOTES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(child: Text('RATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
              ],
            ),
            const Divider(),
            const SizedBox(height: 40),

            // Empty State
            Center(
              child: Text(
                'No time entries found for this invoice',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 40),

            // Overall Totals
            const Text('OVERALL TOTALS', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  // ============ EXPENSES TAB ============
  Widget _buildExpensesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton(onPressed: () {}, child: const Text('Add Expense')),
            const SizedBox(height: 24),

            // Table Header
            Row(
              children: [
                Expanded(flex: 2, child: Text('DESCRIPTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(child: Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(child: Text('AMOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
              ],
            ),
            const Divider(),
            const SizedBox(height: 40),

            // Empty State
            Center(
              child: Text(
                'No expenses found for this invoice',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ HISTORY TAB ============
  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Invoice History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: AppColors.textTertiary),
                  const SizedBox(height: 12),
                  Text(
                    'No history events yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
