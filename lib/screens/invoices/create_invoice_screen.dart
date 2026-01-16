import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../main.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final String? projectId; // If coming from a project
  
  const CreateInvoiceScreen({super.key, this.projectId});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  int _currentStep = 0;
  
  // Invoice data
  String? _selectedClientId;
  String? _selectedProjectId;
  String _invoiceType = 'standard'; // standard, milestone, recurring
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  String _paymentTerms = 'net_30';
  
  // Line items
  final List<InvoiceLineItem> _lineItems = [];
  
  // Milestones (for project-based invoicing)
  final List<InvoiceMilestone> _milestones = [];
  
  // Unbilled items from project
  List<Map<String, dynamic>> _unbilledTimeEntries = [];
  List<Map<String, dynamic>> _unbilledExpenses = [];
  
  // Tax & Discount
  double _taxRate = 0.0;
  double _discountPercent = 0.0;
  double _discountAmount = 0.0;
  String _discountType = 'percent'; // percent or fixed
  
  // Notes
  final _notesController = TextEditingController();
  final _termsController = TextEditingController(
    text: 'Payment is due within 30 days of invoice date. Late payments may incur a 1.5% monthly fee.',
  );

  // Mock data
  final List<Map<String, dynamic>> _clients = [
    {'id': '1', 'name': 'Acme Corp', 'email': 'billing@acme.com'},
    {'id': '2', 'name': 'TechStart Inc', 'email': 'accounts@techstart.io'},
    {'id': '3', 'name': 'Design Studio', 'email': 'pay@designstudio.com'},
    {'id': '4', 'name': 'Global Media', 'email': 'finance@globalmedia.com'},
  ];

  final List<Map<String, dynamic>> _projects = [
    {
      'id': '1',
      'name': 'Mobile App UI Design',
      'clientId': '1',
      'budget': 25000.0,
      'milestones': [
        {'id': 'm1', 'name': 'Discovery & Research', 'percentage': 20, 'status': 'completed'},
        {'id': 'm2', 'name': 'Wireframes', 'percentage': 25, 'status': 'completed'},
        {'id': 'm3', 'name': 'Visual Design', 'percentage': 30, 'status': 'in_progress'},
        {'id': 'm4', 'name': 'Prototyping & Handoff', 'percentage': 25, 'status': 'pending'},
      ],
    },
    {
      'id': '2',
      'name': 'E-commerce Website Redesign',
      'clientId': '2',
      'budget': 45000.0,
      'milestones': [
        {'id': 'm5', 'name': 'Phase 1 - Homepage', 'percentage': 30, 'status': 'completed'},
        {'id': 'm6', 'name': 'Phase 2 - Product Pages', 'percentage': 40, 'status': 'in_progress'},
        {'id': 'm7', 'name': 'Phase 3 - Checkout Flow', 'percentage': 30, 'status': 'pending'},
      ],
    },
    {
      'id': '3',
      'name': 'Virtual Tour Production',
      'clientId': '3',
      'budget': 15000.0,
      'milestones': [],
    },
  ];

  final List<Map<String, dynamic>> _services = [
    {'id': '1', 'name': 'UI/UX Design', 'rate': 150.0, 'unit': 'hour'},
    {'id': '2', 'name': '3D Laser Scanning', 'rate': 500.0, 'unit': 'scan'},
    {'id': '3', 'name': 'Web Development', 'rate': 125.0, 'unit': 'hour'},
    {'id': '4', 'name': 'Consulting', 'rate': 200.0, 'unit': 'hour'},
    {'id': '5', 'name': 'Photography', 'rate': 350.0, 'unit': 'session'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) {
      _selectedProjectId = widget.projectId;
      // Auto-select client from project
      final project = _projects.firstWhere(
        (p) => p['id'] == widget.projectId,
        orElse: () => {},
      );
      if (project.isNotEmpty) {
        _selectedClientId = project['clientId'];
      }
    }
    
    // Add some mock unbilled entries
    _unbilledTimeEntries = [
      {'id': 't1', 'project': 'Mobile App UI Design', 'task': 'Wireframes - iOS', 'hours': 8.0, 'rate': 150.0, 'date': DateTime(2026, 1, 10), 'selected': false},
      {'id': 't2', 'project': 'Mobile App UI Design', 'task': 'Visual Design System', 'hours': 12.0, 'rate': 150.0, 'date': DateTime(2026, 1, 12), 'selected': false},
      {'id': 't3', 'project': 'Mobile App UI Design', 'task': 'Component Library', 'hours': 6.5, 'rate': 150.0, 'date': DateTime(2026, 1, 13), 'selected': false},
    ];
    
    _unbilledExpenses = [
      {'id': 'e1', 'description': 'Stock photos license', 'category': 'Software', 'amount': 149.0, 'date': DateTime(2026, 1, 8), 'selected': false, 'billable': true},
      {'id': 'e2', 'description': 'Client meeting - Uber', 'category': 'Travel', 'amount': 28.50, 'date': DateTime(2026, 1, 11), 'selected': false, 'billable': true},
    ];
  }

  @override
  void dispose() {
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  double get _subtotal {
    double total = 0.0;
    
    // Line items
    for (var item in _lineItems) {
      total += item.quantity * item.rate;
    }
    
    // Selected time entries
    for (var entry in _unbilledTimeEntries.where((e) => e['selected'] == true)) {
      total += entry['hours'] * entry['rate'];
    }
    
    // Selected expenses
    for (var expense in _unbilledExpenses.where((e) => e['selected'] == true)) {
      total += expense['amount'];
    }
    
    // Milestone amounts
    if (_invoiceType == 'milestone' && _selectedProjectId != null) {
      final project = _projects.firstWhere((p) => p['id'] == _selectedProjectId);
      final budget = project['budget'] as double;
      for (var milestone in _milestones.where((m) => m.selected)) {
        total += (milestone.percentage / 100) * budget;
      }
    }
    
    return total;
  }

  double get _discount {
    if (_discountType == 'percent') {
      return _subtotal * (_discountPercent / 100);
    }
    return _discountAmount;
  }

  double get _tax => (_subtotal - _discount) * (_taxRate / 100);

  double get _total => _subtotal - _discount + _tax;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create Invoice'),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () => setState(() => _currentStep--),
              child: const Text('Back'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(),
          
          // Step Content
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildStep1ClientProject(),
                _buildStep2LineItems(),
                _buildStep3ReviewSend(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.cardBackground,
      child: Row(
        children: [
          _buildStepIndicator(0, 'Client & Type'),
          Expanded(child: Container(height: 2, color: _currentStep >= 1 ? AppColors.accent : AppColors.border)),
          _buildStepIndicator(1, 'Line Items'),
          Expanded(child: Container(height: 2, color: _currentStep >= 2 ? AppColors.accent : AppColors.border)),
          _buildStepIndicator(2, 'Review'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : AppColors.neutral100,
            shape: BoxShape.circle,
            border: isCurrent ? Border.all(color: AppColors.accent, width: 2) : null,
          ),
          child: Center(
            child: isActive && !isCurrent
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
            color: isCurrent ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ============ STEP 1: CLIENT & PROJECT ============
  Widget _buildStep1ClientProject() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client Selection
          const Text(
            'Select Client *',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _clients.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final client = _clients[index];
                final isSelected = _selectedClientId == client['id'];
                
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent.withOpacity(0.1) : AppColors.neutral100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        client['name'][0],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.accent : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  title: Text(client['name']),
                  subtitle: Text(client['email'], style: const TextStyle(fontSize: 12)),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.accent)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedClientId = client['id'];
                      _selectedProjectId = null; // Reset project when client changes
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // Invoice Type
          const Text(
            'Invoice Type',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTypeCard(
                'standard',
                'Standard',
                Icons.receipt_long_outlined,
                'Add manual line items',
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildTypeCard(
                'milestone',
                'Milestone',
                Icons.flag_outlined,
                'Bill by project milestone',
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildTypeCard(
                'time_materials',
                'Time & Materials',
                Icons.access_time,
                'Import unbilled time',
              )),
            ],
          ),
          const SizedBox(height: 24),
          
          // Project Selection (for milestone or time-based)
          if (_invoiceType != 'standard' && _selectedClientId != null) ...[
            const Text(
              'Select Project',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: _projects
                    .where((p) => p['clientId'] == _selectedClientId)
                    .map((project) {
                  final isSelected = _selectedProjectId == project['id'];
                  final milestones = project['milestones'] as List;
                  
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent.withOpacity(0.1) : AppColors.neutral100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.folder_outlined, size: 20),
                    ),
                    title: Text(project['name']),
                    subtitle: Text(
                      'Budget: \$${NumberFormat('#,###').format(project['budget'])} • ${milestones.length} milestones',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.accent)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedProjectId = project['id'];
                        // Load milestones for this project
                        _milestones.clear();
                        for (var m in milestones) {
                          _milestones.add(InvoiceMilestone(
                            id: m['id'],
                            name: m['name'],
                            percentage: m['percentage'].toDouble(),
                            status: m['status'],
                            selected: false,
                          ));
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          
          // Payment Terms
          const Text(
            'Payment Terms',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _paymentTerms,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'due_receipt', child: Text('Due on Receipt')),
                  DropdownMenuItem(value: 'net_15', child: Text('Net 15')),
                  DropdownMenuItem(value: 'net_30', child: Text('Net 30')),
                  DropdownMenuItem(value: 'net_45', child: Text('Net 45')),
                  DropdownMenuItem(value: 'net_60', child: Text('Net 60')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom Date')),
                ],
                onChanged: (value) {
                  setState(() {
                    _paymentTerms = value!;
                    switch (value) {
                      case 'due_receipt':
                        _dueDate = _issueDate;
                        break;
                      case 'net_15':
                        _dueDate = _issueDate.add(const Duration(days: 15));
                        break;
                      case 'net_30':
                        _dueDate = _issueDate.add(const Duration(days: 30));
                        break;
                      case 'net_45':
                        _dueDate = _issueDate.add(const Duration(days: 45));
                        break;
                      case 'net_60':
                        _dueDate = _issueDate.add(const Duration(days: 60));
                        break;
                    }
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Dates Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Issue Date', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _issueDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _issueDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(DateFormat('MMM d, yyyy').format(_issueDate)),
                          ],
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
                    const Text('Due Date', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _dueDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(DateFormat('MMM d, yyyy').format(_dueDate)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(String type, String label, IconData icon, String description) {
    final isSelected = _invoiceType == type;
    
    return GestureDetector(
      onTap: () => setState(() => _invoiceType = type),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withOpacity(0.1) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.accent : AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ============ STEP 2: LINE ITEMS ============
  Widget _buildStep2LineItems() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Milestone Selection (if milestone type)
          if (_invoiceType == 'milestone' && _milestones.isNotEmpty) ...[
            const Text(
              'Select Milestones to Invoice',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  // Project Budget Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Project Budget',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          currencyFormat.format(_getProjectBudget()),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  
                  // Milestones
                  ...List.generate(_milestones.length, (index) {
                    final milestone = _milestones[index];
                    final amount = (_getProjectBudget() * milestone.percentage / 100);
                    final isCompleted = milestone.status == 'completed';
                    
                    return Column(
                      children: [
                        CheckboxListTile(
                          value: milestone.selected,
                          onChanged: isCompleted ? (value) {
                            setState(() => milestone.selected = value ?? false);
                          } : null,
                          activeColor: AppColors.accent,
                          title: Row(
                            children: [
                              Expanded(child: Text(milestone.name)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getMilestoneStatusColor(milestone.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  milestone.status.toUpperCase().replaceAll('_', ' '),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: _getMilestoneStatusColor(milestone.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${milestone.percentage.toInt()}% • ${currencyFormat.format(amount)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        if (index < _milestones.length - 1)
                          const Divider(height: 1, color: AppColors.border),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Unbilled Time Entries (if time & materials)
          if (_invoiceType == 'time_materials' && _unbilledTimeEntries.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Unbilled Time Entries',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      final allSelected = _unbilledTimeEntries.every((e) => e['selected']);
                      for (var entry in _unbilledTimeEntries) {
                        entry['selected'] = !allSelected;
                      }
                    });
                  },
                  child: Text(_unbilledTimeEntries.every((e) => e['selected']) ? 'Deselect All' : 'Select All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.card,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _unbilledTimeEntries.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, index) {
                  final entry = _unbilledTimeEntries[index];
                  final amount = entry['hours'] * entry['rate'];
                  
                  return CheckboxListTile(
                    value: entry['selected'],
                    onChanged: (value) {
                      setState(() => entry['selected'] = value);
                    },
                    activeColor: AppColors.accent,
                    title: Text(entry['task']),
                    subtitle: Text(
                      '${entry['hours']}h × ${currencyFormat.format(entry['rate'])}/hr • ${DateFormat('MMM d').format(entry['date'])}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    secondary: Text(
                      currencyFormat.format(amount),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Unbilled Expenses
          if (_unbilledExpenses.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Billable Expenses',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      final allSelected = _unbilledExpenses.every((e) => e['selected']);
                      for (var expense in _unbilledExpenses) {
                        expense['selected'] = !allSelected;
                      }
                    });
                  },
                  child: Text(_unbilledExpenses.every((e) => e['selected']) ? 'Deselect All' : 'Select All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.card,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _unbilledExpenses.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, index) {
                  final expense = _unbilledExpenses[index];
                  
                  return CheckboxListTile(
                    value: expense['selected'],
                    onChanged: (value) {
                      setState(() => expense['selected'] = value);
                    },
                    activeColor: AppColors.accent,
                    title: Text(expense['description']),
                    subtitle: Text(
                      '${expense['category']} • ${DateFormat('MMM d').format(expense['date'])}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    secondary: Text(
                      currencyFormat.format(expense['amount']),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Manual Line Items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Line Items',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              TextButton.icon(
                onPressed: _showAddLineItemModal,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (_lineItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.textTertiary),
                    const SizedBox(height: 8),
                    const Text(
                      'No line items added',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap "Add Item" to add services or products',
                      style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.card,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _lineItems.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, index) {
                  final item = _lineItems[index];
                  
                  return ListTile(
                    title: Text(item.description),
                    subtitle: Text(
                      '${item.quantity} × ${currencyFormat.format(item.rate)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currencyFormat.format(item.quantity * item.rate),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() => _lineItems.removeAt(index));
                          },
                          child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          
          // Tax & Discount
          const Text(
            'Tax & Discount',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                // Tax Rate
                Row(
                  children: [
                    const Expanded(child: Text('Tax Rate')),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          suffixText: '%',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.neutral50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _taxRate = double.tryParse(value) ?? 0.0);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Discount
                Row(
                  children: [
                    const Expanded(child: Text('Discount')),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'percent', label: Text('%')),
                        ButtonSegment(value: 'fixed', label: Text('\$')),
                      ],
                      selected: {_discountType},
                      onSelectionChanged: (value) {
                        setState(() => _discountType = value.first);
                      },
                      style: ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.neutral50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            if (_discountType == 'percent') {
                              _discountPercent = double.tryParse(value) ?? 0.0;
                            } else {
                              _discountAmount = double.tryParse(value) ?? 0.0;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ STEP 3: REVIEW & SEND ============
  Widget _buildStep3ReviewSend() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final selectedClient = _clients.firstWhere(
      (c) => c['id'] == _selectedClientId,
      orElse: () => {'name': 'Unknown', 'email': ''},
    );
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice Preview Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.elevated,
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INVOICE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'INV-${DateTime.now().year}${(DateTime.now().month).toString().padLeft(2, '0')}${(DateTime.now().day).toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(_total),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Due ${DateFormat('MMM d, yyyy').format(_dueDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Client Info
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BILL TO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedClient['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              selectedClient['email'],
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Issue: ${DateFormat('MMM d, yyyy').format(_issueDate)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text(
                            'Due: ${DateFormat('MMM d, yyyy').format(_dueDate)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1, color: AppColors.border),
                
                // Summary
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal'),
                          Text(currencyFormat.format(_subtotal)),
                        ],
                      ),
                      if (_discount > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Discount${_discountType == 'percent' ? ' (${_discountPercent.toInt()}%)' : ''}'),
                            Text(
                              '-${currencyFormat.format(_discount)}',
                              style: const TextStyle(color: AppColors.success),
                            ),
                          ],
                        ),
                      ],
                      if (_taxRate > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tax (${_taxRate.toInt()}%)'),
                            Text(currencyFormat.format(_tax)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            currencyFormat.format(_total),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Notes
          const Text(
            'Notes (Optional)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add any notes for the client...',
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Terms
          const Text(
            'Payment Terms',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _termsController,
            maxLines: 2,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Running Total
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  currencyFormat.format(_total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          
          // Action Button
          if (_currentStep < 2)
            ElevatedButton(
              onPressed: _canProceed() ? () => setState(() => _currentStep++) : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text('Continue'),
            )
          else
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    // Save as draft
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invoice saved as draft')),
                    );
                    context.pop();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  child: const Text('Save Draft'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // Send invoice
                    _showSendInvoiceDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.send, size: 18),
                      SizedBox(width: 8),
                      Text('Send'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  bool _canProceed() {
    if (_currentStep == 0) {
      return _selectedClientId != null;
    }
    if (_currentStep == 1) {
      return _total > 0;
    }
    return true;
  }

  double _getProjectBudget() {
    if (_selectedProjectId == null) return 0.0;
    final project = _projects.firstWhere(
      (p) => p['id'] == _selectedProjectId,
      orElse: () => {'budget': 0.0},
    );
    return project['budget'] as double;
  }

  Color _getMilestoneStatusColor(String status) {
    switch (status) {
      case 'completed': return AppColors.success;
      case 'in_progress': return AppColors.warning;
      default: return AppColors.textSecondary;
    }
  }

  void _showAddLineItemModal() {
    String selectedServiceId = _services.first['id'];
    final quantityController = TextEditingController(text: '1');
    final rateController = TextEditingController(text: _services.first['rate'].toString());
    final descriptionController = TextEditingController(text: _services.first['name']);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Add Line Item',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                
                // Service Selection
                const Text('Service', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.neutral50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedServiceId,
                      isExpanded: true,
                      items: _services.map((s) => DropdownMenuItem(
                        value: s['id'] as String,
                        child: Text(s['name'] as String),
                      )).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedServiceId = value!;
                          final service = _services.firstWhere((s) => s['id'] == value);
                          rateController.text = service['rate'].toString();
                          descriptionController.text = service['name'];
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description
                const Text('Description', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.neutral50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Quantity & Rate
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quantity', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.neutral50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: AppColors.border),
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
                          const Text('Rate', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: rateController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixText: '\$',
                              filled: true,
                              fillColor: AppColors.neutral50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Add Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final quantity = double.tryParse(quantityController.text) ?? 1;
                      final rate = double.tryParse(rateController.text) ?? 0;
                      
                      setState(() {
                        _lineItems.add(InvoiceLineItem(
                          description: descriptionController.text,
                          quantity: quantity,
                          rate: rate,
                        ));
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Add Item'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSendInvoiceDialog() {
    final selectedClient = _clients.firstWhere(
      (c) => c['id'] == _selectedClientId,
      orElse: () => {'email': ''},
    );
    final emailController = TextEditingController(text: selectedClient['email']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send this invoice to:', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppColors.accent,
                ),
                const Text('Send me a copy'),
              ],
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Invoice sent to ${emailController.text}'),
                  backgroundColor: AppColors.success,
                ),
              );
              context.go('/invoices');
            },
            child: const Text('Send Invoice'),
          ),
        ],
      ),
    );
  }
}

// Data Models
class InvoiceLineItem {
  final String description;
  final double quantity;
  final double rate;
  
  InvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.rate,
  });
}

class InvoiceMilestone {
  final String id;
  final String name;
  final double percentage;
  final String status;
  bool selected;
  
  InvoiceMilestone({
    required this.id,
    required this.name,
    required this.percentage,
    required this.status,
    this.selected = false,
  });
}
