import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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
    // TODO: Get actual company ID from user
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
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              authProvider.userName.isNotEmpty ? authProvider.userName : 'User',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              _buildStatsGrid(colorScheme, currencyFormat),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActions(context, colorScheme),
              const SizedBox(height: 24),

              // Recent Invoices
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Invoices',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/invoices'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildRecentInvoices(colorScheme),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/invoices/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }

  Widget _buildStatsGrid(ColorScheme colorScheme, NumberFormat currencyFormat) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Revenue',
          currencyFormat.format(_stats?['totalRevenue'] ?? 0),
          Icons.trending_up,
          colorScheme.primary,
          colorScheme,
        ),
        _buildStatCard(
          'Outstanding',
          currencyFormat.format(_stats?['outstanding'] ?? 0),
          Icons.pending_actions,
          colorScheme.tertiary,
          colorScheme,
        ),
        _buildStatCard(
          'Expenses',
          currencyFormat.format(_stats?['totalExpenses'] ?? 0),
          Icons.receipt_long,
          colorScheme.error,
          colorScheme,
        ),
        _buildStatCard(
          'Profit',
          currencyFormat.format(_stats?['profit'] ?? 0),
          Icons.account_balance_wallet,
          Colors.green,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                Icon(icon, color: iconColor, size: 20),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            'Invoice',
            Icons.receipt_long,
            () => context.push('/invoices/create'),
            colorScheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context,
            'Client',
            Icons.person_add,
            () => context.go('/clients'),
            colorScheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context,
            'Expense',
            Icons.add_card,
            () => context.go('/expenses'),
            colorScheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context,
            'Report',
            Icons.bar_chart,
            () => context.go('/reports'),
            colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
    ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentInvoices(ColorScheme colorScheme) {
    // Placeholder - will be populated with real data
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Text('C${index + 1}'),
            ),
            title: Text('Invoice #INV-00${index + 1}'),
            subtitle: Text('Client ${index + 1}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${(index + 1) * 500}.00',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: index == 0
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    index == 0 ? 'Paid' : 'Pending',
                    style: TextStyle(
                      fontSize: 10,
                      color: index == 0 ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () => context.push('/invoices/$index'),
          );
        },
      ),
    );
  }
}
