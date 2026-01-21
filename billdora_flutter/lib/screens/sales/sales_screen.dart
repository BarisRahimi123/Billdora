import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/permissions_provider.dart';
import '../../services/supabase_service.dart';
import '../shell/app_header.dart';
import '../projects/projects_screen.dart';

// NOTE: consultantsList is now managed by SalesProvider
// Access via: context.watch<SalesProvider>().consultants
// Legacy reference for backward compatibility during migration:
List<Map<String, dynamic>> get consultantsList => _legacyConsultantsList;
final List<Map<String, dynamic>> _legacyConsultantsList = [];

class SalesScreen extends StatefulWidget {
  final int? initialTab;
  final int? initialSubTab;
  
  const SalesScreen({
    super.key, 
    this.initialTab,
    this.initialSubTab,
  });

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<_LeadsTabState> _leadsTabKey = GlobalKey<_LeadsTabState>();
  final GlobalKey<_ClientsTabState> _clientsTabKey = GlobalKey<_ClientsTabState>();
  final GlobalKey<_ConsultantsTabState> _consultantsTabKey = GlobalKey<_ConsultantsTabState>();
  bool _initialized = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5, 
      vsync: this,
      initialIndex: widget.initialTab ?? 0,
    );
    _tabController.addListener(() => setState(() {}));
    
    // Load data immediately after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataIfNeeded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initializeProviders();
    }
  }
  
  /// Automatically load data if it's not already loaded
  Future<void> _loadDataIfNeeded() async {
    final salesProvider = context.read<SalesProvider>();
    final authProvider = context.read<AuthProvider>();
    
    // If leads are empty and we're not currently loading, trigger a load
    if (salesProvider.leads.isEmpty && !salesProvider.isLoading) {
      final companyId = authProvider.companyId;
      if (companyId != null) {
        debugPrint('SalesScreen._loadDataIfNeeded: Triggering automatic data load...');
        await salesProvider.initialize(companyId, userEmail: authProvider.userEmail);
      }
    }
  }

  Future<void> _initializeProviders() async {
    // Try to get companyId from AuthProvider first, then PermissionsProvider
    final authProvider = context.read<AuthProvider>();
    final permProvider = context.read<PermissionsProvider>();
    
    debugPrint('SalesScreen._initializeProviders: Starting...');
    debugPrint('SalesScreen._initializeProviders: authProvider.companyId=${authProvider.companyId}');
    debugPrint('SalesScreen._initializeProviders: authProvider.isLoading=${authProvider.isLoading}');
    debugPrint('SalesScreen._initializeProviders: permProvider.currentCompanyId=${permProvider.currentCompanyId}');
    
    // Wait for AuthProvider to complete initial load
    debugPrint('SalesScreen._initializeProviders: Waiting for AuthProvider to complete init...');
    await authProvider.waitForInit();
    debugPrint('SalesScreen._initializeProviders: AuthProvider init complete. companyId=${authProvider.companyId}');
    
    final companyId = authProvider.companyId ?? permProvider.currentCompanyId;
    debugPrint('SalesScreen._initializeProviders: using companyId=$companyId');
    
    if (companyId != null) {
      await context.read<SalesProvider>().initialize(companyId, userEmail: authProvider.userEmail);
    } else {
      debugPrint('SalesScreen._initializeProviders: WARNING - No company ID available! Will retry...');
      // Retry with exponential backoff
      for (int i = 0; i < 3; i++) {
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        final retryCompanyId = authProvider.companyId ?? permProvider.currentCompanyId;
        if (retryCompanyId != null) {
          debugPrint('SalesScreen._initializeProviders: Retry ${i + 1} successful with companyId=$retryCompanyId');
          await context.read<SalesProvider>().initialize(retryCompanyId, userEmail: authProvider.userEmail);
          return;
        }
      }
      debugPrint('SalesScreen._initializeProviders: ERROR - Still no company ID after retries!');
    }
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
      case 2: return 'Add Consultant';
      case 3: return 'Add Quote';
      case 4: return ''; // No add for Inbox
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
                  if (_tabController.index < 4)
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
                children: [
                  _LeadsTab(key: _leadsTabKey),
                  _ClientsTab(key: _clientsTabKey),
                  _ConsultantsTab(key: _consultantsTabKey),
                  _QuotesTab(initialSubTab: widget.initialSubTab),
                  const _ReceivedInvitationsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final salesProvider = context.watch<SalesProvider>();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildTab(0, 'Leads', salesProvider.leadsCount),
          _buildTab(1, 'Clients', salesProvider.clientsCount),
          _buildTab(2, 'Team', salesProvider.consultantsCount),
          _buildTab(3, 'Quotes', salesProvider.quotesCount),
          _buildTab(4, 'Inbox', salesProvider.receivedInvitationsCount),
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ] : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
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
        _showAddConsultantModal();
        break;
      case 3:
        _showCreateProposalDialog();
        break;
      case 4:
        // No add action for received invitations
        break;
    }
  }

  void _showAddConsultantModal() {
    _consultantsTabKey.currentState?.showAddConsultantModal();
  }

  void _showAddLeadModal() {
    _leadsTabKey.currentState?.showAddLeadModal();
  }

  void _showAddClientModal() {
    _clientsTabKey.currentState?.showAddClientModal();
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
  const _LeadsTab({super.key});

  @override
  State<_LeadsTab> createState() => _LeadsTabState();
}

class _LeadsTabState extends State<_LeadsTab> {
  String _statusFilter = 'all';
  String _searchQuery = '';

  final List<String> _statuses = ['all', 'new', 'contacted', 'qualified', 'proposal', 'won', 'lost'];

