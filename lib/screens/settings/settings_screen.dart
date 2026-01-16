import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../shell/app_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock profile data
  final Map<String, dynamic> _profile = {
    'fullName': 'Baris Rahimi',
    'phone': '5128396700',
    'email': 'baris@plansrow.com',
    'dateOfBirth': DateTime(1985, 12, 26),
    'streetAddress': '2469 N Pearwood Ave',
    'city': 'Fresno',
    'state': 'Ca',
    'zipCode': '93727',
    'emergencyContactName': '',
    'emergencyPhone': '',
    'emergencyRelationship': '',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
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
                  Text('Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Manage your account and company preferences', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),

            // Icon Tabs
            Container(
              height: 50,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.accent,
                labelColor: AppColors.accent,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(icon: Icon(Icons.person_outline, size: 20)),
                  Tab(icon: Icon(Icons.business_outlined, size: 20)),
                  Tab(icon: Icon(Icons.credit_card_outlined, size: 20)),
                  Tab(icon: Icon(Icons.people_outline, size: 20)),
                  Tab(icon: Icon(Icons.design_services_outlined, size: 20)),
                  Tab(icon: Icon(Icons.sell_outlined, size: 20)),
                  Tab(icon: Icon(Icons.group_outlined, size: 20)),
                  Tab(icon: Icon(Icons.description_outlined, size: 20)),
                  Tab(icon: Icon(Icons.notifications_outlined, size: 20)),
                  Tab(icon: Icon(Icons.link_outlined, size: 20)),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileTab(),
                  _buildPlaceholderTab('Company', 'Company settings and branding'),
                  _buildPlaceholderTab('Billing', 'Subscription and payment methods'),
                  _buildPlaceholderTab('Team', 'Team member permissions'),
                  _buildPlaceholderTab('Services', 'Services and rate configuration'),
                  _buildPlaceholderTab('Tags', 'Project and invoice tags'),
                  _buildPlaceholderTab('Clients', 'Client defaults and settings'),
                  _buildPlaceholderTab('Documents', 'Document templates'),
                  _buildPlaceholderTab('Notifications', 'Email and push notification settings'),
                  _buildPlaceholderTab('Integrations', 'Third-party integrations'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),

            // Basic Information
            const Text('BASIC INFORMATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 16),
            _buildEditableField('Full Name', _profile['fullName']),
            const SizedBox(height: 16),
            _buildEditableField('Phone Number', _profile['phone']),
            const SizedBox(height: 16),
            _buildEditableField('Email', _profile['email'], enabled: false),
            const SizedBox(height: 16),
            _buildDateDisplayField('Date of Birth', _profile['dateOfBirth']),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Address
            const Text('ADDRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 16),
            _buildEditableField('Street Address', _profile['streetAddress']),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildEditableField('City', _profile['city'])),
                const SizedBox(width: 12),
                Expanded(child: _buildEditableField('State', _profile['state'])),
                const SizedBox(width: 12),
                Expanded(child: _buildEditableField('Zip Code', _profile['zipCode'])),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Emergency Contact
            const Text('EMERGENCY CONTACT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 16),
            _buildEditableField('Contact Name', _profile['emergencyContactName'], hint: 'Enter contact name'),
            const SizedBox(height: 16),
            _buildEditableField('Phone', _profile['emergencyPhone'], hint: 'Enter phone number'),
            const SizedBox(height: 16),
            _buildEditableField('Relationship', _profile['emergencyRelationship'], hint: 'Select relationship'),
            const SizedBox(height: 32),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, String value, {bool enabled = true, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: enabled ? AppColors.neutral50 : AppColors.neutral100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value.isNotEmpty ? value : (hint ?? ''),
                  style: TextStyle(
                    color: value.isNotEmpty ? (enabled ? AppColors.textPrimary : AppColors.textSecondary) : AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateDisplayField(String label, DateTime date) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(child: Text(dateFormat.format(date))),
        ),
      ],
    );
  }

  Widget _buildPlaceholderTab(String title, String subtitle) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Icon(Icons.construction_outlined, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            const Text('Coming soon...', style: TextStyle(color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}
