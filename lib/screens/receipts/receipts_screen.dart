import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../main.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  // Demo data
  List<Map<String, dynamic>> get _demoReceipts => [
    {'id': '1', 'vendor': 'Office Supplies Co', 'category': 'Office', 'amount': 156.50, 'date': DateTime.now().subtract(const Duration(days: 1)), 'status': 'processed'},
    {'id': '2', 'vendor': 'Tech Store', 'category': 'Equipment', 'amount': 899.00, 'date': DateTime.now().subtract(const Duration(days: 3)), 'status': 'processed'},
    {'id': '3', 'vendor': 'Cloud Services Inc', 'category': 'Software', 'amount': 49.99, 'date': DateTime.now().subtract(const Duration(days: 5)), 'status': 'pending'},
    {'id': '4', 'vendor': 'Business Lunch', 'category': 'Meals', 'amount': 78.25, 'date': DateTime.now().subtract(const Duration(days: 7)), 'status': 'processed'},
    {'id': '5', 'vendor': 'Uber', 'category': 'Travel', 'amount': 34.50, 'date': DateTime.now().subtract(const Duration(days: 10)), 'status': 'processed'},
    {'id': '6', 'vendor': 'Adobe Creative', 'category': 'Software', 'amount': 54.99, 'date': DateTime.now().subtract(const Duration(days: 12)), 'status': 'pending'},
  ];

  List<Map<String, dynamic>> get _filteredReceipts {
    if (_filterStatus == 'all') return _demoReceipts;
    return _demoReceipts.where((r) => r['status'] == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Receipts', style: Theme.of(context).textTheme.headlineMedium),
                  Row(
                    children: [
                      _HeaderButton(icon: Icons.filter_list, onTap: _showFilterSheet),
                      const SizedBox(width: 8),
                      _HeaderButton(icon: Icons.camera_alt, onTap: () {}, isPrimary: true),
                    ],
                  ),
                ],
              ),
            ),

            // Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _StatCard(label: 'This Month', value: '\$1,273', icon: Icons.calendar_month)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'Pending', value: '2', icon: Icons.pending_actions)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _FilterChip(label: 'All', isSelected: _filterStatus == 'all', onTap: () => setState(() => _filterStatus = 'all')),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Processed', isSelected: _filterStatus == 'processed', onTap: () => setState(() => _filterStatus = 'processed')),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Pending', isSelected: _filterStatus == 'pending', onTap: () => setState(() => _filterStatus = 'pending')),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Receipt List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
                  : RefreshIndicator(
                      color: AppColors.blue,
                      backgroundColor: AppColors.cardBackground,
                      onRefresh: _loadReceipts,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredReceipts.length,
                        itemBuilder: (context, index) => _ReceiptCard(receipt: _filteredReceipts[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filter Receipts', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            _FilterOption(label: 'All Receipts', isSelected: _filterStatus == 'all', onTap: () { setState(() => _filterStatus = 'all'); Navigator.pop(context); }),
            _FilterOption(label: 'Processed', isSelected: _filterStatus == 'processed', onTap: () { setState(() => _filterStatus = 'processed'); Navigator.pop(context); }),
            _FilterOption(label: 'Pending Review', isSelected: _filterStatus == 'pending', onTap: () { setState(() => _filterStatus = 'pending'); Navigator.pop(context); }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _HeaderButton({required this.icon, required this.onTap, this.isPrimary = false});

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
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.blue : AppColors.cardBorder),
        ),
        child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final Map<String, dynamic> receipt;

  const _ReceiptCard({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final isPending = receipt['status'] == 'pending';
    final dateFormat = DateFormat.MMMd();
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long, color: AppColors.purple, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(receipt['vendor'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(receipt['category'] as String, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                          Text(dateFormat.format(receipt['date'] as DateTime), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(currencyFormat.format(receipt['amount']), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isPending ? AppColors.orange : AppColors.green).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(isPending ? 'Pending' : 'Processed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isPending ? AppColors.orange : AppColors.green)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(label, style: TextStyle(color: AppColors.textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.blue) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