  // Helper to parse date from various formats
  DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) {
      return DateTime.tryParse(dateValue) ?? DateTime.now();
    }
    return DateTime.now();
  }

  // Get leads from provider
  List<Map<String, dynamic>> get _leads => context.read<SalesProvider>().leads;

  List<Map<String, dynamic>> get _filteredLeads {
    final salesProvider = context.watch<SalesProvider>();
    var filtered = salesProvider.leads;
    if (_statusFilter != 'all') {
      filtered = filtered.where((l) => l['status'] == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((l) =>
        (l['contact_name'] ?? l['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (l['company_name'] ?? l['company'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    return filtered;
  }

  int _getStatusCount(String status) {
    final leads = context.read<SalesProvider>().leads;
    if (status == 'all') return leads.length;
    return leads.where((l) => l['status'] == status).length;
  }

  // Public method to show add lead modal (called from parent)
  void showAddLeadModal() {
    // Get provider BEFORE showing modal to avoid context issues
    final salesProvider = context.read<SalesProvider>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddLeadModal(
        onLeadAdded: (newLead) async {
          // Use provider captured from parent context
          debugPrint('Adding lead via provider...');
          final success = await salesProvider.createLead(newLead);
          debugPrint('Lead creation result: $success');
        },
      ),
    );
  }

  void _showEditLeadModal(Map<String, dynamic> lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EditLeadModal(
        lead: lead,
        onLeadUpdated: (updatedLead) async {
          // Use provider to update lead
          await context.read<SalesProvider>().updateLead(
            updatedLead['id'],
            updatedLead,
          );
        },
      ),
    );
  }

  void _deleteLead(Map<String, dynamic> lead) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Lead?'),
        content: Text('Are you sure you want to delete "${lead['name']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<SalesProvider>().deleteLead(lead['id']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lead deleted'), backgroundColor: AppColors.success),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesProvider = context.watch<SalesProvider>();
    final authProvider = context.watch<AuthProvider>();
    
    return Column(
      children: [
        // Debug Info Banner (temporary - remove after debugging)
        if (authProvider.companyId != null)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Company: ${authProvider.companyId?.substring(0, 8)}... | Leads: ${salesProvider.leads.length} | Loading: ${salesProvider.isLoading}',
                    style: TextStyle(fontSize: 11, color: AppColors.info),
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
          child: context.watch<SalesProvider>().isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredLeads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 12),
                          const Text('No leads found', style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              final authProvider = context.read<AuthProvider>();
                              if (authProvider.companyId != null) {
                                context.read<SalesProvider>().loadLeads();
                              }
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reload'),
                          ),
                        ],
                      ),
                    )
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
    // Handle both camelCase (app) and snake_case (Supabase) field names
    final proposalStatus = (lead['proposalStatus'] ?? lead['proposal_status'] ?? 'none') as String;
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
                  color: _getLeadColor(lead['name'] ?? '').withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    ((lead['name'] ?? '') as String).isNotEmpty ? (lead['name'] as String)[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: _getLeadColor(lead['name'] ?? ''),
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
                            lead['name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (context.watch<PermissionsProvider>().permissions.canViewClientValues)
                          Text(
                            currencyFormat.format(lead['value'] ?? 0),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                      ],
                    ),
                    if ((lead['company'] ?? lead['company_name'] ?? '').toString().isNotEmpty)
                      Text(
                        (lead['company'] ?? lead['company_name'] ?? '').toString(),
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              
              // More Menu
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppColors.textTertiary, size: 18),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditLeadModal(lead);
                  } else if (value == 'delete') {
                    _deleteLead(lead);
                  }
                },
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
              _buildMiniChip(lead['source'] ?? 'other'),
              const SizedBox(width: 6),
              _buildStatusBadge(lead['status'] ?? 'new'),
              const SizedBox(width: 6),
              if (hasProposal) ...[
                _buildProposalBadge(proposalStatus),
                const SizedBox(width: 6),
              ],
              const Spacer(),
              Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                dateFormat.format(_parseDate(lead['created'] ?? lead['created_at'])),
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
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
    // Navigate to create proposal with lead pre-selected and all lead data
    final leadId = lead['id'];
    final leadName = Uri.encodeComponent(lead['name'] ?? '');
    final leadEmail = Uri.encodeComponent(lead['email'] ?? '');
    final leadCompany = Uri.encodeComponent(lead['company'] ?? '');
    context.push('/sales/proposal/create?leadId=$leadId&leadName=$leadName&leadEmail=$leadEmail&leadCompany=$leadCompany');
  }

  void _convertToProject(Map<String, dynamic> lead) {
    // Show conversion dialog with options
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ConversionModal(
        lead: lead,
        onConvert: (convertedClient, projectName) {
          // Generate unique project ID
          final projectId = 'p${DateTime.now().millisecondsSinceEpoch}';
          final clientId = convertedClient['id'];
          
          // Create new project
          final newProject = {
            'id': projectId,
            'name': projectName,
            'description': 'Converted from lead: ${lead['name']}',
            'status': 'active',
            'budget': lead['value'] ?? 0.0,
            'clientId': clientId,
          };
          
          // Add to clients list
          setState(() {
            clientsList.add(convertedClient);
            // Update lead status to 'won' and remove from active leads
            final index = _leads.indexWhere((l) => l['id'] == lead['id']);
            if (index != -1) {
              _leads[index]['status'] = 'won';
            }
          });
          
          // Note: Project is created in the database via provider
          // The projects list will be refreshed when user navigates to Projects page
          
          // Show success message with auto-dismiss
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully converted to project: $projectName'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'View Project',
                textColor: Colors.white,
                onPressed: () {
                  // Navigate to specific project
                  context.push('/projects/$projectId');
                },
              ),
            ),
          );
        },
      ),
    );
  }
  
  void _convertToProjectLegacy(Map<String, dynamic> lead) {
    // Legacy dialog - keeping for reference
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
// Global clients list for shared access
final List<Map<String, dynamic>> clientsList = [
  {
    'id': '1',
    'company': 'Barzan Retail LLC',
    // Primary Contact (main point of contact)
    'primaryName': 'Barzan Ahmed',
    'primaryEmail': 'barzan@barzanshop.com',
    'primaryPhone': '+1 (555) 123-4567',
    'primaryTitle': 'Owner',
    // Billing Contact (for invoices - if empty, uses primary)
    'billingName': 'Sarah Johnson',
    'billingEmail': 'billing@barzanshop.com',
    'billingPhone': '+1 (555) 123-4568',
    'billingTitle': 'Accounts Payable',
    // Address
    'address': '123 Main Street',
    'city': 'Los Angeles',
    'state': 'CA',
    'zip': '90001',
    'website': 'www.barzanshop.com',
    'type': 'Retail',
    'notes': 'Premium client, prefers email communication',
    'quotes': 16,
    'projects': 5,
    'value': 12150.0,
    'created': DateTime(2025, 3, 15),
    'lastActivity': DateTime.now().subtract(const Duration(days: 5)),
  },
  {
    'id': '2',
    'company': 'Sequoia Consulting Group',
    'primaryName': 'Michael Chen',
    'primaryEmail': 'michael@sequoia.com',
    'primaryPhone': '+1 (555) 234-5678',
    'primaryTitle': 'Managing Partner',
    'billingName': '',
    'billingEmail': '',
    'billingPhone': '',
    'billingTitle': '',
    'address': '456 Business Ave',
    'city': 'San Francisco',
    'state': 'CA',
    'zip': '94102',
    'website': 'www.sequoiaconsulting.com',
    'type': 'Consulting',
    'notes': '',
    'quotes': 1,
    'projects': 0,
    'value': 2000.0,
    'created': DateTime(2025, 8, 20),
    'lastActivity': DateTime.now().subtract(const Duration(days: 120)),
  },
  {
    'id': '3',
    'company': 'Wall Street Global Inc',
    'primaryName': 'James Morrison',
    'primaryEmail': 'jmorrison@wallstreet.com',
    'primaryPhone': '+1 (555) 345-6789',
    'primaryTitle': 'VP of Operations',
    'billingName': 'Linda Park',
    'billingEmail': 'ap@wallstreet.com',
    'billingPhone': '+1 (555) 345-6700',
    'billingTitle': 'Finance Manager',
    'address': '789 Finance Blvd',
    'city': 'New York',
    'state': 'NY',
    'zip': '10001',
    'website': 'www.wallstreetglobal.com',
    'type': 'Finance',
    'notes': 'Key account, requires quarterly reviews',
    'quotes': 8,
    'projects': 3,
    'value': 6400.0,
    'created': DateTime(2025, 1, 10),
    'lastActivity': DateTime.now().subtract(const Duration(days: 15)),
  },
  {
    'id': '4',
    'company': 'TechStart Innovation Labs',
    'primaryName': 'Alex Rivera',
    'primaryEmail': 'alex@techstart.io',
    'primaryPhone': '+1 (555) 456-7890',
    'primaryTitle': 'CEO',
    'billingName': '',
    'billingEmail': '',
    'billingPhone': '',
    'billingTitle': '',
    'address': '100 Innovation Way',
    'city': 'Austin',
    'state': 'TX',
    'zip': '73301',
    'website': 'www.techstart.io',
    'type': 'Technology',
    'notes': 'Fast-growing startup, potential for large projects',
    'quotes': 12,
    'projects': 4,
    'value': 28500.0,
    'created': DateTime(2024, 11, 5),
    'lastActivity': DateTime.now().subtract(const Duration(days: 2)),
  },
  {
    'id': '5',
    'company': 'MedCare Health Systems',
    'primaryName': 'Dr. Emily Watson',
    'primaryEmail': 'ewatson@medcare.health',
    'primaryPhone': '+1 (555) 567-8901',
    'primaryTitle': 'Director of IT',
    'billingName': 'Robert Kim',
    'billingEmail': 'rkim@medcare.health',
    'billingPhone': '+1 (555) 567-8902',
    'billingTitle': 'Billing Department',
    'address': '500 Health Plaza',
    'city': 'Boston',
    'state': 'MA',
    'zip': '02101',
    'website': 'www.medcare.health',
    'type': 'Healthcare',
    'notes': 'Requires HIPAA compliance documentation',
    'quotes': 4,
    'projects': 2,
    'value': 15800.0,
    'created': DateTime(2025, 2, 18),
    'lastActivity': DateTime.now().subtract(const Duration(days: 45)),
  },
  {
    'id': '6',
    'company': 'Green Build Construction',
    'primaryName': 'Tom Martinez',
    'primaryEmail': 'tom@greenbuild.co',
    'primaryPhone': '+1 (555) 678-9012',
    'primaryTitle': 'Project Manager',
    'billingName': '',
    'billingEmail': '',
    'billingPhone': '',
    'billingTitle': '',
    'address': '250 Builder Lane',
    'city': 'Denver',
    'state': 'CO',
    'zip': '80201',
    'website': 'www.greenbuild.co',
    'type': 'Other',
    'notes': 'Sustainable construction focus',
    'quotes': 6,
    'projects': 1,
    'value': 8900.0,
    'created': DateTime(2025, 5, 22),
    'lastActivity': DateTime.now().subtract(const Duration(days: 180)),
  },
];

// Helper to get billing contact (falls back to primary if no billing contact)
Map<String, String> getBillingContact(Map<String, dynamic> client) {
  final hasBilling = (client['billingEmail'] as String?)?.isNotEmpty ?? false;
  if (hasBilling) {
    return {
      'name': client['billingName'] as String? ?? '',
      'email': client['billingEmail'] as String? ?? '',
      'phone': client['billingPhone'] as String? ?? '',
      'title': client['billingTitle'] as String? ?? '',
    };
  }
  return {
    'name': client['primaryName'] as String? ?? '',
    'email': client['primaryEmail'] as String? ?? '',
    'phone': client['primaryPhone'] as String? ?? '',
    'title': client['primaryTitle'] as String? ?? '',
  };
}

// Helper to get primary contact
Map<String, String> getPrimaryContact(Map<String, dynamic> client) {
  return {
    'name': client['primaryName'] as String? ?? '',
    'email': client['primaryEmail'] as String? ?? '',
    'phone': client['primaryPhone'] as String? ?? '',
    'title': client['primaryTitle'] as String? ?? '',
  };
}

class _ClientsTab extends StatefulWidget {
  const _ClientsTab({super.key});

  @override
  State<_ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<_ClientsTab> {
  String _searchQuery = '';
  String _typeFilter = 'all';
  String _statusFilter = 'all'; // all, active, inactive
  String _sortBy = 'revenue'; // revenue, activity, name, recent

  final List<String> _clientTypes = ['all', 'Retail', 'Consulting', 'Finance', 'Technology', 'Healthcare', 'Other'];

  // Determine if client is active (had activity in last 90 days)
  bool _isClientActive(Map<String, dynamic> client) {
    final lastActivity = client['lastActivity'] as DateTime?;
    if (lastActivity == null) return false;
    return DateTime.now().difference(lastActivity).inDays <= 90;
  }

  // Calculate activity score (quotes + projects)
  int _getActivityCount(Map<String, dynamic> client) {
    return (client['quotes'] as int? ?? 0) + (client['projects'] as int? ?? 0);
  }

  List<Map<String, dynamic>> get _filteredClients {
    var filtered = context.watch<SalesProvider>().clients;
    
    // Type filter
    if (_typeFilter != 'all') {
      filtered = filtered.where((c) => c['type'] == _typeFilter).toList();
    }
    
    // Status filter
    if (_statusFilter == 'active') {
      filtered = filtered.where((c) => _isClientActive(c)).toList();
    } else if (_statusFilter == 'inactive') {
      filtered = filtered.where((c) => !_isClientActive(c)).toList();
    }
    
    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) =>
        (c['primaryName'] as String? ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (c['company'] as String? ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (c['primaryEmail'] as String? ?? '').toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Sort
    switch (_sortBy) {
      case 'revenue':
        filtered.sort((a, b) => ((b['value'] as double?) ?? 0).compareTo((a['value'] as double?) ?? 0));
        break;
      case 'activity':
        filtered.sort((a, b) => _getActivityCount(b).compareTo(_getActivityCount(a)));
        break;
      case 'name':
        filtered.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        break;
      case 'recent':
        filtered.sort((a, b) {
          final aDate = a['lastActivity'] as DateTime? ?? a['created'] as DateTime? ?? DateTime(2000);
          final bDate = b['lastActivity'] as DateTime? ?? b['created'] as DateTime? ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
        break;
    }
    
    return filtered;
  }
  
  // Get top clients (top 3 by revenue)
  List<String> get _topClientIds {
    final sorted = List<Map<String, dynamic>>.from(context.read<SalesProvider>().clients);
    sorted.sort((a, b) => ((b['value'] as double?) ?? 0).compareTo((a['value'] as double?) ?? 0));
    return sorted.take(3).map((c) => c['id'] as String).toList();
  }

  void showAddClientModal({Map<String, dynamic>? clientToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddClientModalFull(
        client: clientToEdit,
        onClientSaved: (client) async {
          if (clientToEdit != null) {
            await context.read<SalesProvider>().updateClient(client['id'], client);
          } else {
            await context.read<SalesProvider>().addClient(client);
          }
        },
      ),
    );
  }

  void _deleteClient(Map<String, dynamic> client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Client?'),
        content: Text('Are you sure you want to delete "${client['name']}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<SalesProvider>().deleteClient(client['id']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Client deleted'), backgroundColor: AppColors.success),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
    
  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final activeCount = clientsList.where((c) => _isClientActive(c)).length;
    final inactiveCount = clientsList.length - activeCount;
    
    return Column(
      children: [
        // Filter Row
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              const Spacer(),
              // Sort Button
              _buildFilterButton(
                icon: Icons.sort,
                label: _getSortLabel(),
                onTap: () => _showSortOptions(context),
                isActive: _sortBy != 'revenue',
              ),
              const SizedBox(width: 6),
              // Type Filter
              _buildFilterButton(
                icon: Icons.business_outlined,
                label: _typeFilter == 'all' ? 'Type' : _typeFilter,
                onTap: () => _showTypeFilter(context),
                isActive: _typeFilter != 'all',
              ),
            ],
          ),
        ),
        
        // Status Filter Chips
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Row(
            children: [
              _buildStatusChip('All', 'all', clientsList.length),
              const SizedBox(width: 8),
              _buildStatusChip('Active', 'active', activeCount),
              const SizedBox(width: 8),
              _buildStatusChip('Inactive', 'inactive', inactiveCount),
              const Spacer(),
              // Quick stats
              Text(
                '${_filteredClients.length} client${_filteredClients.length != 1 ? 's' : ''}',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),

        // Clients List
        Expanded(
          child: _filteredClients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_outlined, size: 48, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      Text('No clients found', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text('Try adjusting your filters', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _filteredClients.length,
                  itemBuilder: (context, index) {
                    final client = _filteredClients[index];
                    return _buildClientCard(client, currencyFormat);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterButton({required IconData icon, required String label, required VoidCallback onTap, bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent.withOpacity(0.1) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? AppColors.accent.withOpacity(0.3) : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? AppColors.accent : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: isActive ? AppColors.accent : AppColors.textSecondary)),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 14, color: isActive ? AppColors.accent : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, int count) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.neutral100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.neutral200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'revenue': return 'Revenue';
      case 'activity': return 'Activity';
      case 'name': return 'Name';
      case 'recent': return 'Recent';
      default: return 'Sort';
    }
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort Clients By', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            if (context.read<PermissionsProvider>().permissions.canViewClientValues)
              _buildSortOption('revenue', 'Revenue', 'Highest revenue first', Icons.attach_money),
            _buildSortOption('activity', 'Activity', 'Most quotes & projects', Icons.trending_up),
            _buildSortOption('name', 'Name', 'Alphabetical order', Icons.sort_by_alpha),
            _buildSortOption('recent', 'Recent Activity', 'Most recently active', Icons.access_time),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String value, String title, String subtitle, IconData icon) {
    final isSelected = _sortBy == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withOpacity(0.1) : AppColors.neutral100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: isSelected ? AppColors.accent : AppColors.textSecondary),
      ),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: isSelected ? Icon(Icons.check_circle, color: AppColors.accent, size: 20) : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
    );
  }

  void _showTypeFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter by Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                if (_typeFilter != 'all')
                  TextButton(
                    onPressed: () {
                      setState(() => _typeFilter = 'all');
                      Navigator.pop(context);
                    },
                    child: const Text('Clear', style: TextStyle(fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _clientTypes.map((type) {
                final isSelected = _typeFilter == type;
                final count = type == 'all' 
                    ? clientsList.length 
                    : clientsList.where((c) => c['type'] == type).length;
                return GestureDetector(
                  onTap: () {
                    setState(() => _typeFilter = type);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent : AppColors.neutral100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${type == 'all' ? 'All Types' : type} ($count)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client, NumberFormat currencyFormat) {
    final isTopClient = _topClientIds.contains(client['id']);
    final isActive = _isClientActive(client);
    final revenue = (client['value'] as double?) ?? 0;
    final company = client['company'] as String? ?? '';
    final primaryName = client['primaryName'] as String? ?? '';
    final primaryEmail = client['primaryEmail'] as String? ?? '';
    final hasBillingContact = (client['billingEmail'] as String?)?.isNotEmpty ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.sm,
        border: isTopClient ? Border.all(color: AppColors.warning.withOpacity(0.4), width: 1.5) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showClientDetail(context, client),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar with status indicator
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isTopClient 
                            ? AppColors.warning.withOpacity(0.15) 
                            : AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          company.isNotEmpty ? company[0] : 'C',
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.w700, 
                            color: isTopClient ? AppColors.warning : AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    // Active indicator
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.success : AppColors.neutral300,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cardBackground, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                
                // Client Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(company, 
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isTopClient) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.warning, AppColors.warning.withOpacity(0.8)],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, size: 10, color: Colors.white),
                                  SizedBox(width: 2),
                                  Text('TOP', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Primary Contact
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 12, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(primaryName,
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasBillingContact) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.receipt_outlined, size: 10, color: AppColors.info),
                                  const SizedBox(width: 2),
                                  Text('Billing', style: TextStyle(fontSize: 9, color: AppColors.info)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Stats Row
                      Row(
                        children: [
                          if (context.watch<PermissionsProvider>().permissions.canViewClientValues) ...[
                            _buildMiniStat(Icons.attach_money, currencyFormat.format(revenue), AppColors.success),
                            const SizedBox(width: 10),
                          ],
                          _buildMiniStat(Icons.description_outlined, '${client['quotes']} quotes', AppColors.info),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.success.withOpacity(0.1) : AppColors.neutral100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isActive ? AppColors.success : AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Actions
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.textTertiary, size: 18),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onSelected: (value) {
                    if (value == 'edit') showAddClientModal(clientToEdit: client);
                    else if (value == 'delete') _deleteClient(client);
                    else if (value == 'proposal') {
                      // Navigate to create proposal with client pre-selected
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'proposal', child: Text('Send Proposal', style: TextStyle(fontSize: 13))),
                    const PopupMenuItem(value: 'edit', child: Text('Edit Client', style: TextStyle(fontSize: 13))),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(fontSize: 13, color: AppColors.error))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color.withOpacity(0.7)),
        const SizedBox(width: 3),
        Text(value, style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showClientDetail(BuildContext context, Map<String, dynamic> client) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('MMM d, yyyy');
    final company = client['company'] as String? ?? '';
    final primaryContact = getPrimaryContact(client);
    final billingContact = getBillingContact(client);
    final hasSeparateBilling = (client['billingEmail'] as String?)?.isNotEmpty ?? false;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                        company.isNotEmpty ? company[0] : 'C',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(company, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(client['type'] as String? ?? '', style: TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Stats Row
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Quotes', '${client['quotes']}', Icons.description_outlined, AppColors.info)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildStatCard('Value', currencyFormat.format(client['value']), Icons.attach_money, AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Primary Contact
                  _buildContactCard(
                    'Primary Contact',
                    primaryContact['name'] ?? '',
                    primaryContact['title'] ?? '',
                    primaryContact['email'] ?? '',
                    primaryContact['phone'] ?? '',
                    Icons.person,
                    AppColors.accent,
                    isPrimary: true,
                  ),
                  const SizedBox(height: 12),
                  
                  // Billing Contact
                  _buildContactCard(
                    'Billing Contact',
                    billingContact['name'] ?? '',
                    billingContact['title'] ?? '',
                    billingContact['email'] ?? '',
                    billingContact['phone'] ?? '',
                    Icons.receipt_long,
                    AppColors.info,
                    isPrimary: false,
                    showSameAsPrimary: !hasSeparateBilling,
                  ),
                  const SizedBox(height: 16),
                  
                  // Address
                  _buildDetailSection('Company Address', [
                    if ((client['address'] as String?)?.isNotEmpty ?? false)
                      _buildDetailRow(Icons.location_on_outlined, 'Street', client['address'] as String),
                    _buildDetailRow(Icons.location_city_outlined, 'City/State', '${client['city'] ?? ''}, ${client['state'] ?? ''} ${client['zip'] ?? ''}'),
                    if ((client['website'] as String?)?.isNotEmpty ?? false)
                      _buildDetailRow(Icons.language, 'Website', client['website'] as String),
                  ]),
                  const SizedBox(height: 16),
                  
                  // Notes
                  if ((client['notes'] as String?)?.isNotEmpty ?? false) ...[
                    _buildDetailSection('Notes', [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.neutral50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(client['notes'] as String, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                      ),
                    ]),
                    const SizedBox(height: 16),
                  ],
                  
                  // Client Since
                  if (client['created'] != null)
                    _buildDetailSection('Account Info', [
                      _buildDetailRow(Icons.calendar_today_outlined, 'Client Since', dateFormat.format(client['created'] as DateTime)),
                    ]),
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  const Text('Quick Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(Icons.send_outlined, 'Proposal', AppColors.accent, () {
                          Navigator.pop(context);
                          // Navigate to create proposal with client pre-selected
                          final clientData = {
                            'id': client['id'],
                            'name': client['primaryContact']['name'],
                            'email': client['primaryContact']['email'],
                            'company': client['company'],
                          };
                          context.push(
                            '/sales/proposal/create?clientId=${client['id']}&clientName=${Uri.encodeComponent(client['company'])}&clientEmail=${Uri.encodeComponent(client['primaryContact']['email'])}',
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(Icons.receipt_outlined, 'Invoice', AppColors.success, () {
                          Navigator.pop(context);
                          // Show invoice creation modal or navigate to invoices
                          _showClientInvoiceOptions(context, client);
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(Icons.email_outlined, 'Email', AppColors.info, () {
                          Navigator.pop(context);
                          // Show email composer
                          _showEmailComposer(context, client);
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(Icons.edit_outlined, 'Edit', AppColors.textSecondary, () {
                          Navigator.pop(context);
                          showAddClientModal(clientToEdit: client);
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(String title, String name, String jobTitle, String email, String phone, IconData icon, Color color, {bool isPrimary = false, bool showSameAsPrimary = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    if (showSameAsPrimary)
                      Text('Same as Primary Contact', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic))
                    else
                      Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('PRIMARY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                ),
            ],
          ),
          if (!showSameAsPrimary) ...[
            const SizedBox(height: 12),
            if (jobTitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.work_outline, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 8),
                    Text(jobTitle, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Expanded(child: Text(email, style: const TextStyle(fontSize: 13))),
              ],
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 8),
                  Text(phone, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
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

  // Helper method to show invoice options
  void _showClientInvoiceOptions(BuildContext context, Map<String, dynamic> client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invoice Options for ${client['company']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.add, color: AppColors.success),
              ),
              title: const Text('Create New Invoice'),
              subtitle: const Text('Create a new invoice for this client'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to invoice creation with client pre-selected
                context.push('/invoicing/create?clientId=${client['id']}&clientName=${Uri.encodeComponent(client['company'])}');
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.list_alt, color: AppColors.info),
              ),
              title: const Text('View All Invoices'),
              subtitle: Text('See invoice history (${client['invoices'] ?? 0})'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to invoices page filtered by this client
                context.push('/invoicing?clientId=${client['id']}');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Helper method to show email composer
  void _showEmailComposer(BuildContext context, Map<String, dynamic> client) {
    final primaryContact = client['primaryContact'] as Map<String, dynamic>;
    final emailController = TextEditingController();
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    // Pre-fill with client info
    emailController.text = primaryContact['email'] as String? ?? '';
    subjectController.text = 'Following up on ${client['company']}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Email ${client['company']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipient
              Text('To:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Email address',
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Subject
              Text('Subject:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: subjectController,
                decoration: InputDecoration(
                  hintText: 'Email subject',
                  prefixIcon: const Icon(Icons.subject, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Body
              Text('Message:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: bodyController,
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(14),
                ),
                maxLines: 8,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Integrate with email service (e.g., url_launcher or API)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email functionality will be integrated soon!')),
              );
              Navigator.pop(context);
            },
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Send Email'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ QUOTES TAB ============
// ============ QUOTES TAB (with sub-tabs: All Quotes, Responses, Templates) ============
class _QuotesTab extends StatefulWidget {
  final int? initialSubTab;
  
  const _QuotesTab({this.initialSubTab});

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
      'clientEmail': 'billing@barzanshop.com',
      'totalValue': 12150.0,
      'quotes': [
        {'id': 'q1', 'title': 'Proposal for Wall street global', 'number': '260114-538', 'date': DateTime(2026, 1, 14), 'status': 'sent', 'views': 0, 'amount': 3500.0, 'lineItems': [
          {'name': 'Website Design', 'amount': 2000.0},
          {'name': 'SEO Setup', 'amount': 1500.0},
        ]},
        {'id': 'q2', 'title': 'Proposal for Wall street global', 'number': '260114-280', 'date': DateTime(2026, 1, 14), 'status': 'sent', 'views': 1, 'amount': 2800.0, 'lineItems': [
          {'name': 'Logo Design', 'amount': 1800.0},
          {'name': 'Brand Guidelines', 'amount': 1000.0},
        ]},
        {'id': 'q3', 'title': 'Proposal for Wall street global', 'number': '260114-049', 'date': DateTime(2026, 1, 14), 'status': 'sent', 'views': 0, 'amount': 1850.0, 'lineItems': [
          {'name': 'Social Media Setup', 'amount': 850.0},
          {'name': 'Marketing Strategy', 'amount': 1000.0},
        ]},
        {'id': 'q4', 'title': 'Proposal for Wall street global', 'number': '260114-717', 'date': DateTime(2026, 1, 14), 'status': 'approved', 'views': 5, 'amount': 4000.0, 'signedAt': DateTime(2026, 1, 15), 'signedBy': 'Barzan Jan Rahimi', 'lineItems': [
          {'name': 'Mobile App UI Design', 'amount': 2500.0},
          {'name': 'Prototyping', 'amount': 1500.0},
        ]},
      ],
    },
    {
      'client': 'Sequoia Consulting',
      'clientEmail': 'stevenm@seqhq.com',
      'totalValue': 2000.0,
      'quotes': [
        {'id': 'q5', 'title': 'Website Redesign Proposal', 'number': '260112-001', 'date': DateTime(2026, 1, 12), 'status': 'draft', 'views': 0, 'amount': 2000.0, 'lineItems': [
          {'name': 'TSM Map Design', 'amount': 2000.0},
        ]},
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
    _subTabController = TabController(
      length: 4, 
      vsync: this,
      initialIndex: widget.initialSubTab ?? 0,
    );
    _subTabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  int get _totalQuotes => _quotesByClient.fold(0, (sum, g) => sum + (g['quotes'] as List).length);
  
  // Get pending proposals from sent invitations
  List<Map<String, dynamic>> get _actualPendingProposals {
    final salesProvider = context.watch<SalesProvider>();
    
    // Transform sent invitations into pending proposal format
    final invitationProposals = salesProvider.sentInvitations
        .where((inv) => inv['status'] != 'submitted')
        .map((inv) {
          final createdAt = inv['created_at'] != null 
              ? DateTime.tryParse(inv['created_at'].toString()) ?? DateTime.now()
              : DateTime.now();
          
          // Parse line_items from database (stored as JSONB)
          final rawLineItems = inv['line_items'];
          final lineItems = rawLineItems is List 
              ? rawLineItems.map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{}).toList()
              : <Map<String, dynamic>>[];
          
          // Calculate total amount from line items
          double totalAmount = 0;
          for (final item in lineItems) {
            totalAmount += (item['amount'] as num?)?.toDouble() ?? 0;
          }
          
          return <String, dynamic>{
            'id': inv['id'],
            'title': inv['project_name'] ?? 'Collaboration Request',
            'number': inv['id']?.toString().substring(0, 8) ?? '',
            'date': createdAt,
            'client': inv['company_name'] ?? inv['owner_name'] ?? '',
            'clientEmail': inv['collaborator_email'] ?? '',
            'amount': totalAmount > 0 ? totalAmount : (inv['response_amount'] ?? 0) as num,
            'lineItems': lineItems,
            'collaborators': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': inv['id'],
                'name': inv['collaborator_name'] ?? '',
                'company': inv['collaborator_company'] ?? '',
                'email': inv['collaborator_email'] ?? '',
                'role': inv['role'] ?? 'Collaborator',
                'status': inv['status'] ?? 'pending',
                'showInfo': inv['show_pricing'] ?? true,
              }
            ],
          };
        }).toList();
    
    return invitationProposals;
  }
  
  int get _pendingCount => _actualPendingProposals.length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sub-tabs (All Quotes, Pending, Responses, Templates)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _buildSubTab(0, 'All', _totalQuotes),
              _buildSubTab(1, 'Pending', _pendingCount, highlight: _pendingCount > 0),
              _buildSubTab(2, 'Responses', _responses.length),
              _buildSubTab(3, 'Templates', _templates.length),
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
              _buildPendingContent(),
              _buildResponsesContent(),
              _buildTemplatesContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubTab(int index, String label, int count, {bool highlight = false}) {
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
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: highlight 
                      ? AppColors.warning.withOpacity(isSelected ? 0.2 : 0.1)
                      : (isSelected ? AppColors.accent.withOpacity(0.1) : AppColors.neutral200),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: highlight 
                        ? AppColors.warning 
                        : (isSelected ? AppColors.accent : AppColors.textTertiary),
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
        // Filter
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Spacer(),
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
                      ...quotes.map((quote) => _buildQuoteItem(
                        quote, 
                        clientName: client, 
                        clientEmail: group['clientEmail'] as String?,
                      )),
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

  Widget _buildQuoteItem(Map<String, dynamic> quote, {String? clientName, String? clientEmail}) {
    final dateFormat = DateFormat('M/d/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final amount = (quote['amount'] as num?)?.toDouble() ?? 0.0;
    final title = (quote['title'] as String?) ?? 'Untitled Quote';
    final number = (quote['number'] as String?) ?? '';
    final status = (quote['status'] as String?) ?? 'draft';
    final views = (quote['views'] as int?) ?? 0;
    
    // Handle both DateTime and String dates
    DateTime? quoteDate;
    final dateValue = quote['date'] ?? quote['created_at'];
    if (dateValue is DateTime) {
      quoteDate = dateValue;
    } else if (dateValue is String) {
      quoteDate = DateTime.tryParse(dateValue);
    }
    quoteDate ??= DateTime.now();
    
    return InkWell(
      onTap: () => _showQuotePreview(quote, clientName: clientName, clientEmail: clientEmail),
      child: Container(
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
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      number.isNotEmpty 
                        ? '$number • ${dateFormat.format(quoteDate)}'
                        : dateFormat.format(quoteDate),
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount
              Text(
                currencyFormat.format(amount),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(status),
                  if (views > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_outlined, size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 2),
                        Text('$views', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuotePreview(Map<String, dynamic> quote, {String? clientName, String? clientEmail}) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final lineItems = (quote['lineItems'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final amount = (quote['amount'] as num?)?.toDouble() ?? 0.0;
    final status = (quote['status'] as String?) ?? 'draft';
    final title = (quote['title'] as String?) ?? 'Untitled Quote';
    final number = (quote['number'] as String?) ?? '';
    
    // Handle both DateTime and String dates
    DateTime? quoteDate;
    final dateValue = quote['date'] ?? quote['created_at'];
    if (dateValue is DateTime) {
      quoteDate = dateValue;
    } else if (dateValue is String) {
      quoteDate = DateTime.tryParse(dateValue);
    }
    quoteDate ??= DateTime.now();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildStatusBadge(status),
                            const SizedBox(width: 8),
                            if (number.isNotEmpty)
                              Text('# $number', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Created ${dateFormat.format(quoteDate!)}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
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
                                clientName?.isNotEmpty == true ? clientName![0] : 'C',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.accent),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(clientName ?? 'Client', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                if (clientEmail != null)
                                  Text(clientEmail, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Line Items
                    const Text('Services & Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.neutral50,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: Row(
                              children: [
                                const Expanded(flex: 3, child: Text('Item', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                                const SizedBox(width: 60, child: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // Items
                          ...lineItems.map((item) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.5))),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text(item['name'] as String, style: const TextStyle(fontSize: 13))),
                                SizedBox(width: 80, child: Text(currencyFormat.format(item['amount']), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
                              ],
                            ),
                          )),
                          // Total
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.05),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                Text(currencyFormat.format(amount), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Signature Info (if approved)
                    if (status == 'approved' && quote['signedBy'] != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.verified, color: AppColors.success, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Approved & Signed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'By ${quote['signedBy']} on ${dateFormat.format(quote['signedAt'])}',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Views Info
                    if ((quote['views'] as int?) != null && quote['views'] > 0) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 16, color: AppColors.textTertiary),
                          const SizedBox(width: 6),
                          Text('Viewed ${quote['views']} time${quote['views'] > 1 ? 's' : ''}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  if (status == 'draft') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Edit proposal
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Proposal sent!'), behavior: SnackBarBehavior.floating),
                          );
                        },
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('Send'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                  ] else if (status == 'sent') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _resendProposal(quote, clientName, clientEmail);
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Resend'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Download PDF
                        },
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Download'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                  ] else if (status == 'approved') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Download PDF
                        },
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Download'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Convert to project
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Converting to project...'), behavior: SnackBarBehavior.floating),
                          );
                        },
                        icon: const Icon(Icons.rocket_launch, size: 18),
                        label: const Text('Convert'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status.isEmpty) status = 'draft';
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

  // ============ PENDING CONTENT ============
  Widget _buildPendingContent() {
    final dateFormat = DateFormat('MMM d');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    
    if (_actualPendingProposals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No Pending Proposals',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Proposals waiting for collaborator\nsubmissions will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Info Banner
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.warning.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppColors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'These proposals are waiting for collaborator submissions before sending to clients.',
                  style: TextStyle(fontSize: 11, color: AppColors.warning.withOpacity(0.9)),
                ),
              ),
            ],
          ),
        ),

        // Pending Proposals List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _actualPendingProposals.length,
            itemBuilder: (context, index) {
              final proposal = _actualPendingProposals[index];
              final collaboratorsList = proposal['collaborators'] as List<dynamic>? ?? [];
              final collaborators = collaboratorsList.map((c) => c as Map<String, dynamic>).toList();
              final submitted = collaborators.where((c) => c['status'] == 'submitted').length;
              final total = collaborators.length;
              final allSubmitted = submitted == total;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppShadows.sm,
                  border: allSubmitted ? Border.all(color: AppColors.success.withOpacity(0.3), width: 1.5) : null,
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
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: allSubmitted ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              allSubmitted ? Icons.check_circle_outline : Icons.hourglass_top,
                              color: allSubmitted ? AppColors.success : AppColors.warning,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (proposal['title'] as String?) ?? 'Untitled',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Text(
                                      (proposal['client'] as String?) ?? '',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('•', style: TextStyle(color: AppColors.textTertiary)),
                                    const SizedBox(width: 8),
                                    Text(
                                      '#${proposal['number']}',
                                      style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFormat.format(proposal['amount']),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateFormat.format(proposal['date'] as DateTime),
                                style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const Divider(height: 1),
                    
                    // Collaborators Status
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Collaborators',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: allSubmitted ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$submitted / $total submitted',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: allSubmitted ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...collaborators.map((collab) => _buildCollaboratorRow(collab)),
                        ],
                      ),
                    ),
                    
                    const Divider(height: 1),
                    
                    // Actions
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          if (allSubmitted) ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showMergePreview(proposal),
                                icon: const Icon(Icons.merge, size: 18),
                                label: const Text('Merge & Review'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _sendCollaboratorReminder(proposal),
                                icon: const Icon(Icons.notifications_active_outlined, size: 18),
                                label: const Text('Send Reminder'),
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showPartialPreview(proposal),
                                icon: const Icon(Icons.visibility_outlined, size: 18),
                                label: const Text('Preview'),
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                              ),
                            ),
                          ],
                          const SizedBox(width: 10),
                          PopupMenuButton(
                            icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit Proposal')),
                              const PopupMenuItem(value: 'send_solo', child: Text('Send Without Collaborators')),
                              const PopupMenuItem(value: 'cancel', child: Text('Cancel', style: TextStyle(color: AppColors.error))),
                            ],
                            onSelected: (value) {
                              if (value == 'send_solo') {
                                _showSendSoloConfirmation(proposal);
                              }
                            },
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

  Widget _buildCollaboratorRow(Map<String, dynamic> collab) {
    final isSubmitted = collab['status'] == 'submitted';
    final showInfo = collab['showInfo'] as bool? ?? true;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSubmitted ? AppColors.success.withOpacity(0.05) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSubmitted ? AppColors.success.withOpacity(0.2) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Avatar with status
          Stack(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.neutral200,
                child: Text(
                  ((collab['name'] as String?) ?? '?').isNotEmpty ? (collab['name'] as String).substring(0, 1) : '?',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isSubmitted ? AppColors.success : AppColors.warning,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      (collab['name'] as String?) ?? 'Unknown',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    if (!showInfo)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Anonymous',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: AppColors.purple),
                        ),
                      ),
                  ],
                ),
                Text(
                  (collab['role'] as String?) ?? 'Collaborator',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (isSubmitted) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(collab['totalAmount'] ?? 0),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 10, color: AppColors.success),
                    const SizedBox(width: 2),
                    Text('Submitted', style: TextStyle(fontSize: 9, color: AppColors.success)),
                  ],
                ),
              ],
            ),
          ] else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.hourglass_empty, size: 14, color: AppColors.warning),
                Text('Pending', style: TextStyle(fontSize: 9, color: AppColors.warning)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showMergePreview(Map<String, dynamic> proposal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MergedProposalPreview(
        proposal: proposal,
        showCollaboratorInfo: true, // Show with collaborator info first
        onSend: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Proposal sent to client!'), backgroundColor: AppColors.success),
          );
          // Refresh pending invitations
          context.read<SalesProvider>().loadAll();
        },
      ),
    );
  }

  Future<void> _sendCollaboratorReminder(Map<String, dynamic> proposal) async {
    final invitationId = proposal['id'];
    if (invitationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send reminder: invitation not found'), backgroundColor: AppColors.error),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final supabaseService = SupabaseService();
      await supabaseService.sendCollaboratorReminder(invitationId.toString());
      
      Navigator.pop(context); // Close loading
      
      if (mounted) {
        final collaboratorEmail = proposal['clientEmail'] ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder sent to $collaboratorEmail'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reminder: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showPartialPreview(Map<String, dynamic> proposal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MergedProposalPreview(
        proposal: proposal,
        showCollaboratorInfo: true,
        isPartial: true,
      ),
    );
  }

  void _showSendSoloConfirmation(Map<String, dynamic> proposal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Without Collaborators?'),
        content: Text(
          'This will send only your services to ${proposal['client']}. '
          'Collaborators can still send their proposals independently.',
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
                const SnackBar(content: Text('Proposal sent without collaborators'), backgroundColor: AppColors.info),
              );
              // Refresh pending invitations
              context.read<SalesProvider>().loadAll();
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _resendProposal(Map<String, dynamic> quote, String? clientName, String? clientEmail) async {
    if (clientEmail == null || clientEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No client email available'), backgroundColor: AppColors.error),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resend Proposal'),
        content: Text('Resend this proposal to $clientEmail?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resend'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final authProvider = context.read<AuthProvider>();
      final supabase = context.read<SupabaseService>();
      
      await supabase.sendProposal(
        quoteId: quote['id'],
        companyId: authProvider.currentCompanyId ?? '',
        clientEmail: clientEmail,
        clientName: clientName ?? 'Client',
        projectName: quote['title'] ?? quote['project'] ?? 'Project',
        companyName: authProvider.currentCompanyName ?? 'Company',
        senderName: authProvider.userName,
        letterContent: 'This is a reminder about the proposal we sent previously. Please review and respond at your earliest convenience.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Proposal resent to $clientEmail'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ============ RESPONSES CONTENT ============
  Widget _buildResponsesContent() {
    final dateFormat = DateFormat('M/d');
    
    return Column(
      children: [
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
        // Add Button
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Spacer(),
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

// ============ MERGED PROPOSAL PREVIEW ============
class _MergedProposalPreview extends StatefulWidget {
  final Map<String, dynamic> proposal;
  final bool showCollaboratorInfo;
  final bool isPartial;
  final VoidCallback? onSend;

  const _MergedProposalPreview({
    required this.proposal,
    this.showCollaboratorInfo = true,
    this.isPartial = false,
    this.onSend,
  });

  @override
  State<_MergedProposalPreview> createState() => _MergedProposalPreviewState();
}

class _MergedProposalPreviewState extends State<_MergedProposalPreview> {
  late bool _showCollaboratorInfo;
  
  @override
  void initState() {
    super.initState();
    _showCollaboratorInfo = widget.showCollaboratorInfo;
  }

  @override
  Widget build(BuildContext context) {
    try {
      return _buildContent(context);
    } catch (e, stack) {
      debugPrint('MergedProposalPreview ERROR: $e');
      debugPrint('Stack: $stack');
      return Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading preview:\n$e', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildContent(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('MMMM d, yyyy');
    final proposal = widget.proposal;
    final lineItemsList = proposal['lineItems'] as List<dynamic>? ?? [];
    final lineItems = lineItemsList.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();
    final collaboratorsList = proposal['collaborators'] as List<dynamic>? ?? [];
    final collaborators = collaboratorsList.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();
    final submittedCollaborators = collaborators.where((c) => c['status'] == 'submitted').toList();
    
    // Calculate totals
    double ownerTotal = (proposal['amount'] as num?)?.toDouble() ?? 0.0;
    double collaboratorTotal = 0;
    for (final collab in submittedCollaborators) {
      collaboratorTotal += (collab['totalAmount'] as num? ?? 0).toDouble();
    }
    double grandTotal = ownerTotal + collaboratorTotal;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.description_outlined, color: AppColors.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isPartial ? 'Preview (Partial)' : 'Merged Proposal Preview',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '#${proposal['number']}',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                
                // Toggle View Mode
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showCollaboratorInfo = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _showCollaboratorInfo ? AppColors.cardBackground : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _showCollaboratorInfo ? AppShadows.sm : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.visibility,
                                  size: 16,
                                  color: _showCollaboratorInfo ? AppColors.accent : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'With Info',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _showCollaboratorInfo ? FontWeight.w600 : FontWeight.w400,
                                    color: _showCollaboratorInfo ? AppColors.accent : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showCollaboratorInfo = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_showCollaboratorInfo ? AppColors.cardBackground : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: !_showCollaboratorInfo ? AppShadows.sm : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.visibility_off,
                                  size: 16,
                                  color: !_showCollaboratorInfo ? AppColors.purple : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Anonymous',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: !_showCollaboratorInfo ? FontWeight.w600 : FontWeight.w400,
                                    color: !_showCollaboratorInfo ? AppColors.purple : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Proposal Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.accent.withOpacity(0.1),
                          child: Text(
                            (proposal['client'] as String?)?.isNotEmpty == true 
                                ? (proposal['client'] as String).substring(0, 1).toUpperCase()
                                : '?',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accent),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (proposal['client'] as String?)?.isNotEmpty == true 
                                    ? proposal['client'] as String 
                                    : 'Unknown Client',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                (proposal['clientEmail'] as String?) ?? '',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Proposal Date', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                            Text(
                              proposal['date'] != null 
                                  ? dateFormat.format(proposal['date'] as DateTime)
                                  : '-',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Proposal Title
                  Text(
                    (proposal['title'] as String?) ?? 'Untitled Proposal',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // YOUR SERVICES SECTION
                  _buildSectionHeader('Your Services', ownerTotal, currencyFormat, isOwner: true),
                  const SizedBox(height: 12),
                  _buildLineItemsTable(lineItems, currencyFormat),
                  
                  const SizedBox(height: 24),
                  
                  // COLLABORATOR SERVICES
                  if (submittedCollaborators.isNotEmpty) ...[
                    for (final collab in submittedCollaborators) ...[
                      _buildCollaboratorSection(collab, currencyFormat),
                      const SizedBox(height: 20),
                    ],
                  ],
                  
                  // Pending Collaborators Notice
                  if (widget.isPartial && collaborators.where((c) => c['status'] != 'submitted').isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.hourglass_empty, size: 18, color: AppColors.warning),
                              const SizedBox(width: 8),
                              Text(
                                'Awaiting Submissions',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warning),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...collaborators.where((c) => c['status'] != 'submitted').map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  '${p['name']} - ${p['role']}',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // GRAND TOTAL
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Your Services', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            Text(currencyFormat.format(ownerTotal), style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        if (collaboratorTotal > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Collaborator Services', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              Text(currencyFormat.format(collaboratorTotal), style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ],
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grand Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            Text(
                              currencyFormat.format(grandTotal),
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.accent),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // View Mode Description
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _showCollaboratorInfo ? AppColors.info.withOpacity(0.08) : AppColors.purple.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _showCollaboratorInfo ? Icons.visibility : Icons.visibility_off,
                          size: 18,
                          color: _showCollaboratorInfo ? AppColors.info : AppColors.purple,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _showCollaboratorInfo
                                ? 'Client will see collaborator names and company details alongside their services.'
                                : 'Client will only see "Additional Services" without collaborator identities.',
                            style: TextStyle(
                              fontSize: 11,
                              color: _showCollaboratorInfo ? AppColors.info : AppColors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Footer Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                if (!widget.isPartial && widget.onSend != null)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: widget.onSend,
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Send to Client'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                if (widget.isPartial)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Download'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, double total, NumberFormat currencyFormat, {bool isOwner = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOwner ? AppColors.accent.withOpacity(0.1) : AppColors.neutral100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: [
          if (isOwner)
            Icon(Icons.person, size: 16, color: AppColors.accent)
          else
            Icon(Icons.group, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isOwner ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            currencyFormat.format(total),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isOwner ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemsTable(List<Map<String, dynamic>> items, NumberFormat currencyFormat) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final isLast = entry.key == items.length - 1;
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: isLast ? null : Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text((item['name'] as String?) ?? (item['description'] as String?) ?? '', style: const TextStyle(fontSize: 13)),
                ),
                if (item['days'] != null)
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${item['days']} days',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                SizedBox(
                  width: 80,
                  child: Text(
                    currencyFormat.format(item['amount']),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCollaboratorSection(Map<String, dynamic> collab, NumberFormat currencyFormat) {
    final showInfo = collab['showInfo'] as bool? ?? true;
    final items = collab['lineItems'] as List<Map<String, dynamic>>? ?? [];
    final total = (collab['totalAmount'] as num? ?? 0).toDouble();
    
    // Determine what to show based on _showCollaboratorInfo toggle
    String sectionTitle;
    if (_showCollaboratorInfo && showInfo) {
      sectionTitle = '${collab['name']} - ${collab['company']}';
    } else {
      sectionTitle = 'Additional Services ${collab['role'] != null ? '(${collab['role']})' : ''}';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _showCollaboratorInfo && showInfo 
                ? AppColors.info.withOpacity(0.1) 
                : AppColors.purple.withOpacity(0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(
            children: [
              if (_showCollaboratorInfo && showInfo) ...[
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.info.withOpacity(0.2),
                  child: Text(
                    ((collab['name'] as String?) ?? '?').isNotEmpty ? (collab['name'] as String).substring(0, 1) : '?',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.info),
                  ),
                ),
              ] else ...[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_outline, size: 14, color: AppColors.purple),
                ),
              ],
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _showCollaboratorInfo && showInfo ? AppColors.info : AppColors.purple,
                      ),
                    ),
                    if (_showCollaboratorInfo && showInfo)
                      Text(
                        (collab['email'] as String?) ?? '',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              Text(
                currencyFormat.format(total),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _showCollaboratorInfo && showInfo ? AppColors.info : AppColors.purple,
                ),
              ),
            ],
          ),
        ),
        _buildLineItemsTable(items, currencyFormat),
      ],
    );
  }
}

// ============ MODALS & DIALOGS ============
class _AddLeadModal extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onLeadAdded;
  
  const _AddLeadModal({required this.onLeadAdded});

  @override
  State<_AddLeadModal> createState() => _AddLeadModalState();
}

class _AddLeadModalState extends State<_AddLeadModal> {
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _valueController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedSource = 'Website';
  String _selectedType = 'Other';
  bool _showMoreFields = false;
  
  final List<String> _sources = ['Website', 'Referral', 'Cold Call', 'Social Media', 'Other'];
  final List<String> _types = ['Retail', 'Consulting', 'Finance', 'Technology', 'Healthcare', 'Construction', 'Real Estate', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _valueController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a lead name'), backgroundColor: AppColors.error),
      );
      return;
    }

    // Save scaffold messenger before closing modal
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final valueText = _valueController.text.replaceAll(RegExp(r'[^\d.]'), '');
    final value = double.tryParse(valueText) ?? 0.0;

    final newLead = {
      'name': _nameController.text.trim(),
      'title': _titleController.text.trim(),
      'company': _companyController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'zip': _zipController.text.trim(),
      'website': _websiteController.text.trim(),
      'type': _selectedType,
      'source': _selectedSource.toLowerCase(),
      'status': 'new',
      'value': value,
      'notes': _notesController.text.trim(),
    };

    // Close modal
    Navigator.pop(context);
    
    // Save lead (async) - provider was captured in parent context
    await widget.onLeadAdded(newLead);
    
    // Show success
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Lead added successfully!'), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: _showMoreFields ? 0.92 : 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Add Lead', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              Text('Enter lead details for future conversion to client', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              
              // Basic Info
              _buildTextField('Contact Name *', 'Full name', _nameController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Company', 'Company name', _companyController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField('Title', 'Job title', _titleController)),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField('Email', 'email@example.com', _emailController, TextInputType.emailAddress),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Phone', '+1 (555) 000-0000', _phoneController, TextInputType.phone)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField('Est. Value', '\$0.00', _valueController, TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSourceDropdown()),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTypeDropdown()),
                ],
              ),
              
              // Show more fields toggle
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _showMoreFields = !_showMoreFields),
                child: Row(
                  children: [
                    Icon(_showMoreFields ? Icons.expand_less : Icons.expand_more, 
                      size: 18, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(_showMoreFields ? 'Show less' : 'Add more details (address, website, notes)',
                      style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              
              if (_showMoreFields) ...[
                const SizedBox(height: 16),
                _buildTextField('Address', 'Street address', _addressController),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(flex: 2, child: _buildTextField('City', 'City', _cityController)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField('State', 'CA', _stateController)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField('ZIP', '90001', _zipController, TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField('Website', 'www.company.com', _websiteController, TextInputType.url),
                const SizedBox(height: 12),
                _buildTextArea('Notes', 'Additional notes about this lead...', _notesController),
              ],
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Add Lead'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, [TextInputType? keyboardType]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.neutral50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.accent)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildTextArea(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.neutral50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Source', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSource,
              isExpanded: true,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              items: _sources.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setState(() => _selectedSource = val ?? 'Website'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedType,
              isExpanded: true,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _selectedType = val ?? 'Other'),
            ),
          ),
        ),
      ],
    );
  }
}

// Edit Lead Modal
class _EditLeadModal extends StatefulWidget {
  final Map<String, dynamic> lead;
  final Function(Map<String, dynamic>) onLeadUpdated;
  
  const _EditLeadModal({required this.lead, required this.onLeadUpdated});

  @override
  State<_EditLeadModal> createState() => _EditLeadModalState();
}

class _EditLeadModalState extends State<_EditLeadModal> {
  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _valueController;
  late String _selectedSource;
  late String _selectedStatus;
  
  final List<String> _sources = ['Website', 'Referral', 'Cold Call', 'Social Media', 'Other'];
  final List<String> _statuses = ['new', 'contacted', 'qualified', 'proposal', 'won', 'lost'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.lead['name']);
    _companyController = TextEditingController(text: widget.lead['company'] ?? '');
    _emailController = TextEditingController(text: widget.lead['email'] ?? '');
    _phoneController = TextEditingController(text: widget.lead['phone'] ?? '');
    _valueController = TextEditingController(text: widget.lead['value']?.toString() ?? '0');
    _selectedSource = widget.lead['source'] ?? 'Website';
    _selectedStatus = widget.lead['status'] ?? 'new';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a lead name'), backgroundColor: AppColors.error),
      );
      return;
    }

    final valueText = _valueController.text.replaceAll(RegExp(r'[^\d.]'), '');
    final value = double.tryParse(valueText) ?? 0.0;

    final updatedLead = {
      ...widget.lead,
      'name': _nameController.text.trim(),
      'company': _companyController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'source': _selectedSource,
      'status': _selectedStatus,
      'value': value,
    };

    widget.onLeadUpdated(updatedLead);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lead updated successfully!'), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
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
              const Text('Edit Lead', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _buildTextField('Lead Name *', 'Enter lead name', _nameController),
              const SizedBox(height: 14),
              _buildTextField('Company', 'Company name', _companyController),
              const SizedBox(height: 14),
              _buildTextField('Email', 'email@example.com', _emailController, TextInputType.emailAddress),
              const SizedBox(height: 14),
              _buildTextField('Phone', '+1 (555) 000-0000', _phoneController, TextInputType.phone),
              const SizedBox(height: 14),
              _buildTextField('Estimated Value', '\$0.00', _valueController, TextInputType.number),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildSourceDropdown()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatusDropdown()),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, [TextInputType? keyboardType]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.neutral50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.accent)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Source', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSource,
              isExpanded: true,
              items: _sources.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (val) => setState(() => _selectedSource = val ?? 'Website'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              isExpanded: true,
              items: _statuses.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s[0].toUpperCase() + s.substring(1), style: const TextStyle(fontSize: 14)),
              )).toList(),
              onChanged: (val) => setState(() => _selectedStatus = val ?? 'new'),
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
    // This is a legacy placeholder - use _AddClientModalFull instead
    return const SizedBox.shrink();
  }
}

// Full Add/Edit Client Modal
class _AddClientModalFull extends StatefulWidget {
  final Map<String, dynamic>? client;
  final Function(Map<String, dynamic>) onClientSaved;
  
  const _AddClientModalFull({this.client, required this.onClientSaved});

  @override
  State<_AddClientModalFull> createState() => _AddClientModalFullState();
}

class _AddClientModalFullState extends State<_AddClientModalFull> {
  // Company Info
  late TextEditingController _companyController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _websiteController;
  late TextEditingController _notesController;
  String _selectedType = 'Retail';
  
  // Primary Contact
  late TextEditingController _primaryNameController;
  late TextEditingController _primaryEmailController;
  late TextEditingController _primaryPhoneController;
  late TextEditingController _primaryTitleController;
  
  // Billing Contact
  late TextEditingController _billingNameController;
  late TextEditingController _billingEmailController;
  late TextEditingController _billingPhoneController;
  late TextEditingController _billingTitleController;
  bool _hasSeparateBilling = false;
  
  final List<String> _clientTypes = ['Retail', 'Consulting', 'Finance', 'Technology', 'Healthcare', 'Construction', 'Real Estate', 'Other'];

  bool get _isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    // Company
    _companyController = TextEditingController(text: widget.client?['company'] ?? '');
    _addressController = TextEditingController(text: widget.client?['address'] ?? '');
    _cityController = TextEditingController(text: widget.client?['city'] ?? '');
    _stateController = TextEditingController(text: widget.client?['state'] ?? '');
    _zipController = TextEditingController(text: widget.client?['zip'] ?? '');
    _websiteController = TextEditingController(text: widget.client?['website'] ?? '');
    _notesController = TextEditingController(text: widget.client?['notes'] ?? '');
    _selectedType = widget.client?['type'] ?? 'Retail';
    
    // Primary Contact
    _primaryNameController = TextEditingController(text: widget.client?['primaryName'] ?? '');
    _primaryEmailController = TextEditingController(text: widget.client?['primaryEmail'] ?? '');
    _primaryPhoneController = TextEditingController(text: widget.client?['primaryPhone'] ?? '');
    _primaryTitleController = TextEditingController(text: widget.client?['primaryTitle'] ?? '');
    
    // Billing Contact
    _billingNameController = TextEditingController(text: widget.client?['billingName'] ?? '');
    _billingEmailController = TextEditingController(text: widget.client?['billingEmail'] ?? '');
    _billingPhoneController = TextEditingController(text: widget.client?['billingPhone'] ?? '');
    _billingTitleController = TextEditingController(text: widget.client?['billingTitle'] ?? '');
    _hasSeparateBilling = (widget.client?['billingEmail'] as String?)?.isNotEmpty ?? false;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    _primaryNameController.dispose();
    _primaryEmailController.dispose();
    _primaryPhoneController.dispose();
    _primaryTitleController.dispose();
    _billingNameController.dispose();
    _billingEmailController.dispose();
    _billingPhoneController.dispose();
    _billingTitleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_companyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter company name'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_primaryNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter primary contact name'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_primaryEmailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter primary contact email'), backgroundColor: AppColors.error),
      );
      return;
    }

    final clientData = {
      'id': widget.client?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'company': _companyController.text.trim(),
      // Primary Contact
      'primaryName': _primaryNameController.text.trim(),
      'primaryEmail': _primaryEmailController.text.trim(),
      'primaryPhone': _primaryPhoneController.text.trim(),
      'primaryTitle': _primaryTitleController.text.trim(),
      // Billing Contact (empty if same as primary)
      'billingName': _hasSeparateBilling ? _billingNameController.text.trim() : '',
      'billingEmail': _hasSeparateBilling ? _billingEmailController.text.trim() : '',
      'billingPhone': _hasSeparateBilling ? _billingPhoneController.text.trim() : '',
      'billingTitle': _hasSeparateBilling ? _billingTitleController.text.trim() : '',
      // Address
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'zip': _zipController.text.trim(),
      'website': _websiteController.text.trim(),
      'notes': _notesController.text.trim(),
      'type': _selectedType,
      // Preserve existing data
      'quotes': widget.client?['quotes'] ?? 0,
      'projects': widget.client?['projects'] ?? 0,
      'value': widget.client?['value'] ?? 0.0,
      'created': widget.client?['created'] ?? DateTime.now(),
      'lastActivity': widget.client?['lastActivity'] ?? DateTime.now(),
    };

    widget.onClientSaved(clientData);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Client updated successfully!' : 'Client added successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
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
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_isEditing ? 'Edit Client' : 'Add Client', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 20),

              // Company Info Section
              _buildSectionCard(
                'Company Information',
                Icons.business,
                AppColors.accent,
                [
                  _buildTextField('Company Name *', 'Enter company name', _companyController),
                  const SizedBox(height: 12),
                  _buildTypeDropdown(),
                  const SizedBox(height: 12),
                  _buildTextField('Website', 'www.company.com', _websiteController, TextInputType.url),
                ],
              ),
              const SizedBox(height: 16),

              // Primary Contact Section
              _buildSectionCard(
                'Primary Contact',
                Icons.person,
                AppColors.accent,
                [
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Name *', 'Full name', _primaryNameController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Title', 'Job title', _primaryTitleController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField('Email *', 'email@company.com', _primaryEmailController, TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _buildTextField('Phone', '+1 (555) 000-0000', _primaryPhoneController, TextInputType.phone),
                ],
                badge: 'Main point of contact',
              ),
              const SizedBox(height: 16),

              // Billing Contact Section
              _buildSectionCard(
                'Billing Contact',
                Icons.receipt_long,
                AppColors.info,
                [
                  // Toggle for separate billing
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Different from primary contact?',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                      Switch(
                        value: _hasSeparateBilling,
                        onChanged: (val) => setState(() => _hasSeparateBilling = val),
                        activeColor: AppColors.info,
                      ),
                    ],
                  ),
                  if (_hasSeparateBilling) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Name', 'Full name', _billingNameController)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField('Title', 'Accounts Payable', _billingTitleController)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField('Email', 'billing@company.com', _billingEmailController, TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _buildTextField('Phone', '+1 (555) 000-0000', _billingPhoneController, TextInputType.phone),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Invoices will be sent to the primary contact',
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary, fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
                badge: 'For sending invoices',
              ),
              const SizedBox(height: 16),

              // Address Section
              _buildSectionCard(
                'Company Address',
                Icons.location_on,
                AppColors.textSecondary,
                [
                  _buildTextField('Street Address', '123 Main Street', _addressController),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(flex: 2, child: _buildTextField('City', 'City', _cityController)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTextField('State', 'CA', _stateController)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTextField('ZIP', '90001', _zipController, TextInputType.number)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes Section
              _buildSectionCard(
                'Notes',
                Icons.notes,
                AppColors.textSecondary,
                [
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Additional notes about this client...',
                      filled: true,
                      fillColor: AppColors.neutral50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isEditing ? 'Save Changes' : 'Add Client'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, List<Widget> children, {String? badge}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              if (badge != null) ...[
                const Spacer(),
                Text(badge, style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, [TextInputType? keyboardType]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.neutral50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.accent)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Client Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedType,
              isExpanded: true,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              items: _clientTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _selectedType = val ?? 'Retail'),
            ),
          ),
        ),
      ],
    );
  }
}

// ============ CONVERSION MODAL ============
// Handles Lead → Client and Proposal → Project conversion
class _ConversionModal extends StatefulWidget {
  final Map<String, dynamic> lead;
  final Function(Map<String, dynamic> client, String projectName) onConvert;
  
  const _ConversionModal({required this.lead, required this.onConvert});

  @override
  State<_ConversionModal> createState() => _ConversionModalState();
}

class _ConversionModalState extends State<_ConversionModal> {
  late TextEditingController _projectNameController;
  late TextEditingController _companyController;
  late TextEditingController _primaryNameController;
  late TextEditingController _primaryEmailController;
  late TextEditingController _primaryPhoneController;
  late TextEditingController _primaryTitleController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _websiteController;
  late String _selectedType;
  bool _addBillingContact = false;
  late TextEditingController _billingNameController;
  late TextEditingController _billingEmailController;
  late TextEditingController _billingPhoneController;
  late TextEditingController _billingTitleController;
  
  // Mock proposal line items (in real app, fetch from proposal)
  final List<Map<String, dynamic>> _proposalLineItems = [
    {'name': 'Web Development', 'hours': 40, 'rate': 150.0, 'amount': 6000.0},
    {'name': 'UI/UX Design', 'hours': 20, 'rate': 125.0, 'amount': 2500.0},
    {'name': 'Project Management', 'hours': 10, 'rate': 100.0, 'amount': 1000.0},
  ];

  @override
  void initState() {
    super.initState();
    final lead = widget.lead;
    
    // Pre-fill from lead data
    _projectNameController = TextEditingController(
      text: '${lead['company']?.isNotEmpty == true ? lead['company'] : lead['name']} Project'
    );
    _companyController = TextEditingController(text: lead['company'] ?? '');
    _primaryNameController = TextEditingController(text: lead['name'] ?? '');
    _primaryEmailController = TextEditingController(text: lead['email'] ?? '');
    _primaryPhoneController = TextEditingController(text: lead['phone'] ?? '');
    _primaryTitleController = TextEditingController(text: lead['title'] ?? '');
    _addressController = TextEditingController(text: lead['address'] ?? '');
    _cityController = TextEditingController(text: lead['city'] ?? '');
    _stateController = TextEditingController(text: lead['state'] ?? '');
    _zipController = TextEditingController(text: lead['zip'] ?? '');
    _websiteController = TextEditingController(text: lead['website'] ?? '');
    _selectedType = lead['type'] ?? 'Other';
    
    // Billing (empty by default - uses primary)
    _billingNameController = TextEditingController();
    _billingEmailController = TextEditingController();
    _billingPhoneController = TextEditingController();
    _billingTitleController = TextEditingController();
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _companyController.dispose();
    _primaryNameController.dispose();
    _primaryEmailController.dispose();
    _primaryPhoneController.dispose();
    _primaryTitleController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _websiteController.dispose();
    _billingNameController.dispose();
    _billingEmailController.dispose();
    _billingPhoneController.dispose();
    _billingTitleController.dispose();
    super.dispose();
  }

  void _convert() {
    if (_companyController.text.isEmpty || _primaryNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company name and primary contact are required'), backgroundColor: AppColors.error),
      );
      return;
    }

    // Create client from lead data
    final newClient = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'company': _companyController.text.trim(),
      'primaryName': _primaryNameController.text.trim(),
      'primaryEmail': _primaryEmailController.text.trim(),
      'primaryPhone': _primaryPhoneController.text.trim(),
      'primaryTitle': _primaryTitleController.text.trim(),
      'billingName': _addBillingContact ? _billingNameController.text.trim() : '',
      'billingEmail': _addBillingContact ? _billingEmailController.text.trim() : '',
      'billingPhone': _addBillingContact ? _billingPhoneController.text.trim() : '',
      'billingTitle': _addBillingContact ? _billingTitleController.text.trim() : '',
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'zip': _zipController.text.trim(),
      'website': _websiteController.text.trim(),
      'type': _selectedType,
      'notes': 'Converted from lead: ${widget.lead['name']}\nOriginal proposal value: \$${widget.lead['value']}',
      'quotes': 1,
      'projects': 1,
      'value': widget.lead['value'] ?? 0.0,
      'created': DateTime.now(),
      'lastActivity': DateTime.now(),
      // Reference to original lead
      'convertedFromLeadId': widget.lead['id'],
    };

    Navigator.pop(context);
    widget.onConvert(newClient, _projectNameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              
              // Header
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.rocket_launch, color: AppColors.success, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Convert to Project', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        Text('Lead: ${widget.lead['name']}', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 20),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Conversion Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
                    const SizedBox(height: 12),
                    _buildSummaryRow(Icons.check_circle_outline, 'Create new client from lead info'),
                    _buildSummaryRow(Icons.check_circle_outline, 'Create project: "${_projectNameController.text}"'),
                    _buildSummaryRow(Icons.check_circle_outline, 'Convert ${_proposalLineItems.length} line items to tasks'),
                    _buildSummaryRow(Icons.check_circle_outline, 'Project value: ${currencyFormat.format(widget.lead['value'])}'),
                    _buildSummaryRow(Icons.check_circle_outline, 'Mark lead as "Won"'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Project Name
              _buildSectionHeader('Project Details', Icons.folder_outlined, AppColors.accent),
              const SizedBox(height: 10),
              _buildTextField('Project Name *', _projectNameController),
              const SizedBox(height: 20),

              // Tasks from Line Items
              _buildSectionHeader('Tasks (from proposal)', Icons.checklist, AppColors.info),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.neutral50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: _proposalLineItems.asMap().entries.map((entry) {
                    final item = entry.value;
                    final isLast = entry.key == _proposalLineItems.length - 1;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: isLast ? null : Border(bottom: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.task_alt, size: 16, color: AppColors.info),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                Text('${item['hours']}h @ ${currencyFormat.format(item['rate'])}/hr', 
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Text(currencyFormat.format(item['amount']), 
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Client Info (editable)
              _buildSectionHeader('Client Information', Icons.business, AppColors.accent),
              const SizedBox(height: 10),
              _buildTextField('Company Name *', _companyController),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildTextField('City', _cityController)),
                  const SizedBox(width: 10),
                  SizedBox(width: 70, child: _buildTextField('State', _stateController)),
                  const SizedBox(width: 10),
                  SizedBox(width: 80, child: _buildTextField('ZIP', _zipController)),
                ],
              ),
              const SizedBox(height: 20),

              // Primary Contact
              _buildSectionHeader('Primary Contact', Icons.person, AppColors.accent),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildTextField('Name *', _primaryNameController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField('Title', _primaryTitleController)),
                ],
              ),
              const SizedBox(height: 10),
              _buildTextField('Email', _primaryEmailController),
              const SizedBox(height: 10),
              _buildTextField('Phone', _primaryPhoneController),
              const SizedBox(height: 20),

              // Billing Contact (optional)
              Row(
                children: [
                  Expanded(child: _buildSectionHeader('Billing Contact', Icons.receipt_long, AppColors.info)),
                  Switch(
                    value: _addBillingContact,
                    onChanged: (val) => setState(() => _addBillingContact = val),
                    activeColor: AppColors.info,
                  ),
                ],
              ),
              if (_addBillingContact) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Name', _billingNameController)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField('Title', _billingTitleController)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTextField('Email', _billingEmailController),
                const SizedBox(height: 10),
                _buildTextField('Phone', _billingPhoneController),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Invoices will be sent to primary contact', 
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary, fontStyle: FontStyle.italic)),
                ),
              const SizedBox(height: 28),

              // Convert Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _convert,
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text('Convert to Project'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.neutral50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.accent)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
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

// ============ CONSULTANTS TAB ============
class _ConsultantsTab extends StatefulWidget {
  const _ConsultantsTab({super.key});

  @override
  State<_ConsultantsTab> createState() => _ConsultantsTabState();
}

class _ConsultantsTabState extends State<_ConsultantsTab> {
  String _searchQuery = '';
  String _statusFilter = 'all';
  
  List<Map<String, dynamic>> get _filteredConsultants {
    var filtered = context.watch<SalesProvider>().consultants;
    if (_statusFilter != 'all') {
      filtered = filtered.where((c) => c['status'] == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((c) =>
        ((c['name'] as String?) ?? '').toLowerCase().contains(query) ||
        ((c['company'] as String?) ?? '').toLowerCase().contains(query) ||
        ((c['specialty'] as String?) ?? '').toLowerCase().contains(query)
      ).toList();
    }
    return filtered;
  }

  Map<String, List<Map<String, dynamic>>> get _consultantsBySpecialty {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final consultant in _filteredConsultants) {
      final specialty = (consultant['specialty'] as String?) ?? 'Other';
      if (!groups.containsKey(specialty)) {
        groups[specialty] = [];
      }
      groups[specialty]!.add(consultant);
    }
    // Sort groups by specialty name
    final sortedKeys = groups.keys.toList()..sort();
    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, groups[key]!))
    );
  }

  void showAddConsultantModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddConsultantModal(
        onConsultantAdded: (newConsultant) async {
          await context.read<SalesProvider>().addConsultant(newConsultant);
        },
      ),
    );
  }

  void _showEditConsultantModal(Map<String, dynamic> consultant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EditConsultantModal(
        consultant: consultant,
        onConsultantUpdated: (updatedConsultant) async {
          await context.read<SalesProvider>().updateConsultant(
            updatedConsultant['id'],
            updatedConsultant,
          );
        },
      ),
    );
  }

  void _deleteConsultant(Map<String, dynamic> consultant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Consultant?'),
        content: Text('Are you sure you want to delete "${consultant['name']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<SalesProvider>().deleteConsultant(consultant['id']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Consultant deleted'), backgroundColor: AppColors.success),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showConsultantDetail(Map<String, dynamic> consultant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConsultantDetailModal(
        consultant: consultant,
        onEdit: () {
          Navigator.pop(context);
          _showEditConsultantModal(consultant);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    
    return Column(
      children: [
        // Filter
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) => setState(() => _statusFilter = value),
                child: Container(
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
                      Text(_statusFilter == 'all' ? 'All' : _statusFilter[0].toUpperCase() + _statusFilter.substring(1), 
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'all', child: Text('All')),
                  const PopupMenuItem(value: 'active', child: Text('Active')),
                  const PopupMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
              ),
            ],
          ),
        ),
        
        // Stats Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Consultants',
                  '${_filteredConsultants.length}',
                  Icons.people_outline,
                  AppColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Active Projects',
                  '${_filteredConsultants.fold(0, (sum, c) => sum + ((c['projects'] as int?) ?? 0))}',
                  Icons.work_outline,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Total Billed',
                  currencyFormat.format(_filteredConsultants.fold(0.0, (sum, c) => sum + ((c['totalBilled'] as num?)?.toDouble() ?? 0.0))),
                  Icons.attach_money,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Consultants List (Grouped by Specialty)
        Expanded(
          child: _filteredConsultants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 48, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      Text('No consultants found', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: showAddConsultantModal,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Consultant'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _consultantsBySpecialty.length,
                  itemBuilder: (context, groupIndex) {
                    final specialty = _consultantsBySpecialty.keys.elementAt(groupIndex);
                    final consultants = _consultantsBySpecialty[specialty]!;
                    
                    return _buildSpecialtyGroup(specialty, consultants);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyGroup(String specialty, List<Map<String, dynamic>> consultants) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.engineering_outlined,
                size: 18,
                color: AppColors.accent,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  specialty,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neutral50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${consultants.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          children: consultants.map((consultant) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildConsultantCard(consultant),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildConsultantCard(Map<String, dynamic> consultant) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final name = (consultant['name'] as String?) ?? 'Unknown';
    final isActive = consultant['status'] == 'active' || consultant['status'] == 'invited';
    final isCollaborator = consultant['is_collaborator'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showConsultantDetail(consultant),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accent.withOpacity(0.2), AppColors.accent.withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.success.withOpacity(0.1) : AppColors.neutral200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isActive ? AppColors.success : AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (consultant['company'] as String?) ?? (consultant['email'] as String?) ?? '',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Flexible(
                            child: _buildMiniInfo(Icons.build_outlined, (consultant['specialty'] as String?) ?? 'Consultant'),
                          ),
                          const SizedBox(width: 12),
                          if (consultant['rate'] != null)
                            Flexible(
                              child: _buildMiniInfo(
                                Icons.attach_money,
                                '${currencyFormat.format((consultant['rate'] as num?)?.toDouble() ?? 0)}/${consultant['rateType'] == 'hourly' ? 'hr' : 'project'}',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Actions
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.textTertiary, size: 18),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditConsultantModal(consultant);
                    } else if (value == 'delete') {
                      _deleteConsultant(consultant);
                    } else if (value == 'invite') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite sent to consultant')),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(fontSize: 13))),
                    const PopupMenuItem(value: 'invite', child: Text('Invite to Project', style: TextStyle(fontSize: 13))),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(fontSize: 13, color: AppColors.error))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ============ ADD CONSULTANT MODAL ============
class _AddConsultantModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onConsultantAdded;
  
  const _AddConsultantModal({required this.onConsultantAdded});

  @override
  State<_AddConsultantModal> createState() => _AddConsultantModalState();
}

class _AddConsultantModalState extends State<_AddConsultantModal> {
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _rateController = TextEditingController();
  String _rateType = 'hourly';
  
  final List<String> _specialties = [
    'Landscape Architecture',
    'Structural Engineering',
    'Civil Engineering',
    'Interior Design',
    'MEP Engineering',
    'Project Management',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter consultant name'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email address'), backgroundColor: AppColors.error),
      );
      return;
    }

    final rateText = _rateController.text.replaceAll(RegExp(r'[^\d.]'), '');
    final rate = double.tryParse(rateText) ?? 0.0;

    final newConsultant = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _nameController.text.trim(),
      'company': _companyController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'specialty': _specialtyController.text.isEmpty ? 'Other' : _specialtyController.text.trim(),
      'rate': rate,
      'rateType': _rateType,
      'status': 'active',
      'projects': 0,
      'totalBilled': 0.0,
      'created': DateTime.now(),
    };

    widget.onConsultantAdded(newConsultant);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Consultant added successfully!'), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Add Consultant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Add a sub-consultant to collaborate on projects', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              
              // Contact Information Section
              _buildSectionHeader('Contact Information'),
              const SizedBox(height: 12),
              _buildTextField('Full Name *', 'Enter consultant name', _nameController),
              const SizedBox(height: 12),
              _buildTextField('Company', 'Company or firm name', _companyController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Email *', 'email@example.com', _emailController, TextInputType.emailAddress)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Phone', '+1 (555) 000-0000', _phoneController, TextInputType.phone)),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Professional Details Section
              _buildSectionHeader('Professional Details'),
              const SizedBox(height: 12),
              _buildSpecialtyDropdown(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Rate', '\$0.00', _rateController, TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildRateTypeDropdown()),
                ],
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Add Consultant'),
                ),
              ),
            ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, [TextInputType? keyboardType]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: true,
          enableInteractiveSelection: true,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.neutral50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.accent, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialtyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Specialty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return _specialties;
            }
            return _specialties.where((option) =>
              option.toLowerCase().contains(textEditingValue.text.toLowerCase())
            );
          },
          onSelected: (String selection) {
            setState(() {
              _specialtyController.text = selection;
            });
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            // Sync the autocomplete controller with our specialty controller
            if (_specialtyController.text.isNotEmpty && textEditingController.text.isEmpty) {
              textEditingController.text = _specialtyController.text;
            }
            textEditingController.addListener(() {
              if (textEditingController.text != _specialtyController.text) {
                setState(() {
                  _specialtyController.text = textEditingController.text;
                });
              }
            });
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              enabled: true,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Select or type specialty',
                filled: true,
                fillColor: AppColors.neutral50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.accent, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRateTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rate Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
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
              value: _rateType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'hourly', child: Text('Per Hour')),
                DropdownMenuItem(value: 'project', child: Text('Per Project')),
                DropdownMenuItem(value: 'day', child: Text('Per Day')),
              ],
              onChanged: (val) => setState(() => _rateType = val ?? 'hourly'),
            ),
          ),
        ),
      ],
    );
  }
}

