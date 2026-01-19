import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../shell/app_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  int _activeTab = 0; // 0 = Overview, 1 = Business Health
  bool _showQuickAdd = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final supabase = context.read<SupabaseService>();
    final authProvider = context.read<AuthProvider>();
    final companyId = authProvider.currentCompanyId;
    if (companyId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final stats = await supabase.getDashboardStats(companyId);
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.cardBackground,
          onRefresh: _loadStats,
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // App Header with Hamburger Menu
                  const SliverToBoxAdapter(
                    child: AppHeader(showSearch: true),
                  ),

                  // Dashboard Title with Tabs
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Dashboard',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _TabSelector(
                                      tabs: const ['Overview', 'Health'],
                                      activeIndex: _activeTab,
                                      onTap: (index) => setState(() => _activeTab = index),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Welcome back, ${authProvider.userName.isNotEmpty ? authProvider.userName : 'User'}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _QuickAddButton(
                            isExpanded: _showQuickAdd,
                            onTap: () => setState(() => _showQuickAdd = !_showQuickAdd),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_activeTab == 0) ...[
                    // Profit & Loss Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: _ProfitLossCard(
                          actualProfit: _stats?['profit'] ?? 8500,
                          targetProfit: 10000,
                          period: 'Monthly',
                        ),
                      ),
                    ),

                    // KPI Cards - Row 1
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _KPICard(
                                icon: Icons.attach_money_rounded,
                                label: 'Total Revenue',
                                value: currencyFormat.format(_stats?['totalRevenue'] ?? 24580),
                                subtitle: 'All-time paid',
                                onTap: () => context.go('/invoices'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _KPICard(
                                icon: Icons.receipt_outlined,
                                label: 'Outstanding',
                                value: currencyFormat.format(_stats?['outstanding'] ?? 4250),
                                subtitle: 'Awaiting payment',
                                onTap: () => context.go('/invoices'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 8)),

                    // KPI Cards - Row 2
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _KPICard(
                                icon: Icons.schedule_rounded,
                                label: 'Hours/Week',
                                value: '${_stats?['hoursThisWeek'] ?? 32}h',
                                subtitle: '${_stats?['hoursToday'] ?? 4}h today',
                                onTap: () => context.go('/expenses'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _KPICard(
                                icon: Icons.folder_outlined,
                                label: 'Projects',
                                value: '${_stats?['activeProjects'] ?? 5}',
                                subtitle: '${_stats?['pendingTasks'] ?? 12} tasks',
                                onTap: () => context.go('/projects'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // Billability Chart
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _BillabilityCard(
                          utilization: _stats?['utilization'] ?? 78,
                          billableHours: _stats?['billableHours'] ?? 28,
                          nonBillableHours: _stats?['nonBillableHours'] ?? 4,
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // Invoicing Summary
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _InvoicingSummaryCard(
                          unbilledWIP: _stats?['unbilledWIP'] ?? 3200,
                          draftCount: _stats?['draftInvoices'] ?? 3,
                          sentCount: _stats?['sentInvoices'] ?? 7,
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // Revenue Trend
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _RevenueTrendCard(),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // Payment Aging
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _PaymentAgingCard(),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // Recent Activity
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _RecentActivityCard(),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ] else ...[
                    // Business Health Tree View
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _BusinessHealthTree(),
                      ),
                    ),
                  ],
                ],
              ),

              // Quick Add Dropdown
              if (_showQuickAdd)
                Positioned(
                  top: 60,
                  right: 16,
                  child: _QuickAddMenu(
                    onDismiss: () => setState(() => _showQuickAdd = false),
                    onLogTime: () {
                      setState(() => _showQuickAdd = false);
                      _showLogTimeModal();
                    },
                    onNewProject: () {
                      setState(() => _showQuickAdd = false);
                      context.go('/projects');
                    },
                    onCreateInvoice: () {
                      setState(() => _showQuickAdd = false);
                      context.push('/invoices/create');
                    },
                    onScanReceipt: () {
                      setState(() => _showQuickAdd = false);
                      context.go('/receipts');
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogTimeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LogTimeModal(),
    );
  }
}

// Tab Selector Widget
class _TabSelector extends StatelessWidget {
  final List<String> tabs;
  final int activeIndex;
  final Function(int) onTap;

  const _TabSelector({
    required this.tabs,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(tabs.length, (index) {
          final isActive = index == activeIndex;
          return GestureDetector(
            onTap: () => onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.cardBackground : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isActive ? AppShadows.sm : null,
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Quick Add Button
class _QuickAddButton extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  const _QuickAddButton({required this.isExpanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            const Text(
              'Add',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// Quick Add Menu
class _QuickAddMenu extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onLogTime;
  final VoidCallback onNewProject;
  final VoidCallback onCreateInvoice;
  final VoidCallback onScanReceipt;

  const _QuickAddMenu({
    required this.onDismiss,
    required this.onLogTime,
    required this.onNewProject,
    required this.onCreateInvoice,
    required this.onScanReceipt,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.dropdown,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QuickAddMenuItem(
              icon: Icons.timer_outlined,
              label: 'Log Time',
              onTap: onLogTime,
            ),
            _QuickAddMenuItem(
              icon: Icons.create_new_folder_outlined,
              label: 'New Project',
              onTap: onNewProject,
            ),
            _QuickAddMenuItem(
              icon: Icons.receipt_long_outlined,
              label: 'Create Invoice',
              onTap: onCreateInvoice,
            ),
            _QuickAddMenuItem(
              icon: Icons.camera_alt_outlined,
              label: 'Scan Receipt',
              onTap: onScanReceipt,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  const _QuickAddMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast 
          ? const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            )
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isLast ? null : Border(
            bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Profit & Loss Card
class _ProfitLossCard extends StatelessWidget {
  final double actualProfit;
  final double targetProfit;
  final String period;

  const _ProfitLossCard({
    required this.actualProfit,
    required this.targetProfit,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (actualProfit / targetProfit * 100).clamp(0.0, 100.0);
    final isOnTrack = percentage >= 100;
    final isBehind = percentage >= 50 && percentage < 100;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    Color statusColor = isOnTrack ? AppColors.success : (isBehind ? AppColors.warning : AppColors.error);
    Color bgColor = isOnTrack ? AppColors.successLight : (isBehind ? AppColors.warningLight : AppColors.errorLight);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.track_changes, size: 16, color: statusColor),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profit & Loss',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'vs Target',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 18),
                color: AppColors.textTertiary,
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currencyFormat.format(actualProfit),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    'Actual Profit',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(targetProfit),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$period Target',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.neutral100,
              valueColor: AlwaysStoppedAnimation(statusColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}% of target',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
              Text(
                isOnTrack ? '✓ On Track' : (isBehind ? '⚠ Behind Target' : '⚠ Critical'),
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// KPI Card
class _KPICard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;

  const _KPICard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: AppColors.accent),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Billability Card
class _BillabilityCard extends StatelessWidget {
  final int utilization;
  final int billableHours;
  final int nonBillableHours;

  const _BillabilityCard({
    required this.utilization,
    required this.billableHours,
    required this.nonBillableHours,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Billability',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Circular Progress
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: utilization / 100,
                          strokeWidth: 8,
                          backgroundColor: AppColors.neutral200,
                          valueColor: const AlwaysStoppedAnimation(AppColors.textPrimary),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '$utilization%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Legend
              Expanded(
                child: Column(
                  children: [
                    _LegendItem(
                      color: AppColors.accent,
                      label: 'Billable',
                      value: '${billableHours}h',
                    ),
                    const SizedBox(height: 8),
                    _LegendItem(
                      color: AppColors.neutral200,
                      label: 'Non-Billable',
                      value: '${nonBillableHours}h',
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Text(
                      '$utilization% Overall Utilization',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
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
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// Invoicing Summary Card
class _InvoicingSummaryCard extends StatelessWidget {
  final double unbilledWIP;
  final int draftCount;
  final int sentCount;

  const _InvoicingSummaryCard({
    required this.unbilledWIP,
    required this.draftCount,
    required this.sentCount,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invoicing Summary',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SummaryBox(
                value: currencyFormat.format(unbilledWIP),
                label: 'Unbilled WIP',
              )),
              const SizedBox(width: 8),
              Expanded(child: _SummaryBox(
                value: '$draftCount',
                label: 'Drafts',
              )),
              const SizedBox(width: 8),
              Expanded(child: _SummaryBox(
                value: '$sentCount',
                label: 'Finalized',
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// Revenue Trend Card
class _RevenueTrendCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final months = ['Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan'];
    final values = [4200.0, 5800.0, 3200.0, 7500.0, 6100.0, 8900.0];
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              const Text(
                'Revenue Trend (6 Months)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(months.length, (index) {
                final height = (values[index] / maxValue) * 100;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(values[index]),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          months[index],
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// Payment Aging Card
class _PaymentAgingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ranges = ['0-30', '31-60', '61-90', '90+'];
    final amounts = [2500.0, 1200.0, 800.0, 350.0];
    final counts = [3, 2, 1, 1];
    final maxAmount = amounts.reduce((a, b) => a > b ? a : b);
    final colors = [AppColors.accent, const Color(0xFF8B7355), const Color(0xFF6B5B4F), const Color(0xFF4A4A4A)];
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              const Text(
                'Payment Aging Report',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(ranges.length, (index) {
            final width = (amounts[index] / maxAmount * 100).clamp(5.0, 100.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${ranges[index]} days',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${currencyFormat.format(amounts[index])} (${counts[index]})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: width / 100,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors[index],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// Recent Activity Card
class _RecentActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final activities = [
      {'desc': 'Logged 2h on Website Redesign', 'meta': 'Homepage mockups', 'date': 'Today'},
      {'desc': 'Logged 3h on Mobile App', 'meta': 'API integration', 'date': 'Today'},
      {'desc': 'Logged 1.5h on Branding Project', 'meta': 'Logo revisions', 'date': 'Yesterday'},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...activities.map((activity) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['desc']!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (activity['meta']!.isNotEmpty)
                          Text(
                            activity['meta']!,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    activity['date']!,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

// Business Health Tree (placeholder)
class _BusinessHealthTree extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          const Icon(Icons.park_outlined, size: 64, color: AppColors.accent),
          const SizedBox(height: 16),
          const Text(
            'Business Health Tree',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A visual representation of your business health metrics',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          _HealthMetric(label: 'Cash Flow', value: 85, target: 80),
          _HealthMetric(label: 'Utilization', value: 72, target: 75),
          _HealthMetric(label: 'Win Rate', value: 35, target: 30),
          _HealthMetric(label: 'Profit Margin', value: 18, target: 20),
        ],
      ),
    );
  }
}

class _HealthMetric extends StatelessWidget {
  final String label;
  final int value;
  final int target;

  const _HealthMetric({
    required this.label,
    required this.value,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final isOnTarget = value >= target;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  Text(
                    '$value%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isOnTarget ? AppColors.success : AppColors.warning,
                    ),
                  ),
                  Text(
                    ' / $target%',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: AppColors.neutral100,
              valueColor: AlwaysStoppedAnimation(
                isOnTarget ? AppColors.success : AppColors.warning,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// Log Time Modal
class _LogTimeModal extends StatefulWidget {
  @override
  State<_LogTimeModal> createState() => _LogTimeModalState();
}

class _LogTimeModalState extends State<_LogTimeModal> {
  String _selectedProject = '';
  String _hours = '';
  String _description = '';
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Log Time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FormField(
                  label: 'Project',
                  child: DropdownButtonFormField<String>(
                    value: _selectedProject.isEmpty ? null : _selectedProject,
                    hint: const Text('Select project'),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: const [
                      DropdownMenuItem(value: '1', child: Text('Website Redesign')),
                      DropdownMenuItem(value: '2', child: Text('Mobile App')),
                      DropdownMenuItem(value: '3', child: Text('Branding Project')),
                    ],
                    onChanged: (value) => setState(() => _selectedProject = value ?? ''),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FormField(
                        label: 'Hours *',
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '1.5',
                          ),
                          onChanged: (value) => _hours = value,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FormField(
                        label: 'Date *',
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _selectedDate = date);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            child: Text(
                              DateFormat('MMM d, yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _FormField(
                  label: 'Description',
                  child: TextFormField(
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'What did you work on?',
                    ),
                    onChanged: (value) => _description = value,
                  ),
                ),
              ],
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.neutral50,
              border: Border(top: BorderSide(color: AppColors.border)),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
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
                    onPressed: () {
                      // Save time entry
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
