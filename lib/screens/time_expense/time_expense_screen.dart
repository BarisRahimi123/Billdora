import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../../main.dart';
import '../shell/app_header.dart';

// Mock Projects Data (would come from a service/provider in production)
final List<Map<String, dynamic>> mockProjects = [
  {
    'id': 'p1',
    'name': 'Mobile App UI Design',
    'client': 'Tech Startup Inc.',
    'tasks': [
      {
        'id': 't1',
        'name': 'User Research & Analysis',
        'subtasks': [
          {'id': 'st1', 'name': 'Conduct user interviews'},
          {'id': 'st2', 'name': 'Analyze competitors'},
          {'id': 'st3', 'name': 'Create user personas'},
        ],
      },
      {
        'id': 't2',
        'name': 'Wireframing',
        'subtasks': [
          {'id': 'st4', 'name': 'Sketch initial layouts'},
          {'id': 'st5', 'name': 'Create low-fi wireframes'},
          {'id': 'st6', 'name': 'Client review session'},
        ],
      },
      {
        'id': 't3',
        'name': 'Visual Design',
        'subtasks': [
          {'id': 'st7', 'name': 'Design system creation'},
          {'id': 'st8', 'name': 'Hi-fi mockups'},
          {'id': 'st9', 'name': 'Asset preparation'},
        ],
      },
    ],
  },
  {
    'id': 'p2',
    'name': 'E-commerce Website',
    'client': 'Retail Corp',
    'tasks': [
      {
        'id': 't4',
        'name': 'Homepage Design',
        'subtasks': [
          {'id': 'st10', 'name': 'Hero section'},
          {'id': 'st11', 'name': 'Product showcase'},
          {'id': 'st12', 'name': 'Footer design'},
        ],
      },
      {
        'id': 't5',
        'name': 'Product Pages',
        'subtasks': [
          {'id': 'st13', 'name': 'Product detail template'},
          {'id': 'st14', 'name': 'Shopping cart UI'},
          {'id': 'st15', 'name': 'Checkout flow'},
        ],
      },
    ],
  },
  {
    'id': 'p3',
    'name': 'Virtual Tour Production',
    'client': 'Real Estate Agency',
    'tasks': [
      {
        'id': 't6',
        'name': '360° Photography',
        'subtasks': [
          {'id': 'st16', 'name': 'Property walkthrough'},
          {'id': 'st17', 'name': 'Photo editing'},
        ],
      },
      {
        'id': 't7',
        'name': 'Tour Assembly',
        'subtasks': [
          {'id': 'st18', 'name': 'Stitch panoramas'},
          {'id': 'st19', 'name': 'Add hotspots'},
          {'id': 'st20', 'name': 'Final testing'},
        ],
      },
    ],
  },
  {
    'id': 'p4',
    'name': 'Brand Identity Design',
    'client': 'Fashion Boutique',
    'tasks': [
      {
        'id': 't8',
        'name': 'Logo Design',
        'subtasks': [
          {'id': 'st21', 'name': 'Concept sketches'},
          {'id': 'st22', 'name': 'Digital refinement'},
          {'id': 'st23', 'name': 'Color variations'},
        ],
      },
      {
        'id': 't9',
        'name': 'Brand Guidelines',
        'subtasks': [
          {'id': 'st24', 'name': 'Typography system'},
          {'id': 'st25', 'name': 'Color palette'},
          {'id': 'st26', 'name': 'Usage examples'},
        ],
      },
    ],
  },
];

class TimeExpenseScreen extends StatefulWidget {
  const TimeExpenseScreen({super.key});

  @override
  State<TimeExpenseScreen> createState() => _TimeExpenseScreenState();
}

