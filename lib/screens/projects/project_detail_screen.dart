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
    'totalHours': 0.0,
    'tasksCompleted': 1,
    'tasksTotal': 2,
    'amountInvoiced': 1500.0,
    'laborCost': 0.0,
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
      {'id': 't1', 'name': 'Revisions - CD Plans revesions', 'status': 'todo', 'assignee': 'Baris Rahimi', 'estimatedHours': 10.0, 'amount': 500.0, 'percentBilled': 0},
      {'id': 't2', 'name': 'TSM Map - TENTATIVE SUBDIVISION MAP', 'status': 'done', 'assignee': 'Baris Rahimi', 'estimatedHours': 30.0, 'amount': 1500.0, 'percentBilled': 100},
    ],
    'invoices': [
      {'id': 'inv1', 'number': 'INV-542754', 'date': DateTime(2026, 1, 10), 'amount': 1500.0, 'status': 'draft'},
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
              Expanded(child: _buildStatCard(Icons.schedule, 'Total Hours', '${_project['totalHours'].toInt()}h')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(Icons.attach_money, 'Project Budget', currencyFormat.format(_project['budget']))),
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
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(Icons.description_outlined, 'Amount Invoiced', currencyFormat.format(_project['amountInvoiced']))),
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

  Widget _buildStatCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 12),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildStatCardWithProgress(IconData icon, String label, String value, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
  Widget _buildTasksTab() {
    final tasks = _project['tasks'] as List<Map<String, dynamic>>;
    final todoCount = tasks.where((t) => t['status'] == 'todo').length;
    final inProgressCount = tasks.where((t) => t['status'] == 'in_progress').length;
    final doneCount = tasks.where((t) => t['status'] == 'done').length;
    final progress = doneCount / tasks.length;

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
            // Tab Toggle
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  _buildTaskTabButton('Overview', true),
                  _buildTaskTabButton('Editor', false),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Task Stats
            Row(
              children: [
                _buildTaskStat('To Do:', todoCount),
                const SizedBox(width: 16),
                _buildTaskStat('In Progress:', inProgressCount),
                const SizedBox(width: 16),
                _buildTaskStat('Done:', doneCount),
                const SizedBox(width: 16),
                _buildTaskStat('Total:', tasks.length),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Progress:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.neutral200,
                    valueColor: AlwaysStoppedAnimation(AppColors.accent),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 24),

            // Tasks List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tasks.map((task) => _buildTaskItem(task)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTabButton(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isActive ? AppColors.accent : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          color: isActive ? AppColors.accent : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTaskStat(String label, int value) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(width: 4),
        Text('$value', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    final isDone = task['status'] == 'done';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isDone ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDone ? AppColors.accent : AppColors.border, width: 2),
            ),
            child: isDone ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.success.withOpacity(0.1) : AppColors.neutral100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isDone ? 'Done' : 'To Do',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDone ? AppColors.success : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(task['assignee'], style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ FINANCIALS TAB ============
  Widget _buildFinancialsTab() {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

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
            // Financial Stats Grid
            Row(
              children: [
                Expanded(child: _buildFinancialCard('Budget', currencyFormat.format(_project['budget']), null)),
                const SizedBox(width: 12),
                Expanded(child: _buildFinancialCard('Labor Cost', currencyFormat.format(_project['laborCost']), '${_project['totalHours'].toInt()}h @ \$${_project['laborRate'].toInt()}/hr')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildFinancialCard('Expenses', currencyFormat.format(_project['expenses']), '0 expenses')),
                const SizedBox(width: 12),
                Expanded(child: _buildFinancialCard('Invoiced', currencyFormat.format(_project['amountInvoiced']), null, valueColor: AppColors.success)),
              ],
            ),
            const SizedBox(height: 12),
            _buildFinancialCard('Collected', currencyFormat.format(_project['collected']), null),
            const SizedBox(height: 24),

            // Time Entries
            const Text('Time Entries', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'No time entries for this project',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),

            // Expenses
            const Text('Expenses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'No expenses for this project',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(String label, String value, String? subtitle, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
