import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../main.dart';
import '../shell/app_header.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  String _searchQuery = '';
  String? _selectedStaffId;

  // Mock data
  final List<Map<String, dynamic>> _staff = [];

  List<Map<String, dynamic>> get _filteredStaff {
    if (_searchQuery.isEmpty) return _staff;
    return _staff.where((s) => 
      s['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
      s['email'].toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
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
            const AppHeader(showSearch: false),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Team', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Manage staff members and their assignments', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildActionButton(Icons.send_outlined, false, () {}),
                  const SizedBox(width: 8),
                  _buildActionButton(Icons.add, true, () => _showAddStaffModal()),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search and List
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.neutral50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextField(
                                onChanged: (value) => setState(() => _searchQuery = value),
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Checkbox(
                            value: false,
                            onChanged: (_) {},
                            activeColor: AppColors.accent,
                          ),
                          Text('No staff found', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),

                    // Staff List or Empty State
                    Expanded(
                      child: _filteredStaff.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 64, color: AppColors.textTertiary),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Select a staff member to view details',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredStaff.length,
                              itemBuilder: (context, index) {
                                final staff = _filteredStaff[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.accent.withOpacity(0.1),
                                    child: Text(
                                      staff['name'][0],
                                      style: const TextStyle(color: AppColors.accent),
                                    ),
                                  ),
                                  title: Text(staff['name']),
                                  subtitle: Text(staff['role'] ?? staff['email']),
                                  selected: _selectedStaffId == staff['id'],
                                  onTap: () => setState(() => _selectedStaffId = staff['id']),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, bool isPrimary, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.accent : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: isPrimary ? null : Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 20, color: isPrimary ? Colors.white : AppColors.textSecondary),
      ),
    );
  }

  void _showAddStaffModal() {
    showDialog(
      context: context,
      builder: (context) => const _AddStaffModal(),
    );
  }
}

class _AddStaffModal extends StatefulWidget {
  const _AddStaffModal();

  @override
  State<_AddStaffModal> createState() => _AddStaffModalState();
}

class _AddStaffModalState extends State<_AddStaffModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Personal Info
  String _fullName = '';
  String _email = '';
  String _phone = '';
  DateTime? _dateOfBirth;
  String _address = '';
  String _city = '';
  String _state = '';
  String _zipCode = '';

  // Employment
  String _employeeId = '';
  DateTime? _hireDate;
  String _jobTitle = '';
  String _department = '';
  String _role = 'Staff';
  String _employmentType = 'Full-time';
  String _reportsTo = '';
  String _workLocation = '';

  // Emergency Contact
  String _emergencyName = '';
  String _relationship = '';
  String _emergencyPhone = '';
  String _emergencyEmail = '';

  final List<String> _roles = ['Staff', 'Admin', 'Manager', 'Contractor'];
  final List<String> _employmentTypes = ['Full-time', 'Part-time', 'Contract', 'Freelance'];
  final List<String> _relationships = ['Parent', 'Spouse', 'Sibling', 'Friend', 'Other'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Staff Member', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.accent,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Personal Info'),
                Tab(text: 'Employment'),
                Tab(text: 'Emergency Contact'),
              ],
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPersonalInfoTab(),
                  _buildEmploymentTab(),
                  _buildEmergencyContactTab(),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Add Staff'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField('Full Name *', 'Enter full name', (v) => _fullName = v),
          const SizedBox(height: 16),
          _buildTextField('Email *', 'user@email.com', (v) => _email = v, helper: "Staff member's email address"),
          const SizedBox(height: 16),
          _buildTextField('Phone', '(555) 123-4567', (v) => _phone = v),
          const SizedBox(height: 16),
          _buildDateField('Date of Birth', _dateOfBirth, (d) => setState(() => _dateOfBirth = d)),
          const SizedBox(height: 16),
          _buildTextField('Address', '123 Main Street', (v) => _address = v),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField('City', '', (v) => _city = v)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('State', '', (v) => _state = v)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Zip Code', '', (v) => _zipCode = v)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmploymentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField('Employee ID', 'EMP-001', (v) => _employeeId = v),
          const SizedBox(height: 16),
          _buildDateField('Hire Date', _hireDate, (d) => setState(() => _hireDate = d)),
          const SizedBox(height: 16),
          _buildTextField('Job Title', 'Senior Developer', (v) => _jobTitle = v),
          const SizedBox(height: 16),
          _buildTextField('Department', 'Engineering', (v) => _department = v),
          const SizedBox(height: 16),
          _buildDropdownField('Role', _role, _roles, (v) => setState(() => _role = v!)),
          const SizedBox(height: 16),
          _buildDropdownField('Employment Type', _employmentType, _employmentTypes, (v) => setState(() => _employmentType = v!)),
          const SizedBox(height: 16),
          _buildTextField('Reports To', 'Manager Name', (v) => _reportsTo = v),
          const SizedBox(height: 16),
          _buildTextField('Work Location', 'Remote / Office', (v) => _workLocation = v),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Provide emergency contact information for this staff member.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          _buildTextField('Contact Name', 'John Doe', (v) => _emergencyName = v),
          const SizedBox(height: 16),
          _buildDropdownField('Relationship', _relationship.isEmpty ? null : _relationship, _relationships, (v) => setState(() => _relationship = v ?? '')),
          const SizedBox(height: 16),
          _buildTextField('Phone', '(555) 123-4567', (v) => _emergencyPhone = v),
          const SizedBox(height: 16),
          _buildTextField('Email', 'contact@email.com', (v) => _emergencyEmail = v),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, Function(String) onChanged, {String? helper}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.neutral50,
          ),
          onChanged: onChanged,
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(helper, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? date, Function(DateTime) onChanged) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );
            if (pickedDate != null) onChanged(pickedDate);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              date != null ? dateFormat.format(date) : 'Select date',
              style: TextStyle(color: date != null ? AppColors.textPrimary : AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: const Text('Select...'),
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
