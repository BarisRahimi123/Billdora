import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../providers/permissions_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/sales_provider.dart';
import '../shell/app_header.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _searchQuery = '';
  String _viewMode = 'list';
  final Set<String> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (auth.companyId != null) {
      context.read<ProjectsProvider>().loadProjects(auth.companyId!);
      // Also load clients for the create modal
      context.read<SalesProvider>().loadClients();
    }
  }

  // Group projects by client
  List<Map<String, dynamic>> _getGroupedProjects(List<Map<String, dynamic>> projects) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (final project in projects) {
      final clientName = project['clients']?['name'] ?? 'Unassigned';
      grouped.putIfAbsent(clientName, () => []);
      grouped[clientName]!.add(project);
    }
    
    return grouped.entries.map((e) => {
      'client': e.key,
      'clientId': e.value.first['client_id'],
      'projects': e.value,
    }).toList();
  }

  List<Map<String, dynamic>> _filterProjects(List<Map<String, dynamic>> projects) {
    if (_searchQuery.isEmpty) return projects;
    return projects.where((p) =>
      (p['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (p['description'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final projectsProvider = context.watch<ProjectsProvider>();
    final permissions = context.watch<PermissionsProvider>();
    final filteredProjects = _filterProjects(projectsProvider.projects);
    final groupedProjects = _getGroupedProjects(filteredProjects);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(showSearch: false),

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

            // Content
            Expanded(
              child: projectsProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : projectsProvider.errorMessage != null
                      ? Center(child: Text('Error: ${projectsProvider.errorMessage}'))
                      : filteredProjects.isEmpty
                          ? _buildEmptyState()
                          : _viewMode == 'list'
                              ? _buildGroupedView(groupedProjects, permissions)
                              : _buildGridView(filteredProjects, permissions),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showNewProjectModal(),
            child: const Text('Create your first project'),
          ),
        ],
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

  Widget _buildGroupedView(List<Map<String, dynamic>> groups, PermissionsProvider permissions) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        return _buildProjectGroup(groups[index], permissions);
      },
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> projects, PermissionsProvider permissions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _buildFlatProjectCard(project, permissions);
      },
    );
  }

  Widget _buildFlatProjectCard(Map<String, dynamic> project, PermissionsProvider permissions) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final status = project['status'] ?? 'active';
    final budget = (project['budget'] as num?)?.toDouble() ?? 0.0;
    final clientName = project['clients']?['name'] ?? 'Unassigned';

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
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.folder_outlined,
            color: _getStatusColor(status),
            size: 24,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project['name'] ?? '',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.business_outlined, size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  clientName,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              _buildStatusChip(status),
              const SizedBox(width: 8),
              if (permissions.canViewClientValues && budget > 0)
                Text(
                  currencyFormat.format(budget),
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
      case 'active': return AppColors.success;
      case 'completed': return AppColors.info;
      case 'on-hold': return AppColors.warning;
      default: return AppColors.textSecondary;
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

  Widget _buildProjectGroup(Map<String, dynamic> group, PermissionsProvider permissions) {
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
                Text(client, style: const TextStyle(fontWeight: FontWeight.w600)),
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
          if (isExpanded) ...[
            const Divider(height: 1, color: AppColors.border),
            ...projects.map((project) => _buildProjectItem(project, permissions)),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectItem(Map<String, dynamic> project, PermissionsProvider permissions) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final status = project['status'] ?? 'active';
    final budget = (project['budget'] as num?)?.toDouble() ?? 0.0;

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
              (project['name'] ?? 'P')[0].toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        title: Text(
          project['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          project['description'] ?? '',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusBadge(status),
            if (permissions.canViewClientValues) ...[
              const SizedBox(width: 12),
              Text(
                currencyFormat.format(budget),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(status),
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

class _NewProjectModal extends StatefulWidget {
  const _NewProjectModal();

  @override
  State<_NewProjectModal> createState() => _NewProjectModalState();
}

class _NewProjectModalState extends State<_NewProjectModal> {
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedClientId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    final projectData = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'budget': double.tryParse(_budgetController.text) ?? 0.0,
      'client_id': _selectedClientId,
      'status': 'active',
    };

    await context.read<ProjectsProvider>().addProject(projectData);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = context.watch<SalesProvider>().clients;
    final permissions = context.watch<PermissionsProvider>();

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
              _buildTextField('Project Name *', 'Enter project name', _nameController),
              const SizedBox(height: 16),
              _buildClientDropdown(clients),
              const SizedBox(height: 16),
              if (permissions.canViewClientValues)
                _buildTextField('Budget', '\$0.00', _budgetController),
              if (permissions.canViewClientValues)
                const SizedBox(height: 16),
              _buildTextField('Description', 'Project description...', _descriptionController, maxLines: 3),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _createProject,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Project'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
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

  Widget _buildClientDropdown(List<Map<String, dynamic>> clients) {
    final options = [
      {'id': null, 'name': 'None (Unassigned)'},
      ...clients,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Client', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedClientId,
              isExpanded: true,
              hint: const Text('Select client'),
              items: options.map((c) => DropdownMenuItem(
                value: c['id'] as String?,
                child: Text(c['name'] ?? 'Unknown'),
              )).toList(),
              onChanged: (value) => setState(() => _selectedClientId = value),
            ),
          ),
        ),
      ],
    );
  }
}
