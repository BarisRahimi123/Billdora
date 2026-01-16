import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../main.dart';
import '../shell/app_header.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _addButtonLabel {
    switch (_tabController.index) {
      case 0: return 'Add Lead';
      case 1: return 'Add Client';
      case 2: return 'Add Quote';
      default: return 'Add';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Header with Hamburger Menu
            const AppHeader(showSearch: true),

            // Title and Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sales',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage clients and quotes',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (_tabController.index < 3)
                    GestureDetector(
                      onTap: () => _handleAddButton(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, color: Colors.white, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              _addButtonLabel,
                              style: const TextStyle(
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
            ),
            
            // Tabs
            _buildTabBar(),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _LeadsTab(),
                  _ClientsTab(),
                  _QuotesTab(),
                  _ResponsesTab(),
                  _TemplatesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTab(0, 'Leads', 3),
          const SizedBox(width: 8),
          _buildTab(1, 'Clients', 3),
          const SizedBox(width: 8),
          _buildTab(2, 'Quotes', 31),
          const SizedBox(width: 8),
          _buildTab(3, 'Responses', 24),
          const SizedBox(width: 8),
          _buildTab(4, 'Templates', 1),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, int count) {
    final isSelected = _tabController.index == index;
    
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cardBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? AppShadows.sm : null,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent.withOpacity(0.1) : AppColors.neutral100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddButton() {
    switch (_tabController.index) {
      case 0:
        _showAddLeadModal();
        break;
      case 1:
        _showAddClientModal();
        break;
      case 2:
        _showCreateProposalDialog();
        break;
    }
  }

  void _showAddLeadModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _AddLeadModal(),
    );
  }

  void _showAddClientModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _AddClientModal(),
    );
  }

  void _showCreateProposalDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateProposalDialog(
        onCreateFromScratch: () {
          Navigator.pop(context);
          context.push('/sales/proposal/create');
        },
        onUseTemplate: () {
          Navigator.pop(context);
          _showTemplateSelector();
        },
      ),
    );
  }

  void _showTemplateSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _TemplateSelector(
        onTemplateSelected: (template) {
          Navigator.pop(context);
          context.push('/sales/proposal/create?template=${template['id']}');
        },
        onCreateFromScratch: () {
          Navigator.pop(context);
          context.push('/sales/proposal/create');
        },
      ),
    );
  }
}

// ============ LEADS TAB ============
class _LeadsTab extends StatefulWidget {
  const _LeadsTab();

  @override
  State<_LeadsTab> createState() => _LeadsTabState();
}

class _LeadsTabState extends State<_LeadsTab> {
  String _statusFilter = 'all';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _leads = [
    {'id': '1', 'name': 'Testing', 'company': 'Wgcc', 'source': 'Other', 'status': 'new', 'value': 5009.0, 'created': DateTime(2026, 1, 13)},
    {'id': '2', 'name': 'John', 'company': '', 'source': 'Other', 'status': 'new', 'value': 4000.0, 'created': DateTime(2026, 1, 13)},
    {'id': '3', 'name': 'Sarah Miller', 'company': 'Tech Solutions', 'source': 'Referral', 'status': 'contacted', 'value': 8500.0, 'created': DateTime(2026, 1, 10)},
    {'id': '4', 'name': 'Mike Johnson', 'company': 'StartupXYZ', 'source': 'Website', 'status': 'won', 'value': 12000.0, 'created': DateTime(2026, 1, 5)},
  ];

  final List<String> _statuses = ['all', 'new', 'contacted', 'qualified', 'proposal', 'won', 'lost'];

