import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../main.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'This Month';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Reports', style: Theme.of(context).textTheme.headlineMedium),
                    Row(
                      children: [
                        _PeriodSelector(selected: _selectedPeriod, onChanged: (v) => setState(() => _selectedPeriod = v)),
                        const SizedBox(width: 8),
                        _HeaderButton(icon: Icons.download, onTap: () {}),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Revenue Chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ChartCard(
                  title: 'Revenue Overview',
                  subtitle: '+12.5% from last period',
                  child: SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 10000,
                        barGroups: [
                          _makeBarGroup(0, 5000),
                          _makeBarGroup(1, 7500),
                          _makeBarGroup(2, 6000),
                          _makeBarGroup(3, 8500),
                          _makeBarGroup(4, 7000),
                          _makeBarGroup(5, 9500),
                        ],
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(months[value.toInt()], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Summary Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: _SummaryCard(title: 'Total Revenue', value: '\$43,500', change: '+12.5%', isPositive: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _SummaryCard(title: 'Total Expenses', value: '\$18,200', change: '-3.2%', isPositive: true)),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: _SummaryCard(title: 'Net Profit', value: '\$25,300', change: '+18.7%', isPositive: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _SummaryCard(title: 'Outstanding', value: '\$8,450', change: '+5.1%', isPositive: false)),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Quick Reports
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Quick Reports', style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _ReportTile(title: 'Profit & Loss', subtitle: 'View income vs expenses', icon: Icons.trending_up, color: AppColors.green),
                    const SizedBox(height: 12),
                    _ReportTile(title: 'Invoice Aging', subtitle: 'Track overdue payments', icon: Icons.access_time, color: AppColors.orange),
                    const SizedBox(height: 12),
                    _ReportTile(title: 'Client Report', subtitle: 'Revenue by client', icon: Icons.people, color: AppColors.blue),
                    const SizedBox(height: 12),
                    _ReportTile(title: 'Tax Summary', subtitle: 'Prepare for tax season', icon: Icons.account_balance, color: AppColors.purple),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: const LinearGradient(colors: [AppColors.blue, AppColors.purple], begin: Alignment.bottomCenter, end: Alignment.topCenter),
          width: 24,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final String selected;
  final Function(String) onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.cardBackground,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ['This Week', 'This Month', 'This Quarter', 'This Year'].map((period) => ListTile(
                title: Text(period, style: TextStyle(color: AppColors.textPrimary, fontWeight: selected == period ? FontWeight.w600 : FontWeight.w400)),
                trailing: selected == period ? const Icon(Icons.check, color: AppColors.blue) : null,
                onTap: () { onChanged(period); Navigator.pop(context); },
              )).toList(),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selected, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.green)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;

  const _SummaryCard({required this.title, required this.value, required this.change, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: (isPositive ? AppColors.green : AppColors.red).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
            child: Text(change, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isPositive ? AppColors.green : AppColors.red)),
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ReportTile({required this.title, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: () {},
      ),
    );
  }
}