class _TimeExpenseScreenState extends State<TimeExpenseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
            // App Header with Hamburger Menu
            const AppHeader(showSearch: true),
            
            // Title and Actions
            _buildTitleRow(context),
            
            // Tabs
            _buildTabs(),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _TimeTab(),
                  _ExpensesTab(),
                  _ApproveTab(),
                  _HistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Time & Expense',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          GestureDetector(
            onTap: () => _showAddMenu(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          boxShadow: AppShadows.sm,
        ),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        tabs: const [
          Tab(text: 'Time'),
          Tab(text: 'Expenses'),
          Tab(text: 'Approve'),
          Tab(text: 'History'),
        ],
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.access_time, color: AppColors.accent),
              ),
              title: const Text('Log Time Entry'),
              subtitle: const Text('Add manual time entry'),
              onTap: () {
                Navigator.pop(context);
                _showAddTimeEntryModal(context);
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long, color: AppColors.info),
              ),
              title: const Text('Add Expense'),
              subtitle: const Text('Record a new expense'),
              onTap: () {
                Navigator.pop(context);
                _showAddExpenseModal(context);
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.build_outlined, color: AppColors.success),
              ),
              title: const Text('Add Service'),
              subtitle: const Text('Create a new service type'),
              onTap: () {
                Navigator.pop(context);
                _showAddServiceModal(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddTimeEntryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _AddTimeEntryModal(),
    );
  }

  void _showAddExpenseModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _AddExpenseModal(),
    );
  }

  void _showAddServiceModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddServiceDialog(),
    );
  }
}

// ============ TIME TAB ============
class _TimeTab extends StatefulWidget {
  const _TimeTab();

  @override
  State<_TimeTab> createState() => _TimeTabState();
}

class _TimeTabState extends State<_TimeTab> {
  // Timer state
  bool _isTimerRunning = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  
  String? _selectedProjectId;
  String? _selectedTaskId;
  String? _selectedSubtaskId;
  final TextEditingController _descriptionController = TextEditingController();
  
  // Day selection
  DateTime _selectedDate = DateTime.now();
  
  // Mock time entries
  final List<Map<String, dynamic>> _timeEntries = [];
  
  // Helper getters to access data
  Map<String, dynamic>? get selectedProject => 
      mockProjects.firstWhere((p) => p['id'] == _selectedProjectId, orElse: () => <String, dynamic>{});
  
  List<Map<String, dynamic>> get availableTasks {
    if (_selectedProjectId == null) return [];
    final project = mockProjects.firstWhere((p) => p['id'] == _selectedProjectId, orElse: () => <String, dynamic>{});
    return (project['tasks'] as List<Map<String, dynamic>>?) ?? [];
  }
  
  List<Map<String, dynamic>> get availableSubtasks {
    if (_selectedTaskId == null) return [];
    final task = availableTasks.firstWhere((t) => t['id'] == _selectedTaskId, orElse: () => <String, dynamic>{});
    return (task['subtasks'] as List<Map<String, dynamic>>?) ?? [];
  }

