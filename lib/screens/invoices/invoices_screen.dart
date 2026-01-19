import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../providers/invoices_provider.dart';
import '../../providers/permissions_provider.dart';
import '../../providers/sales_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (auth.companyId != null) {
      context.read<InvoicesProvider>().loadInvoices(auth.companyId!);
      context.read<SalesProvider>().loadClients(auth.companyId!);
    }
  }

  List<Map<String, dynamic>> _getFilteredInvoices(List<Map<String, dynamic>> invoices) {
    var filtered = invoices;
    
    // Filter by tab
    if (_activeTab == 1) {
      filtered = filtered.where((i) => i['status'] == 'draft').toList();
    } else if (_activeTab == 2) {
      filtered = filtered.where((i) => i['status'] == 'sent').toList();
    } else if (_activeTab == 3) {
      filtered = filtered.where((i) => i['status'] == 'overdue' || i['status'] == 'sent').toList();
    }
    
    // Filter by status
    if (_statusFilter != 'all') {
      filtered = filtered.where((i) => i['status'] == _statusFilter).toList();
    }
    
    // Filter by search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((i) => 
        (i['invoice_number'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (i['clients']?['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }

  Map<String, double> _getStats(List<Map<String, dynamic>> invoices) {
    final wip = invoices.where((i) => i['status'] == 'draft').fold(0.0, (sum, i) => sum + ((i['total'] as num?) ?? 0).toDouble());
    final sent = invoices.where((i) => i['status'] == 'sent').fold(0.0, (sum, i) => sum + ((i['total'] as num?) ?? 0).toDouble());
    final aging = invoices.where((i) => i['status'] == 'overdue').fold(0.0, (sum, i) => sum + ((i['total'] as num?) ?? 0).toDouble());
    return {'wip': wip, 'sent': sent, 'aging': aging};
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final invoicesProvider = context.watch<InvoicesProvider>();
    final permissions = context.watch<PermissionsProvider>();
    final filteredInvoices = _getFilteredInvoices(invoicesProvider.invoices);
    final stats = _getStats(invoicesProvider.invoices);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: AppHeader(showSearch: false)),

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
                        if (permissions.canViewClientValues)
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
                                Text('New', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
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

            // Stats Row (only for users with permission)
            if (permissions.canViewClientValues)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: _StatPill(label: 'WIP', value: currencyFormat.format(stats['wip']), color: AppColors.neutral500)),
                      const SizedBox(width: 8),
                      Expanded(child: _StatPill(label: 'Sent', value: currencyFormat.format(stats['sent']), color: AppColors.warning)),
                      const SizedBox(width: 8),
                      Expanded(child: _StatPill(label: 'Aging', value: currencyFormat.format(stats['aging']), color: AppColors.error)),
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
                child: invoicesProvider.isLoading
                    ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                    : invoicesProvider.errorMessage != null
                        ? Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('Error: ${invoicesProvider.errorMessage}')))
                        : Container(
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              boxShadow: AppShadows.card,
                            ),
                            child: filteredInvoices.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(40),
                                    child: Center(child: Text('No invoices found', style: TextStyle(color: AppColors.textSecondary))),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: filteredInvoices.length,
                                    separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border),
                                    itemBuilder: (context, index) {
                                      final invoice = filteredInvoices[index];
                                      return _InvoiceListTile(
                                        invoice: invoice,
                                        showAmount: permissions.canViewClientValues,
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
  String? _selectedClientId;
  double _amount = 0.0;
  String _paymentType = 'Check';
  DateTime _paymentDate = DateTime.now();
  String _referenceNumber = '';
  String _notes = '';
  bool _projectSpecific = false;
  bool _isSubmitting = false;

  final List<String> _paymentTypes = ['Check', 'Cash', 'Credit Card', 'Bank Transfer', 'PayPal', 'Stripe', 'Other'];

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final clients = context.watch<SalesProvider>().clients;
    
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          value: _selectedClientId,
                          isExpanded: true,
                          hint: const Text('Select a client'),
                          items: clients.map((c) => DropdownMenuItem(
                            value: c['id'] as String,
                            child: Text(c['name'] ?? 'Unknown'),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedClientId = value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

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
                      onPressed: _isSubmitting ? null : () {
                        // TODO: Save payment via provider
                        Navigator.pop(context);
                      },
                      child: _isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save'),
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
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
  final bool showAmount;
  final VoidCallback onTap;

  const _InvoiceListTile({required this.invoice, required this.showAmount, required this.onTap});

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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('MMM d');
    final clientName = invoice['clients']?['name'] ?? 'Unknown Client';
    final dueDate = invoice['due_date'] != null ? DateTime.tryParse(invoice['due_date']) : null;
    final total = (invoice['total'] as num?)?.toDouble() ?? 0.0;
    
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
            clientName.isNotEmpty ? clientName[0] : '?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.accent),
          ),
        ),
      ),
      title: Row(
        children: [
          Text(
            invoice['invoice_number'] ?? 'INV-???',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          ),
          if (dueDate != null) ...[
            const SizedBox(width: 8),
            Text(
              'Due ${dateFormat.format(dueDate)}',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
      subtitle: Text(
        clientName,
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showAmount)
            Text(
              currencyFormat.format(total),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusBgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              (invoice['status'] ?? 'draft').toString().toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
