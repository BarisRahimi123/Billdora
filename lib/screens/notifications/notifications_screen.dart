import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../main.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  // Demo data
  List<Map<String, dynamic>> get _demoNotifications => [
    {'id': '1', 'type': 'invoice_paid', 'title': 'Invoice Paid', 'message': 'Invoice #INV-2024001 was paid by Acme Corp', 'time': DateTime.now().subtract(const Duration(minutes: 15)), 'read': false},
    {'id': '2', 'type': 'invoice_overdue', 'title': 'Invoice Overdue', 'message': 'Invoice #INV-2024015 is now 7 days overdue', 'time': DateTime.now().subtract(const Duration(hours: 2)), 'read': false},
    {'id': '3', 'type': 'new_client', 'title': 'New Client Added', 'message': 'TechStart Inc has been added to your clients', 'time': DateTime.now().subtract(const Duration(hours: 5)), 'read': true},
    {'id': '4', 'type': 'project_update', 'title': 'Project Milestone', 'message': 'Website Redesign reached 75% completion', 'time': DateTime.now().subtract(const Duration(days: 1)), 'read': true},
    {'id': '5', 'type': 'payment_reminder', 'title': 'Payment Reminder Sent', 'message': 'Reminder sent for Invoice #INV-2024008', 'time': DateTime.now().subtract(const Duration(days: 2)), 'read': true},
    {'id': '6', 'type': 'invoice_sent', 'title': 'Invoice Sent', 'message': 'Invoice #INV-2024020 sent to Design Studio Co', 'time': DateTime.now().subtract(const Duration(days: 3)), 'read': true},
  ];

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_filter == 'all') return _demoNotifications;
    if (_filter == 'unread') return _demoNotifications.where((n) => n['read'] == false).toList();
    return _demoNotifications;
  }

  int get _unreadCount => _demoNotifications.where((n) => n['read'] == false).length;

  IconData _getIcon(String type) {
    switch (type) {
      case 'invoice_paid': return Icons.check_circle;
      case 'invoice_overdue': return Icons.warning_amber;
      case 'new_client': return Icons.person_add;
      case 'project_update': return Icons.folder;
      case 'payment_reminder': return Icons.notifications;
      case 'invoice_sent': return Icons.send;
      default: return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'invoice_paid': return AppColors.green;
      case 'invoice_overdue': return AppColors.red;
      case 'new_client': return AppColors.blue;
      case 'project_update': return AppColors.purple;
      case 'payment_reminder': return AppColors.orange;
      case 'invoice_sent': return AppColors.info;
      default: return AppColors.blue;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Notifications', style: Theme.of(context).textTheme.headlineMedium),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: () {
                // Mark all as read
              },
              child: const Text('Mark all read', style: TextStyle(color: AppColors.blue)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _FilterTab(label: 'All', isSelected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 12),
                _FilterTab(label: 'Unread', isSelected: _filter == 'unread', badge: _unreadCount, onTap: () => setState(() => _filter = 'unread')),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
                : _filteredNotifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppColors.blue,
                        backgroundColor: AppColors.cardBackground,
                        onRefresh: _loadNotifications,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = _filteredNotifications[index];
                            return _NotificationCard(
                              notification: notification,
                              icon: _getIcon(notification['type'] as String),
                              color: _getColor(notification['type'] as String),
                              timeAgo: _formatTime(notification['time'] as DateTime),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.notifications_none, size: 40, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text('No notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('You\'re all caught up!', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int? badge;
  final VoidCallback onTap;

  const _FilterTab({required this.label, required this.isSelected, this.badge, required this.onTap});

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : AppColors.textSecondary)),
            if (badge != null && badge! > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$badge', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final IconData icon;
  final Color color;
  final String timeAgo;

  const _NotificationCard({required this.notification, required this.icon, required this.color, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    final isUnread = notification['read'] == false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread ? color.withOpacity(0.05) : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUnread ? color.withOpacity(0.2) : AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['message'] as String,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeAgo,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