  List<Map<String, dynamic>> get _filteredLeads {
    var filtered = _leads;
    
    if (_statusFilter != 'all') {
      filtered = filtered.where((l) => l['status'] == _statusFilter).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((l) =>
        l['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
        l['company'].toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }

  int _getStatusCount(String status) {
    if (status == 'all') return _leads.length;
    return _leads.where((l) => l['status'] == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('M/d/yyyy');
    
    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search leads...',
                      hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    const Text('Filters'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Status Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _statuses.map((status) {
              final isSelected = _statusFilter == status;
              final count = _getStatusCount(status);
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _statusFilter = status),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent.withOpacity(0.1) : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.accent : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? AppColors.accent : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Leads List
        Expanded(
          child: _filteredLeads.isEmpty
              ? const Center(child: Text('No leads found', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredLeads.length,
                  itemBuilder: (context, index) {
                    final lead = _filteredLeads[index];
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row
                          Row(
                            children: [
                              // Avatar
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _getLeadColor(lead['name']),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    lead['name'][0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // Name and Company
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lead['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    if (lead['company'].isNotEmpty)
                                      Text(
                                        lead['company'],
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              // More Menu
                              PopupMenuButton(
                                icon: Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 12),
                                        Text('Edit Lead'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                        SizedBox(width: 12),
                                        Text('Delete', style: TextStyle(color: AppColors.error)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  // Handle menu actions
                                },
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Details Row
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _buildInfoChip(Icons.source_outlined, lead['source']),
                              _buildStatusDropdown(lead),
                              _buildInfoChip(Icons.attach_money, currencyFormat.format(lead['value'])),
                              _buildInfoChip(Icons.calendar_today_outlined, dateFormat.format(lead['created'])),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.send_outlined, size: 16),
                                  label: const Text('Proposal'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.accent,
                                    side: BorderSide(color: AppColors.accent.withOpacity(0.3)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.person_add_outlined, size: 16),
                                  label: const Text('Convert'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

  Color _getLeadColor(String name) {
    final colors = [
      const Color(0xFFE6B325), // Yellow
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5CF6), // Purple
    ];
    return colors[name.hashCode % colors.length];
  }

  Widget _buildStatusDropdown(Map<String, dynamic> lead) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(lead['status']).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _getStatusColor(lead['status']).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            lead['status'][0].toUpperCase() + lead['status'].substring(1),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _getStatusColor(lead['status']),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.unfold_more, size: 12, color: _getStatusColor(lead['status'])),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new': return AppColors.info;
      case 'contacted': return AppColors.warning;
      case 'qualified': return const Color(0xFF8B5CF6);
      case 'proposal': return AppColors.accent;
      case 'won': return AppColors.success;
      case 'lost': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ CLIENTS TAB ============
class _ClientsTab extends StatelessWidget {
  const _ClientsTab();

  @override
  Widget build(BuildContext context) {
    final clients = [
      {'id': '1', 'name': 'Barzan Shop', 'email': 'contact@barzanshop.com', 'quotes': 16, 'value': 12150.0},
      {'id': '2', 'name': 'Sequoia Consulting', 'email': 'hello@sequoia.com', 'quotes': 1, 'value': 2000.0},
      {'id': '3', 'name': 'Wall Street Global', 'email': 'info@wallstreet.com', 'quotes': 8, 'value': 6400.0},
    ];
    
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final client = clients[index];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.card,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Navigate to client detail
                _showClientDetail(context, client);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          client['name'].toString()[0],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Client Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            client['email'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${client['quotes']} quotes • ${currencyFormat.format(client['value'])}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Chevron
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showClientDetail(BuildContext context, Map<String, dynamic> client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        client['name'].toString()[0],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client['name'] as String,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          client['email'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Quotes',
                          '${client['quotes']}',
                          Icons.description_outlined,
                          AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Total Value',
                          NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(client['value']),
                          Icons.attach_money,
                          AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildActionTile(
                    Icons.send_outlined,
                    'Create Quote',
                    'Send a new quote to this client',
                    () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 8),
                  _buildActionTile(
                    Icons.email_outlined,
                    'Send Email',
                    'Send an email to ${client['email']}',
                    () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 8),
                  _buildActionTile(
                    Icons.edit_outlined,
                    'Edit Client',
                    'Update client information',
                    () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ QUOTES TAB ============
class _QuotesTab extends StatefulWidget {
  const _QuotesTab();

  @override
  State<_QuotesTab> createState() => _QuotesTabState();
}

class _QuotesTabState extends State<_QuotesTab> {
  String _viewMode = 'clients'; // clients or leads
  final Set<String> _expandedClients = {};

  final List<Map<String, dynamic>> _quotesByClient = [
    {
      'client': 'Barzan Shop',
      'totalValue': 12150.0,
      'quotes': [
        {'id': 'q1', 'title': 'Proposal for Wall street global', 'number': '260114-538', 'date': DateTime(2026, 1, 14), 'status': 'sent', 'views': 0},
        {'id': 'q2', 'title': 'Proposal for Wall street global', 'number': '260114-280', 'date': DateTime(2026, 1, 14), 'status': 'sent', 'views': 1},
        {'id': 'q3', 'title': 'Proposal for Wall street global', 'number': '260114-049', 'date': DateTime(2026, 1, 14), 'status': 'sent', 'views': 0},
        {'id': 'q4', 'title': 'Proposal for Wall street global', 'number': '260114-717', 'date': DateTime(2026, 1, 14), 'status': 'approved', 'views': 5},
      ],
    },
    {
      'client': 'Sequoia Consulting',
      'totalValue': 2000.0,
      'quotes': [
        {'id': 'q5', 'title': 'Website Redesign Proposal', 'number': '260112-001', 'date': DateTime(2026, 1, 12), 'status': 'draft', 'views': 0},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    
    return Column(
      children: [
        // Search & Filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search quotes...',
                      hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildToggleButton('Clients', _viewMode == 'clients', () {
                setState(() => _viewMode = 'clients');
              }),
            ],
          ),
        ),

        // Quotes List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _quotesByClient.length,
            itemBuilder: (context, index) {
              final group = _quotesByClient[index];
              final client = group['client'] as String;
              final quotes = group['quotes'] as List<Map<String, dynamic>>;
              final isExpanded = _expandedClients.contains(client);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  children: [
                    // Client Header
                    ListTile(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedClients.remove(client);
                          } else {
                            _expandedClients.add(client);
                          }
                        });
                      },
                      leading: Icon(
                        isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                      title: Text(
                        client,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '(${quotes.length} quotes)',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: Text(
                        currencyFormat.format(group['totalValue']),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    
                    // Expanded Quotes
                    if (isExpanded) ...[
                      const Divider(height: 1, color: AppColors.border),
                      ...quotes.map((quote) => _buildQuoteItem(quote)),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.cardBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? AppColors.border : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteItem(Map<String, dynamic> quote) {
    final dateFormat = DateFormat('M/d/yyyy');
    
    return Container(
      color: AppColors.neutral50,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.description_outlined, size: 18, color: AppColors.textSecondary),
        ),
        title: Text(
          quote['title'],
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${quote['number']} • ${dateFormat.format(quote['date'])}',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusBadge(quote['status']),
                if (quote['views'] > 0) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.visibility_outlined, size: 12, color: AppColors.textTertiary),
                  const SizedBox(width: 2),
                  Text(
                    '${quote['views']}',
                    style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_forward, size: 12, color: AppColors.success),
                  const SizedBox(width: 4),
                  const Text(
                    'Convert',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.success,
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

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'sent': color = AppColors.info; break;
      case 'approved': color = AppColors.success; break;
      case 'draft': color = AppColors.neutral500; break;
      default: color = AppColors.textSecondary;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ============ RESPONSES TAB ============
class _ResponsesTab extends StatelessWidget {
  const _ResponsesTab();

  @override
  Widget build(BuildContext context) {
    final responses = [
      {'quote': 'Proposal for Wall street global', 'number': '260114-717', 'response': 'Accepted', 'signer': 'Barzan Jan Rahimi', 'hasSignature': true},
      {'quote': 'Proposal for Wall street global', 'number': '260113-470', 'response': 'Accepted', 'signer': 'Barzan Jan Rahimi', 'hasSignature': true},
      {'quote': 'Proposal for Wall street global', 'number': '260113-524', 'response': 'Accepted', 'signer': 'Barzan Jan Rahimi', 'hasSignature': true},
      {'quote': 'Proposal for Wall street global', 'number': '260113-749', 'response': 'Accepted', 'signer': 'Barzan Jan Rahimi\nFirst', 'hasSignature': true},
      {'quote': 'Proposal for Wall street global', 'number': '260113-651', 'response': 'Accepted', 'signer': 'Testing', 'hasSignature': true},
    ];
    
    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search responses...',
                hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ),

        // Table Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.neutral50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Expanded(flex: 2, child: Text('Quote', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                const Expanded(child: Text('Response', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                const Expanded(child: Text('Signer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                const SizedBox(width: 60, child: Text('Signature', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
              ],
            ),
          ),
        ),

        // Responses List
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              itemCount: responses.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final response = responses[index];
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              response['quote'] as String,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              response['number'] as String,
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            response['response'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          response['signer'] as String,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 14, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              'View',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ============ TEMPLATES TAB ============
class _TemplatesTab extends StatelessWidget {
  const _TemplatesTab();

  @override
  Widget build(BuildContext context) {
    final templates = [
      {
        'id': '1',
        'name': 'Subdivisions',
        'description': 'For lennar only',
        'category': 'Subdivisions',
        'clientType': 'Home Builders',
        'usedCount': 48,
      },
    ];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.card,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description_outlined, color: AppColors.accent),
            ),
            title: Text(
              template['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(template['description'] as String, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.label_outline, size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(template['category'] as String, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    Icon(Icons.people_outline, size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(template['clientType'] as String, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text('Used ${template['usedCount']}x', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'use', child: Text('Use Template')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============ MODALS & DIALOGS ============
class _AddLeadModal extends StatelessWidget {
  const _AddLeadModal();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
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
              const Text('Add Lead', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              _buildTextField('Lead Name *', 'Enter lead name'),
              const SizedBox(height: 16),
              _buildTextField('Company', 'Company name'),
              const SizedBox(height: 16),
              _buildTextField('Email', 'email@example.com'),
              const SizedBox(height: 16),
              _buildTextField('Phone', '+1 (555) 000-0000'),
              const SizedBox(height: 16),
              _buildTextField('Estimated Value', '\$0.00'),
              const SizedBox(height: 16),
              _buildDropdown('Source', ['Website', 'Referral', 'Cold Call', 'Social Media', 'Other']),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Add Lead'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.neutral50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.first,
              isExpanded: true,
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
              onChanged: (_) {},
            ),
          ),
        ),
      ],
    );
  }
}

class _AddClientModal extends StatelessWidget {
  const _AddClientModal();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
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
              const Text('Add Client', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              // Form fields would go here
              const Text('Client Name, Email, Phone, Address fields...'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Add Client'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CreateProposalDialog extends StatelessWidget {
  final VoidCallback onCreateFromScratch;
  final VoidCallback onUseTemplate;

  const _CreateProposalDialog({
    required this.onCreateFromScratch,
    required this.onUseTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Create Proposal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'How would you like to create your proposal?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            
            // Use Template Option
            _buildOption(
              icon: Icons.description_outlined,
              iconColor: AppColors.accent,
              title: 'Use a Template',
              subtitle: 'Start from a saved template for faster creation',
              onTap: onUseTemplate,
            ),
            const SizedBox(height: 12),
            
            // Create from Scratch Option
            _buildOption(
              icon: Icons.add,
              iconColor: AppColors.textSecondary,
              title: 'Create from Scratch',
              subtitle: 'Start with a blank proposal',
              onTap: onCreateFromScratch,
            ),
            const SizedBox(height: 16),
            
            Center(
              child: Text(
                '1 template available',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _TemplateSelector extends StatelessWidget {
  final Function(Map<String, dynamic>) onTemplateSelected;
  final VoidCallback onCreateFromScratch;

  const _TemplateSelector({
    required this.onTemplateSelected,
    required this.onCreateFromScratch,
  });

  @override
  Widget build(BuildContext context) {
    final templates = [
      {
        'id': '1',
        'name': 'Subdivisions',
        'description': 'For lennar only',
        'category': 'Subdivisions',
        'clientType': 'Home Builders',
        'usedCount': 48,
      },
    ];
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
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
                      const Text('Choose Template', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Select a template to start your proposal', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  
                  // Search
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.neutral50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search templates...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Filter Dropdowns
                  Row(
                    children: [
                      _buildFilterChip('All Categories'),
                      const SizedBox(width: 8),
                      _buildFilterChip('All Client Types'),
                    ],
                  ),
                ],
              ),
            ),
            
            // Template List
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: templates.length + 1, // +1 for "Start from Scratch"
                itemBuilder: (context, index) {
                  if (index == templates.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: OutlinedButton(
                        onPressed: onCreateFromScratch,
                        child: const Text('Start from Scratch'),
                      ),
                    );
                  }
                  
                  final template = templates[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => onTemplateSelected(template),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.description_outlined, color: AppColors.accent),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(template['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(template['description'] as String, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.label_outline, size: 12, color: AppColors.textTertiary),
                                      const SizedBox(width: 4),
                                      Text(template['category'] as String, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      const SizedBox(width: 12),
                                      Icon(Icons.people_outline, size: 12, color: AppColors.textTertiary),
                                      const SizedBox(width: 4),
                                      Text(template['clientType'] as String, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      const SizedBox(width: 12),
                                      Icon(Icons.access_time, size: 12, color: AppColors.textTertiary),
                                      const SizedBox(width: 4),
                                      Text('Used ${template['usedCount']}x', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    ],
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
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 18),
        ],
      ),
    );
  }
}
