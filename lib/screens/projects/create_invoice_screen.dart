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
  String _billingMethod = 'percentage'; // percentage, items, milestone
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  
  // For per-task percentage billing
  final Map<String, double> _taskPercentages = {};
  
  // For item selection
  final Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    // Initialize task percentages to 0
    final tasks = widget.project['tasks'] as List<Map<String, dynamic>>;
    for (var task in tasks) {
      _taskPercentages[task['id']] = 0.0;
    }
  }

  double get _selectedTotal {
    final tasks = widget.project['tasks'] as List<Map<String, dynamic>>;
    double total = 0;
    
    if (_billingMethod == 'percentage') {
      // For percentage billing, sum each task's percentage amount
      for (var task in tasks) {
        final taskId = task['id'] as String;
        final percentage = _taskPercentages[taskId] ?? 0.0;
        final taskAmount = task['amount'] as double;
        final percentBilled = task['percentBilled'] as int;
        final remaining = taskAmount * (1 - percentBilled / 100);
        total += remaining * (percentage / 100);
      }
      return total;
    } else if (_billingMethod == 'milestone') {
      // For milestone, bill all remaining amounts
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
          final percentBilled = task['percentBilled'] as int;
          final remaining = (task['amount'] as double) * (1 - percentBilled / 100);
          total += remaining;
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
                              value: 'percentage',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('By Percentage', style: TextStyle(fontWeight: FontWeight.w500)),
                                  Text('Set billing percentage for each task', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'items',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('By Items', style: TextStyle(fontWeight: FontWeight.w500)),
                                  Text('Select specific tasks to bill fully', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                                  Text('Bill all remaining amounts', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _billingMethod = value!;
                              _selectedItems.clear();
                              // Reset percentages
                              for (var key in _taskPercentages.keys) {
                                _taskPercentages[key] = 0.0;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Budget Summary Card
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
                              Text('Total Project Budget', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              Text(currencyFormat.format(_totalBudget), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Previously Billed', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              Text(currencyFormat.format(_priorBilled), style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.info)),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Remaining to Bill', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text(currencyFormat.format(_remainingBudget), style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.success)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // PERCENTAGE BILLING - Per Task
                    if (_billingMethod == 'percentage') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tasks & Percentage', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                // Set all tasks to 100%
                                for (var task in tasks) {
                                  final percentBilled = task['percentBilled'] as int;
                                  if (percentBilled < 100) {
                                    _taskPercentages[task['id']] = 100.0;
                                  }
                                }
                              });
                            },
                            icon: Icon(Icons.done_all, size: 16, color: AppColors.accent),
                            label: Text('Bill All 100%', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppShadows.sm,
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
                                  const Expanded(flex: 3, child: Text('Task', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                                  const Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                                  const Expanded(flex: 2, child: Text('Bill %', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                                  const Expanded(flex: 2, child: Text('This Invoice', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            // Tasks
                            ...tasks.asMap().entries.map((entry) {
                              final index = entry.key;
                              final task = entry.value;
                              final isLast = index == tasks.length - 1;
                              return _buildPercentageTaskRow(task, currencyFormat, isLast);
                            }),
                          ],
                        ),
                      ),
                    ],

                    // ITEMS BILLING
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

                    // MILESTONE BILLING
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
                                Icon(Icons.flag_outlined, size: 18, color: AppColors.warning),
                                const SizedBox(width: 8),
                                const Text('Milestone Billing', style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This will bill all remaining unbilled amounts for all tasks.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Show all tasks with remaining amounts
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppShadows.sm,
                        ),
                        child: Column(
                          children: [
                            ...tasks.where((t) => (t['percentBilled'] as int) < 100).map((task) {
                              final percentBilled = task['percentBilled'] as int;
                              final taskAmount = task['amount'] as double;
                              final remaining = taskAmount * (1 - percentBilled / 100);
                              return ListTile(
                                dense: true,
                                title: Text(task['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                subtitle: Text('$percentBilled% billed', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                trailing: Text(currencyFormat.format(remaining), style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.success)),
                              );
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
                      child: Row(
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
                            // Create invoice
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

  Widget _buildPercentageTaskRow(Map<String, dynamic> task, NumberFormat currencyFormat, bool isLast) {
    final taskId = task['id'] as String;
    final taskName = task['name'] as String;
    final taskAmount = task['amount'] as double;
    final percentBilled = task['percentBilled'] as int;
    final remaining = taskAmount * (1 - percentBilled / 100);
    final currentPercentage = _taskPercentages[taskId] ?? 0.0;
    final thisInvoiceAmount = remaining * (currentPercentage / 100);
    final canBill = remaining > 0;

    return Container(
      decoration: BoxDecoration(
        border: !isLast ? Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.5))) : null,
        color: !canBill ? AppColors.neutral50.withOpacity(0.5) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Task Name
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: canBill ? AppColors.textPrimary : AppColors.textTertiary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (percentBilled > 0)
                  Text(
                    '$percentBilled% already billed',
                    style: TextStyle(fontSize: 10, color: AppColors.warning),
                  ),
              ],
            ),
          ),
          // Remaining Amount
          Expanded(
            flex: 2,
            child: Text(
              currencyFormat.format(remaining),
              style: TextStyle(
                fontSize: 12,
                color: canBill ? AppColors.textSecondary : AppColors.textTertiary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          // Percentage Input
          Expanded(
            flex: 2,
            child: canBill
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 32,
                        child: TextField(
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: AppColors.accent),
                            ),
                            suffixText: '%',
                            suffixStyle: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                          ),
                          controller: TextEditingController(text: currentPercentage.toStringAsFixed(0)),
                          onChanged: (value) {
                            final parsed = double.tryParse(value) ?? 0;
                            setState(() {
                              _taskPercentages[taskId] = parsed.clamp(0, 100);
                            });
                          },
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Fully billed',
                    style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                    textAlign: TextAlign.center,
                  ),
          ),
          // This Invoice Amount
          Expanded(
            flex: 2,
            child: Text(
              currencyFormat.format(thisInvoiceAmount),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: thisInvoiceAmount > 0 ? AppColors.success : AppColors.textTertiary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
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
