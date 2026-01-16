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
    _tabController = TabController(length: 3, vsync: this);
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

            // Title and Actions (more compact)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sales',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  if (_tabController.index < 3)
                    GestureDetector(
                      onTap: () => _handleAddButton(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                fontWeight: FontWeight.w600,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTab(0, 'Leads', 4),
          _buildTab(1, 'Clients', 3),
          _buildTab(2, 'Quotes', 31),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, int count) {
    final isSelected = _tabController.index == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : AppColors.neutral200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
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

  // Leads with proposal tracking
  // proposalStatus: 'none' | 'draft' | 'sent' | 'approved' | 'declined'
  final List<Map<String, dynamic>> _leads = [
    {'id': '1', 'name': 'Testing', 'company': 'Wgcc', 'source': 'Other', 'status': 'new', 'value': 5009.0, 'created': DateTime(2026, 1, 13), 'proposalStatus': 'none'},
    {'id': '2', 'name': 'John', 'company': '', 'source': 'Other', 'status': 'new', 'value': 4000.0, 'created': DateTime(2026, 1, 13), 'proposalStatus': 'none'},
    {'id': '3', 'name': 'Sarah Miller', 'company': 'Tech Solutions', 'source': 'Referral', 'status': 'proposal', 'value': 8500.0, 'created': DateTime(2026, 1, 10), 'proposalStatus': 'sent'},
    {'id': '4', 'name': 'Mike Johnson', 'company': 'StartupXYZ', 'source': 'Website', 'status': 'proposal', 'value': 12000.0, 'created': DateTime(2026, 1, 5), 'proposalStatus': 'approved'},
    {'id': '5', 'name': 'Emily Chen', 'company': 'Design Co', 'source': 'Website', 'status': 'contacted', 'value': 6500.0, 'created': DateTime(2026, 1, 8), 'proposalStatus': 'none'},
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
    return Column(
      children: [
        // Compact Search & Filter Row
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search leads...',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('Filters', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Status Filter Pills (minimal, secondary)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: _statuses.map((status) {
              final isSelected = _statusFilter == status;
              final count = _getStatusCount(status);
              
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _statusFilter = status),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.textPrimary.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? AppColors.textSecondary : AppColors.textTertiary,
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
        const SizedBox(height: 8),

        // Leads List (compact cards)
        Expanded(
          child: _filteredLeads.isEmpty
              ? const Center(child: Text('No leads found', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _filteredLeads.length,
                  itemBuilder: (context, index) {
                    final lead = _filteredLeads[index];
                    return _buildLeadCard(lead);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLeadCard(Map<String, dynamic> lead) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('M/d/yy');
    final proposalStatus = lead['proposalStatus'] as String;
    final canConvert = proposalStatus == 'approved';
    final hasProposal = proposalStatus != 'none';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Avatar (smaller, muted colors)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _getLeadColor(lead['name']).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    lead['name'][0].toUpperCase(),
                    style: TextStyle(
                      color: _getLeadColor(lead['name']),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              
              // Name, Company & Value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lead['name'],
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          currencyFormat.format(lead['value']),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                    if (lead['company'].isNotEmpty)
                      Text(
                        lead['company'],
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              
              // More Menu
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: AppColors.textTertiary, size: 18),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Lead', style: TextStyle(fontSize: 13))),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(fontSize: 13, color: AppColors.error))),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Compact Info Row
          Row(
            children: [
              _buildMiniChip(lead['source']),
              const SizedBox(width: 6),
              _buildStatusBadge(lead['status']),
              const SizedBox(width: 6),
              if (hasProposal) ...[
                _buildProposalBadge(proposalStatus),
                const SizedBox(width: 6),
              ],
              const Spacer(),
              Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(dateFormat.format(lead['created']), style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Action Buttons (conditional)
          Row(
            children: [
              // Proposal Button - always show unless already approved
              if (!canConvert)
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: OutlinedButton.icon(
                      onPressed: () => _createProposal(lead),
                      icon: Icon(hasProposal ? Icons.visibility_outlined : Icons.send_outlined, size: 14),
                      label: Text(hasProposal ? 'View' : 'Proposal', style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
              
              // Convert Button - only when proposal is approved
              if (canConvert) ...[
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.visibility_outlined, size: 14),
                      label: const Text('View Proposal', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: ElevatedButton.icon(
                      onPressed: () => _convertToProject(lead),
                      icon: const Icon(Icons.rocket_launch_outlined, size: 14),
                      label: const Text('Convert', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _getStatusColor(status)),
      ),
    );
  }

  Widget _buildProposalBadge(String proposalStatus) {
    Color color;
    String label;
    IconData icon;
    
    switch (proposalStatus) {
      case 'draft':
        color = AppColors.neutral500;
        label = 'Draft';
        icon = Icons.edit_outlined;
        break;
      case 'sent':
        color = AppColors.info;
        label = 'Sent';
        icon = Icons.send;
        break;
      case 'approved':
        color = AppColors.success;
        label = 'Approved';
        icon = Icons.check_circle_outline;
        break;
      case 'declined':
        color = AppColors.error;
        label = 'Declined';
        icon = Icons.cancel_outlined;
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }

  void _createProposal(Map<String, dynamic> lead) {
    // Navigate to create proposal with lead pre-selected
    context.push('/sales/proposal/create?leadId=${lead['id']}');
  }

  void _convertToProject(Map<String, dynamic> lead) {
    // Show conversion dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Convert to Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Convert "${lead['name']}" to a project?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This will:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _buildCheckItem('Create a new project'),
                  _buildCheckItem('Convert line items to tasks'),
                  _buildCheckItem('Add lead as client'),
                  _buildCheckItem('Archive the proposal'),
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
              // Navigate to projects or show success
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Project created successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Convert'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check, size: 14, color: AppColors.success),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Color _getLeadColor(String name) {
    // Muted, professional colors
    final colors = [
      const Color(0xFF6B7280), // Gray
      const Color(0xFF64748B), // Slate
      const Color(0xFF71717A), // Zinc
      const Color(0xFF78716C), // Stone
      const Color(0xFF737373), // Neutral
    ];
    return colors[name.hashCode % colors.length];
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new': return const Color(0xFF6B7280);
      case 'contacted': return const Color(0xFF92400E);
      case 'qualified': return const Color(0xFF7C3AED);
      case 'proposal': return AppColors.accent;
      case 'won': return AppColors.success;
      case 'lost': return const Color(0xFF991B1B);
      default: return AppColors.textSecondary;
    }
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
// ============ QUOTES TAB (with sub-tabs: All Quotes, Responses, Templates) ============
class _QuotesTab extends StatefulWidget {
  const _QuotesTab();

  @override
  State<_QuotesTab> createState() => _QuotesTabState();
}

class _QuotesTabState extends State<_QuotesTab> with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  String _viewMode = 'clients';
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

  final List<Map<String, dynamic>> _responses = [
    {'quote': 'Proposal for Wall street global', 'number': '260114-717', 'response': 'Accepted', 'signer': 'Barzan Jan Rahimi', 'date': DateTime(2026, 1, 14)},
    {'quote': 'Proposal for Wall street global', 'number': '260113-470', 'response': 'Accepted', 'signer': 'Barzan Jan Rahimi', 'date': DateTime(2026, 1, 13)},
    {'quote': 'Proposal for Wall street global', 'number': '260113-524', 'response': 'Accepted', 'signer': 'Barzan Jan Rahimi', 'date': DateTime(2026, 1, 13)},
    {'quote': 'Website Redesign', 'number': '260113-749', 'response': 'Declined', 'signer': 'John Smith', 'date': DateTime(2026, 1, 12)},
    {'quote': 'Proposal for Tech Solutions', 'number': '260113-651', 'response': 'Pending', 'signer': 'Testing', 'date': DateTime(2026, 1, 11)},
  ];

  final List<Map<String, dynamic>> _templates = [
    {'id': '1', 'name': 'Subdivisions', 'description': 'For lennar only', 'category': 'Subdivisions', 'clientType': 'Home Builders', 'usedCount': 48},
    {'id': '2', 'name': 'Web Development', 'description': 'Standard web project proposal', 'category': 'Development', 'clientType': 'Small Business', 'usedCount': 32},
    {'id': '3', 'name': 'Consulting Retainer', 'description': 'Monthly retainer agreement', 'category': 'Consulting', 'clientType': 'Enterprise', 'usedCount': 15},
  ];

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 3, vsync: this);
    _subTabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  int get _totalQuotes => _quotesByClient.fold(0, (sum, g) => sum + (g['quotes'] as List).length);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sub-tabs (All Quotes, Responses, Templates)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _buildSubTab(0, 'All Quotes', _totalQuotes),
              _buildSubTab(1, 'Responses', _responses.length),
              _buildSubTab(2, 'Templates', _templates.length),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // Sub-tab Content
        Expanded(
          child: IndexedStack(
            index: _subTabController.index,
            children: [
              _buildAllQuotesContent(),
              _buildResponsesContent(),
              _buildTemplatesContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubTab(int index, String label, int count) {
    final isSelected = _subTabController.index == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _subTabController.animateTo(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? AppShadows.sm : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent.withOpacity(0.1) : AppColors.neutral200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.accent : AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ ALL QUOTES CONTENT ============
  Widget _buildAllQuotesContent() {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    
    return Column(
      children: [
        // Search & Filter
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search quotes...',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.business_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('Clients', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Quotes List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _quotesByClient.length,
            itemBuilder: (context, index) {
              final group = _quotesByClient[index];
              final client = group['client'] as String;
              final quotes = group['quotes'] as List<Map<String, dynamic>>;
              final isExpanded = _expandedClients.contains(client);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppShadows.sm,
                ),
                child: Column(
                  children: [
                    // Client Header
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedClients.remove(client);
                          } else {
                            _expandedClients.add(client);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                              color: AppColors.textSecondary,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(client, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  Text('(${quotes.length} quotes)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Text(
                              currencyFormat.format(group['totalValue']),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Expanded Quotes
                    if (isExpanded) ...[
                      const Divider(height: 1),
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

  Widget _buildQuoteItem(Map<String, dynamic> quote) {
    final dateFormat = DateFormat('M/d/yyyy');
    
    return Container(
      color: AppColors.neutral50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description_outlined, size: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quote['title'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    '${quote['number']} • ${dateFormat.format(quote['date'])}',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatusBadge(quote['status']),
                if (quote['views'] > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_outlined, size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 2),
                      Text('${quote['views']}', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                    ],
                  ),
                ],
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  // ============ RESPONSES CONTENT ============
  Widget _buildResponsesContent() {
    final dateFormat = DateFormat('M/d');
    
    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search responses...',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              ),
            ),
          ),
        ),

        // Responses List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _responses.length,
            itemBuilder: (context, index) {
              final response = _responses[index];
              final responseType = response['response'] as String;
              Color responseColor;
              IconData responseIcon;
              
              switch (responseType) {
                case 'Accepted':
                  responseColor = AppColors.success;
                  responseIcon = Icons.check_circle_outline;
                  break;
                case 'Declined':
                  responseColor = AppColors.error;
                  responseIcon = Icons.cancel_outlined;
                  break;
                default:
                  responseColor = AppColors.warning;
                  responseIcon = Icons.schedule;
              }
              
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppShadows.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: responseColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(responseIcon, color: responseColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(response['quote'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(response['number'] as String, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(width: 8),
                              Text('•', style: TextStyle(color: AppColors.textTertiary)),
                              const SizedBox(width: 8),
                              Icon(Icons.person_outline, size: 12, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  response['signer'] as String,
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: responseColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            responseType,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: responseColor),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(response['date'] as DateTime),
                          style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
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

  // ============ TEMPLATES CONTENT ============
  Widget _buildTemplatesContent() {
    return Column(
      children: [
        // Search & Add
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search templates...',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),

        // Templates Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.15,
            ),
            itemCount: _templates.length,
            itemBuilder: (context, index) {
              final template = _templates[index];
              
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppShadows.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Template Preview
                    Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(Icons.description_outlined, size: 26, color: AppColors.accent.withOpacity(0.5)),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: PopupMenuButton(
                              icon: Icon(Icons.more_vert, size: 16, color: AppColors.textSecondary),
                              padding: EdgeInsets.zero,
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'use', child: Text('Use Template')),
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Template Info
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            template['description'] as String,
                            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.neutral100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    template['category'] as String,
                                    style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.copy_outlined, size: 10, color: AppColors.textTertiary),
                              const SizedBox(width: 3),
                              Text(
                                '${template['usedCount']}x',
                                style: TextStyle(fontSize: 9, color: AppColors.textTertiary),
                              ),
                            ],
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
      ],
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
