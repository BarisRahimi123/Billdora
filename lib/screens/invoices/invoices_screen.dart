import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../main.dart';
import '../shell/app_header.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  int _activeTab = 0; // 0 = All, 1 = Draft, 2 = Sent, 3 = Aging
  String _statusFilter = 'all';
  String _searchQuery = '';
  String _viewMode = 'list'; // list or client
  
  // Mock data
  final List<Map<String, dynamic>> _invoices = [
    {'id': '1', 'number': 'INV-001', 'client': 'Acme Corp', 'amount': 2500.0, 'status': 'paid', 'dueDate': DateTime.now().subtract(const Duration(days: 5)), 'viewCount': 3, 'lastViewedAt': DateTime.now().subtract(const Duration(days: 2))},
    {'id': '2', 'number': 'INV-002', 'client': 'TechStart Inc', 'amount': 1800.0, 'status': 'sent', 'dueDate': DateTime.now().add(const Duration(days: 15)), 'viewCount': 5, 'lastViewedAt': DateTime.now().subtract(const Duration(hours: 6))},
    {'id': '3', 'number': 'INV-003', 'client': 'Design Studio', 'amount': 4200.0, 'status': 'draft', 'dueDate': null, 'viewCount': 0, 'lastViewedAt': null},
    {'id': '4', 'number': 'INV-004', 'client': 'Global Media', 'amount': 950.0, 'status': 'overdue', 'dueDate': DateTime.now().subtract(const Duration(days: 10)), 'viewCount': 2, 'lastViewedAt': DateTime.now().subtract(const Duration(days: 5))},
    {'id': '5', 'number': 'INV-005', 'client': 'Acme Corp', 'amount': 3200.0, 'status': 'sent', 'dueDate': DateTime.now().add(const Duration(days: 7)), 'viewCount': 1, 'lastViewedAt': DateTime.now().subtract(const Duration(hours: 12))},
    {'id': '6', 'number': 'INV-006', 'client': 'Startup Labs', 'amount': 1500.0, 'status': 'paid', 'dueDate': DateTime.now().subtract(const Duration(days: 20)), 'viewCount': 0, 'lastViewedAt': null},
    {'id': '7', 'number': 'INV-007', 'client': 'Tech Innovations', 'amount': 2100.0, 'status': 'draft', 'dueDate': null, 'viewCount': 0, 'lastViewedAt': null},
  ];

  List<Map<String, dynamic>> get _filteredInvoices {
    var filtered = _invoices;
    
    // Filter by tab
    if (_activeTab == 1) {
      // Draft tab
      filtered = filtered.where((i) => i['status'] == 'draft').toList();
    } else if (_activeTab == 2) {
      // Sent tab
      filtered = filtered.where((i) => i['status'] == 'sent').toList();
    } else if (_activeTab == 3) {
      // Aging tab (overdue + sent)
      filtered = filtered.where((i) => i['status'] == 'overdue' || i['status'] == 'sent').toList();
    }
    
    // Filter by status
    if (_statusFilter != 'all') {
      filtered = filtered.where((i) => i['status'] == _statusFilter).toList();
    }
    
    // Filter by search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((i) => 
        i['number'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
        i['client'].toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }

  Map<String, double> get _stats {
    final wip = _invoices.where((i) => i['status'] == 'draft').fold(0.0, (sum, i) => sum + i['amount']);
    final sent = _invoices.where((i) => i['status'] == 'sent').fold(0.0, (sum, i) => sum + i['amount']);
    final aging = _invoices.where((i) => i['status'] == 'overdue').fold(0.0, (sum, i) => sum + i['amount']);
    return {'wip': wip, 'sent': sent, 'aging': aging};
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final stats = _stats;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Header with Hamburger Menu
            const SliverToBoxAdapter(
              child: AppHeader(showSearch: true),
            ),

            // Title and Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoicing',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manage invoices and payments',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Log Payment Button
                        GestureDetector(
                          onTap: () => _showCreatePaymentModal(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.attach_money, size: 16, color: AppColors.textPrimary),
                                SizedBox(width: 4),
                                Text('Log', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context.push('/invoices/create'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: Colors.white, size: 18),
                                SizedBox(width: 4),
                                Text(
                                  'New',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Stats Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: _StatPill(
                      label: 'WIP',
                      value: currencyFormat.format(stats['wip']),
                      color: AppColors.neutral500,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _StatPill(
                      label: 'Sent',
                      value: currencyFormat.format(stats['sent']),
                      color: AppColors.warning,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _StatPill(
                      label: 'Aging',
                      value: currencyFormat.format(stats['aging']),
                      color: AppColors.error,
                    )),
                  ],
                ),
              ),
            ),

            // Tabs
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _TabButton(label: 'All', isActive: _activeTab == 0, onTap: () => setState(() => _activeTab = 0)),
                      _TabButton(label: 'Draft', isActive: _activeTab == 1, onTap: () => setState(() => _activeTab = 1)),
                      _TabButton(label: 'Sent', isActive: _activeTab == 2, onTap: () => setState(() => _activeTab = 2)),
                      _TabButton(label: 'Aging', isActive: _activeTab == 3, onTap: () => setState(() => _activeTab = 3)),
                    ],
                  ),
                ),
              ),
            ),

            // Search & Filter
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search invoices...',
                            hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterButton(
                      currentFilter: _statusFilter,
                      onFilterChanged: (filter) => setState(() => _statusFilter = filter),
                    ),
                  ],
                ),
              ),
            ),

            // Invoice List
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.card,
                  ),
                  child: _filteredInvoices.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              'No invoices found',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredInvoices.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border),
                          itemBuilder: (context, index) {
                            final invoice = _filteredInvoices[index];
                            return _InvoiceListTile(
                              invoice: invoice,
                              onTap: () => context.push('/invoices/${invoice['id']}'),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePaymentModal() {
    showDialog(
      context: context,
      builder: (context) => const _CreatePaymentModal(),
    );
  }
}

class _CreatePaymentModal extends StatefulWidget {
  const _CreatePaymentModal();

  @override
  State<_CreatePaymentModal> createState() => _CreatePaymentModalState();
}

class _CreatePaymentModalState extends State<_CreatePaymentModal> {
  String? _selectedClient;
  double _amount = 0.0;
  String _paymentType = 'Check';
  DateTime _paymentDate = DateTime.now();
  String _referenceNumber = '';
  String _notes = '';
  bool _projectSpecific = false;

  final List<String> _clients = ['Barzan Shop', 'Sequoia Consulting', 'Acme Corp', 'TechStart Inc'];
  final List<String> _paymentTypes = ['Check', 'Cash', 'Credit Card', 'Bank Transfer', 'PayPal', 'Stripe', 'Other'];

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Create A New Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client
                    _buildLabel('Client'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedClient,
                          isExpanded: true,
                          hint: const Text('Select a client'),
                          items: _clients.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (value) => setState(() => _selectedClient = value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Total Amount
                    _buildLabel('Total Amount'),
                    const SizedBox(height: 8),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: '\$ ',
                        hintText: '0.00',
                        filled: true,
                        fillColor: AppColors.neutral50,
                      ),
                      onChanged: (value) => _amount = double.tryParse(value) ?? 0,
                    ),
                    const SizedBox(height: 16),

                    // Payment Type
                    _buildLabel('Payment Type'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _paymentType,
                          isExpanded: true,
                          items: _paymentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (value) => setState(() => _paymentType = value!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Date
                    _buildLabel('Payment Date'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _paymentDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) setState(() => _paymentDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(child: Text(dateFormat.format(_paymentDate))),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reference Number
                    _buildLabel('Reference Number'),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Check # or Reference',
                        filled: true,
                        fillColor: AppColors.neutral50,
                      ),
                      onChanged: (value) => _referenceNumber = value,
                    ),
                    const SizedBox(height: 16),

                    // Payment Notes/Memo
                    _buildLabel('Payment Notes/Memo'),
                    const SizedBox(height: 8),
                    TextField(
                      maxLines: 3,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Add any notes about this payment...',
                        filled: true,
                        fillColor: AppColors.neutral50,
                      ),
                      onChanged: (value) => _notes = value,
                    ),
                    const SizedBox(height: 8),

                    // Project-Specific Payment
                    Row(
                      children: [
                        Checkbox(
                          value: _projectSpecific,
                          onChanged: (value) => setState(() => _projectSpecific = value!),
                          activeColor: AppColors.accent,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Project-Specific Payment', style: TextStyle(fontWeight: FontWeight.w500)),
                              Text('Apply to a specific project only (optional).', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary));
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive ? AppShadows.sm : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String currentFilter;
  final Function(String) onFilterChanged;

  const _FilterButton({required this.currentFilter, required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onFilterChanged,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'all', child: Text('All')),
        const PopupMenuItem(value: 'draft', child: Text('Draft')),
        const PopupMenuItem(value: 'sent', child: Text('Sent')),
        const PopupMenuItem(value: 'paid', child: Text('Paid')),
        const PopupMenuItem(value: 'overdue', child: Text('Overdue')),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: currentFilter != 'all' ? AppColors.accent.withOpacity(0.1) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: currentFilter != 'all' ? AppColors.accent : AppColors.border),
        ),
        child: Icon(
          Icons.filter_list,
          size: 18,
          color: currentFilter != 'all' ? AppColors.accent : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _InvoiceListTile extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback onTap;

  const _InvoiceListTile({required this.invoice, required this.onTap});

  Color get _statusColor {
    switch (invoice['status']) {
      case 'paid': return AppColors.success;
      case 'sent': return AppColors.warning;
      case 'overdue': return AppColors.error;
      default: return AppColors.neutral500;
    }
  }

  Color get _statusBgColor {
    switch (invoice['status']) {
      case 'paid': return AppColors.successLight;
      case 'sent': return AppColors.warningLight;
      case 'overdue': return AppColors.errorLight;
      default: return AppColors.neutral100;
    }
  }

  String _formatViewTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('MMM d');
    final viewCount = invoice['viewCount'] as int? ?? 0;
    final lastViewedAt = invoice['lastViewedAt'] as DateTime?;
    
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            invoice['client'][0],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Text(
            invoice['number'],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          if (invoice['dueDate'] != null) ...[
            const SizedBox(width: 8),
            Text(
              'Due ${dateFormat.format(invoice['dueDate'])}',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              invoice['client'],
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          // View count indicator (only for sent/paid invoices)
          if (viewCount > 0 && lastViewedAt != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_outlined, size: 12, color: AppColors.info),
                  const SizedBox(width: 4),
                  Text(
                    '$viewCount',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '• ${_formatViewTime(lastViewedAt)}',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            currencyFormat.format(invoice['amount']),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusBgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              invoice['status'].toString().toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
