import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Dashboard',
                  isSelected: _isSelected(context, '/dashboard'),
                  onTap: () => context.go('/dashboard'),
                ),
                _NavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Sales',
                  isSelected: _isSelected(context, '/invoices'),
                  onTap: () => context.go('/invoices'),
                ),
                _NavItem(
                  icon: Icons.timer_outlined,
                  label: 'Time',
                  isSelected: _isSelected(context, '/time'),
                  onTap: () => context.go('/projects'), // Placeholder
                ),
                _NavItem(
                  icon: Icons.folder_outlined,
                  label: 'Projects',
                  isSelected: _isSelected(context, '/projects'),
                  onTap: () => context.go('/projects'),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Me',
                  isSelected: _isSelected(context, '/settings'),
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isSelected(BuildContext context, String path) {
    final location = GoRouterState.of(context).matchedLocation;
    if (path == '/dashboard') return location.startsWith('/dashboard') || location == '/';
    return location.startsWith(path);
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.blue : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.blue : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
