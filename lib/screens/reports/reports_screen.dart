import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today), onPressed: () {}),
          IconButton(icon: const Icon(Icons.download), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue Chart
            Text(
              'Revenue Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 10000,
                      barGroups: [
                        _makeBarGroup(0, 5000, colorScheme.primary),
                        _makeBarGroup(1, 7500, colorScheme.primary),
                        _makeBarGroup(2, 6000, colorScheme.primary),
                        _makeBarGroup(3, 8500, colorScheme.primary),
                        _makeBarGroup(4, 7000, colorScheme.primary),
                        _makeBarGroup(5, 9500, colorScheme.primary),
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
                              return Text(
                                months[value.toInt()],
                                style: const TextStyle(fontSize: 10),
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
            const SizedBox(height: 24),

            // Report Cards
            Text(
              'Quick Reports',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildReportCard(
              context,
              'Profit & Loss',
              'View income vs expenses',
              Icons.trending_up,
              colorScheme,
            ),
            _buildReportCard(
              context,
              'Invoice Aging',
              'Track overdue payments',
              Icons.access_time,
              colorScheme,
            ),
            _buildReportCard(
              context,
              'Client Report',
              'Revenue by client',
              Icons.people,
              colorScheme,
            ),
            _buildReportCard(
              context,
              'Tax Summary',
              'Prepare for tax season',
              Icons.account_balance,
              colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(icon, color: colorScheme.onPrimaryContainer),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Navigate to report detail
        },
      ),
    );
  }
}
