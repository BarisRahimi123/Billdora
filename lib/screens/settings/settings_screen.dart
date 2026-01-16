import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    authProvider.userName.isNotEmpty
                        ? authProvider.userName.substring(0, 1).toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 24,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authProvider.userName.isNotEmpty ? authProvider.userName : 'User',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        authProvider.userEmail,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: Edit profile
                  },
                ),
              ],
            ),
          ),
          const Divider(),

          // Account Section
          _buildSectionHeader(context, 'Account'),
          _buildSettingsTile(
            context,
            Icons.business,
            'Company Profile',
            'Manage your business info',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            Icons.credit_card,
            'Subscription',
            'Manage your plan',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            Icons.receipt,
            'Invoice Templates',
            'Customize your invoices',
            onTap: () {},
          ),
          const Divider(),

          // Preferences Section
          _buildSectionHeader(context, 'Preferences'),
          _buildSettingsTile(
            context,
            Icons.notifications_outlined,
            'Notifications',
            'Configure alerts',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            Icons.palette_outlined,
            'Appearance',
            'Theme and display',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            Icons.language,
            'Language',
            'English (US)',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            Icons.attach_money,
            'Currency',
            'USD (\$)',
            onTap: () {},
          ),
          const Divider(),

          // Integrations Section
          _buildSectionHeader(context, 'Integrations'),
          _buildSettingsTile(
            context,
            Icons.account_balance,
            'Bank Connections',
            'Link your bank accounts',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            Icons.payment,
            'Payment Methods',
            'Stripe, PayPal',
            onTap: () {},
          ),
          const Divider(),

          // Support Section
          _buildSectionHeader(context, 'Support'),
          _buildSettingsTile(
            context,
            Icons.help_outline,
            'Help Center',
            'FAQs and guides',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            Icons.chat_outlined,
            'Contact Support',
            'Get help from our team',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            Icons.description_outlined,
            'Terms & Privacy',
            'Legal information',
            onTap: () {},
          ),
          const Divider(),

          // Sign Out
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () async {
                await authProvider.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              icon: Icon(Icons.logout, color: colorScheme.error),
              label: Text('Sign Out', style: TextStyle(color: colorScheme.error)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Version
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
