import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../main.dart';
import '../shell/app_header.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _searchQuery = '';
  String _viewMode = 'list'; // list or grid
  final Set<String> _expandedGroups = {};

  // Mock data - projects grouped by client
  final List<Map<String, dynamic>> _projectGroups = [
    {
      'client': 'Barzan Shop',
      'clientId': 'c1',
      'projects': [
        {'id': 'p1', 'name': 'Website Redesign', 'description': 'Complete website overhaul', 'status': 'active', 'budget': 5000.0},
        {'id': 'p2', 'name': 'Mobile App', 'description': 'iOS and Android app development', 'status': 'active', 'budget': 8000.0},
        {'id': 'p3', 'name': 'SEO Optimization', 'description': 'Search engine optimization', 'status': 'completed', 'budget': 2000.0},
        {'id': 'p4', 'name': 'Logo Design', 'description': 'Brand identity refresh', 'status': 'active', 'budget': 1500.0},
        {'id': 'p5', 'name': 'Social Media Setup', 'description': 'Social media presence', 'status': 'completed', 'budget': 800.0},
        {'id': 'p6', 'name': 'Email Marketing', 'description': 'Email campaign setup', 'status': 'on-hold', 'budget': 1200.0},
        {'id': 'p7', 'name': 'Analytics Dashboard', 'description': 'Custom analytics solution', 'status': 'active', 'budget': 3500.0},
      ],
    },
    {
      'client': 'Sequoia Consulting',
      'clientId': 'c2',
      'projects': [
        {'id': 'p8', 'name': 'SAGECREST', 'description': 'TSM Map - TENTATIVE SUBDIVISION MAP', 'status': 'active', 'budget': 2000.0},
      ],
    },
    {
      'client': 'Unassigned',
      'clientId': null,
      'projects': [
        {'id': 'p9', 'name': 'Internal Tool', 'description': 'Internal productivity tool', 'status': 'active', 'budget': 0.0},
        {'id': 'p10', 'name': 'Template Library', 'description': 'Reusable design templates', 'status': 'active', 'budget': 0.0},
        {'id': 'p11', 'name': 'Training Materials', 'description': 'Team training resources', 'status': 'completed', 'budget': 0.0},
      ],
    },
  ];

  List<Map<String, dynamic>> get _filteredGroups {
    if (_searchQuery.isEmpty) return _projectGroups;
    
    return _projectGroups.map((group) {
      final filteredProjects = (group['projects'] as List<Map<String, dynamic>>)
          .where((p) =>
              p['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p['description'].toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
      
      if (filteredProjects.isEmpty) return null;
      
      return {...group, 'projects': filteredProjects};
    }).whereType<Map<String, dynamic>>().toList();
  }

  // Get all projects as a flat list (not grouped)
  List<Map<String, dynamic>> get _allProjects {
    final allProjects = <Map<String, dynamic>>[];
    for (final group in _projectGroups) {
      final projects = group['projects'] as List<Map<String, dynamic>>;
      for (final project in projects) {
        allProjects.add({
          ...project,
          'client': group['client'],
          'clientId': group['clientId'],
        });
      }
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      return allProjects
          .where((p) =>
              p['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p['description'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p['client'].toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    
    return allProjects;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Header with Hamburger Menu
            const AppHeader(showSearch: true),

            // Title and Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Projects',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showNewProjectModal(),
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
                            'New',
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
            ),

            // Search and Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search projects...',
                          hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildViewToggle(),
                  const SizedBox(width: 8),
                  _buildMenuButton(),
                ],
              ),
            ),

            // Project Display
            Expanded(
              child: _viewMode == 'list' 
                  ? _buildGroupedView() 
                  : _buildGridView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildViewButton(Icons.view_list, 'list'),
          _buildViewButton(Icons.grid_view, 'grid'),
        ],
      ),
    );
  }

  Widget _buildViewButton(IconData icon, String mode) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neutral100 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: isSelected ? AppColors.textPrimary : AppColors.textSecondary),
      ),
    );
  }

  Widget _buildMenuButton() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
    );
  }

  // Grouped view (by client)
  Widget _buildGroupedView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredGroups.length,
      itemBuilder: (context, index) {
        final group = _filteredGroups[index];
        return _buildProjectGroup(group);
      },
    );
  }

  // Grid view (all projects)
  Widget _buildGridView() {
    final projects = _allProjects;
    
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_outlined, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No projects found',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _buildFlatProjectCard(project);
      },
    );
  }

  Widget _buildFlatProjectCard(Map<String, dynamic> project) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: ListTile(
        onTap: () => context.push('/projects/${project['id']}'),
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getStatusColor(project['status']).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.folder_outlined,
            color: _getStatusColor(project['status']),
            size: 24,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project['name'],
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.business_outlined, size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  project['client'] ?? 'Unassigned',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              _buildStatusChip(project['status']),
              const SizedBox(width: 8),
              if (project['budget'] > 0)
                Text(
                  currencyFormat.format(project['budget']),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'completed':
        return AppColors.info;
      case 'on-hold':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  Widget _buildProjectGroup(Map<String, dynamic> group) {
    final client = group['client'] as String;
    final projects = group['projects'] as List<Map<String, dynamic>>;
    final isExpanded = _expandedGroups.contains(client);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          // Group Header
          ListTile(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedGroups.remove(client);
                } else {
                  _expandedGroups.add(client);
                }
              });
            },
            leading: Icon(
              isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
            title: Row(
              children: [
                Text(
                  client,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Text(
                  '(${projects.length} projects)',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Expanded Projects
          if (isExpanded) ...[
            const Divider(height: 1, color: AppColors.border),
            ...projects.map((project) => _buildProjectItem(project)),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectItem(Map<String, dynamic> project) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    
    return Container(
      color: AppColors.neutral50,
      child: ListTile(
        onTap: () => context.push('/projects/${project['id']}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.neutral200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              project['name'][0].toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        title: Text(
          project['name'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          project['description'],
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusBadge(project['status']),
            const SizedBox(width: 12),
            Text(
              currencyFormat.format(project['budget']),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'active': color = AppColors.success; break;
      case 'completed': color = AppColors.info; break;
      case 'on-hold': color = AppColors.warning; break;
      default: color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showNewProjectModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _NewProjectModal(),
    );
  }
}

class _NewProjectModal extends StatelessWidget {
  const _NewProjectModal();

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
              const Text('New Project', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              _buildTextField('Project Name *', 'Enter project name'),
              const SizedBox(height: 16),
              _buildDropdown('Client', ['Barzan Shop', 'Sequoia Consulting', 'None']),
              const SizedBox(height: 16),
              _buildTextField('Budget', '\$0.00'),
              const SizedBox(height: 16),
              _buildTextField('Description', 'Project description...', maxLines: 3),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Create Project'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.neutral50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.first,
              isExpanded: true,
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
              onChanged: (_) {},
            ),
          ),
        ),
      ],
    );
  }
}
