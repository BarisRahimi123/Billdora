import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

/// Permission categories matching the database schema
class Permissions {
  final Map<String, dynamic> projects;
  final Map<String, dynamic> tasks;
  final Map<String, dynamic> time;
  final Map<String, dynamic> leads;
  final Map<String, dynamic> clients;
  final Map<String, dynamic> quotes;
  final Map<String, dynamic> invoices;
  final Map<String, dynamic> team;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> financials;
  final Map<String, dynamic> approvals;

  Permissions({
    this.projects = const {},
    this.tasks = const {},
    this.time = const {},
    this.leads = const {},
    this.clients = const {},
    this.quotes = const {},
    this.invoices = const {},
    this.team = const {},
    this.settings = const {},
    this.financials = const {},
    this.approvals = const {},
  });

  factory Permissions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Permissions();
    return Permissions(
      projects: json['projects'] ?? {},
      tasks: json['tasks'] ?? {},
      time: json['time'] ?? {},
      leads: json['leads'] ?? {},
      clients: json['clients'] ?? {},
      quotes: json['quotes'] ?? {},
      invoices: json['invoices'] ?? {},
      team: json['team'] ?? {},
      settings: json['settings'] ?? {},
      financials: json['financials'] ?? {},
      approvals: json['approvals'] ?? {},
    );
  }

  // Projects
  bool get canViewProjects => projects['view'] == true;
  bool get canViewAllProjects => projects['viewAll'] == true;
  bool get canCreateProjects => projects['create'] == true;
  bool get canEditProjects => projects['edit'] == true;
  bool get canDeleteProjects => projects['delete'] == true;

  // Tasks
  bool get canViewTasks => tasks['view'] == true;
  bool get canCreateTasks => tasks['create'] == true;
  bool get canEditTasks => tasks['edit'] == true;
  bool get canDeleteTasks => tasks['delete'] == true;

  // Time Tracking
  bool get canViewTime => time['view'] == true;
  bool get canViewAllTime => time['viewAll'] == true;
  bool get canRecordTime => time['create'] == true;
  bool get canEditTime => time['edit'] == true;

  // Leads/CRM
  bool get canViewLeads => leads['view'] == true;
  bool get canViewAllLeads => leads['viewAll'] == true;
  bool get canCreateLeads => leads['create'] == true;
  bool get canEditLeads => leads['edit'] == true;
  bool get canDeleteLeads => leads['delete'] == true;

  // Clients
  bool get canViewClients => clients['view'] == true;
  bool get canCreateClients => clients['create'] == true;
  bool get canEditClients => clients['edit'] == true;

  // Quotes
  bool get canViewQuotes => quotes['view'] == true;
  bool get canCreateQuotes => quotes['create'] == true;
  bool get canEditQuotes => quotes['edit'] == true;
  bool get canSendQuotes => quotes['send'] == true;

  // Invoices
  bool get canViewInvoices => invoices['view'] == true;
  bool get canCreateInvoices => invoices['create'] == true;
  bool get canEditInvoices => invoices['edit'] == true;
  bool get canSendInvoices => invoices['send'] == true;

  // Team
  bool get canViewTeam => team['view'] == true;
  bool get canInviteTeam => team['invite'] == true;
  bool get canManageRoles => team['manage'] == true;

  // Settings
  bool get canViewSettings => settings['view'] == true;
  bool get canEditSettings => settings['edit'] == true;

  // Financials - Critical for hiding budget fields from Employee role
  bool get canViewProjectBudgets => financials['viewProjectBudgets'] == true;
  bool get canViewTaskBudgets => financials['viewTaskBudgets'] == true;
  bool get canViewBillingRates => financials['viewBillingRates'] == true;
  bool get canViewClientValues => financials['viewClientValues'] == true;
  bool get canViewReports => financials['viewReports'] == true;

  // Approvals
  bool get canViewApprovals => approvals['view'] == true;
  bool get canApprove => approvals['approve'] == true;
}

class PermissionsProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  bool _isLoading = false;
  String? _errorMessage;
  
  String? _currentCompanyId;
  String? _currentRoleId;
  String? _roleName;
  Permissions _permissions = Permissions();
  Map<String, dynamic>? _profile;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentCompanyId => _currentCompanyId;
  String? get currentRoleId => _currentRoleId;
  String? get roleName => _roleName;
  Permissions get permissions => _permissions;
  Map<String, dynamic>? get profile => _profile;

  // Role checks
  bool get isOwner => _roleName == 'owner';
  bool get isManager => _roleName == 'manager';
  bool get isProjectManager => _roleName == 'project_manager';
  bool get isEmployee => _roleName == 'employee';
  bool get isSalesRep => _roleName == 'sales_rep';
  bool get isConsultant => _roleName == 'consultant';

  // Shortcut permission getters
  bool get canViewClientValues => _permissions.canViewClientValues;

  /// Load user profile and permissions for a company
  Future<void> loadPermissions(String supabaseUserId, String companyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch user profile with role (uses Supabase Auth user ID)
      final profileData = await _supabaseService.getProfileBySupabaseUserId(supabaseUserId);
      
      if (profileData == null) {
        _errorMessage = 'Profile not found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _profile = profileData;
      _currentCompanyId = companyId;
      _currentRoleId = profileData['role_id'];
      
      // Fetch role with permissions
      if (_currentRoleId != null) {
        final roleData = await _supabaseService.getRole(_currentRoleId!);
        if (roleData != null) {
          _roleName = roleData['name'];
          _permissions = Permissions.fromJson(roleData['permissions']);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear permissions (on logout)
  void clearPermissions() {
    _currentCompanyId = null;
    _currentRoleId = null;
    _roleName = null;
    _permissions = Permissions();
    _profile = null;
    notifyListeners();
  }

  /// Check if user has access to Sales module
  bool get hasSalesAccess => 
      permissions.canViewLeads || permissions.canCreateLeads;

  /// Check if user has access to Invoicing module
  bool get hasInvoicingAccess =>
      permissions.canViewInvoices || permissions.canCreateInvoices;

  /// Check if user has access to Reports module
  bool get hasReportsAccess => permissions.canViewReports;

  /// Check if user can see financials (budgets, rates)
  bool get hasFinancialAccess =>
      permissions.canViewProjectBudgets || 
      permissions.canViewTaskBudgets ||
      permissions.canViewBillingRates;
}