// ============ EDIT CONSULTANT MODAL ============
class _EditConsultantModal extends StatefulWidget {
  final Map<String, dynamic> consultant;
  final Function(Map<String, dynamic>) onConsultantUpdated;
  
  const _EditConsultantModal({required this.consultant, required this.onConsultantUpdated});

  @override
  State<_EditConsultantModal> createState() => _EditConsultantModalState();
}

class _EditConsultantModalState extends State<_EditConsultantModal> {
  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _specialtyController;
  late TextEditingController _rateController;
  late String _rateType;
  late String _status;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.consultant['name']);
    _companyController = TextEditingController(text: widget.consultant['company']);
    _emailController = TextEditingController(text: widget.consultant['email']);
    _phoneController = TextEditingController(text: widget.consultant['phone'] ?? '');
    _specialtyController = TextEditingController(text: widget.consultant['specialty']);
    _rateController = TextEditingController(text: widget.consultant['rate'].toString());
    _rateType = widget.consultant['rateType'] ?? 'hourly';
    _status = widget.consultant['status'] ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter consultant name'), backgroundColor: AppColors.error),
      );
      return;
    }

    final rateText = _rateController.text.replaceAll(RegExp(r'[^\d.]'), '');
    final rate = double.tryParse(rateText) ?? 0.0;

    final updatedConsultant = {
      ...widget.consultant,
      'name': _nameController.text.trim(),
      'company': _companyController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'specialty': _specialtyController.text.trim(),
      'rate': rate,
      'rateType': _rateType,
      'status': _status,
    };

    widget.onConsultantUpdated(updatedConsultant);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Consultant updated successfully!'), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Consultant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              _buildTextField('Full Name *', 'Enter consultant name', _nameController),
              const SizedBox(height: 12),
              _buildTextField('Company', 'Company or firm name', _companyController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Email *', 'email@example.com', _emailController, TextInputType.emailAddress)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Phone', '+1 (555) 000-0000', _phoneController, TextInputType.phone)),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField('Specialty', 'Enter specialty', _specialtyController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Rate', '\$0.00', _rateController, TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildRateTypeDropdown()),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatusDropdown(),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, [TextInputType? keyboardType]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.neutral50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.accent)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildRateTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rate Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
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
              value: _rateType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'hourly', child: Text('Per Hour')),
                DropdownMenuItem(value: 'project', child: Text('Per Project')),
                DropdownMenuItem(value: 'day', child: Text('Per Day')),
              ],
              onChanged: (val) => setState(() => _rateType = val ?? 'hourly'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
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
              value: _status,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (val) => setState(() => _status = val ?? 'active'),
            ),
          ),
        ),
      ],
    );
  }
}

