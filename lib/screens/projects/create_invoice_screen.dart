import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../main.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const CreateInvoiceScreen({super.key, required this.project});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  String _billingMethod = 'items'; // items, milestone, percentage
  final Set<String> _selectedItems = {};
  double _percentageToBill = 0.0;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  double get _selectedTotal {
    final tasks = widget.project['tasks'] as List<Map<String, dynamic>>;
    double total = 0;
    
    if (_billingMethod == 'percentage') {
      // For percentage billing, calculate based on percentage
      double budgetTotal = widget.project['budget'] as double;
      return budgetTotal * (_percentageToBill / 100);
    } else if (_billingMethod == 'milestone') {
      // For milestone, bill remaining amount
      for (var task in tasks) {
        final percentBilled = task['percentBilled'] as int;
        final remaining = (task['amount'] as double) * (1 - percentBilled / 100);
        total += remaining;
      }
      return total;
    } else {
      // For items, sum selected tasks
      for (var task in tasks) {
        if (_selectedItems.contains(task['id'])) {
          total += task['amount'] as double;
        }
      }
      return total;
    }
  }

  double get _priorBilled {
    return widget.project['amountInvoiced'] as double;
  }

  double get _totalBudget {
    return widget.project['budget'] as double;
  }

  double get _remainingBudget {
    return _totalBudget - _priorBilled;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final tasks = widget.project['tasks'] as List<Map<String, dynamic>>;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
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
                        const Text('Create Invoice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(widget.project['name'], style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Billing Method Dropdown
                    const Text('Billing Method', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _billingMethod,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                          items: const [
                            DropdownMenuItem(
                              value: 'items',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('By Items', style: TextStyle(fontWeight: FontWeight.w500)),
                                  Text('Select specific tasks to bill', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'milestone',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('By Milestone', style: TextStyle(fontWeight: FontWeight.w500)),
                                  Text('Bill full remaining amount', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'percentage',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('By Percentage', style: TextStyle(fontWeight: FontWeight.w500)),
                                  Text('Bill percentage of project budget', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _billingMethod = value!;
                              _selectedItems.clear();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Percentage Billing Section
                    if (_billingMethod == 'percentage') ...[
                      // Prior Billing Summary
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.info.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Project Budget', style: TextStyle(color: AppColors.textSecondary)),
                                Text(currencyFormat.format(_totalBudget), style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Previously Billed', style: TextStyle(color: AppColors.textSecondary)),
                                Text(currencyFormat.format(_priorBilled), style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.info)),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Remaining to Bill', style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(currencyFormat.format(_remainingBudget), style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.success)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Percentage Slider
                      const Text('Percentage to Bill', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _percentageToBill,
                              min: 0,
                              max: 100,
                              divisions: 20,
                              label: '${_percentageToBill.toStringAsFixed(0)}%',
                              activeColor: AppColors.accent,
                              onChanged: (value) {
                                setState(() {
                                  _percentageToBill = value;
                                });
                              },
                            ),
                          ),
                          Container(
                            width: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_percentageToBill.toStringAsFixed(0)}%',
                              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.accent),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This will bill ${currencyFormat.format(_selectedTotal)} (${_percentageToBill.toStringAsFixed(0)}% of ${currencyFormat.format(_totalBudget)})',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],

                    // Milestone Billing Section
                    if (_billingMethod == 'milestone') ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                                const SizedBox(width: 8),
                                const Text('Milestone Billing', style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This will bill all remaining unbilled amounts for completed milestones.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Amount to Bill', style: TextStyle(color: AppColors.textSecondary)),
                                Text(currencyFormat.format(_selectedTotal), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.warning)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Items Billing Section
                    if (_billingMethod == 'items') ...[
                      const Text('Select Tasks to Bill', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppShadows.sm,
                        ),
                        child: Column(
                          children: [
                            ...tasks.asMap().entries.map((entry) {
                              final index = entry.key;
                              final task = entry.value;
                              final isLast = index == tasks.length - 1;
                              return _buildTaskCheckboxItem(task, currencyFormat, isLast);
                            }),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Invoice Details
                    const Text('Invoice Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: AppShadows.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Invoice Date', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(height: 6),
                                    Text(DateFormat('MMM d, yyyy').format(DateTime.now()), style: const TextStyle(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Due Date', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: _dueDate,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(const Duration(days: 365)),
                                        );
                                        if (date != null) {
                                          setState(() => _dueDate = date);
                                        }
                                      },
                                      child: Row(
                                        children: [
                                          Text(DateFormat('MMM d, yyyy').format(_dueDate), style: const TextStyle(fontWeight: FontWeight.w500)),
                                          const SizedBox(width: 4),
                                          Icon(Icons.calendar_today, size: 14, color: AppColors.accent),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer with Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Invoice Amount', style: TextStyle(fontSize: 12)),
                          Text(currencyFormat.format(_selectedTotal), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Due ${DateFormat('MMM d').format(_dueDate)}', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text('Net 30', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _selectedTotal > 0 ? () {
                            // TODO: Create invoice
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invoice for ${currencyFormat.format(_selectedTotal)} created'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Create Invoice'),
                        ),
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

  Widget _buildTaskCheckboxItem(Map<String, dynamic> task, NumberFormat currencyFormat, bool isLast) {
    final isSelected = _selectedItems.contains(task['id']);
    final percentBilled = task['percentBilled'] as int;
    final taskAmount = task['amount'] as double;
    final remaining = taskAmount * (1 - percentBilled / 100);
    final canBill = remaining > 0;

    return Container(
      decoration: BoxDecoration(
        border: !isLast ? Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.5))) : null,
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: canBill ? (val) {
          setState(() {
            if (val == true) {
              _selectedItems.add(task['id']);
            } else {
              _selectedItems.remove(task['id']);
            }
          });
        } : null,
        activeColor: AppColors.accent,
        title: Text(
          task['name'],
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: canBill ? AppColors.textPrimary : AppColors.textTertiary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${task['estimatedHours']}h estimated',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            if (percentBilled > 0) ...[
              const SizedBox(height: 2),
              Text(
                '$percentBilled% already billed',
                style: TextStyle(fontSize: 10, color: AppColors.warning),
              ),
            ],
          ],
        ),
        secondary: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(remaining),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: canBill ? AppColors.textPrimary : AppColors.textTertiary,
              ),
            ),
            if (percentBilled > 0)
              Text(
                'of ${currencyFormat.format(taskAmount)}',
                style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
              ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
