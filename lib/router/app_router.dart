import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/invoices/invoices_screen.dart';
import '../screens/invoices/invoice_detail_screen.dart';
import '../screens/invoices/create_invoice_screen.dart';
import '../screens/clients/clients_screen.dart';
import '../screens/projects/projects_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/receipts/receipts_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/shell/app_shell.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final isLoggedIn = authProvider.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/signup' ||
                          state.matchedLocation == '/forgot-password';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      
      // Main App Shell with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/invoices',
            builder: (context, state) => const InvoicesScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateInvoiceScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => InvoiceDetailScreen(
                  invoiceId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/clients',
            builder: (context, state) => const ClientsScreen(),
          ),
          GoRoute(
            path: '/projects',
            builder: (context, state) => const ProjectsScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpensesScreen(),
          ),
          GoRoute(
            path: '/receipts',
            builder: (context, state) => const ReceiptsScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