// ============ CONSULTANT DETAIL MODAL ============
class _ConsultantDetailModal extends StatelessWidget {
  final Map<String, dynamic> consultant;
  final VoidCallback onEdit;
  
  const _ConsultantDetailModal({required this.consultant, required this.onEdit});

  // Helper to safely get name
  String get _name => (consultant['name'] as String?) ?? 'Unknown';
  String get _company => (consultant['company'] as String?) ?? '';
  String get _specialty => (consultant['specialty'] as String?) ?? 'Consultant';
  String get _email => (consultant['email'] as String?) ?? '';
  String get _phone => (consultant['phone'] as String?) ?? '';
  String get _status => (consultant['status'] as String?) ?? 'active';
  double get _rate => (consultant['rate'] as num?)?.toDouble() ?? 0.0;
  String get _rateType => (consultant['rateType'] as String?) ?? 'hourly';
  int get _projects => (consultant['projects'] as int?) ?? 0;
  double get _totalBilled => (consultant['totalBilled'] as num?)?.toDouble() ?? 0.0;
  
  DateTime? get _createdDate {
    final created = consultant['created'] ?? consultant['created_at'];
    if (created == null) return null;
    if (created is DateTime) return created;
    if (created is String) return DateTime.tryParse(created);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('MMM d, yyyy');
    final isActive = _status == 'active' || _status == 'invited';
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accent.withOpacity(0.2), AppColors.accent.withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 26,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive 
                                ? AppColors.success.withOpacity(0.1) 
                                : AppColors.neutral200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isActive ? AppColors.success : AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_company.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _company,
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _specialty,
                        style: TextStyle(fontSize: 12, color: AppColors.accent),
                      ),
                    ],
                  ),
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
                // Contact Info
                _buildSection('Contact', [
                  if (_email.isNotEmpty)
                    _buildInfoRow(Icons.email_outlined, _email),
                  if (_phone.isNotEmpty)
                    _buildInfoRow(Icons.phone_outlined, _phone),
                  if (_email.isEmpty && _phone.isEmpty)
                    _buildInfoRow(Icons.info_outline, 'No contact info available'),
                ]),
                
                const SizedBox(height: 20),
                
                // Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Rate',
                        _rate > 0 
                          ? '${currencyFormat.format(_rate)}/${_rateType == 'hourly' ? 'hr' : 'proj'}'
                          : 'N/A',
                        Icons.attach_money,
                        AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Projects',
                        '$_projects',
                        Icons.work_outline,
                        AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Total Billed',
                        currencyFormat.format(_totalBilled),
                        Icons.receipt_long_outlined,
                        AppColors.success,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Additional Info
                if (_createdDate != null)
                  _buildSection('Additional Info', [
                    _buildInfoRow(Icons.calendar_today_outlined, 'Added ${dateFormat.format(_createdDate!)}'),
                  ]),
                
                const SizedBox(height: 24),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invitation sent to consultant')),
                          );
                        },
                        icon: const Icon(Icons.send_outlined, size: 18),
                        label: const Text('Invite'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
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

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}


