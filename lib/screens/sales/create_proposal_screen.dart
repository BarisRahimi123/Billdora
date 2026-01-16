import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../main.dart';

class CreateProposalScreen extends StatefulWidget {
  final String? templateId;

  const CreateProposalScreen({super.key, this.templateId});

  @override
  State<CreateProposalScreen> createState() => _CreateProposalScreenState();
}

class _CreateProposalScreenState extends State<CreateProposalScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Step 1: Services & Scope
  final _projectNameController = TextEditingController();
  String? _selectedClientId;
  String? _selectedLeadId;
  String _recipientType = 'none'; // 'none', 'client', or 'lead'
  final List<ProposalLineItem> _lineItems = [];
  double _taxRate = 8.25;

  // Step 2: Timeline
  final _scopeController = TextEditingController(text: 'Testing the template');

  // Step 3: Cover & Terms
  String _coverImageUrl = '';
  final _emailSubjectController = TextEditingController();
  final _emailBodyController = TextEditingController();

  // Mock data - Clients with full info
  final List<Map<String, dynamic>> _clients = [
    {'id': '1', 'name': 'Barzan Shop', 'email': 'contact@barzanshop.com', 'phone': '555-0101', 'address': '123 Commerce St'},
    {'id': '2', 'name': 'Sequoia Consulting', 'email': 'hello@sequoia.com', 'phone': '555-0102', 'address': '456 Business Ave'},
    {'id': '3', 'name': 'Wall Street Global', 'email': 'info@wallstreet.com', 'phone': '555-0103', 'address': '789 Finance Blvd'},
  ];

  // Mock data - Leads with full info  
  final List<Map<String, dynamic>> _leads = [
    {'id': '1', 'name': 'Testing - Wgcc', 'email': 'test@wgcc.com', 'phone': '555-0201', 'company': 'WGCC Inc'},
    {'id': '2', 'name': 'John', 'email': 'john@email.com', 'phone': '555-0202', 'company': 'John\'s LLC'},
  ];

  // Services from Settings (would normally come from shared state/provider)
  final List<Map<String, dynamic>> _services = [
    {'id': '1', 'name': 'Web Development', 'description': 'Custom website development', 'rate': 150.0, 'unit': 'hour', 'category': 'Development'},
    {'id': '2', 'name': 'UI/UX Design', 'description': 'User interface design', 'rate': 125.0, 'unit': 'hour', 'category': 'Design'},
    {'id': '3', 'name': 'Strategic Consulting', 'description': 'Business strategy consulting', 'rate': 200.0, 'unit': 'hour', 'category': 'Consulting'},
    {'id': '4', 'name': 'Civil Drafting', 'description': 'Civil engineering drafts', 'rate': 50.0, 'unit': 'hour', 'category': 'Development'},
    {'id': '5', 'name': 'Revisions', 'description': 'CD Plans revisions', 'rate': 50.0, 'unit': 'hour', 'category': 'Development'},
    {'id': '6', 'name': 'TSM Map', 'description': 'Tentative map services', 'rate': 50.0, 'unit': 'hour', 'category': 'Development'},
  ];

  @override
  void initState() {
    super.initState();
    // Start with empty line items - user will add from services
    _lineItems.clear();
  }

  // Get selected recipient info
  Map<String, dynamic>? get _selectedRecipient {
    if (_recipientType == 'client' && _selectedClientId != null) {
      return _clients.firstWhere((c) => c['id'] == _selectedClientId, orElse: () => {});
    } else if (_recipientType == 'lead' && _selectedLeadId != null) {
      return _leads.firstWhere((l) => l['id'] == _selectedLeadId, orElse: () => {});
    }
    return null;
  }

  String get _recipientName => _selectedRecipient?['name'] ?? 'Client';
  String get _recipientEmail => _selectedRecipient?['email'] ?? '';

  void _selectClient(String? clientId) {
    setState(() {
      _selectedClientId = clientId;
      _selectedLeadId = null;
      _recipientType = clientId != null ? 'client' : 'none';
      // Auto-fill project name with client name if empty
      if (clientId != null && _projectNameController.text.isEmpty) {
        final client = _clients.firstWhere((c) => c['id'] == clientId, orElse: () => {});
        _projectNameController.text = 'Proposal for ${client['name'] ?? ''}';
      }
    });
  }

  void _selectLead(String? leadId) {
    setState(() {
      _selectedLeadId = leadId;
      _selectedClientId = null;
      _recipientType = leadId != null ? 'lead' : 'none';
      // Auto-fill project name with lead name if empty
      if (leadId != null && _projectNameController.text.isEmpty) {
        final lead = _leads.firstWhere((l) => l['id'] == leadId, orElse: () => {});
        _projectNameController.text = 'Proposal for ${lead['name'] ?? ''}';
      }
    });
  }

  void _clearRecipient() {
    setState(() {
      _selectedClientId = null;
      _selectedLeadId = null;
      _recipientType = 'none';
    });
  }

  // Show services selection modal
  void _showServicesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ServicesSelectionModal(
        services: _services,
        onServicesSelected: (selectedServices) {
          setState(() {
            for (var service in selectedServices) {
              _lineItems.add(ProposalLineItem(
                description: service['name'],
                unitPrice: service['rate'],
                unit: service['unit'] == 'hour' ? 'h' : service['unit'],
                quantity: 1,
                days: 1,
              ));
            }
          });
        },
      ),
    );
  }

  // Show add item modal
  void _showAddItemModal() {
    final nameController = TextEditingController();
    final rateController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    String selectedUnit = 'h';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
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
              const Text('Add Custom Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter item description',
                  filled: true,
                  fillColor: AppColors.neutral50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: rateController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Unit Price',
                        prefixText: '\$ ',
                        filled: true,
                        fillColor: AppColors.neutral50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedUnit,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        filled: true,
                        fillColor: AppColors.neutral50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'h', child: Text('Hour')),
                        DropdownMenuItem(value: 'ea', child: Text('Each')),
                        DropdownMenuItem(value: 'day', child: Text('Day')),
                        DropdownMenuItem(value: 'flat', child: Text('Flat')),
                      ],
                      onChanged: (value) => setModalState(() => selectedUnit = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  filled: true,
                  fillColor: AppColors.neutral50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty && rateController.text.isNotEmpty) {
                      setState(() {
                        _lineItems.add(ProposalLineItem(
                          description: nameController.text,
                          unitPrice: double.tryParse(rateController.text) ?? 0,
                          unit: selectedUnit,
                          quantity: int.tryParse(qtyController.text) ?? 1,
                          days: 1,
                        ));
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Add Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _projectNameController.dispose();
    _scopeController.dispose();
    _emailSubjectController.dispose();
    _emailBodyController.dispose();
    super.dispose();
  }

  double get _subtotal => _lineItems.fold(0.0, (sum, item) => sum + item.amount);
  double get _taxableAmount => _subtotal;
  double get _taxAmount => _taxableAmount * (_taxRate / 100);
  double get _total => _subtotal + _taxAmount;

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('New Proposal'),
        actions: [
          if (_currentStep == 3)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.pop(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress Steps
          _buildProgressSteps(),

          // Step Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1ServicesScope(),
                _buildStep2Timeline(),
                _buildStep3CoverTerms(),
                _buildStep4Preview(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSteps() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.cardBackground,
      child: Row(
        children: [
          _buildStepIndicator(0, '1', 'Services & Scope'),
          _buildStepConnector(0),
          _buildStepIndicator(1, '2', 'Timeline'),
          _buildStepConnector(1),
          _buildStepIndicator(2, '3', 'Cover & Terms'),
          _buildStepConnector(2),
          _buildStepIndicator(3, '4', 'Preview'),
          const Spacer(),
          if (_currentStep > 0)
            TextButton(
              onPressed: () => _goToStep(_currentStep - 1),
              child: const Text('Back'),
            ),
          const SizedBox(width: 8),
          if (_currentStep < 3)
            ElevatedButton(
              onPressed: () => _goToStep(_currentStep + 1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Next'),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String number, String label) {
    final isCompleted = step < _currentStep;
    final isCurrent = step == _currentStep;
    final isActive = isCompleted || isCurrent;

    return GestureDetector(
      onTap: step <= _currentStep ? () => _goToStep(step) : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.success.withOpacity(0.2) : (isCurrent ? AppColors.accent : AppColors.neutral100),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: isCompleted
              ? const Icon(Icons.check, color: AppColors.success, size: 18)
              : Text(
                  number,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCurrent ? Colors.white : AppColors.textSecondary,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final isCompleted = step < _currentStep;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.chevron_right,
        size: 16,
        color: isCompleted ? AppColors.success : AppColors.textTertiary,
      ),
    );
  }

  // ============ STEP 1: SERVICES & SCOPE ============
  Widget _buildStep1ServicesScope() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line Items Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.list_alt, color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Line Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text('Add services and products to this proposal', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),

                // Project Name
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('Project Name', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(' *', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _projectNameController,
                        decoration: InputDecoration(
                          hintText: 'Enter project name (shown on cover page)',
                          filled: true,
                          fillColor: AppColors.neutral50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.warning),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.warning),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.warning_amber, size: 14, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            'Required - Will use company name if left empty',
                            style: TextStyle(fontSize: 11, color: AppColors.warning),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),

                // Send To Section - Mutually Exclusive Client OR Lead
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Send To', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          if (_recipientType != 'none')
                            TextButton.icon(
                              onPressed: _clearRecipient,
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Clear'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select either a client or a lead to send this proposal',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      // CLIENT Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _recipientType == 'client' ? AppColors.success : AppColors.border,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('CLIENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                              if (_recipientType == 'client')
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('SELECTED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.success)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Opacity(
                                  opacity: _recipientType == 'lead' ? 0.5 : 1.0,
                                  child: IgnorePointer(
                                    ignoring: _recipientType == 'lead',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: _recipientType == 'lead' ? AppColors.neutral100 : AppColors.neutral50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _recipientType == 'client' ? AppColors.accent : AppColors.border,
                                          width: _recipientType == 'client' ? 2 : 1,
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedClientId,
                                          hint: Text(
                                            _recipientType == 'lead' ? 'Disabled - Lead selected' : 'Select a client...',
                                            style: TextStyle(color: _recipientType == 'lead' ? AppColors.textTertiary : null),
                                          ),
                                          isExpanded: true,
                                          items: _clients.map((c) => DropdownMenuItem(
                                            value: c['id'] as String,
                                            child: Text(c['name'] as String),
                                          )).toList(),
                                          onChanged: _selectClient,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.neutral50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.person_add_outlined, size: 18),
                                  onPressed: _recipientType == 'lead' ? null : () {
                                    // TODO: Add new client modal
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // OR Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('OR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
                            ),
                            Expanded(child: Divider(color: AppColors.border)),
                          ],
                        ),
                      ),

                      // LEAD Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _recipientType == 'lead' ? AppColors.info : AppColors.border,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('LEAD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                              if (_recipientType == 'lead')
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('SELECTED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.info)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Opacity(
                            opacity: _recipientType == 'client' ? 0.5 : 1.0,
                            child: IgnorePointer(
                              ignoring: _recipientType == 'client',
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _recipientType == 'client' ? AppColors.neutral100 : AppColors.neutral50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _recipientType == 'lead' ? AppColors.info : AppColors.border,
                                    width: _recipientType == 'lead' ? 2 : 1,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedLeadId,
                                    hint: Text(
                                      _recipientType == 'client' ? 'Disabled - Client selected' : 'Select a lead...',
                                      style: TextStyle(color: _recipientType == 'client' ? AppColors.textTertiary : null),
                                    ),
                                    isExpanded: true,
                                    items: _leads.map((l) => DropdownMenuItem(
                                      value: l['id'] as String,
                                      child: Text(l['name'] as String),
                                    )).toList(),
                                    onChanged: _selectLead,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Selected Recipient Info Card
                      if (_selectedRecipient != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (_recipientType == 'client' ? AppColors.success : AppColors.info).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (_recipientType == 'client' ? AppColors.success : AppColors.info).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: (_recipientType == 'client' ? AppColors.success : AppColors.info).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    _recipientName[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _recipientType == 'client' ? AppColors.success : AppColors.info,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_recipientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(_recipientEmail, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.check_circle,
                                color: _recipientType == 'client' ? AppColors.success : AppColors.info,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),

                // Line Items Table
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.border)),
                        ),
                        child: Row(
                          children: [
                            const Expanded(flex: 2, child: Text('DESCRIPTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                            const SizedBox(width: 50, child: Text('UNIT\nPRICE', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                            const SizedBox(width: 40, child: Text('UNIT', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                            const SizedBox(width: 50, child: Text('QTY', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                          ],
                        ),
                      ),

                      // Line Items
                      if (_lineItems.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Icon(Icons.list_alt_outlined, size: 40, color: AppColors.textTertiary),
                              const SizedBox(height: 12),
                              Text('No items added yet', style: TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text('Use the buttons below to add services', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                            ],
                          ),
                        )
                      else
                        ...List.generate(_lineItems.length, (index) {
                          final item = _lineItems[index];
                          return Dismissible(
                            key: Key('item_$index'),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) {
                              setState(() => _lineItems.removeAt(index));
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              color: AppColors.error.withOpacity(0.1),
                              child: const Icon(Icons.delete_outline, color: AppColors.error),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: AppColors.border)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(flex: 2, child: Text(item.description)),
                                  SizedBox(width: 50, child: Text('\$${item.unitPrice.toInt()}', textAlign: TextAlign.center)),
                                  SizedBox(
                                    width: 40,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(item.unit),
                                        const Icon(Icons.unfold_more, size: 14),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.neutral50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Text(
                                        '${item.quantity}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                      // Add Item Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            TextButton.icon(
                              onPressed: _showAddItemModal,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Item'),
                            ),
                            const SizedBox(width: 16),
                            TextButton.icon(
                              onPressed: _showServicesModal,
                              icon: const Icon(Icons.category_outlined, size: 18),
                              label: const Text('From Services'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Totals
                      const Divider(),
                      _buildTotalRow('Subtotal:', currencyFormat.format(_subtotal)),
                      _buildTotalRow('Taxable Amount:', currencyFormat.format(_taxableAmount)),
                      _buildTotalRow('Tax Rate:', '${_taxRate.toStringAsFixed(2)} %'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ============ STEP 2: TIMELINE ============
  Widget _buildStep2Timeline() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Scope of Work Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.description_outlined, color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scope of Work', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text('Detailed description of deliverables', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    controller: _scopeController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.neutral50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Project Timeline Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_today_outlined, color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Project Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text('Visual schedule based on your line items', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        // Timeline Header
                        Row(
                          children: [
                            const Expanded(flex: 2, child: Text('Task', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                            ...['Start', 'Day 3', 'Day 5', 'Day 7', 'Day 8'].map((day) =>
                              Expanded(child: Text(day, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)))
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Timeline Rows
                        _buildTimelineRow('Civil Drafting - Civil En...', 0, 8, 8),
                        const SizedBox(height: 8),
                        _buildTimelineRow('Revisions - CD Plans re...', 0, 4, 8),
                        const SizedBox(height: 8),
                        _buildTimelineRow('TSM Map - TENTATIVE ...', 0, 4, 8),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Duration:', style: TextStyle(fontWeight: FontWeight.w500)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Text('8 days', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildTimelineRow(String task, int start, int duration, int totalDays) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(task, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          flex: 5,
          child: Container(
            height: 24,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 10,
                  child: Container(
                    height: 4,
                    color: AppColors.border,
                  ),
                ),
                Positioned(
                  left: (start / totalDays) * 100,
                  width: (duration / totalDays) * 100,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${duration}d',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============ STEP 3: COVER & TERMS ============
  Widget _buildStep3CoverTerms() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Cover Page Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.image_outlined, color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cover Page', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text("Your proposal's first impression", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Cover Preview
                Container(
                  height: 300,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1497366216548-37526070297c?w=800'),
                      fit: BoxFit.cover,
                      opacity: 0.6,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.upload, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text('Change Image', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 30,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text('P', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('https://plansrow.com', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 16),
                            const Text('PREPARED FOR', style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text(_recipientName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                            Text(DateFormat('M/d/yyyy').format(DateTime.now()), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 24),
                            Text(
                              _projectNameController.text.isNotEmpty 
                                  ? _projectNameController.text 
                                  : 'Proposal for $_recipientName',
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, height: 1.2),
                            ),
                            const SizedBox(height: 8),
                            const Text('Proposal #New', style: TextStyle(color: Colors.white60, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Company Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('P', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Plansrow LLC', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text('2469 N Pearwood ave\nFresno, CA 93727', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('1/16/2026', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('5128396700', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('https://plansrow.com', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Signature Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.check, color: AppColors.success, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Customer Signature', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text('Signature fields for acceptance', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Customer Acceptance (sign below):', style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.border)),
                          ),
                          child: Text('X', style: TextStyle(fontSize: 24, color: AppColors.textTertiary)),
                        ),
                        const Text('Signature', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.border)),
                          ),
                          child: Text('Print Name', style: TextStyle(fontSize: 14, color: AppColors.textTertiary)),
                        ),
                        const Text('Print Name', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
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

  // ============ STEP 4: PREVIEW ============
  Widget _buildStep4Preview() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Action Buttons
          Row(
            children: [
              _buildIconButton(Icons.download_outlined),
              const SizedBox(width: 8),
              _buildIconButton(Icons.bookmark_outline),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neutral300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Proposal sent!'), backgroundColor: AppColors.success),
                    );
                    context.go('/sales');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Send'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preview Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.elevated,
            ),
            child: Column(
              children: [
                // Cover Image
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1497366216548-37526070297c?w=800'),
                      fit: BoxFit.cover,
                      opacity: 0.6,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 20,
                        top: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text('P', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('https://plansrow.com', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 30,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PREPARED FOR', style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text(_recipientName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                            Text(DateFormat('M/d/yyyy').format(DateTime.now()), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 24),
                            Text(
                              _projectNameController.text.isNotEmpty 
                                  ? _projectNameController.text 
                                  : 'Proposal for $_recipientName',
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700, height: 1.2),
                            ),
                            const SizedBox(height: 8),
                            const Text('Professional Services Proposal', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('PROPOSAL #DRAFT', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, letterSpacing: 1)),
                            const SizedBox(height: 24),
                            Text(
                              currencyFormat.format(_total),
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
                            ),
                            const Text('Proposed Investment', style: TextStyle(color: Colors.white60, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('M/d/yyyy').format(DateTime.now()), style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text(_recipientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      if (_recipientEmail.isNotEmpty)
                        Text(_recipientEmail, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 20, color: AppColors.textSecondary),
    );
  }
}

// Data Models
class ProposalLineItem {
  String description;
  double unitPrice;
  String unit;
  int quantity;
  bool taxable;
  int days;

  ProposalLineItem({
    required this.description,
    required this.unitPrice,
    required this.unit,
    required this.quantity,
    this.taxable = false,
    this.days = 1,
  });

  double get amount => unitPrice * quantity;
}

// ============ SERVICES SELECTION MODAL ============
class _ServicesSelectionModal extends StatefulWidget {
  final List<Map<String, dynamic>> services;
  final Function(List<Map<String, dynamic>>) onServicesSelected;

  const _ServicesSelectionModal({
    required this.services,
    required this.onServicesSelected,
  });

  @override
  State<_ServicesSelectionModal> createState() => _ServicesSelectionModalState();
}

class _ServicesSelectionModalState extends State<_ServicesSelectionModal> {
  final Set<String> _selectedServiceIds = {};
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<String> get _categories {
    final cats = widget.services.map((s) => s['category'] as String).toSet().toList();
    return ['All', ...cats];
  }

  List<Map<String, dynamic>> get _filteredServices {
    return widget.services.where((service) {
      final matchesSearch = service['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          service['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || service['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Select Services', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      if (_selectedServiceIds.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_selectedServiceIds.length} selected',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Choose services to add to your proposal', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),

                  // Search
                  TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search services...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: AppColors.neutral50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedCategory = cat),
                            backgroundColor: AppColors.neutral50,
                            selectedColor: AppColors.accent.withOpacity(0.15),
                            checkmarkColor: AppColors.accent,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.accent : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.accent : AppColors.border,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Services List
            Expanded(
              child: _filteredServices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 12),
                          Text('No services found', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredServices.length,
                      itemBuilder: (context, index) {
                        final service = _filteredServices[index];
                        final isSelected = _selectedServiceIds.contains(service['id']);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accent.withOpacity(0.05) : AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.accent : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedServiceIds.remove(service['id']);
                                } else {
                                  _selectedServiceIds.add(service['id']);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Checkbox
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.accent : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSelected ? AppColors.accent : AppColors.border,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                                        : null,
                                  ),
                                  const SizedBox(width: 16),

                                  // Service Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          service['name'],
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          service['description'],
                                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.neutral100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                service['category'],
                                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Price
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        currencyFormat.format(service['rate']),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? AppColors.accent : AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '/${service['unit']}',
                                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Add Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedServiceIds.isEmpty
                        ? null
                        : () {
                            final selectedServices = widget.services
                                .where((s) => _selectedServiceIds.contains(s['id']))
                                .toList();
                            widget.onServicesSelected(selectedServices);
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: AppColors.neutral100,
                    ),
                    child: Text(
                      _selectedServiceIds.isEmpty
                          ? 'Select services to add'
                          : 'Add ${_selectedServiceIds.length} Service${_selectedServiceIds.length > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
