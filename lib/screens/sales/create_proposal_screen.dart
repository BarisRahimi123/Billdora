import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../main.dart';
import 'sales_screen.dart' show consultantsList;

class CreateProposalScreen extends StatefulWidget {
  final String? templateId;
  final String? leadId;
  final String? clientId;
  final String? leadName;
  final String? leadEmail;
  final String? leadCompany;

  const CreateProposalScreen({
    super.key, 
    this.templateId, 
    this.leadId, 
    this.clientId,
    this.leadName,
    this.leadEmail,
    this.leadCompany,
  });

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
  int _selectedCoverIndex = 0;
  final _emailSubjectController = TextEditingController();
  final _emailBodyController = TextEditingController();

  // Step 4: Collaborators
  final List<Map<String, dynamic>> _collaborators = [];
  
  // Collaborator status options
  static const Map<String, Map<String, dynamic>> _collaboratorStatuses = {
    'invited': {'label': 'Invited', 'color': 0xFF6B7280, 'icon': Icons.mail_outline},
    'viewed': {'label': 'Viewed', 'color': 0xFF3B82F6, 'icon': Icons.visibility_outlined},
    'in_progress': {'label': 'In Progress', 'color': 0xFFF59E0B, 'icon': Icons.edit_outlined},
    'submitted': {'label': 'Submitted', 'color': 0xFF10B981, 'icon': Icons.check_circle_outline},
    'revision_requested': {'label': 'Revision Requested', 'color': 0xFFF97316, 'icon': Icons.refresh},
    'revision_approved': {'label': 'Revision Approved', 'color': 0xFFFBBF24, 'icon': Icons.lock_open},
    'revision_denied': {'label': 'Revision Denied', 'color': 0xFFEF4444, 'icon': Icons.lock},
    'accepted': {'label': 'Accepted', 'color': 0xFF059669, 'icon': Icons.check_circle},
    'locked': {'label': 'Locked', 'color': 0xFF6B7280, 'icon': Icons.lock},
  };