// ============================================================================
// RECEIVED INVITATIONS TAB - Shows invitations received from other companies
// ============================================================================
class _ReceivedInvitationsTab extends StatelessWidget {
  const _ReceivedInvitationsTab();

  @override
  Widget build(BuildContext context) {
    final salesProvider = context.watch<SalesProvider>();
    final invitations = salesProvider.receivedInvitations;

    if (salesProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (invitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 40,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No invitations yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When someone invites you to collaborate\non a proposal, it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => salesProvider.loadAll(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: invitations.length,
        itemBuilder: (context, index) {
          final invitation = invitations[index];
          return _InvitationCard(invitation: invitation);
        },
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  final Map<String, dynamic> invitation;

  const _InvitationCard({required this.invitation});

  @override
  Widget build(BuildContext context) {
    final status = invitation['status'] as String? ?? 'invited';
    final projectName = invitation['project_name'] as String? ?? 'Collaboration Request';
    final companyName = invitation['company_name'] ?? 
        (invitation['companies'] as Map<String, dynamic>?)?['name'] ?? 
        invitation['owner_name'] ?? 
        'Unknown Company';
    final createdAt = invitation['created_at'] != null 
        ? DateTime.tryParse(invitation['created_at'].toString())
        : null;
    final deadline = invitation['deadline'] != null 
        ? DateTime.tryParse(invitation['deadline'].toString())
        : null;
    final notes = invitation['notes'] as String?;
    
    // New rich data from updated query
    final quotes = invitation['quotes'] as Map<String, dynamic>?;
    final projects = invitation['projects'] as Map<String, dynamic>?;
    final scope = quotes?['scope'] as String? ?? projects?['description'] as String?;
    final quoteItems = quotes?['quote_items'] as List<dynamic>? ?? [];
    final fileAttachments = invitation['file_attachments'] as List<dynamic>? ?? [];
    final shareClientInfo = invitation['share_client_info'] as bool? ?? false;
    final paymentOption = invitation['payment_option'] as String?;
    
    // Client info (only shown if share_client_info is true)
    final clientsData = invitation['clients'] as Map<String, dynamic>?;
    final clientInfo = clientsData?['clients'] as Map<String, dynamic>?;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'invited':
        statusColor = Colors.orange;
        statusLabel = 'Action Required';
        statusIcon = Icons.notifications_active;
        break;
      case 'viewed':
        statusColor = Colors.blue;
        statusLabel = 'Viewed';
        statusIcon = Icons.visibility;
        break;
      case 'in_progress':
        statusColor = Colors.purple;
        statusLabel = 'In Progress';
        statusIcon = Icons.edit;
        break;
      case 'submitted':
        statusColor = Colors.teal;
        statusLabel = 'Submitted';
        statusIcon = Icons.send;
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusLabel = 'Accepted';
        statusIcon = Icons.check_circle;
        break;
      case 'revision_requested':
        statusColor = Colors.amber;
        statusLabel = 'Revision Requested';
        statusIcon = Icons.replay;
        break;
      case 'locked':
        statusColor = Colors.grey;
        statusLabel = 'Locked';
        statusIcon = Icons.lock;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status;
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // TODO: Navigate to invitation detail / response page
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening $projectName...'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Status badge and date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (createdAt != null)
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Project name
                Text(
                  projectName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),

                // Company name
                Row(
                  children: [
                    Icon(Icons.business, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'From: $companyName',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                // Deadline if exists
                if (deadline != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: deadline.isBefore(DateTime.now().add(const Duration(days: 3)))
                            ? Colors.red
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Due: ${_formatDate(deadline)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: deadline.isBefore(DateTime.now().add(const Duration(days: 3)))
                              ? Colors.red
                              : AppColors.textSecondary,
                          fontWeight: deadline.isBefore(DateTime.now().add(const Duration(days: 3)))
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],

                // Notes if exists
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notes,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Scope/Description
                if (scope != null && scope.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description_outlined, size: 16, color: AppColors.accent),
                            const SizedBox(width: 8),
                            Text(
                              'Scope of Work',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          scope,
                          style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],

                // Quote Line Items
                if (quoteItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.list_alt, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              'Line Items (${quoteItems.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...quoteItems.take(3).map((item) {
                          final itemMap = item as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(Icons.circle, size: 6, color: AppColors.textTertiary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    itemMap['description'] ?? itemMap['name'] ?? 'Item',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (quoteItems.length > 3)
                          Text(
                            '+${quoteItems.length - 3} more items',
                            style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                          ),
                      ],
                    ),
                  ),
                ],

                // File Attachments
                if (fileAttachments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: fileAttachments.take(3).map((attachment) {
                      final attachmentMap = attachment is Map ? attachment as Map<String, dynamic> : {'name': attachment.toString()};
                      final fileName = attachmentMap['name'] ?? 'File';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_file, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              fileName.toString().length > 20 ? '${fileName.toString().substring(0, 20)}...' : fileName.toString(),
                              style: TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Client Info (if shared)
                if (shareClientInfo && clientInfo != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'Client Information',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (clientInfo['primary_name'] != null || clientInfo['company_name'] != null)
                          Text(
                            clientInfo['company_name'] ?? clientInfo['primary_name'] ?? '',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                          ),
                        if (clientInfo['email'] != null)
                          Text(
                            clientInfo['email'],
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ],

                // Payment option badge
                if (paymentOption != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: paymentOption == 'direct' ? Colors.green.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      paymentOption == 'direct' ? 'Direct Payment to You' : 'Anonymous (Owner Pays)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: paymentOption == 'direct' ? Colors.green : Colors.purple,
                      ),
                    ),
                  ),
                ],

                // Action button for pending invitations
                if (status == 'invited' || status == 'viewed' || status == 'in_progress') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to respond page
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening response form...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: Text(status == 'in_progress' ? 'Continue Response' : 'Submit Your Pricing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}
