import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../main.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Track expanded financial sections
  String? _expandedFinancialSection;

  // Mock project data
  final Map<String, dynamic> _project = {
    'id': 'p8',
    'name': 'SAGECREST',
    'description': 'TSM Map - TENTATIVE SUBDIVISION MAP',
    'status': 'active',
    'category': 'Other',
    'budget': 2000.0,
    'startDate': DateTime(2025, 12, 31),
    'endDate': null,
    'totalHours': 30.5,
    'tasksCompleted': 1,
    'tasksTotal': 2,
    'amountInvoiced': 1500.0,
    'laborCost': 4275.0, // 28.5h * $150
    'laborRate': 150.0,
    'expenses': 0.0,
    'collected': 0.0,
    'client': {
      'name': 'Sequoia Consulting',
      'website': 'https://seqhq.com',
      'email': 'stevenm@seqhq.com',
      'phone': '5594719215',
      'address': '131 E. Kern Ave., Tulare, Ca 93274',
      'contacts': [
        {'type': 'Primary Contact', 'name': 'Steven Macias', 'role': 'Principal', 'email': 'stevenm@seqhq.com', 'phone': '5597860936'},
        {'type': 'Billing Contact', 'name': 'Danielle Macias', 'role': 'Business Management', 'email': 'danielle@seqhq.com', 'phone': '5597860937'},
      ],
    },
    'tasks': [
      {
        'id': 't1', 
        'name': 'Revisions - CD Plans revesions', 
        'status': 'todo', 
        'assignee': 'Baris Rahimi', 
        'estimatedHours': 10.0, 
        'loggedHours': 0.0,
        'amount': 500.0, 
        'percentBilled': 0,
        'type': 'proposal', // from proposal line item
        'subtasks': [
          {'id': 'st1', 'name': 'Review existing plans', 'status': 'done', 'hours': 2.0},
          {'id': 'st2', 'name': 'Draft revision notes', 'status': 'todo', 'hours': 0.0},
        ],
      },
      {
        'id': 't2', 
        'name': 'TSM Map - TENTATIVE SUBDIVISION MAP', 
        'status': 'done', 
        'assignee': 'Baris Rahimi', 
        'estimatedHours': 30.0,
        'loggedHours': 28.5,
        'amount': 1500.0, 
        'percentBilled': 100,
        'type': 'proposal',
        'subtasks': [
          {'id': 'st3', 'name': 'Site analysis', 'status': 'done', 'hours': 8.0},
          {'id': 'st4', 'name': 'Initial draft', 'status': 'done', 'hours': 12.0},
          {'id': 'st5', 'name': 'Client review', 'status': 'done', 'hours': 4.0},
          {'id': 'st6', 'name': 'Final submission', 'status': 'done', 'hours': 4.5},
        ],
      },
    ],
    'invoices': [
      {'id': 'inv1', 'number': 'INV-542754', 'date': DateTime(2026, 1, 10), 'amount': 1500.0, 'status': 'draft', 'dueDate': DateTime(2026, 2, 10)},
    ],
    'timeEntries': [
      {'id': 'te1', 'date': DateTime(2026, 1, 5), 'task': 'TSM Map - TENTATIVE SUBDIVISION MAP', 'subtask': 'Site analysis', 'user': 'Baris Rahimi', 'hours': 8.0, 'rate': 150.0, 'billable': true},
      {'id': 'te2', 'date': DateTime(2026, 1, 6), 'task': 'TSM Map - TENTATIVE SUBDIVISION MAP', 'subtask': 'Initial draft', 'user': 'Baris Rahimi', 'hours': 6.0, 'rate': 150.0, 'billable': true},
      {'id': 'te3', 'date': DateTime(2026, 1, 7), 'task': 'TSM Map - TENTATIVE SUBDIVISION MAP', 'subtask': 'Initial draft', 'user': 'Baris Rahimi', 'hours': 6.0, 'rate': 150.0, 'billable': true},
      {'id': 'te4', 'date': DateTime(2026, 1, 8), 'task': 'TSM Map - TENTATIVE SUBDIVISION MAP', 'subtask': 'Client review', 'user': 'Baris Rahimi', 'hours': 4.0, 'rate': 150.0, 'billable': true},
      {'id': 'te5', 'date': DateTime(2026, 1, 9), 'task': 'TSM Map - TENTATIVE SUBDIVISION MAP', 'subtask': 'Final submission', 'user': 'Baris Rahimi', 'hours': 4.5, 'rate': 150.0, 'billable': true},
      {'id': 'te6', 'date': DateTime(2026, 1, 15), 'task': 'Revisions - CD Plans revesions', 'subtask': 'Review existing plans', 'user': 'Baris Rahimi', 'hours': 2.0, 'rate': 150.0, 'billable': true},
    ],
    'expenseEntries': <Map<String, dynamic>>[
      // Empty for now
    ],
    'payments': <Map<String, dynamic>>[
      // Empty for now
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Tabs
            _buildTabBar(),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVitalsTab(),
                  _buildClientTab(),
                  _buildDetailsTab(),
                  _buildTasksTab(),
                  _buildFinancialsTab(),
                  _buildBillingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _project['name'],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                Text(
                  _project['client']['name'],
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.more_vert, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _project['status'],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppColors.accent,
        indicatorWeight: 2,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Vitals'),
          Tab(text: 'Client'),
          Tab(text: 'Details'),
          Tab(text: 'Tasks'),
          Tab(text: 'Financials'),
          Tab(text: 'Billing'),
        ],
      ),
    );
  }

  // ============ VITALS TAB ============
  Widget _buildVitalsTab() {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('M/d/yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  Icons.schedule,
                  'Total Hours',
                  '${_project['totalHours'].toStringAsFixed(1)}h',
                  onTap: () {
                    // Navigate to Financials tab and expand Labor Cost
                    _tabController.animateTo(4); // Financials is index 4
                    Future.delayed(const Duration(milliseconds: 300), () {
                      setState(() {
                        _expandedFinancialSection = 'labor';
                      });
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  Icons.attach_money,
                  'Project Budget',
                  currencyFormat.format(_project['budget']),
                  onTap: () {
                    // Navigate to Tasks tab
                    _tabController.animateTo(3);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCardWithProgress(
                  Icons.check_box_outlined,
                  'Tasks Completed',
                  '${_project['tasksCompleted']}/${_project['tasksTotal']}',
                  _project['tasksCompleted'] / _project['tasksTotal'],
                  onTap: () {
                    // Navigate to Tasks tab
                    _tabController.animateTo(3);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  Icons.description_outlined,
                  'Amount Invoiced',
                  currencyFormat.format(_project['amountInvoiced']),
                  onTap: () {
                    // Navigate to Billing tab
                    _tabController.animateTo(5);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Project Details Card
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Project Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('Edit', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildDetailItem('Budget', currencyFormat.format(_project['budget']))),
                    Expanded(child: _buildDetailItem('Start Date', dateFormat.format(_project['startDate']))),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildDetailItem('End Date', _project['endDate'] != null ? dateFormat.format(_project['endDate']) : '-')),
                    Expanded(child: _buildDetailItem('Status', _project['status'][0].toUpperCase() + _project['status'].substring(1))),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailItem('Description', _project['description']),
                const SizedBox(height: 16),
                _buildDetailItem('Client', _project['client']['name']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.sm,
          border: onTap != null ? Border.all(color: AppColors.border.withOpacity(0.5)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.accent, size: 18),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
              ],
            ),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardWithProgress(IconData icon, String label, String value, double progress, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.sm,
          border: onTap != null ? Border.all(color: AppColors.border.withOpacity(0.5)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.accent, size: 18),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
              ],
            ),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.neutral200,
              valueColor: AlwaysStoppedAnimation(AppColors.accent),
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ============ CLIENT TAB ============
  Widget _buildClientTab() {
    final client = _project['client'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Client Information Card
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Client Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.neutral50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(left: BorderSide(color: AppColors.accent, width: 3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Company Information', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      _buildClientInfoRow('Company Name', client['name']),
                      _buildClientInfoRow('Website', client['website'], isLink: true),
                      _buildClientInfoRow('Email', client['email']),
                      _buildClientInfoRow('Phone', client['phone']),
                      _buildClientInfoRow('Address', client['address']),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Contacts Card
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
                const Text('Contacts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                ...((client['contacts'] as List).map((contact) => _buildContactItem(contact))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfoRow(String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isLink ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(Map<String, dynamic> contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.person_outline, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact['type'], style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(contact['name'], style: const TextStyle(fontSize: 14)),
                Text(contact['role'], style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(contact['email'], style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(contact['phone'], style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ DETAILS TAB ============
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Project Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Save Changes'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildFormField('Status', DropdownButtonFormField<String>(
              value: 'Active',
              decoration: const InputDecoration(),
              items: ['Active', 'On Hold', 'Completed', 'Cancelled'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (_) {},
            )),
            const SizedBox(height: 16),
            _buildFormField('Category', DropdownButtonFormField<String>(
              value: 'Other',
              decoration: const InputDecoration(),
              items: ['Other', 'Development', 'Design', 'Consulting'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (_) {},
            )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDateField('Start Date', DateTime(2026, 1, 1))),
                const SizedBox(width: 16),
                Expanded(child: _buildDateField('Due Date', DateTime(2026, 1, 15))),
              ],
            ),
            const SizedBox(height: 16),
            _buildFormField('Notes', TextField(
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add any notes about this project...',
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildDateField(String label, DateTime date) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateFormat.format(date)),
              const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }

  // ============ TASKS TAB ============
  // Track expanded tasks for showing subtasks
  final Set<String> _expandedTasks = {};

  Widget _buildTasksTab() {
    final tasks = _project['tasks'] as List<Map<String, dynamic>>;
    final todoCount = tasks.where((t) => t['status'] == 'todo').length;
    final inProgressCount = tasks.where((t) => t['status'] == 'in_progress').length;
    final doneCount = tasks.where((t) => t['status'] == 'done').length;
    final progress = tasks.isEmpty ? 0.0 : doneCount / tasks.length;
    
    // Calculate total hours
    double totalEstimated = 0;
    double totalLogged = 0;
    for (var task in tasks) {
      totalEstimated += (task['estimatedHours'] as double?) ?? 0;
      totalLogged += (task['loggedHours'] as double?) ?? 0;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              children: [
                // Task Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTaskStatCompact('To Do', todoCount, AppColors.warning),
                    _buildTaskStatCompact('In Progress', inProgressCount, AppColors.info),
                    _buildTaskStatCompact('Done', doneCount, AppColors.success),
                    _buildTaskStatCompact('Total', tasks.length, AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 14),
                // Progress Bar
                Row(
                  children: [
                    Text('Progress', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.neutral200,
                          valueColor: AlwaysStoppedAnimation(AppColors.accent),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                // Hours Row
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text('${totalLogged.toStringAsFixed(1)}h logged', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text(' / ${totalEstimated.toStringAsFixed(0)}h estimated', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tasks List Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tasks', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      SizedBox(
                        height: 32,
                        child: TextButton.icon(
                          onPressed: () => _showAddTaskModal(),
                          icon: Icon(Icons.add, size: 16, color: AppColors.accent),
                          label: Text('Add', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                
                // Tasks List
                if (tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.task_alt, size: 40, color: AppColors.textTertiary),
                        const SizedBox(height: 12),
                        Text('No tasks yet', style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _showAddTaskModal(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Task', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) => _buildTaskItemWithSubtasks(tasks[index]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatCompact(String label, int value, Color color) {
    return Column(
      children: [
        Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildTaskItemWithSubtasks(Map<String, dynamic> task) {
    final isDone = task['status'] == 'done';
    final isExpanded = _expandedTasks.contains(task['id']);
    final subtasks = (task['subtasks'] as List<Map<String, dynamic>>?) ?? [];
    final isFromProposal = task['type'] == 'proposal';
    final loggedHours = (task['loggedHours'] as double?) ?? 0;
    final estimatedHours = (task['estimatedHours'] as double?) ?? 0;
    final subtasksDone = subtasks.where((s) => s['status'] == 'done').length;
    
    return Column(
      children: [
        // Main Task Row
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedTasks.remove(task['id']);
              } else {
                _expandedTasks.add(task['id']);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () => _toggleTaskStatus(task),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isDone ? AppColors.accent : AppColors.border, width: 2),
                    ),
                    child: isDone ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                  ),
                ),
                const SizedBox(width: 10),
                
                // Task Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task['name'],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                                color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFromProposal)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Proposal', style: TextStyle(fontSize: 9, color: AppColors.accent)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTaskStatusColor(task['status']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getTaskStatusLabel(task['status']),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _getTaskStatusColor(task['status'])),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Hours
                          Icon(Icons.schedule, size: 12, color: AppColors.textTertiary),
                          const SizedBox(width: 3),
                          Text('${loggedHours.toStringAsFixed(1)}/${estimatedHours.toStringAsFixed(0)}h', 
                            style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          // Subtasks count
                          if (subtasks.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.checklist, size: 12, color: AppColors.textTertiary),
                            const SizedBox(width: 3),
                            Text('$subtasksDone/${subtasks.length}', 
                              style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Expand/Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (subtasks.isNotEmpty || isFromProposal)
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 18, color: AppColors.textTertiary),
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'subtask') _showAddSubtaskModal(task);
                        else if (value == 'time') _showLogTimeModal(task);
                        else if (value == 'edit') _showEditTaskModal(task);
                        else if (value == 'delete') _deleteTask(task);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'subtask', child: Text('Add Subtask', style: TextStyle(fontSize: 13))),
                        const PopupMenuItem(value: 'time', child: Text('Log Time', style: TextStyle(fontSize: 13))),
                        const PopupMenuItem(value: 'edit', child: Text('Edit Task', style: TextStyle(fontSize: 13))),
                        if (task['type'] != 'proposal')
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(fontSize: 13, color: AppColors.error))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Subtasks (when expanded)
        if (isExpanded && subtasks.isNotEmpty)
          Container(
            color: AppColors.neutral50,
            child: Column(
              children: [
                ...subtasks.map((subtask) => _buildSubtaskItem(task, subtask)),
                // Add subtask button
                InkWell(
                  onTap: () => _showAddSubtaskModal(task),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const SizedBox(width: 32),
                        Icon(Icons.add, size: 16, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text('Add subtask', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Add subtask prompt for proposal tasks without subtasks
        if (isExpanded && subtasks.isEmpty && isFromProposal)
          Container(
            color: AppColors.neutral50,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Break down this task', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      Text('Add subtasks to track time more granularly', 
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showAddSubtaskModal(task),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add Subtask', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubtaskItem(Map<String, dynamic> parentTask, Map<String, dynamic> subtask) {
    final isDone = subtask['status'] == 'done';
    final hours = (subtask['hours'] as double?) ?? 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 32), // Indent
          // Checkbox
          GestureDetector(
            onTap: () => _toggleSubtaskStatus(parentTask, subtask),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isDone ? AppColors.success : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: isDone ? AppColors.success : AppColors.border, width: 1.5),
              ),
              child: isDone ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              subtask['name'],
              style: TextStyle(
                fontSize: 12,
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
          ),
          if (hours > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('${hours.toStringAsFixed(1)}h', style: TextStyle(fontSize: 10, color: AppColors.info)),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showLogTimeForSubtask(parentTask, subtask),
            child: Icon(Icons.timer_outlined, size: 16, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Color _getTaskStatusColor(String status) {
    switch (status) {
      case 'done': return AppColors.success;
      case 'in_progress': return AppColors.info;
      case 'todo': return AppColors.warning;
      default: return AppColors.textSecondary;
    }
  }

  String _getTaskStatusLabel(String status) {
    switch (status) {
      case 'done': return 'Done';
      case 'in_progress': return 'In Progress';
      case 'todo': return 'To Do';
      default: return status;
    }
  }

  void _toggleTaskStatus(Map<String, dynamic> task) {
    setState(() {
      if (task['status'] == 'done') {
        task['status'] = 'todo';
      } else {
        task['status'] = 'done';
      }
      // Update project stats
      final tasks = _project['tasks'] as List<Map<String, dynamic>>;
      _project['tasksCompleted'] = tasks.where((t) => t['status'] == 'done').length;
    });
  }

  void _toggleSubtaskStatus(Map<String, dynamic> parentTask, Map<String, dynamic> subtask) {
    setState(() {
      subtask['status'] = subtask['status'] == 'done' ? 'todo' : 'done';
    });
  }

  void _showAddTaskModal() {
    final nameController = TextEditingController();
    final hoursController = TextEditingController();
    String selectedType = 'custom';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Add Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Add a custom task or T&M work', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              
              // Task Type
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => selectedType = 'custom'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selectedType == 'custom' ? AppColors.accent.withOpacity(0.1) : AppColors.neutral50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: selectedType == 'custom' ? AppColors.accent : AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.task_alt, color: selectedType == 'custom' ? AppColors.accent : AppColors.textSecondary),
                            const SizedBox(height: 4),
                            Text('Custom Task', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: selectedType == 'custom' ? AppColors.accent : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => selectedType = 'tnm'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selectedType == 'tnm' ? AppColors.info.withOpacity(0.1) : AppColors.neutral50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: selectedType == 'tnm' ? AppColors.info : AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.schedule, color: selectedType == 'tnm' ? AppColors.info : AppColors.textSecondary),
                            const SizedBox(height: 4),
                            Text('T&M (Extra)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: selectedType == 'tnm' ? AppColors.info : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Name
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Task Name',
                  hintText: 'Enter task name',
                  filled: true,
                  fillColor: AppColors.neutral50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              
              // Hours
              TextField(
                controller: hoursController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Estimated Hours',
                  hintText: '0',
                  filled: true,
                  fillColor: AppColors.neutral50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      setState(() {
                        (_project['tasks'] as List<Map<String, dynamic>>).add({
                          'id': 't${DateTime.now().millisecondsSinceEpoch}',
                          'name': nameController.text.trim(),
                          'status': 'todo',
                          'assignee': 'Unassigned',
                          'estimatedHours': double.tryParse(hoursController.text) ?? 0,
                          'loggedHours': 0.0,
                          'amount': 0.0,
                          'percentBilled': 0,
                          'type': selectedType,
                          'subtasks': <Map<String, dynamic>>[],
                        });
                        _project['tasksTotal'] = (_project['tasks'] as List).length;
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSubtaskModal(Map<String, dynamic> parentTask) {
    final nameController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Add Subtask', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('For: ${parentTask['name']}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 20),
            
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Subtask Name',
                hintText: 'What needs to be done?',
                filled: true,
                fillColor: AppColors.neutral50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    setState(() {
                      (parentTask['subtasks'] as List<Map<String, dynamic>>).add({
                        'id': 'st${DateTime.now().millisecondsSinceEpoch}',
                        'name': nameController.text.trim(),
                        'status': 'todo',
                        'hours': 0.0,
                      });
                      _expandedTasks.add(parentTask['id']);
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Subtask'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogTimeModal(Map<String, dynamic> task) {
    final hoursController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Log Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('For: ${task['name']}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 20),
            
            TextField(
              controller: hoursController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Hours',
                hintText: 'Enter hours to log',
                filled: true,
                fillColor: AppColors.neutral50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final hours = double.tryParse(hoursController.text) ?? 0;
                  if (hours > 0) {
                    setState(() {
                      task['loggedHours'] = ((task['loggedHours'] as double?) ?? 0) + hours;
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Log Time'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogTimeForSubtask(Map<String, dynamic> parentTask, Map<String, dynamic> subtask) {
    final hoursController = TextEditingController(text: subtask['hours'].toString());
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Log Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Subtask: ${subtask['name']}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 20),
            
            TextField(
              controller: hoursController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Hours',
                hintText: 'Enter hours',
                filled: true,
                fillColor: AppColors.neutral50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final hours = double.tryParse(hoursController.text) ?? 0;
                  setState(() {
                    final oldHours = (subtask['hours'] as double?) ?? 0;
                    subtask['hours'] = hours;
                    // Update parent task logged hours
                    parentTask['loggedHours'] = ((parentTask['loggedHours'] as double?) ?? 0) - oldHours + hours;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save Time'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTaskModal(Map<String, dynamic> task) {
    final nameController = TextEditingController(text: task['name']);
    final hoursController = TextEditingController(text: task['estimatedHours'].toString());
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Edit Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Task Name',
                filled: true,
                fillColor: AppColors.neutral50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: hoursController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Estimated Hours',
                filled: true,
                fillColor: AppColors.neutral50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    task['name'] = nameController.text.trim();
                    task['estimatedHours'] = double.tryParse(hoursController.text) ?? task['estimatedHours'];
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTask(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Task?'),
        content: Text('Are you sure you want to delete "${task['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                (_project['tasks'] as List).removeWhere((t) => t['id'] == task['id']);
                _project['tasksTotal'] = (_project['tasks'] as List).length;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ============ FINANCIALS TAB ============
  Widget _buildFinancialsTab() {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final timeEntries = _project['timeEntries'] as List<Map<String, dynamic>>;
    final expenses = _project['expenseEntries'] as List<Map<String, dynamic>>;
    final invoices = _project['invoices'] as List<Map<String, dynamic>>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Financial Stats Grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildFinancialCard('Budget', currencyFormat.format(_project['budget']), null, sectionKey: 'budget')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildFinancialCard('Labor Cost', currencyFormat.format(_project['laborCost']), '${_project['totalHours'].toStringAsFixed(1)}h @ \$${_project['laborRate'].toInt()}/hr', sectionKey: 'labor')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildFinancialCard('Expenses', currencyFormat.format(_project['expenses']), '${expenses.length} expenses', sectionKey: 'expenses')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildFinancialCard('Invoiced', currencyFormat.format(_project['amountInvoiced']), null, valueColor: AppColors.success, sectionKey: 'invoiced')),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFinancialCard('Collected', currencyFormat.format(_project['collected']), null, sectionKey: 'collected'),
              ],
            ),
          ),
          
          // Expanded Budget Detail
          if (_expandedFinancialSection == 'budget') ...[
            const SizedBox(height: 16),
            _buildBudgetDetailInline(),
          ],
          
          // Expanded Labor Cost Detail
          if (_expandedFinancialSection == 'labor') ...[
            const SizedBox(height: 16),
            _buildLaborCostDetailInline(timeEntries),
          ],
          
          // Expanded Expenses Detail
          if (_expandedFinancialSection == 'expenses') ...[
            const SizedBox(height: 16),
            _buildExpensesDetailInline(expenses),
          ],
          
          // Expanded Invoiced Detail
          if (_expandedFinancialSection == 'invoiced') ...[
            const SizedBox(height: 16),
            _buildInvoicesDetailInline(invoices),
          ],
          
          // Expanded Collected Detail
          if (_expandedFinancialSection == 'collected') ...[
            const SizedBox(height: 16),
            _buildCollectedDetailInline(),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialCard(String label, String value, String? subtitle, {Color? valueColor, String? sectionKey}) {
    final isExpanded = _expandedFinancialSection == sectionKey;
    
    return InkWell(
      onTap: sectionKey != null ? () {
        setState(() {
          _expandedFinancialSection = isExpanded ? null : sectionKey;
        });
      } : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isExpanded ? AppColors.accent.withOpacity(0.05) : AppColors.neutral50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isExpanded ? AppColors.accent : AppColors.border.withOpacity(0.5),
            width: isExpanded ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: isExpanded ? AppColors.accent : AppColors.textSecondary, fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w400)),
                if (sectionKey != null)
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: isExpanded ? AppColors.accent : AppColors.textTertiary,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeEntryRow(Map<String, dynamic> entry) {
    final dateFormat = DateFormat('M/d/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final total = (entry['hours'] as double) * (entry['rate'] as double);
    
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry['task'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(entry['subtask'], style: TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry['hours']}h', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text(dateFormat.format(entry['date']), style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }

  // ============ INLINE FINANCIAL DETAILS ============
  
  Widget _buildBudgetDetailInline() {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final budget = _project['budget'] as double;
    final laborCost = _project['laborCost'] as double;
    final expenses = _project['expenses'] as double;
    final totalCost = laborCost + expenses;
    final remaining = budget - totalCost;
    final percentUsed = budget > 0 ? (totalCost / budget) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Budget Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text('${(percentUsed * 100).toStringAsFixed(0)}% used', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentUsed.clamp(0.0, 1.0),
              backgroundColor: AppColors.neutral200,
              valueColor: AlwaysStoppedAnimation(percentUsed > 0.9 ? AppColors.error : AppColors.accent),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          _buildBudgetRow('Labor Cost', laborCost, AppColors.info),
          _buildBudgetRow('Expenses', expenses, AppColors.warning),
          const Divider(height: 24),
          _buildBudgetRow('Total Cost', totalCost, AppColors.textPrimary, bold: true),
          _buildBudgetRow('Remaining', remaining, remaining >= 0 ? AppColors.success : AppColors.error, bold: true),
        ],
      ),
    );
  }

  Widget _buildLaborCostDetailInline(List<Map<String, dynamic>> timeEntries) {
    final dateFormat = DateFormat('M/d/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Time Entries', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${_project['totalHours']}h total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.info)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (timeEntries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No time entries yet', style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: timeEntries.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final entry = timeEntries[index];
                final total = (entry['hours'] as double) * (entry['rate'] as double);
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dateFormat.format(entry['date']), style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text(entry['user'], style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(entry['task'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(entry['subtask'], style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${entry['hours']}h @ ${currencyFormat.format(entry['rate'])}/hr', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                        Text(currencyFormat.format(total), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.info)),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildExpensesDetailInline(List<Map<String, dynamic>> expenses) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Expenses', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          
          if (expenses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 40, color: AppColors.textTertiary),
                    const SizedBox(height: 12),
                    Text('No expenses for this project', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInvoicesDetailInline(List<Map<String, dynamic>> invoices) {
    final dateFormat = DateFormat('M/d/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Invoices', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          
          if (invoices.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No invoices created', style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invoices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                final status = invoice['status'] as String;
                final statusColor = status == 'paid' ? AppColors.success : status == 'sent' ? AppColors.info : AppColors.warning;
                
                return InkWell(
                  onTap: () {
                    context.push('/invoices/${invoice['id']}');
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(invoice['number'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date', style: TextStyle(fontSize: 9, color: AppColors.textTertiary)),
                                Text(dateFormat.format(invoice['date']), style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Due', style: TextStyle(fontSize: 9, color: AppColors.textTertiary)),
                                Text(dateFormat.format(invoice['dueDate']), style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Amount', style: TextStyle(fontSize: 9, color: AppColors.textTertiary)),
                                Text(currencyFormat.format(invoice['amount']), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCollectedDetailInline() {
    final payments = _project['payments'] as List<Map<String, dynamic>>;
    final collected = _project['collected'] as double;
    final invoiced = _project['amountInvoiced'] as double;
    final outstanding = invoiced - collected;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.neutral50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Invoiced', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(currencyFormat.format(invoiced), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Collected', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(currencyFormat.format(collected), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Outstanding', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(currencyFormat.format(outstanding), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: outstanding > 0 ? AppColors.error : AppColors.success)),
                  ],
                ),
              ],
            ),
          ),
          
          if (payments.isEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.payments_outlined, size: 40, color: AppColors.textTertiary),
                    const SizedBox(height: 12),
                    Text('No payments received yet', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Detail Modal: Budget
  void _showBudgetDetail() {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final budget = _project['budget'] as double;
    final laborCost = _project['laborCost'] as double;
    final expenses = _project['expenses'] as double;
    final totalCost = laborCost + expenses;
    final remaining = budget - totalCost;
    final percentUsed = budget > 0 ? (totalCost / budget) : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Budget Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              
              // Budget Overview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.neutral50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Budget', style: TextStyle(color: AppColors.textSecondary)),
                        Text(currencyFormat.format(budget), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentUsed.clamp(0.0, 1.0),
                        backgroundColor: AppColors.neutral200,
                        valueColor: AlwaysStoppedAnimation(percentUsed > 0.9 ? AppColors.error : AppColors.accent),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${(percentUsed * 100).toStringAsFixed(0)}% used', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Breakdown
              const Text('Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _buildBudgetRow('Labor Cost', laborCost, AppColors.info),
              _buildBudgetRow('Expenses', expenses, AppColors.warning),
              const Divider(height: 24),
              _buildBudgetRow('Total Cost', totalCost, AppColors.textPrimary, bold: true),
              _buildBudgetRow('Remaining', remaining, remaining >= 0 ? AppColors.success : AppColors.error, bold: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetRow(String label, double amount, Color color, {bool bold = false}) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
          Text(currencyFormat.format(amount), style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color)),
        ],
      ),
    );
  }

  // Detail Modal: Labor Cost
  void _showLaborCostDetail() {
    final timeEntries = _project['timeEntries'] as List<Map<String, dynamic>>;
    final dateFormat = DateFormat('M/d/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Time Entries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${_project['totalHours']}h total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.info)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              if (timeEntries.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text('No time entries yet', style: TextStyle(color: AppColors.textSecondary))),
                )
              else
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: timeEntries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = timeEntries[index];
                      final total = (entry['hours'] as double) * (entry['rate'] as double);
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(dateFormat.format(entry['date']), style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Text(entry['user'], style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(entry['task'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            Text(entry['subtask'], style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${entry['hours']}h @ ${currencyFormat.format(entry['rate'])}/hr', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                Text(currencyFormat.format(total), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.info)),
                              ],
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
      ),
    );
  }

  // Detail Modal: Expenses
  void _showExpensesDetail() {
    final expenses = _project['expenseEntries'] as List<Map<String, dynamic>>;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              
              if (expenses.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 48, color: AppColors.textTertiary),
                        const SizedBox(height: 12),
                        Text('No expenses for this project', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Detail Modal: Invoices
  void _showInvoicesDetail() {
    final invoices = _project['invoices'] as List<Map<String, dynamic>>;
    final dateFormat = DateFormat('M/d/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Invoices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              
              if (invoices.isEmpty)
                Expanded(
                  child: Center(
                    child: Text('No invoices created', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: invoices.length,
                    separatorBuilder: (_, __) => const Divider(height: 20),
                    itemBuilder: (context, index) {
                      final invoice = invoices[index];
                      final status = invoice['status'] as String;
                      final statusColor = status == 'paid' ? AppColors.success : status == 'sent' ? AppColors.info : AppColors.warning;
                      
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/invoices/${invoice['id']}');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.neutral50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(invoice['number'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Date', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                                      Text(dateFormat.format(invoice['date']), style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Due', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                                      Text(dateFormat.format(invoice['dueDate']), style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Amount', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                                      Text(currencyFormat.format(invoice['amount']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Detail Modal: Collected
  void _showCollectedDetail() {
    final payments = _project['payments'] as List<Map<String, dynamic>>;
    final collected = _project['collected'] as double;
    final invoiced = _project['amountInvoiced'] as double;
    final outstanding = invoiced - collected;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Collected Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              
              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.neutral50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Invoiced', style: TextStyle(color: AppColors.textSecondary)),
                        Text(currencyFormat.format(invoiced), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Collected', style: TextStyle(color: AppColors.textSecondary)),
                        Text(currencyFormat.format(collected), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Outstanding', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        Text(currencyFormat.format(outstanding), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: outstanding > 0 ? AppColors.error : AppColors.success)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              if (payments.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payments_outlined, size: 48, color: AppColors.textTertiary),
                        const SizedBox(height: 12),
                        Text('No payments received yet', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ BILLING TAB ============
  Widget _buildBillingTab() {
    final invoices = _project['invoices'] as List<Map<String, dynamic>>;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('M/d/yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Billing History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ElevatedButton.icon(
                  onPressed: () => _showCreateInvoiceModal(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...invoices.map((invoice) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                title: Text(invoice['number'], style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(dateFormat.format(invoice['date']), style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(currencyFormat.format(invoice['amount']), style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.neutral100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            invoice['status'],
                            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showCreateInvoiceModal() {
    showDialog(
      context: context,
      builder: (context) => CreateInvoiceModal(project: _project),
    );
  }
}

// ============ CREATE INVOICE MODAL ============
class CreateInvoiceModal extends StatefulWidget {
  final Map<String, dynamic> project;

  const CreateInvoiceModal({super.key, required this.project});

  @override
  State<CreateInvoiceModal> createState() => _CreateInvoiceModalState();
}

class _CreateInvoiceModalState extends State<CreateInvoiceModal> {
  String _billingMethod = 'items'; // items, milestone, percentage
  final Set<String> _selectedItems = {};
  double _additionalAmount = 0.0;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  double get _selectedTotal {
    final tasks = widget.project['tasks'] as List<Map<String, dynamic>>;
    double total = 0;
    for (var task in tasks) {
      if (_selectedItems.contains(task['id'])) {
        if (_billingMethod == 'percentage') {
          total += (task['amount'] as double) * (1 - task['percentBilled'] / 100);
        } else {
          total += task['amount'] as double;
        }
      }
    }
    return total + _additionalAmount;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final tasks = widget.project['tasks'] as List<Map<String, dynamic>>;
    
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Create Invoice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(widget.project['name'], style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
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
                    // Billing Method
                    const Text('BILLING METHOD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildMethodButton('By Items', 'Select specific items', 'items'),
                        const SizedBox(width: 8),
                        _buildMethodButton('By Milestone', 'Bill full remaining', 'milestone'),
                        const SizedBox(width: 8),
                        _buildMethodButton('By Percentage', 'Bill % of budget', 'percentage'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Items
                    if (_billingMethod == 'items') ...[
                      _buildCheckboxItem(
                        'Project Budget (Fixed Fee)',
                        'Allocated project budget',
                        currencyFormat.format(widget.project['budget']),
                        'budget',
                      ),
                      const Divider(),
                    ],

                    // Tasks
                    _buildCheckboxItem(
                      'Tasks (${tasks.length})',
                      null,
                      currencyFormat.format(_selectedTotal - _additionalAmount) + ' selected',
                      null,
                      isHeader: true,
                    ),
                    ...tasks.map((task) => _buildTaskCheckboxItem(task, currencyFormat)),

                    const SizedBox(height: 16),
                    
                    // Additional Amount & Due Date
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ADDITIONAL AMOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              TextField(
                                decoration: InputDecoration(
                                  prefixText: '\$ ',
                                  hintText: '0.00',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _additionalAmount = double.tryParse(value) ?? 0;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DUE DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.neutral50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(DateFormat('MMM d, yyyy').format(_dueDate)),
                              ),
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
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(color: Colors.white70)),
                      Text(currencyFormat.format(_selectedTotal), style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(currencyFormat.format(_selectedTotal), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
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
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Create Invoice'),
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

  Widget _buildMethodButton(String title, String subtitle, String method) {
    final isSelected = _billingMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _billingMethod = method),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.neutral50 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.accent : AppColors.border),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.accent : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxItem(String title, String? subtitle, String value, String? id, {bool isHeader = false}) {
    final isSelected = id != null && _selectedItems.contains(id);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: id != null
          ? Checkbox(
              value: isSelected,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedItems.add(id);
                  } else {
                    _selectedItems.remove(id);
                  }
                });
              },
              activeColor: AppColors.accent,
            )
          : const SizedBox(width: 24),
      title: Text(title, style: TextStyle(fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)) : null,
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildTaskCheckboxItem(Map<String, dynamic> task, NumberFormat currencyFormat) {
    final isSelected = _selectedItems.contains(task['id']);
    final percentBilled = task['percentBilled'] as int;
    final remaining = (task['amount'] as double) * (1 - percentBilled / 100);

    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Checkbox(
          value: isSelected,
          onChanged: remaining > 0 ? (val) {
            setState(() {
              if (val == true) {
                _selectedItems.add(task['id']);
              } else {
                _selectedItems.remove(task['id']);
              }
            });
          } : null,
          activeColor: AppColors.accent,
        ),
        title: Text(
          task['name'],
          style: TextStyle(
            fontSize: 13,
            color: remaining > 0 ? AppColors.textPrimary : AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${task['estimatedHours']}h estimated${percentBilled > 0 ? ' • ${percentBilled}% billed' : ''}',
          style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_billingMethod == 'percentage') ...[
              Text('Prior', style: TextStyle(fontSize: 9, color: AppColors.textTertiary)),
              Text(currencyFormat.format(task['amount'] * percentBilled / 100), style: const TextStyle(fontSize: 12)),
              Text('${percentBilled}%', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
            ] else ...[
              Text(currencyFormat.format(remaining), style: const TextStyle(fontWeight: FontWeight.w500)),
              if (remaining == 0)
                Text('0% left', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
            ],
          ],
        ),
      ),
    );
  }
}
