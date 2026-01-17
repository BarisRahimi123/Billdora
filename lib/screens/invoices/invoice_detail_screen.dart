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
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, size: 24, color: AppColors.textPrimary),
                        onSelected: (value) {
                          if (value == 'delete') _showDeleteConfirmation();
                          else if (value == 'duplicate') _duplicateInvoice();
                          else if (value == 'export') _exportInvoice();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.content_copy, size: 18),
                                SizedBox(width: 12),
                                Text('Duplicate'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'export',
                            child: Row(
                              children: [
                                Icon(Icons.download, size: 18),
                                SizedBox(width: 12),
                                Text('Export PDF'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(value: 'delete', child: SizedBox(height: 1)),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                SizedBox(width: 12),
                                Text('Delete Invoice', style: TextStyle(color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_invoice['client'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('Client', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  Text(
                    '\$${_invoice['amount'].toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
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
          // Controls - Compact Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_invoice['billingType'], style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    const Icon(Icons.unfold_more, size: 14),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {}, 
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Edit', style: TextStyle(fontSize: 13)),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Refresh', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Snapshot', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Invoice Preview
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
                // Header - Compact Layout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo - Smaller
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('P', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('INVOICE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('Date: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(dateFormat.format(_invoice['draftDate']), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 12),
                              Text('Total: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(currencyFormat.format(_invoice['amount']), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text('Number: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(_invoice['number'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 12),
                              Text('Terms: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(_invoice['terms'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Company and Bill To - Side by Side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_invoice['company']['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(_invoice['company']['address'], style: const TextStyle(fontSize: 11)),
                          Text(_invoice['company']['city'], style: const TextStyle(fontSize: 11)),
                          Text(_invoice['company']['phone'], style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Bill To
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bill To:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(_invoice['client'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(_invoice['clientAddress'], style: const TextStyle(fontSize: 11)),
                          Text(_invoice['clientPhone'], style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Milestone Billing Table - Compact
                const Text('Milestone Billing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
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
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('Task', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('Prior', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('Current', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('Budget', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('Amount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                    ...(_invoice['tasks'] as List).map((task) => TableRow(
                      children: [
                        Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(task['name'], style: const TextStyle(fontSize: 11))),
                        Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(currencyFormat.format(task['prior']), style: const TextStyle(fontSize: 11))),
                        Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(currencyFormat.format(task['current']), style: const TextStyle(fontSize: 11))),
                        Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(currencyFormat.format(task['budget']), style: const TextStyle(fontSize: 11))),
                        Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(currencyFormat.format(task['amount']), style: const TextStyle(fontSize: 11))),
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
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invoice # and Period
                Row(
                  children: [
                    Expanded(child: _buildFormField('Invoice #', _invoice['number'])),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdownField('Period', _invoice['period'], ['Current Invoice', 'Previous Invoice'])),
                  ],
                ),
                const SizedBox(height: 12),

                // PO Number and Terms
                Row(
                  children: [
                    Expanded(child: _buildFormField('PO Number', _invoice['poNumber'], hint: 'Enter PO #')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdownField('Terms', _invoice['terms'], ['Net 15', 'Net 30', 'Net 45', 'Net 60', 'Due on Receipt'])),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Status Section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildDropdownField('Status', _invoice['status'], ['Draft', 'Sent', 'Viewed', 'Paid', 'Overdue'])),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDateField('Sent Date', _invoice['sentDate'])),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Due date calculated from sent date + terms',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),

                // Timeline - Redesigned for compact display
                Row(
                  children: [
                    Expanded(child: _buildTimelineItem('Drafted', shortDateFormat.format(_invoice['draftDate']))),
                    Container(width: 1, height: 24, color: AppColors.border),
                    Expanded(child: _buildTimelineItem('Sent', shortDateFormat.format(_invoice['sentDate']))),
                    Container(width: 1, height: 24, color: AppColors.border),
                    Expanded(child: _buildTimelineItem('Due', shortDateFormat.format(_invoice['dueDate']))),
                  ],
                ),
                const SizedBox(height: 14),

                // Due Date
                _buildDateField('Due Date', _invoice['dueDate']),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Payment Reminder - More Compact
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_outlined, color: AppColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment Reminder', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        'Set automatic reminder',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    foregroundColor: AppColors.warning,
                    side: BorderSide(color: AppColors.warning),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Set', style: TextStyle(fontSize: 12)),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            value.isEmpty ? (hint ?? '') : value,
            style: TextStyle(
              fontSize: 13,
              color: value.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
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
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: Text(
              dateFormat.format(date),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(String label, String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            date,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============ TIME TAB ============
  Widget _buildTimeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buttons - More Compact
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Time', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.attach_money, size: 16),
                    label: const Text('Update Rates', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table Header - More Compact
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('STAFF MEMBER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                  Expanded(child: Text('DATE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                  Expanded(child: Text('CATEGORY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                  Expanded(child: Text('NOTES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                  Expanded(child: Text('RATE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary), textAlign: TextAlign.right)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Empty State - Modern Design
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.access_time, size: 40, color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No time entries yet',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add time entries to track billable hours',
                      style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ EXPENSES TAB ============
  Widget _buildExpensesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Expense', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Table Header - More Compact
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('DESCRIPTION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                  Expanded(child: Text('DATE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                  Expanded(child: Text('AMOUNT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary), textAlign: TextAlign.right)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Empty State - Modern Design
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No expenses yet',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add reimbursable expenses for this invoice',
                      style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ),
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
      padding: const EdgeInsets.all(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Invoice History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.history, size: 40, color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No activity yet',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Invoice actions and updates will appear here',
                      style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ HELPER METHODS ============
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.error, size: 24),
            const SizedBox(width: 12),
            const Text('Delete Invoice?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete invoice ${_invoice['number']}?'),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.pop(); // Go back to invoices list
              // TODO: Actually delete the invoice from the database
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _duplicateInvoice() {
    // Show a snackbar for now
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Duplicating invoice ${_invoice['number']}...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // TODO: Implement invoice duplication
  }

  void _exportInvoice() {
    // Show a snackbar for now
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting invoice ${_invoice['number']} as PDF...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // TODO: Implement PDF export
  }
}