  @override
  void dispose() {
    _timer?.cancel();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() {
      _isTimerRunning = !_isTimerRunning;
      if (_isTimerRunning) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() => _elapsedSeconds++);
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _stopTimer() {
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    
    setState(() {
      _isTimerRunning = false;
      _timer?.cancel();
      if (_elapsedSeconds > 0) {
        // Get project, task, and subtask names
        final project = mockProjects.firstWhere((p) => p['id'] == _selectedProjectId);
        String? taskName;
        String? subtaskName;
        
        if (_selectedTaskId != null) {
          final task = (project['tasks'] as List).firstWhere((t) => t['id'] == _selectedTaskId, orElse: () => <String, dynamic>{});
          taskName = task['name'];
          
          if (_selectedSubtaskId != null) {
            final subtask = (task['subtasks'] as List?)?.firstWhere((st) => st['id'] == _selectedSubtaskId, orElse: () => <String, dynamic>{});
            subtaskName = subtask?['name'];
          }
        }
        
        // Save entry
        _timeEntries.add({
          'projectId': _selectedProjectId!,
          'projectName': project['name'],
          'taskId': _selectedTaskId,
          'taskName': taskName,
          'subtaskId': _selectedSubtaskId,
          'subtaskName': subtaskName,
          'description': _descriptionController.text,
          'hours': _elapsedSeconds / 3600,
          'date': _selectedDate,
          'status': 'draft',
        });
        _elapsedSeconds = 0;
        _selectedProjectId = null;
        _selectedTaskId = null;
        _selectedSubtaskId = null;
        _descriptionController.clear();
      }
    });
  }

  String _formatDuration(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE');
    final dayFormat = DateFormat('MMM d');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timer Card - Optimized
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              children: [
                // Timer Display
                Text(
                  _formatDuration(_elapsedSeconds),
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 14),
                
                // Project Dropdown (Required)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.neutral50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedProjectId,
                      hint: Text('Select Project *', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      isExpanded: true,
                      icon: Icon(Icons.unfold_more, size: 20, color: AppColors.textSecondary),
                      items: mockProjects.map((project) {
                        return DropdownMenuItem(
                          value: project['id'] as String,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(project['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              Text(project['client'] as String, style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProjectId = value;
                          // Reset task and subtask when project changes
                          _selectedTaskId = null;
                          _selectedSubtaskId = null;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Task Dropdown (Optional - only shown if project is selected)
                if (_selectedProjectId != null && availableTasks.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedTaskId,
                        hint: Text('Select Task (Optional)', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                        isExpanded: true,
                        icon: Icon(Icons.unfold_more, size: 20, color: AppColors.textSecondary),
                        items: [
                          DropdownMenuItem(
                            value: null, 
                            child: Text('None', style: TextStyle(color: AppColors.textTertiary, fontSize: 13, fontStyle: FontStyle.italic)),
                          ),
                          ...availableTasks.map((task) {
                            return DropdownMenuItem(
                              value: task['id'] as String,
                              child: Text(task['name'] as String, style: const TextStyle(fontSize: 13)),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedTaskId = value;
                            // Reset subtask when task changes
                            _selectedSubtaskId = null;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Subtask Dropdown (Optional - only shown if task is selected)
                if (_selectedTaskId != null && availableSubtasks.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedSubtaskId,
                        hint: Text('Select Subtask (Optional)', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                        isExpanded: true,
                        icon: Icon(Icons.unfold_more, size: 20, color: AppColors.textSecondary),
                        items: [
                          DropdownMenuItem(
                            value: null, 
                            child: Text('None', style: TextStyle(color: AppColors.textTertiary, fontSize: 13, fontStyle: FontStyle.italic)),
                          ),
                          ...availableSubtasks.map((subtask) {
                            return DropdownMenuItem(
                              value: subtask['id'] as String,
                              child: Text(subtask['name'] as String, style: const TextStyle(fontSize: 13)),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSubtaskId = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                
                // Description Field - Compact
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'What are you working on?',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.neutral50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                
                // Timer Controls - Improved
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectedProjectId != null ? _toggleTimer : null,
                        icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow, size: 20),
                        label: Text(_isTimerRunning ? 'Pause' : 'Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTimerRunning ? AppColors.success : AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          disabledBackgroundColor: AppColors.neutral200,
                          disabledForegroundColor: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _elapsedSeconds > 0 ? _stopTimer : null,
                      icon: const Icon(Icons.stop, size: 20),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withOpacity(0.1),
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        disabledBackgroundColor: AppColors.neutral100,
                        disabledForegroundColor: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Day Entries Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                // Status Badge & Day Navigation
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Draft',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        onPressed: () {
                          setState(() {
                            _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Text(
                            dateFormat.format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            dayFormat.format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20),
                        onPressed: () {
                          setState(() {
                            _selectedDate = _selectedDate.add(const Duration(days: 1));
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1, color: AppColors.border),
                
                // Table Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Project / Task',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 60,
                        child: Text(
                          'Hours',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1, color: AppColors.border),
                
                // Time Entries or Empty State
                if (_timeEntries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Text(
                          'No time entries for ${dateFormat.format(_selectedDate)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: const Text('+ Add Project Row'),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _timeEntries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final entry = _timeEntries[index];
                      // Build subtitle based on what's available
                      String? subtitle;
                      if (entry['subtaskName'] != null) {
                        subtitle = '${entry['taskName']} › ${entry['subtaskName']}';
                      } else if (entry['taskName'] != null) {
                        subtitle = entry['taskName'];
                      } else if (entry['description'].toString().isNotEmpty) {
                        subtitle = entry['description'];
                      }
                      
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          entry['projectName'],
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        subtitle: subtitle != null
                            ? Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
                            : null,
                        trailing: Text(
                          '${entry['hours'].toStringAsFixed(1)}h',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      );
                    },
                  ),
                
                // Add Another Row Link
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add another project row'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _timeEntries.isEmpty ? null : () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _timeEntries.isEmpty 
                    ? AppColors.neutral300 
                    : AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.send_outlined),
              label: const Text('Submit for Approval'),
            ),
          ),
        ],
      ),
    );
  }

}

// ============ EXPENSES TAB ============
class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'This Month',
                  value: '\$1,245',
                  icon: Icons.calendar_month,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Pending',
                  value: '\$320',
                  icon: Icons.hourglass_empty,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Billable',
                  value: '\$890',
                  icon: Icons.attach_money,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Recent Expenses
          Text(
            'Recent Expenses',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                _ExpenseListItem(
                  category: 'Software',
                  description: 'Adobe Creative Cloud',
                  amount: 54.99,
                  date: DateTime.now().subtract(const Duration(days: 2)),
                  status: 'pending',
                ),
                const Divider(height: 1, color: AppColors.border),
                _ExpenseListItem(
                  category: 'Travel',
                  description: 'Client meeting - Uber',
                  amount: 28.50,
                  date: DateTime.now().subtract(const Duration(days: 5)),
                  status: 'approved',
                ),
                const Divider(height: 1, color: AppColors.border),
                _ExpenseListItem(
                  category: 'Equipment',
                  description: 'USB-C Hub',
                  amount: 79.00,
                  date: DateTime.now().subtract(const Duration(days: 7)),
                  status: 'approved',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseListItem extends StatelessWidget {
  final String category;
  final String description;
  final double amount;
  final DateTime date;
  final String status;

  const _ExpenseListItem({
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          _getCategoryIcon(category),
          color: AppColors.textSecondary,
          size: 20,
        ),
      ),
      title: Text(
        description,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '$category • ${dateFormat.format(date)}',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            currencyFormat.format(amount),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: status == 'approved' ? AppColors.successLight : AppColors.warningLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: status == 'approved' ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'software': return Icons.computer;
      case 'travel': return Icons.directions_car;
      case 'equipment': return Icons.build;
      case 'meals': return Icons.restaurant;
      default: return Icons.receipt;
    }
  }
}

// ============ APPROVE TAB ============
class _ApproveTab extends StatefulWidget {
  const _ApproveTab();

  @override
  State<_ApproveTab> createState() => _ApproveTabState();
}

class _ApproveTabState extends State<_ApproveTab> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(2026, 1, 1),
    end: DateTime(2026, 1, 31),
  );

  // Mock pending entries grouped by project
  final List<Map<String, dynamic>> _pendingEntries = [
    {
      'project': 'Virtual Tour Production',
      'entries': [
        {
          'id': '1',
          'user': 'Barzan Rahimi',
          'task': 'Tour editing and enhancements',
          'date': DateTime(2026, 1, 10),
          'hours': 4.0,
          'selected': false,
        },
        {
          'id': '2',
          'user': 'Barzan Rahimi',
          'task': 'Property 2 - Matterport scan',
          'date': DateTime(2026, 1, 6),
          'hours': 3.5,
          'selected': false,
        },
      ],
    },
    {
      'project': 'E-commerce Website Redesign',
      'entries': [
        {
          'id': '3',
          'user': 'Barzan Rahimi',
          'task': 'Visual Design System',
          'date': DateTime(2026, 1, 6),
          'hours': 8.0,
          'selected': false,
        },
      ],
    },
  ];

  double _getProjectTotal(List<dynamic> entries) {
    return entries.fold(0.0, (sum, e) => sum + (e['hours'] as double));
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Approvals',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // Date Range Picker
          GestureDetector(
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
                initialDateRange: _dateRange,
              );
              if (picked != null) {
                setState(() => _dateRange = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    '${dateFormat.format(_dateRange.start)} - ${dateFormat.format(_dateRange.end)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Pending Time Entries
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Pending Time Entries',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                
                // Project Groups
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pendingEntries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, projectIndex) {
                    final project = _pendingEntries[projectIndex];
                    final entries = project['entries'] as List<dynamic>;
                    final total = _getProjectTotal(entries);
                    
                    return Column(
                      children: [
                        // Project Header
                        ListTile(
                          leading: Checkbox(
                            value: entries.every((e) => e['selected'] == true),
                            onChanged: (value) {
                              setState(() {
                                for (var entry in entries) {
                                  entry['selected'] = value;
                                }
                              });
                            },
                            activeColor: AppColors.accent,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  project['project'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '(${entries.length})',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            'Total: ${total}h',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        
                        // Individual Entries
                        ...entries.map((entry) => _PendingEntryTile(
                          entry: entry,
                          onChanged: (value) {
                            setState(() => entry['selected'] = value);
                          },
                        )),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Pending Expenses
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Pending Expenses',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No pending expenses for this period',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
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

class _PendingEntryTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  final ValueChanged<bool?> onChanged;

  const _PendingEntryTile({required this.entry, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');
    
    return Container(
      color: AppColors.neutral50,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 56, right: 16),
        leading: Checkbox(
          value: entry['selected'] ?? false,
          onChanged: onChanged,
          activeColor: AppColors.accent,
        ),
        title: Text(
          entry['user'],
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry['task'],
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${dateFormat.format(entry['date'])} • ${entry['hours']}h',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ HISTORY TAB ============
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search history...',
                      hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // History List
          Text(
            'January 2026',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                _HistoryItem(
                  type: 'time',
                  description: 'Week of Jan 6-12 approved',
                  amount: '32.5h',
                  date: DateTime(2026, 1, 13),
                  status: 'approved',
                ),
                const Divider(height: 1, color: AppColors.border),
                _HistoryItem(
                  type: 'expense',
                  description: 'Adobe Creative Cloud',
                  amount: '\$54.99',
                  date: DateTime(2026, 1, 10),
                  status: 'approved',
                ),
                const Divider(height: 1, color: AppColors.border),
                _HistoryItem(
                  type: 'time',
                  description: 'Week of Dec 30 - Jan 5',
                  amount: '28.0h',
                  date: DateTime(2026, 1, 6),
                  status: 'approved',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String type;
  final String description;
  final String amount;
  final DateTime date;
  final String status;

  const _HistoryItem({
    required this.type,
    required this.description,
    required this.amount,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: type == 'time' ? AppColors.accent.withOpacity(0.1) : AppColors.info.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          type == 'time' ? Icons.access_time : Icons.receipt_long,
          color: type == 'time' ? AppColors.accent : AppColors.info,
          size: 20,
        ),
      ),
      title: Text(
        description,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        dateFormat.format(date),
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            amount,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ MODALS ============
class _AddTimeEntryModal extends StatelessWidget {
  const _AddTimeEntryModal();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Time Entry',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              // Form fields would go here
              const Text('Project, Task, Hours, Date, Notes fields...'),
            ],
          ),
        );
      },
    );
  }
}

class _AddExpenseModal extends StatelessWidget {
  const _AddExpenseModal();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Expense',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              const Text('Category, Amount, Date, Receipt upload, Notes...'),
            ],
          ),
        );
      },
    );
  }
}

class _AddServiceDialog extends StatefulWidget {
  const _AddServiceDialog();

  @override
  State<_AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends State<_AddServiceDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rateController = TextEditingController(text: '150.00');
  final _unitController = TextEditingController(text: 'hour');
  String _category = 'Other';
  String _pricingType = 'Hourly Rate';
  bool _isActive = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Service',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Service Name
              const Text(
                'Service Name *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g., 3D Laser Scanning',
                  filled: true,
                  fillColor: AppColors.neutral50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Description
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Brief description of the service...',
                  filled: true,
                  fillColor: AppColors.neutral50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Category
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.neutral50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    icon: const Icon(Icons.unfold_more, size: 20),
                    items: ['Design', 'Development', 'Consulting', 'Photography', 'Other']
                        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                        .toList(),
                    onChanged: (value) => setState(() => _category = value!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Pricing Type
              const Text(
                'Pricing Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.neutral50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _pricingType,
                    isExpanded: true,
                    icon: const Icon(Icons.unfold_more, size: 20),
                    items: ['Hourly Rate', 'Fixed Price', 'Per Unit']
                        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                        .toList(),
                    onChanged: (value) => setState(() => _pricingType = value!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Rate
              const Text(
                'Rate (\$)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _rateController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.neutral50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Unit Label
              const Text(
                'Unit Label',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _unitController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.neutral50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Active Toggle
              Row(
                children: [
                  Switch(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    activeColor: AppColors.accent,
                  ),
                  const Text('Active'),
                ],
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Save service
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Create Service'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