  // Cover image options
  final List<Map<String, String>> _coverImages = [
    {'url': 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800', 'name': 'Modern Office'},
    {'url': 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800', 'name': 'Skyscraper'},
    {'url': 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=800', 'name': 'Business Meeting'},
    {'url': 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=800', 'name': 'Architecture'},
    {'url': 'https://images.unsplash.com/photo-1553877522-43269d4ea984?w=800', 'name': 'Workspace'},
    {'url': 'https://images.unsplash.com/photo-1497215842964-222b430dc094?w=800', 'name': 'Creative Studio'},
    {'url': 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800', 'name': 'Team Work'},
    {'url': 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=800', 'name': 'Collaboration'},
  ];

  String get _selectedCoverUrl => _coverImages[_selectedCoverIndex]['url']!;

  // Terms & Conditions - Default terms that can be toggled on/off
  final List<Map<String, dynamic>> _availableTerms = [
    {
      'id': '1',
      'title': 'Payment Terms',
      'content': 'Payment is due within 30 days of invoice date. A late fee of 1.5% per month will be applied to overdue balances.',
      'isSelected': true,
    },
    {
      'id': '2',
      'title': 'Scope Changes',
      'content': 'Any changes to the project scope after acceptance will require a written change order and may affect the timeline and cost.',
      'isSelected': true,
    },
    {
      'id': '3',
      'title': 'Intellectual Property',
      'content': 'Upon full payment, client receives full ownership of all deliverables. Provider retains the right to use work samples in portfolio.',
      'isSelected': true,
    },
    {
      'id': '4',
      'title': 'Cancellation Policy',
      'content': 'Either party may cancel with 14 days written notice. Client is responsible for payment of all work completed up to cancellation date.',
      'isSelected': true,
    },
    {
      'id': '5',
      'title': 'Confidentiality',
      'content': 'Both parties agree to keep confidential information private and not disclose to third parties without written consent.',
      'isSelected': false,
    },
    {
      'id': '6',
      'title': 'Limitation of Liability',
      'content': 'Provider liability is limited to the total amount paid under the agreement. Provider is not liable for indirect or consequential damages.',
      'isSelected': false,
    },
    {
      'id': '7',
      'title': 'Warranty',
      'content': 'All work is warranted to be free from defects for 30 days after delivery. Issues reported within this period will be addressed at no additional cost.',
      'isSelected': false,
    },
  ];

  List<Map<String, dynamic>> get _selectedTerms => _availableTerms.where((t) => t['isSelected'] == true).toList();

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
          if (_currentStep == 4)
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
                _buildStep4Collaborators(),
                _buildStep5Preview(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSteps() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: AppColors.cardBackground,
      child: Column(
        children: [
          // Step indicators row (scrollable for mobile)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStepIndicator(0, '1', 'Scope'),
                _buildStepConnector(0),
                _buildStepIndicator(1, '2', 'Timeline'),
                _buildStepConnector(1),
                _buildStepIndicator(2, '3', 'Terms'),
                _buildStepConnector(2),
                _buildStepIndicator(3, '4', 'Team'),
                _buildStepConnector(3),
                _buildStepIndicator(4, '5', 'Preview'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                TextButton.icon(
                  onPressed: () => _goToStep(_currentStep - 1),
                  icon: const Icon(Icons.chevron_left, size: 18),
                  label: const Text('Back'),
                )
              else
                const SizedBox(width: 80),
              Text(
                'Step ${_currentStep + 1} of 5',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              if (_currentStep < 4)
                ElevatedButton(
                  onPressed: () => _goToStep(_currentStep + 1),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_currentStep == 3 ? 'Skip' : 'Next'),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                )
              else
                const SizedBox(width: 80),
            ],
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

  // Calculate total project duration based on scheduling
  int get _totalDuration {
    if (_lineItems.isEmpty) return 0;
    
    int maxEndDay = 0;
    for (var item in _lineItems) {
      int endDay = item.startDay + item.days;
      if (endDay > maxEndDay) maxEndDay = endDay;
    }
    return maxEndDay;
  }

  // Get scheduling options for a task
  List<String> _getSchedulingOptions(int currentIndex) {
    List<String> options = ['Day 1'];
    
    for (int i = 0; i < currentIndex; i++) {
      final prevItem = _lineItems[i];
      options.add('After "${_truncateText(prevItem.description, 15)}"');
      options.add('With "${_truncateText(prevItem.description, 15)}"');
    }
    
    return options;
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Update task scheduling based on selection
  void _updateTaskScheduling(int index, String option) {
    setState(() {
      if (option == 'Day 1') {
        _lineItems[index].startDay = 0;
      } else if (option.startsWith('After')) {
        // Find the task it's after
        for (int i = 0; i < index; i++) {
          if (option.contains(_truncateText(_lineItems[i].description, 15))) {
            _lineItems[index].startDay = _lineItems[i].startDay + _lineItems[i].days;
            break;
          }
        }
      } else if (option.startsWith('With')) {
        // Find the task it's parallel with
        for (int i = 0; i < index; i++) {
          if (option.contains(_truncateText(_lineItems[i].description, 15))) {
            _lineItems[index].startDay = _lineItems[i].startDay;
            break;
          }
        }
      }
    });
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
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calendar_today_outlined, color: AppColors.accent, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Project Timeline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            if (_lineItems.isNotEmpty)
                              Text(
                                'Set duration for each task',
                                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                              ),
                          ],
                        ),
                      ),
                      // Total duration badge
                      if (_lineItems.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_totalDuration days',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent),
                          ),
                        ),
                    ],
                  ),
                ),

                // Empty State
                if (_lineItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.event_note_outlined, size: 36, color: AppColors.textTertiary),
                          const SizedBox(height: 8),
                          Text('No tasks yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Add services in Step 1', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 32,
                            child: OutlinedButton.icon(
                              onPressed: () => _goToStep(0),
                              icon: const Icon(Icons.arrow_back, size: 14),
                              label: const Text('Add Services', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // Task Configuration List - Compact Design
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: List.generate(_lineItems.length, (index) {
                        final item = _lineItems[index];
                        final options = _getSchedulingOptions(index);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              // Task Number Badge
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _getTaskColor(index),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              
                              // Task Name
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.description,
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Compact Days Control
                              Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.neutral50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        if (item.days > 1) setState(() => item.days--);
                                      },
                                      child: Container(
                                        width: 28,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          border: Border(right: BorderSide(color: AppColors.border)),
                                        ),
                                        child: Icon(Icons.remove, size: 14, color: AppColors.textSecondary),
                                      ),
                                    ),
                                    Container(
                                      width: 32,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${item.days}d',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => setState(() => item.days++),
                                      child: Container(
                                        width: 28,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          border: Border(left: BorderSide(color: AppColors.border)),
                                        ),
                                        child: Icon(Icons.add, size: 14, color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Compact Scheduling Dropdown
                              Container(
                                height: 32,
                                constraints: const BoxConstraints(maxWidth: 100),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.neutral50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _getSchedulingValue(index),
                                    isExpanded: true,
                                    isDense: true,
                                    icon: const Icon(Icons.unfold_more, size: 14),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                                    items: options.map((opt) => DropdownMenuItem(
                                      value: opt,
                                      child: Text(opt, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                                    )).toList(),
                                    onChanged: (value) {
                                      if (value != null) _updateTaskScheduling(index, value);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Visual Timeline (Gantt Chart) - Compact
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Visual Timeline', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary)),
                              Text('${_lineItems.length} tasks', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Timeline Rows (compact)
                          ...List.generate(_lineItems.length, (index) {
                            final item = _lineItems[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _buildCompactTimelineRow(
                                item.description,
                                item.startDay,
                                item.days,
                                _totalDuration > 0 ? _totalDuration : 1,
                                _getTaskColor(index),
                                index + 1,
                              ),
                            );
                          }),

                          // Total Duration footer (compact)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.schedule, size: 14, color: AppColors.accent),
                                const SizedBox(width: 6),
                                Text('Total: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Text(
                                  '$_totalDuration day${_totalDuration != 1 ? 's' : ''}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Get the current scheduling value for display
  String _getSchedulingValue(int index) {
    if (index == 0) return 'Day 1';
    
    final item = _lineItems[index];
    
    // Check if it starts at day 0
    if (item.startDay == 0) return 'Day 1';
    
    // Find what task this is relative to
    for (int i = 0; i < index; i++) {
      final prevItem = _lineItems[i];
      // Starts after previous task
      if (item.startDay == prevItem.startDay + prevItem.days) {
        return 'After "${_truncateText(prevItem.description, 15)}"';
      }
      // Starts with previous task (parallel)
      if (item.startDay == prevItem.startDay) {
        return 'With "${_truncateText(prevItem.description, 15)}"';
      }
    }
    
    return 'Day 1';
  }

  // Build timeline header labels
  List<Widget> _buildTimelineHeaders() {
    final total = _totalDuration > 0 ? _totalDuration : 1;
    List<Widget> headers = [];
    
    // Show key day markers
    List<int> markers = [1];
    if (total > 2) markers.add((total / 2).round());
    if (total > 1) markers.add(total);
    
    markers = markers.toSet().toList()..sort();
    
    for (var day in markers) {
      headers.add(Text(
        'Day $day',
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ));
    }
    
    return headers;
  }

  // Get color for task based on index
  Color _getTaskColor(int index) {
    final colors = [
      AppColors.accent,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
      const Color(0xFF8B5CF6), // purple
      const Color(0xFFEC4899), // pink
    ];
    return colors[index % colors.length];
  }

  Widget _buildDynamicTimelineRow(String task, int start, int duration, int totalDays, Color color) {
    // Calculate positions as percentages
    final startPercent = start / totalDays;
    final widthPercent = duration / totalDays;

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            task,
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final barStart = startPercent * totalWidth;
              final barWidth = (widthPercent * totalWidth).clamp(30.0, totalWidth - barStart);

              return Container(
                height: 28,
                child: Stack(
                  children: [
                    // Background track
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 12,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Task bar
                    Positioned(
                      left: barStart,
                      width: barWidth,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
              );
            },
          ),
        ),
      ],
    );
  }

  // Compact timeline row for minimalist design
  Widget _buildCompactTimelineRow(String task, int start, int duration, int totalDays, Color color, int index) {
    final startPercent = start / totalDays;
    final widthPercent = duration / totalDays;

    return Row(
      children: [
        // Task number + name (compact)
        SizedBox(
          width: 80,
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text('$index', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  task,
                  style: const TextStyle(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Timeline bar
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final barStart = startPercent * totalWidth;
              final barWidth = (widthPercent * totalWidth).clamp(24.0, totalWidth - barStart);

              return Container(
                height: 20,
                child: Stack(
                  children: [
                    // Background track
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 9,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.border.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    // Task bar
                    Positioned(
                      left: barStart,
                      width: barWidth,
                      top: 2,
                      bottom: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${duration}d',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
          // Cover Preview Card (Compact)
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Change Button
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.image_outlined, color: AppColors.accent, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cover Page', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            Text("First impression matters", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showCoverImagePicker,
                        icon: const Icon(Icons.photo_library_outlined, size: 16),
                        label: const Text('Change'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Cover Preview (Compact)
                GestureDetector(
                  onTap: _showCoverImagePicker,
                  child: Container(
                    height: 220,
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(_selectedCoverUrl),
                        fit: BoxFit.cover,
                        opacity: 0.6,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Tap to change overlay
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.touch_app, color: Colors.white70, size: 14),
                                SizedBox(width: 4),
                                Text('Tap to change', style: TextStyle(color: Colors.white70, fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                        // Content
                        Positioned(
                          left: 16,
                          bottom: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PREPARED FOR', style: TextStyle(color: Colors.white60, fontSize: 9, letterSpacing: 1)),
                              const SizedBox(height: 2),
                              Text(
                                _recipientName,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(DateFormat('M/d/yyyy').format(DateTime.now()), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              const SizedBox(height: 12),
                              Text(
                                _projectNameController.text.isNotEmpty 
                                    ? _projectNameController.text 
                                    : 'Proposal for $_recipientName',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, height: 1.2),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Company Info Card (Compact)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('P', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Plansrow LLC', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('2469 N Pearwood ave, Fresno, CA', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.business_outlined, size: 18, color: AppColors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Terms & Signature Card (Compact)
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              children: [
                // Signature Section
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.draw_outlined, color: AppColors.success, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('E-Signature', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('Client signs digitally', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Enabled', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Payment Terms
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.payments_outlined, color: AppColors.info, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment Terms', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('Due upon receipt', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Validity
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.timer_outlined, color: AppColors.warning, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Proposal Validity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('Valid for 30 days', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Quick Summary Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL AMOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(symbol: '\$').format(_total),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$_totalDuration days',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.schedule, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Terms & Conditions Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.gavel_outlined, color: AppColors.purple, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Terms & Conditions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('${_selectedTerms.length} terms included', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showTermsEditor,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Selected Terms Preview
                if (_selectedTerms.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text('No terms selected. Tap Edit to add terms.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(10),
                    itemCount: _selectedTerms.length > 3 ? 3 : _selectedTerms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final term = _selectedTerms[index];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.neutral50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 14, color: AppColors.success),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                term['title'],
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                if (_selectedTerms.length > 3)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Text(
                      '+${_selectedTerms.length - 3} more terms...',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Show Terms Editor Modal
  void _showTermsEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.gavel_outlined, color: AppColors.purple),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Terms & Conditions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                Text('Select terms to include in proposal', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Info Banner
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.info.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.info),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Toggle terms on/off. You can manage default terms in Settings.',
                          style: TextStyle(fontSize: 11, color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
                // Terms List
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _availableTerms.length,
                    itemBuilder: (context, index) {
                      final term = _availableTerms[index];
                      final isSelected = term['isSelected'] == true;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent.withOpacity(0.05) : AppColors.neutral50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.accent.withOpacity(0.3) : AppColors.border,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            setModalState(() {
                              term['isSelected'] = !isSelected;
                            });
                            setState(() {});
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        term['title'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        term['content'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          height: 1.4,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Footer with Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              for (var term in _availableTerms) {
                                term['isSelected'] = false;
                              }
                            });
                            setState(() {});
                          },
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Done (${_selectedTerms.length} selected)'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Show cover image picker modal
  void _showCoverImagePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Choose Cover Image', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Select a background image for your proposal cover', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              
              // Image Grid
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: _coverImages.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedCoverIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCoverIndex = index);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.accent : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                _coverImages[index]['url']!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: AppColors.neutral100,
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                },
                              ),
                              // Gradient overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.6),
                                    ],
                                  ),
                                ),
                              ),
                              // Name label
                              Positioned(
                                left: 8,
                                bottom: 8,
                                child: Text(
                                  _coverImages[index]['name']!,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                              // Selected checkmark
                              if (isSelected)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Tags for the proposal
  List<String> _selectedTags = [];
  final List<String> _availableTags = ['Urgent', 'VIP Client', 'Follow-up', 'New Business', 'Renewal', 'High Priority'];

  // Payment schedule
  String _paymentSchedule = '100_completion'; // Options: 100_completion, 50_50, milestone
  final Map<String, String> _paymentOptions = {
    '100_completion': '100% upon completion',
    '50_50': '50% upfront, 50% on completion',
    'milestone': 'Milestone-based payments',
    'net_30': 'Net 30 days',
  };

  // Email message
  late TextEditingController _emailMessageController;

  @override
  void initState() {
    super.initState();
    _lineItems.clear();
    _emailMessageController = TextEditingController(
      text: 'Thank you for the opportunity to work together. I have attached the proposal for your consideration which includes a detailed Scope of Work, deliverable schedule, and investment summary.\n\nPlease review and let me know if you have any questions.',
    );
    
    // Pre-select lead if leadId was passed
    if (widget.leadId != null) {
      // Check if lead exists in list, if not add it
      final leadExists = _leads.any((l) => l['id'] == widget.leadId);
      if (!leadExists && widget.leadName != null) {
        _leads.add({
          'id': widget.leadId,
          'name': widget.leadName ?? 'Lead',
          'email': widget.leadEmail ?? '',
          'phone': '',
          'company': widget.leadCompany ?? '',
        });
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_leads.any((l) => l['id'] == widget.leadId)) {
          _selectLead(widget.leadId);
        }
      });
    }
    
    // Pre-select client if clientId was passed
    if (widget.clientId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _selectClient(widget.clientId);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _projectNameController.dispose();
    _scopeController.dispose();
    _emailSubjectController.dispose();
    _emailBodyController.dispose();
    _emailMessageController.dispose();
    super.dispose();
  }

  // ============ STEP 4: COLLABORATORS ============
  Widget _buildStep4Collaborators() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent.withOpacity(0.1), AppColors.purple.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.people_outline, color: AppColors.accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Invite Collaborators',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Invite sub-consultants to add their services and pricing to this proposal.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Add Collaborator Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAddCollaboratorModal,
              icon: const Icon(Icons.person_add_outlined, size: 20),
              label: const Text('Add Collaborator'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.accent, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Collaborators List
          if (_collaborators.isEmpty)
            _buildEmptyCollaboratorsState()
          else
            _buildCollaboratorsList(),

          const SizedBox(height: 16),

          // Status Summary (when collaborators exist)
          if (_collaborators.isNotEmpty) ...[
            _buildCollaboratorStatusSummary(),
            const SizedBox(height: 16),
          ],

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _collaborators.isEmpty ? 'Ready to continue?' : 'What would you like to do?',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                
                if (_collaborators.isEmpty) ...[
                  // No collaborators - simple continue
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _goToStep(4),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Continue to Preview'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _saveDraft,
                      child: Text('Save as Draft', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                ] else ...[
                  // Has collaborators - multiple options
                  _buildCollaboratorActionOption(
                    icon: Icons.save_outlined,
                    title: 'Save & Wait for Responses',
                    subtitle: 'Save draft and wait for collaborators to submit their pricing',
                    color: AppColors.info,
                    onTap: () {
                      _saveDraft();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Proposal saved! You\'ll be notified when collaborators respond.'),
                          backgroundColor: AppColors.info,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildCollaboratorActionOption(
                    icon: Icons.arrow_forward,
                    title: 'Continue to Preview',
                    subtitle: 'Review your proposal (collaborator prices pending)',
                    color: AppColors.accent,
                    onTap: () => _goToStep(4),
                  ),
                  const SizedBox(height: 10),
                  _buildCollaboratorActionOption(
                    icon: Icons.send_outlined,
                    title: 'Send Without Collaborators',
                    subtitle: 'Collaborators will send their proposals independently',
                    color: AppColors.warning,
                    onTap: () => _showIndependentSendConfirmation(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Info Note
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.neutral50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _collaborators.isEmpty 
                        ? 'This step is optional - skip if you don\'t need collaborators.'
                        : 'Collaborators will receive email invitations to submit their pricing.',
                    style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaboratorStatusSummary() {
    final pending = _collaborators.where((c) => !['submitted', 'accepted', 'locked'].contains(c['status'])).length;
    final submitted = _collaborators.where((c) => ['submitted', 'accepted', 'locked'].contains(c['status'])).length;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pending > 0 ? AppColors.warning.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: pending > 0 ? AppColors.warning.withOpacity(0.3) : AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            pending > 0 ? Icons.hourglass_empty : Icons.check_circle_outline,
            size: 20,
            color: pending > 0 ? AppColors.warning : AppColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pending > 0 
                      ? '$pending collaborator${pending > 1 ? 's' : ''} pending'
                      : 'All collaborators have responded!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: pending > 0 ? AppColors.warning : AppColors.success,
                  ),
                ),
                if (submitted > 0)
                  Text(
                    '$submitted submitted',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          if (pending > 0)
            TextButton(
              onPressed: () {
                // Send reminder to pending collaborators
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder sent to pending collaborators'), backgroundColor: AppColors.info),
                );
              },
              child: const Text('Send Reminder', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildCollaboratorActionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  void _saveDraft() {
    // Save proposal as draft
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Proposal saved as draft'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showIndependentSendConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Send Independently?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your collaborators will send their proposals separately to the client.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What happens:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _buildBulletPoint('You send your proposal with your services only'),
                  _buildBulletPoint('Collaborators are notified to send their proposals'),
                  _buildBulletPoint('Client receives separate proposals from each'),
                  _buildBulletPoint('You can forward collaborator proposals to client'),
                ],
              ),
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
              _goToStep(4); // Go to preview
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: AppColors.textSecondary)),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildEmptyCollaboratorsState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(Icons.group_add_outlined, size: 36, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No collaborators yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite sub-consultants to contribute their\nservices and pricing to this proposal.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaboratorsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Collaborators (${_collaborators.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (_collaborators.any((c) => c['status'] == 'submitted'))
              TextButton.icon(
                onPressed: () {
                  // Lock all collaborators
                  setState(() {
                    for (var c in _collaborators) {
                      if (c['status'] == 'submitted' || c['status'] == 'accepted') {
                        c['status'] = 'locked';
                      }
                    }
                  });
                },
                icon: const Icon(Icons.lock_outline, size: 16),
                label: const Text('Lock All'),
                style: TextButton.styleFrom(foregroundColor: AppColors.warning),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ..._collaborators.asMap().entries.map((entry) {
          final index = entry.key;
          final collaborator = entry.value;
          return _buildCollaboratorCard(collaborator, index);
        }),
      ],
    );
  }

  Widget _buildCollaboratorCard(Map<String, dynamic> collaborator, int index) {
    final status = collaborator['status'] as String;
    final statusInfo = _collaboratorStatuses[status]!;
    final statusColor = Color(statusInfo['color'] as int);
    final hasSubmission = status == 'submitted' || status == 'accepted' || status == 'locked';
    final isRevisionRequested = status == 'revision_requested';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRevisionRequested ? AppColors.warning.withOpacity(0.5) : AppColors.border,
          width: isRevisionRequested ? 2 : 1,
        ),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      (collaborator['name'] as String)[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collaborator['name'] as String,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        collaborator['company'] as String,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(statusInfo['icon'] as IconData, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusInfo['label'] as String,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                          ),
                          if (collaborator['deadline'] != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.schedule, size: 11, color: AppColors.textTertiary),
                            const SizedBox(width: 3),
                            Text(
                              'Due ${DateFormat('M/d').format(collaborator['deadline'] as DateTime)}',
                              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (value) => _handleCollaboratorAction(value, index),
                  itemBuilder: (context) => [
                    if (isRevisionRequested) ...[
                      const PopupMenuItem(value: 'approve_revision', child: Text('Approve Revision')),
                      const PopupMenuItem(value: 'deny_revision', child: Text('Deny Revision')),
                      const PopupMenuDivider(),
                    ],
                    if (hasSubmission)
                      const PopupMenuItem(value: 'view_submission', child: Text('View Submission')),
                    const PopupMenuItem(value: 'resend_invite', child: Text('Resend Invitation')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit Settings')),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Revision Request Banner
          if (isRevisionRequested)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                border: Border(top: BorderSide(color: AppColors.warning.withOpacity(0.3))),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note, size: 18, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Revision Requested',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          collaborator['revisionReason'] ?? 'No reason provided',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _handleCollaboratorAction('approve_revision', index),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.success.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Approve', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Submission Preview
          if (hasSubmission && collaborator['lineItems'] != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(collaborator['lineItems'] as List).length} items submitted',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        NumberFormat.currency(symbol: '\$').format(
                          (collaborator['lineItems'] as List).fold(0.0, (sum, item) => sum + (item['total'] as double)),
                        ),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  if (status != 'accepted' && status != 'locked') ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleCollaboratorAction('view_submission', index),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                            child: const Text('Review', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => collaborator['status'] = 'accepted');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text('Accept', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

          // Settings Preview (collapsed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _buildSettingChip(
                  collaborator['showPricing'] == true ? 'Pricing Visible' : 'Pricing Hidden',
                  collaborator['showPricing'] == true ? Icons.visibility : Icons.visibility_off,
                ),
                const SizedBox(width: 8),
                _buildSettingChip(
                  collaborator['paymentMode'] == 'owner' ? 'You Pay' : 'Client Pays',
                  Icons.payments_outlined,
                ),
                const SizedBox(width: 8),
                _buildSettingChip(
                  collaborator['displayMode'] == 'transparent' ? 'Named' : 'Anonymous',
                  Icons.badge_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _handleCollaboratorAction(String action, int index) {
    final collaborator = _collaborators[index];
    
    switch (action) {
      case 'approve_revision':
        setState(() => collaborator['status'] = 'revision_approved');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Revision approved'), backgroundColor: AppColors.success),
        );
        break;
      case 'deny_revision':
        setState(() => collaborator['status'] = 'submitted');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Revision denied')),
        );
        break;
      case 'view_submission':
        _showSubmissionPreview(collaborator);
        break;
      case 'resend_invite':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invitation resent to ${collaborator['email']}')),
        );
        break;
      case 'edit':
        _showEditCollaboratorModal(collaborator, index);
        break;
      case 'remove':
        _confirmRemoveCollaborator(index);
        break;
    }
  }

  void _showSubmissionPreview(Map<String, dynamic> collaborator) {
    final lineItems = collaborator['lineItems'] as List? ?? [];
    final total = lineItems.fold(0.0, (sum, item) => sum + (item['total'] as double));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            (collaborator['name'] as String)[0].toUpperCase(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(collaborator['name'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            Text(collaborator['company'] as String, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Text(
                        NumberFormat.currency(symbol: '\$').format(total),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Line Items
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: lineItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = lineItems[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['description'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                              Text(
                                '${item['qty']} × ${NumberFormat.currency(symbol: '\$').format(item['rate'])}',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          NumberFormat.currency(symbol: '\$').format(item['total']),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveCollaborator(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Remove Collaborator?'),
        content: Text('Are you sure you want to remove ${_collaborators[index]['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _collaborators.removeAt(index));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddCollaboratorModal() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final companyController = TextEditingController();
    final roleController = TextEditingController();
    final notesController = TextEditingController();
    final linkController = TextEditingController();
    bool showPricing = false;
    String paymentMode = 'client'; // 'owner' or 'client'
    String displayMode = 'transparent'; // 'transparent' or 'anonymous'
    DateTime deadline = DateTime.now().add(const Duration(days: 7));
    String? selectedConsultantId;
    List<Map<String, String>> projectLinks = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Add Collaborator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  'Invite a sub-consultant to contribute to this proposal',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                // Select from existing consultants
                if (consultantsList.isNotEmpty) ...[
                  _buildSectionHeader('Select Existing Consultant'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selectedConsultantId != null ? AppColors.accent : AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: selectedConsultantId,
                        isExpanded: true,
                        hint: Row(
                          children: [
                            Icon(Icons.people_outline, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 10),
                            Text('Select from your consultants', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Enter new consultant', style: TextStyle(fontStyle: FontStyle.italic)),
                          ),
                          ...consultantsList.map((c) => DropdownMenuItem<String?>(
                            value: c['id'] as String,
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      c['name'][0].toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.accent),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(c['name'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                                      Text(
                                        '${c['company']} • ${c['specialty']}',
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                        onChanged: (val) {
                          setModalState(() {
                            selectedConsultantId = val;
                            if (val != null) {
                              final consultant = consultantsList.firstWhere((c) => c['id'] == val);
                              nameController.text = consultant['name'] ?? '';
                              emailController.text = consultant['email'] ?? '';
                              companyController.text = consultant['company'] ?? '';
                              roleController.text = consultant['specialty'] ?? '';
                            } else {
                              nameController.clear();
                              emailController.clear();
                              companyController.clear();
                              roleController.clear();
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Divider with "OR"
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
                      ),
                      Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Contact Info Section
                _buildSectionHeader('Contact Information'),
                const SizedBox(height: 12),
                _buildModalTextField('Name *', 'Contact name', nameController),
                const SizedBox(height: 12),
                _buildModalTextField('Email *', 'email@company.com', emailController, TextInputType.emailAddress),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildModalTextField('Company', 'Company name', companyController)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildModalTextField('Role / Specialty', 'e.g., Engineer', roleController)),
                  ],
                ),
                const SizedBox(height: 20),

                // Deadline Section
                _buildSectionHeader('Deadline'),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: deadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) setModalState(() => deadline = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Text(DateFormat('MMMM d, yyyy').format(deadline)),
                        const Spacer(),
                        Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Visibility Settings
                _buildSectionHeader('Visibility Settings'),
                const SizedBox(height: 12),
                _buildToggleOption(
                  'Show my pricing',
                  'Collaborator can see your line items and pricing',
                  showPricing,
                  (val) => setModalState(() => showPricing = val),
                ),
                const SizedBox(height: 20),

                // Payment Structure
                _buildSectionHeader('Payment Structure'),
                const SizedBox(height: 12),
                _buildRadioOption(
                  'I will pay this collaborator',
                  'Their fee will be hidden from the client',
                  paymentMode == 'owner',
                  () => setModalState(() => paymentMode = 'owner'),
                ),
                const SizedBox(height: 8),
                _buildRadioOption(
                  'Client pays directly',
                  'Their fee will be visible on the proposal',
                  paymentMode == 'client',
                  () => setModalState(() => paymentMode = 'client'),
                ),
                const SizedBox(height: 20),

                // Display Mode
                _buildSectionHeader('Client Display'),
                const SizedBox(height: 12),
                _buildRadioOption(
                  'Show with name & company',
                  'Transparent - Client sees who the collaborator is',
                  displayMode == 'transparent',
                  () => setModalState(() => displayMode = 'transparent'),
                ),
                const SizedBox(height: 8),
                _buildRadioOption(
                  'Show as anonymous line items',
                  'Hidden - Only pricing shown, no collaborator info',
                  displayMode == 'anonymous',
                  () => setModalState(() => displayMode = 'anonymous'),
                ),
                const SizedBox(height: 20),

                // Notes
                _buildSectionHeader('Notes for Collaborator'),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Instructions or scope details...',
                    filled: true,
                    fillColor: AppColors.neutral50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                  ),
                ),
                const SizedBox(height: 20),

                // Project Documents/Links Section
                _buildSectionHeader('Project Documents & Links'),
                const SizedBox(height: 8),
                Text(
                  'Share files to help collaborators prepare accurate proposals',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 12),
                
                // Link Input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: linkController,
                        decoration: InputDecoration(
                          hintText: 'Paste Dropbox, Drive, OneDrive URL...',
                          hintStyle: TextStyle(fontSize: 13),
                          filled: true,
                          fillColor: AppColors.neutral50,
                          prefixIcon: Icon(Icons.link, size: 18, color: AppColors.textSecondary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          if (linkController.text.trim().isNotEmpty) {
                            setModalState(() {
                              // Detect link type
                              final url = linkController.text.trim();
                              String type = 'link';
                              String icon = 'link';
                              if (url.contains('dropbox.com')) {
                                type = 'Dropbox';
                                icon = 'dropbox';
                              } else if (url.contains('drive.google.com')) {
                                type = 'Google Drive';
                                icon = 'gdrive';
                              } else if (url.contains('onedrive') || url.contains('sharepoint')) {
                                type = 'OneDrive';
                                icon = 'onedrive';
                              } else if (url.contains('box.com')) {
                                type = 'Box';
                                icon = 'box';
                              }
                              projectLinks.add({'url': url, 'type': type, 'icon': icon});
                              linkController.clear();
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quick Cloud Storage Buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildCloudStorageChip('Dropbox', Icons.cloud_outlined, const Color(0xFF0061FF)),
                    _buildCloudStorageChip('Google Drive', Icons.add_to_drive, const Color(0xFF4285F4)),
                    _buildCloudStorageChip('OneDrive', Icons.cloud_queue, const Color(0xFF0078D4)),
                  ],
                ),
                const SizedBox(height: 12),

                // Added Links List
                if (projectLinks.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.folder_shared_outlined, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text('${projectLinks.length} file${projectLinks.length > 1 ? 's' : ''} attached', 
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...projectLinks.asMap().entries.map((entry) {
                          final index = entry.key;
                          final link = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: _getLinkColor(link['type']!).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    _getLinkIcon(link['type']!),
                                    size: 14,
                                    color: _getLinkColor(link['type']!),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(link['type']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                      Text(
                                        link['url']!,
                                        style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setModalState(() => projectLinks.removeAt(index)),
                                  child: Icon(Icons.close, size: 16, color: AppColors.textTertiary),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 12),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (nameController.text.isEmpty || emailController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter name and email'), backgroundColor: AppColors.error),
                        );
                        return;
                      }

                      setState(() {
                        _collaborators.add({
                          'id': DateTime.now().millisecondsSinceEpoch.toString(),
                          'name': nameController.text,
                          'email': emailController.text,
                          'company': companyController.text.isNotEmpty ? companyController.text : 'Independent',
                          'role': roleController.text,
                          'notes': notesController.text,
                          'deadline': deadline,
                          'showPricing': showPricing,
                          'paymentMode': paymentMode,
                          'displayMode': displayMode,
                          'status': 'invited',
                          'lineItems': null,
                          'projectLinks': List<Map<String, String>>.from(projectLinks),
                        });
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invitation sent to ${emailController.text}'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: const Text('Send Invitation'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditCollaboratorModal(Map<String, dynamic> collaborator, int index) {
    // Similar to add modal but pre-filled - simplified for now
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit collaborator settings')),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
    );
  }

  Widget _buildModalTextField(String label, String hint, TextEditingController controller, [TextInputType? keyboardType]) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.neutral50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.accent)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildCloudStorageChip(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        // In a real app, this would open the respective cloud storage picker
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Open $label picker - paste your shared link above'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  IconData _getLinkIcon(String type) {
    switch (type) {
      case 'Dropbox': return Icons.cloud_outlined;
      case 'Google Drive': return Icons.add_to_drive;
      case 'OneDrive': return Icons.cloud_queue;
      case 'Box': return Icons.inventory_2_outlined;
      default: return Icons.link;
    }
  }

  Color _getLinkColor(String type) {
    switch (type) {
      case 'Dropbox': return const Color(0xFF0061FF);
      case 'Google Drive': return const Color(0xFF4285F4);
      case 'OneDrive': return const Color(0xFF0078D4);
      case 'Box': return const Color(0xFF0061D5);
      default: return AppColors.accent;
    }
  }

  Widget _buildToggleOption(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: value ? AppColors.accent.withOpacity(0.3) : AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String title, String subtitle, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withOpacity(0.05) : AppColors.neutral50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.accent : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? AppColors.accent : AppColors.border, width: 2),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: selected ? AppColors.accent : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ STEP 5: PREVIEW ============
  Widget _buildStep5Preview() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMMM d, yyyy');
    
    // Collaborator analysis for status banner
    final hasCollaborators = _collaborators.isNotEmpty;
    final pendingCollaborators = _collaborators.where((c) => 
      c['status'] == 'invited' || c['status'] == 'accepted' || c['status'] == 'revision_requested'
    ).toList();
    final submittedCollaborators = _collaborators.where((c) => 
      c['status'] == 'submitted' || c['status'] == 'locked'
    ).toList();
    final allSubmitted = hasCollaborators && pendingCollaborators.isEmpty;

    return Column(
      children: [
        // Collaborator Status Banner (if applicable)
        if (hasCollaborators)
          _buildCollaboratorStatusBanner(pendingCollaborators, submittedCollaborators, allSubmitted),
        
        // Sticky Action Bar at Top
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            boxShadow: AppShadows.sm,
          ),
          child: Row(
            children: [
              // Quick Actions - Icon only for compact fit
              _buildIconAction(Icons.download_outlined, 'Download PDF', _downloadProposal),
              _buildIconAction(Icons.bookmark_add_outlined, 'Save as Template', _showSaveAsTemplateModal),
              _buildIconAction(
                _selectedTags.isEmpty ? Icons.label_outline : Icons.label,
                'Tags${_selectedTags.isNotEmpty ? ' (${_selectedTags.length})' : ''}', 
                _showTagsModal,
              ),
              const Spacer(),
              // Main Actions - Compact
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: _saveProposalAsDraft,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('Save', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: _recipientEmail.isNotEmpty ? _showSendProposalModal : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 14),
                  label: const Text('Send', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ),

        // Scrollable Proposal Document
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ============ COVER PAGE ============
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    children: [
                      // Cover Image
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          image: DecorationImage(
                            image: NetworkImage(_selectedCoverUrl),
                            fit: BoxFit.cover,
                            opacity: 0.6,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 16,
                              bottom: 16,
                              right: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _projectNameController.text.isNotEmpty 
                                        ? _projectNameController.text 
                                        : 'Proposal for $_recipientName',
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, height: 1.2),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text('Prepared for ', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                                      Text(_recipientName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Company Info
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(child: Text('P', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent))),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Plansrow LLC', style: TextStyle(fontWeight: FontWeight.w600)),
                                  Text('2469 N Pearwood Ave, Fresno, CA 93727', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Text(dateFormat.format(DateTime.now()), style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ============ EMAIL MESSAGE (Editable) ============
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
                          Icon(Icons.email_outlined, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          const Text('Email Message', style: TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _showEditEmailModal(),
                            child: const Text('Edit', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dear $_recipientName,\n\n${_emailMessageController.text}\n\nSincerely,\nPlansrow LLC',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ============ SCOPE OF WORK ============
                _buildProposalSection(
                  icon: Icons.description_outlined,
                  title: 'Scope of Work',
                  child: Text(
                    _scopeController.text.isNotEmpty ? _scopeController.text : 'No scope defined yet.',
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                ),
                const SizedBox(height: 16),

                // ============ PROJECT TIMELINE ============
                if (_lineItems.isNotEmpty)
                  _buildProposalSection(
                    icon: Icons.timeline_outlined,
                    title: 'Project Timeline',
                    child: Column(
                      children: [
                        ...List.generate(_lineItems.length, (index) {
                          final item = _lineItems[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _getTaskColor(index),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(item.description, style: const TextStyle(fontSize: 13))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getTaskColor(index).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('${item.days} days', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _getTaskColor(index))),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Duration', style: TextStyle(fontWeight: FontWeight.w600)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('$_totalDuration days', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (_lineItems.isNotEmpty) const SizedBox(height: 16),

                // ============ INVESTMENT SUMMARY ============
                _buildProposalSection(
                  icon: Icons.payments_outlined,
                  title: 'Investment Summary',
                  child: Column(
                    children: [
                      // Line Items
                      ..._lineItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(item.description, style: const TextStyle(fontSize: 13)),
                            ),
                            Expanded(
                              child: Text('${item.quantity} ${item.unit}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ),
                            Expanded(
                              child: Text(currencyFormat.format(item.amount), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      )),
                      const Divider(height: 24),
                      _buildSummaryRow('Subtotal', currencyFormat.format(_subtotal)),
                      _buildSummaryRow('Tax (${_taxRate}%)', currencyFormat.format(_taxAmount)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Investment', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            Text(currencyFormat.format(_total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.accent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ============ PAYMENT TERMS ============
                _buildProposalSection(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Payment Terms',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._paymentOptions.entries.map((entry) {
                        final isSelected = _paymentSchedule == entry.key;
                        return GestureDetector(
                          onTap: () => setState(() => _paymentSchedule = entry.key),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.accent.withOpacity(0.1) : AppColors.neutral50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSelected ? AppColors.accent : AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? AppColors.accent : Colors.transparent,
                                    border: Border.all(color: isSelected ? AppColors.accent : AppColors.border, width: 2),
                                  ),
                                  child: isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                                ),
                                const SizedBox(width: 12),
                                Text(entry.value, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Text('• Proposal valid for 30 days', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text('• Work begins upon signed acceptance', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ============ WHAT'S NOT INCLUDED ============
                _buildProposalSection(
                  icon: Icons.info_outline,
                  title: "What's Not Included",
                  subtitle: 'Exclusions & Clarifications',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildExclusionItem('Third-party software licenses or subscriptions'),
                      _buildExclusionItem('Content creation (copywriting, photography)'),
                      _buildExclusionItem('Hosting and domain registration fees'),
                      _buildExclusionItem('Scope changes after project kickoff'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ============ ACCEPTANCE ============
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified_outlined, color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          const Text('Acceptance', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'By signing below, $_recipientName agrees to the scope of work, timeline, and payment terms outlined in this proposal.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: AppColors.border)),
                                  ),
                                ),
                                const Text('Signature', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: AppColors.border)),
                                  ),
                                ),
                                const Text('Date', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.neutral50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildIconAction(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.neutral50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildCollaboratorStatusBanner(
    List<Map<String, dynamic>> pendingCollaborators,
    List<Map<String, dynamic>> submittedCollaborators,
    bool allSubmitted,
  ) {
    if (allSubmitted) {
      // All collaborators submitted - ready to send merged
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.08),
          border: Border(bottom: BorderSide(color: AppColors.success.withOpacity(0.2))),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle, color: AppColors.success, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All collaborators submitted!',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.success),
                  ),
                  Text(
                    '${submittedCollaborators.length} submission${submittedCollaborators.length > 1 ? 's' : ''} ready to merge',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _goToStep(3), // Go to Collaborators step
              child: const Text('Review', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    } else {
      // Some collaborators still pending
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.08),
          border: Border(bottom: BorderSide(color: AppColors.warning.withOpacity(0.2))),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.hourglass_empty, color: AppColors.warning, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${pendingCollaborators.length} collaborator${pendingCollaborators.length > 1 ? 's' : ''} pending',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.warning),
                  ),
                  Row(
                    children: [
                      ...pendingCollaborators.take(3).map((c) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(c['name'].split(' ')[0], style: const TextStyle(fontSize: 10)),
                        ),
                      )),
                      if (pendingCollaborators.length > 3)
                        Text('+${pendingCollaborators.length - 3} more', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _goToStep(3), // Go to Collaborators step
                  child: const Text('Manage', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildProposalSection({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
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
              Icon(icon, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    if (subtitle != null)
                      Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildExclusionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.remove, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  void _showEditEmailModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
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
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            const Text('Edit Email Message', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _emailMessageController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Enter your message...',
                filled: true,
                fillColor: AppColors.neutral50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {});
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 18, color: AppColors.textSecondary),
                if (badge != null)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 30, color: AppColors.border);
  }

  // Save as Draft
  void _saveProposalAsDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proposal saved as draft'), backgroundColor: AppColors.success),
    );
  }

  // Download Proposal
  void _downloadProposal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading proposal as PDF...'), backgroundColor: AppColors.info),
    );
  }

  // Show Send Proposal Modal
  void _showSendProposalModal() {
    final emailController = TextEditingController(text: _recipientEmail);
    final subjectController = TextEditingController(
      text: 'Proposal: ${_projectNameController.text.isNotEmpty ? _projectNameController.text : "for $_recipientName"}',
    );
    bool sendCopy = true;
    
    // Collaborator status analysis
    final hasCollaborators = _collaborators.isNotEmpty;
    final pendingCollaborators = _collaborators.where((c) => 
      c['status'] == 'invited' || c['status'] == 'accepted' || c['status'] == 'revision_requested'
    ).toList();
    final submittedCollaborators = _collaborators.where((c) => 
      c['status'] == 'submitted' || c['status'] == 'locked'
    ).toList();
    final allSubmitted = hasCollaborators && pendingCollaborators.isEmpty;
    
    // Default send mode: 'merged' if all submitted, 'wait' if pending, 'none' if no collaborators
    String sendMode = hasCollaborators 
        ? (allSubmitted ? 'merged' : 'wait') 
        : 'none';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: hasCollaborators ? 0.85 : 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
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
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.send_rounded, color: AppColors.accent),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Send Proposal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        Text('Send to client\'s primary contact', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // ========== COLLABORATOR STATUS SECTION ==========
                if (hasCollaborators) ...[
                  // Collaborator Status Summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: allSubmitted 
                          ? AppColors.success.withOpacity(0.08)
                          : AppColors.warning.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: allSubmitted 
                            ? AppColors.success.withOpacity(0.3)
                            : AppColors.warning.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              allSubmitted ? Icons.check_circle_outline : Icons.hourglass_empty,
                              size: 20,
                              color: allSubmitted ? AppColors.success : AppColors.warning,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                allSubmitted 
                                    ? 'All collaborators have submitted!'
                                    : '${pendingCollaborators.length} collaborator${pendingCollaborators.length > 1 ? 's' : ''} pending',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: allSubmitted ? AppColors.success : AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!allSubmitted) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: pendingCollaborators.map((c) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildCollaboratorStatusIcon(c['status']),
                                  const SizedBox(width: 4),
                                  Text(
                                    c['name'],
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                        ],
                        if (submittedCollaborators.isNotEmpty && !allSubmitted) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${submittedCollaborators.length} already submitted',
                            style: TextStyle(fontSize: 11, color: AppColors.success),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ========== SEND MODE OPTIONS ==========
                  Text('Send Options', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),

                  // Option 1: Merged Proposal (only if all submitted)
                  _buildSendModeOption(
                    sendMode,
                    'merged',
                    Icons.merge_type,
                    'Send Merged Proposal',
                    'Include all collaborator line items in one proposal',
                    AppColors.success,
                    enabled: allSubmitted,
                    disabledReason: !allSubmitted ? 'Wait for all submissions' : null,
                    onSelect: (val) => setModalState(() => sendMode = val),
                  ),
                  const SizedBox(height: 10),

                  // Option 2: Send Without Collaborators
                  _buildSendModeOption(
                    sendMode,
                    'without',
                    Icons.person,
                    'Send Without Collaborators',
                    'Send only your services, exclude pending collaborators',
                    AppColors.info,
                    enabled: true,
                    onSelect: (val) => setModalState(() => sendMode = val),
                  ),
                  const SizedBox(height: 10),

                  // Option 3: Wait for Submissions
                  if (pendingCollaborators.isNotEmpty)
                    _buildSendModeOption(
                      sendMode,
                      'wait',
                      Icons.schedule,
                      'Wait for All Submissions',
                      'Save as draft, send automatically when all submit',
                      AppColors.warning,
                      enabled: true,
                      onSelect: (val) => setModalState(() => sendMode = val),
                    ),
                  if (pendingCollaborators.isNotEmpty)
                    const SizedBox(height: 10),

                  // Option 4: Independent Sending
                  _buildSendModeOption(
                    sendMode,
                    'independent',
                    Icons.call_split,
                    'Send Independently',
                    'You send yours, collaborators send theirs directly',
                    AppColors.purple,
                    enabled: true,
                    onSelect: (val) => setModalState(() => sendMode = val),
                  ),
                  const SizedBox(height: 20),

                  // Warning/Info based on selected mode
                  if (sendMode == 'without' && pendingCollaborators.isNotEmpty)
                    _buildModeWarning(
                      Icons.warning_amber_rounded,
                      AppColors.warning,
                      '${pendingCollaborators.length} collaborator${pendingCollaborators.length > 1 ? 's' : ''} will be excluded from this proposal.',
                    ),
                  if (sendMode == 'wait')
                    _buildModeWarning(
                      Icons.info_outline,
                      AppColors.info,
                      'Proposal will be saved as draft. You\'ll be notified when all collaborators submit, then you can review and send.',
                    ),
                  if (sendMode == 'independent')
                    _buildModeWarning(
                      Icons.info_outline,
                      AppColors.purple,
                      'Client will receive separate proposals from each collaborator. A note will be included informing them of additional incoming proposals.',
                    ),
                  if (sendMode == 'without' || sendMode == 'wait' || sendMode == 'independent')
                    const SizedBox(height: 16),

                  const Divider(height: 32),
                ],
                
                // ========== RECIPIENT SECTION ==========
                // Recipient Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.neutral50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _recipientName.isNotEmpty ? _recipientName[0].toUpperCase() : 'C',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_recipientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(_recipientType == 'client' ? 'Client' : 'Lead', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Email Field
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Recipient Email',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    filled: true,
                    fillColor: AppColors.neutral50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Subject Field
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    labelText: 'Email Subject',
                    prefixIcon: const Icon(Icons.subject, size: 20),
                    filled: true,
                    fillColor: AppColors.neutral50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Send Copy Checkbox
                GestureDetector(
                  onTap: () => setModalState(() => sendCopy = !sendCopy),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: sendCopy ? AppColors.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: sendCopy ? AppColors.accent : AppColors.border, width: 2),
                        ),
                        child: sendCopy ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                      ),
                      const SizedBox(width: 10),
                      const Text('Send me a copy', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Send Button - changes based on mode
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _executeSendMode(sendMode, emailController.text, sendCopy);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: _getSendModeColor(sendMode),
                    ),
                    icon: Icon(_getSendModeIcon(sendMode), size: 18),
                    label: Text(_getSendModeButtonText(sendMode)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollaboratorStatusIcon(String status) {
    switch (status) {
      case 'invited':
        return Icon(Icons.mail_outline, size: 12, color: AppColors.info);
      case 'accepted':
        return Icon(Icons.pending_outlined, size: 12, color: AppColors.warning);
      case 'revision_requested':
        return Icon(Icons.edit_outlined, size: 12, color: AppColors.warning);
      case 'submitted':
        return Icon(Icons.check, size: 12, color: AppColors.success);
      case 'locked':
        return Icon(Icons.lock, size: 12, color: AppColors.success);
      default:
        return Icon(Icons.help_outline, size: 12, color: AppColors.textTertiary);
    }
  }

  Widget _buildSendModeOption(
    String currentMode,
    String mode,
    IconData icon,
    String title,
    String subtitle,
    Color color, {
    bool enabled = true,
    String? disabledReason,
    required Function(String) onSelect,
  }) {
    final isSelected = currentMode == mode;
    
    return GestureDetector(
      onTap: enabled ? () => onSelect(mode) : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.08) : AppColors.neutral50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.15) : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enabled ? subtitle : (disabledReason ?? subtitle),
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: color, size: 22)
              else if (!enabled)
                Icon(Icons.lock_outline, color: AppColors.textTertiary, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeWarning(IconData icon, Color color, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSendModeColor(String mode) {
    switch (mode) {
      case 'merged': return AppColors.success;
      case 'without': return AppColors.info;
      case 'wait': return AppColors.warning;
      case 'independent': return AppColors.purple;
      default: return AppColors.accent;
    }
  }

  IconData _getSendModeIcon(String mode) {
    switch (mode) {
      case 'merged': return Icons.merge_type;
      case 'without': return Icons.send_rounded;
      case 'wait': return Icons.schedule;
      case 'independent': return Icons.call_split;
      default: return Icons.send_rounded;
    }
  }

  String _getSendModeButtonText(String mode) {
    switch (mode) {
      case 'merged': return 'Send Merged Proposal';
      case 'without': return 'Send Without Collaborators';
      case 'wait': return 'Save & Wait for Submissions';
      case 'independent': return 'Send Independently';
      default: return 'Send Proposal';
    }
  }

  void _executeSendMode(String mode, String email, bool sendCopy) {
    String message;
    
    switch (mode) {
      case 'merged':
        message = 'Merged proposal sent to $email';
        // Logic: Include all collaborator line items
        break;
      case 'without':
        message = 'Proposal sent to $email (without pending collaborators)';
        // Logic: Exclude pending collaborators
        break;
      case 'wait':
        message = 'Proposal saved as draft. You\'ll be notified when all collaborators submit.';
        // Logic: Save as draft, set up auto-send trigger
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.warning, duration: const Duration(seconds: 4)),
        );
        // Don't navigate away - stay on proposal
        return;
      case 'independent':
        message = 'Your proposal sent to $email. Collaborators have been notified to send their proposals.';
        // Logic: Send your part, notify collaborators to send directly
        break;
      default:
        message = 'Proposal sent to $email';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success, duration: const Duration(seconds: 3)),
    );
    context.go('/sales');
  }

  // Show Save as Template Modal
  void _showSaveAsTemplateModal() {
    final templateNameController = TextEditingController(
      text: _projectNameController.text.isNotEmpty ? _projectNameController.text : 'My Template',
    );
    String selectedCategory = 'General';
    final categories = ['General', 'Web Development', 'Design', 'Consulting', 'Marketing', 'Other'];

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
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.copy_outlined, color: AppColors.info),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Save as Template', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text('Reuse this proposal structure', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Template Name
              TextField(
                controller: templateNameController,
                decoration: InputDecoration(
                  labelText: 'Template Name',
                  prefixIcon: const Icon(Icons.description_outlined, size: 20),
                  filled: true,
                  fillColor: AppColors.neutral50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),

              // Category
              const Text('Category', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent : AppColors.neutral50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppColors.accent : AppColors.border),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // What's included
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.neutral50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Template will include:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildIncludedItem('${_lineItems.length} line items'),
                    _buildIncludedItem('Cover image selection'),
                    _buildIncludedItem('Scope of work'),
                    _buildIncludedItem('Timeline settings'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Template "${templateNameController.text}" saved'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save Template'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncludedItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // Show Tags Modal
  void _showTagsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
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
              const Text('Add Tags', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Tag this proposal for easy filtering', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        if (isSelected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                      setState(() {}); // Update parent
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent : AppColors.neutral50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppColors.accent : AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(Icons.check, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            tag,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
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
  int startDay; // For timeline scheduling

  ProposalLineItem({
    required this.description,
    required this.unitPrice,
    required this.unit,
    required this.quantity,
    this.taxable = false,
    this.days = 1,
    this.startDay = 0,
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
