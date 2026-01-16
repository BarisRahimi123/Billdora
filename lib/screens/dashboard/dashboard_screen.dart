import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final supabase = context.read<SupabaseService>();
    try {
      final stats = await supabase.getDashboardStats('company-id');
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
          color: AppColors.blue,
          backgroundColor: AppColors.cardBackground,
          onRefresh: _loadStats,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Main Dashboard',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Welcome back, ${authProvider.userName.isNotEmpty ? authProvider.userName : 'User'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _HeaderIconButton(
                            icon: Icons.notifications_outlined,
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                          _HeaderIconButton(
                            icon: Icons.add,
                            onTap: () => context.push('/invoices/create'),
                            isPrimary: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Main Stats Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildMainStatsCards(currencyFormat),
                ),
              ),

              // Quick Actions Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildQuickActionsRow(context),
                ),
              ),

              // Recent Activity Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildRecentActivitySection(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainStatsCards(NumberFormat currencyFormat) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.blue),
        ),
      );
    }

    return Column(
      children: [
        // Row 1: Cash Flow & Revenue
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Cash Flow',
                value: currencyFormat.format(_stats?['cashFlow'] ?? 24580),
                change: '+12.5%',
                isPositive: true,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Revenue',
                value: currencyFormat.format(_stats?['totalRevenue'] ?? 48250),
                change: '+8.2%',
                isPositive: true,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E4035), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                icon: Icons.trending_up,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Profit & Expenses
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Profit',
                value: currencyFormat.format(_stats?['profit'] ?? 18420),
                change: '+15.3%',
                isPositive: true,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D1F4E), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                icon: Icons.show_chart,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Expenses',
                value: currencyFormat.format(_stats?['totalExpenses'] ?? 12840),
                change: '-3.1%',
                isPositive: false,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A1D1D), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                icon: Icons.receipt_long_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _QuickAction(
          icon: Icons.receipt_long,
          label: 'Invoice',
          onTap: () => context.push('/invoices/create'),
        )),
        const SizedBox(width: 12),
        Expanded(child: _QuickAction(
          icon: Icons.person_add,
          label: 'Client',
          onTap: () => context.go('/clients'),
        )),
        const SizedBox(width: 12),
        Expanded(child: _QuickAction(
          icon: Icons.folder_outlined,
          label: 'Project',
          onTap: () => context.go('/projects'),
        )),
        const SizedBox(width: 12),
        Expanded(child: _QuickAction(
          icon: Icons.timer_outlined,
          label: 'Time',
          onTap: () {}, // TODO: Navigate to time tracking
        )),
      ],
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Invoices',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => context.go('/invoices'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: AppColors.cardBorder,
            ),
            itemBuilder: (context, index) => _InvoiceListItem(
              invoiceNumber: 'INV-${2024001 + index}',
              clientName: ['Acme Corp', 'TechStart Inc', 'Design Studio', 'Global Media'][index],
              amount: [2500, 1800, 3200, 950][index].toDouble(),
              status: ['Paid', 'Pending', 'Paid', 'Overdue'][index],
              onTap: () => context.push('/invoices/$index'),
            ),
          ),
        ),
      ],
    );
  }
}

// Header Icon Button
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.blue : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary ? null : Border.all(color: AppColors.cardBorder),
        ),
        child: Icon(
          icon,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}

// Stat Card with gradient
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final Gradient gradient;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.gradient,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.textPrimary, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.green : AppColors.red).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? AppColors.green : AppColors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// Quick Action Button
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.blue, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Invoice List Item
class _InvoiceListItem extends StatelessWidget {
  final String invoiceNumber;
  final String clientName;
  final double amount;
  final String status;
  final VoidCallback onTap;

  const _InvoiceListItem({
    required this.invoiceNumber,
    required this.clientName,
    required this.amount,
    required this.status,
    required this.onTap,
  });

  Color get _statusColor {
    switch (status.toLowerCase()) {
      case 'paid': return AppColors.green;
      case 'pending': return AppColors.orange;
      case 'overdue': return AppColors.red;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.blue.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            clientName[0],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.blue,
            ),
          ),
        ),
      ),
      title: Text(
        invoiceNumber,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        clientName,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            currencyFormat.format(amount),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
