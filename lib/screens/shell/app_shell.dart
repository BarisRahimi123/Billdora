import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../providers/auth_provider.dart';

// Global key to access the scaffold from anywhere
final GlobalKey<ScaffoldState> appScaffoldKey = GlobalKey<ScaffoldState>();

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appScaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
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
                  icon: Icons.trending_up_rounded,
                  label: 'Sales',
                  isSelected: _isSelected(context, '/sales'),
                  onTap: () => context.go('/sales'),
                ),
                _NavItem(
                  icon: Icons.schedule_rounded,
                  label: 'Time',
                  isSelected: _isSelected(context, '/time'),
                  onTap: () => context.go('/time'),
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
    if (path == '/sales') return location.startsWith('/sales') || location.startsWith('/invoices') || location.startsWith('/clients');
    if (path == '/time') return location.startsWith('/expenses') || location.startsWith('/time');
    return location.startsWith(path);
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Drawer(
      backgroundColor: AppColors.accent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo/Brand
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Billdora',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Navigation Items
            Expanded(
              child: Column(
                children: [
                  _DrawerItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Dashboard',
                    isSelected: location.startsWith('/dashboard'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/dashboard');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.people_outline,
                    label: 'Sales',
                    isSelected: location.startsWith('/sales'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/sales');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.folder_outlined,
                    label: 'Projects',
                    isSelected: location.startsWith('/projects'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/projects');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.access_time,
                    label: 'Time',
                    isSelected: location.startsWith('/time'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/time');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.description_outlined,
                    label: 'Invoicing',
                    isSelected: location.startsWith('/invoices'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/invoices');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.group_outlined,
                    label: 'Team',
                    isSelected: location.startsWith('/team'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/team');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Expenses',
                    isSelected: location.startsWith('/expenses'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/expenses');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.bar_chart_outlined,
                    label: 'Financials',
                    isSelected: location.startsWith('/reports'),
                    hasSubmenu: true,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/reports');
                    },
                  ),
                ],
              ),
            ),

            // Bottom Items
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    isSelected: location.startsWith('/settings'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/settings');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.logout,
                    label: 'Sign Out',
                    isSelected: false,
                    onTap: () async {
                      Navigator.pop(context);
                      await context.read<AuthProvider>().signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool hasSubmenu;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.hasSubmenu = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: Colors.white.withOpacity(isSelected ? 1.0 : 0.8),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(isSelected ? 1.0 : 0.8),
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (hasSubmenu)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.white.withOpacity(0.6),
              ),
          ],
        ),
      ),
    );
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
          color: isSelected ? AppColors.accent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
