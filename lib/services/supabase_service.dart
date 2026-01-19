import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  SupabaseClient get client => _client;

  // ============ COMPANIES ============
  Future<List<Map<String, dynamic>>> getCompanies(String userId) async {
    final response = await _client
        .from('companies')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createCompany(Map<String, dynamic> data) async {
    final response = await _client
        .from('companies')
        .insert(data)
        .select()
        .single();
    return response;
  }

  // ============ CLIENTS ============
  Future<List<Map<String, dynamic>>> getClients(String companyId) async {
    final response = await _client
        .from('clients')
        .select()
        .eq('company_id', companyId)
        .order('name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createClient(Map<String, dynamic> data) async {
    final response = await _client
        .from('clients')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updateClient(String id, Map<String, dynamic> data) async {
    await _client.from('clients').update(data).eq('id', id);
  }

  Future<void> deleteClient(String id) async {
    await _client.from('clients').delete().eq('id', id);
  }

  // ============ INVOICES ============
  Future<List<Map<String, dynamic>>> getInvoices(String companyId) async {
    final response = await _client
        .from('invoices')
        .select('*, clients(*)')
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> getInvoice(String id) async {
    final response = await _client
        .from('invoices')
        .select('*, clients(*), invoice_items(*)')
        .eq('id', id)
        .single();
    return response;
  }

  Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> data) async {
    final response = await _client
        .from('invoices')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updateInvoice(String id, Map<String, dynamic> data) async {
    await _client.from('invoices').update(data).eq('id', id);
  }

  Future<void> deleteInvoice(String id) async {
    await _client.from('invoices').delete().eq('id', id);
  }

  // ============ PROJECTS ============
  Future<List<Map<String, dynamic>>> getProjects(String companyId) async {
    final response = await _client
        .from('projects')
        .select('*, clients(*)')
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createProject(Map<String, dynamic> data) async {
    final response = await _client
        .from('projects')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updateProject(String id, Map<String, dynamic> data) async {
    await _client.from('projects').update(data).eq('id', id);
  }

  Future<void> deleteProject(String id) async {
    await _client.from('projects').delete().eq('id', id);
  }

  // ============ EXPENSES ============
  Future<List<Map<String, dynamic>>> getExpenses(String companyId) async {
    final response = await _client
        .from('expenses')
        .select('*, categories(*)')
        .eq('company_id', companyId)
        .order('date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> data) async {
    final response = await _client
        .from('expenses')
        .insert(data)
        .select()
        .single();
    return response;
  }

  // ============ RECEIPTS ============
  Future<List<Map<String, dynamic>>> getReceipts(String companyId) async {
    final response = await _client
        .from('receipts')
        .select()
        .eq('company_id', companyId)
        .order('date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============ ANALYTICS ============
  Future<Map<String, dynamic>> getDashboardStats(String companyId) async {
    // Get invoice totals
    final invoices = await _client
        .from('invoices')
        .select('total, status')
        .eq('company_id', companyId);
    
    double totalRevenue = 0;
    double outstanding = 0;
    double unbilledWIP = 0;
    int paidCount = 0;
    int draftCount = 0;
    int sentCount = 0;

    for (var inv in invoices) {
      final total = (inv['total'] ?? 0).toDouble();
      final status = inv['status'] as String? ?? '';
      if (status == 'paid') {
        totalRevenue += total;
        paidCount++;
      } else if (status == 'draft') {
        unbilledWIP += total;
        draftCount++;
      } else if (status == 'sent' || status == 'pending' || status == 'overdue') {
        outstanding += total;
        sentCount++;
      }
    }

    // Get expense totals
    final expenses = await _client
        .from('expense_entries')
        .select('amount')
        .eq('company_id', companyId);
    
    double totalExpenses = 0;
    for (var exp in expenses) {
      totalExpenses += (exp['amount'] ?? 0).toDouble();
    }

    // Get active projects and pending tasks
    final projects = await _client
        .from('projects')
        .select('id, status')
        .eq('company_id', companyId);
    
    int activeProjects = 0;
    for (var p in projects) {
      if (p['status'] == 'active' || p['status'] == 'in_progress') {
        activeProjects++;
      }
    }

    final tasks = await _client
        .from('tasks')
        .select('id, status')
        .eq('company_id', companyId);
    
    int pendingTasks = 0;
    for (var t in tasks) {
      if (t['status'] != 'completed' && t['status'] != 'cancelled') {
        pendingTasks++;
      }
    }

    // Get time entries for this week
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    final timeEntries = await _client
        .from('time_entries')
        .select('hours, is_billable, date')
        .eq('company_id', companyId)
        .gte('date', startOfWeek.toIso8601String().split('T')[0]);
    
    double hoursThisWeek = 0;
    double hoursToday = 0;
    double billableHours = 0;
    double nonBillableHours = 0;

    for (var entry in timeEntries) {
      final hours = (entry['hours'] ?? 0).toDouble();
      hoursThisWeek += hours;
      
      final entryDate = DateTime.tryParse(entry['date'] ?? '');
      if (entryDate != null && entryDate.year == startOfDay.year && 
          entryDate.month == startOfDay.month && entryDate.day == startOfDay.day) {
        hoursToday += hours;
      }
      
      if (entry['is_billable'] == true) {
        billableHours += hours;
      } else {
        nonBillableHours += hours;
      }
    }
    
    final totalHours = billableHours + nonBillableHours;
    final utilization = totalHours > 0 ? ((billableHours / totalHours) * 100).round() : 0;

    return {
      'totalRevenue': totalRevenue,
      'outstanding': outstanding,
      'totalExpenses': totalExpenses,
      'profit': totalRevenue - totalExpenses,
      'invoiceCount': invoices.length,
      'paidCount': paidCount,
      'draftInvoices': draftCount,
      'sentInvoices': sentCount,
      'unbilledWIP': unbilledWIP,
      'activeProjects': activeProjects,
      'pendingTasks': pendingTasks,
      'hoursThisWeek': hoursThisWeek.round(),
      'hoursToday': hoursToday.round(),
      'billableHours': billableHours.round(),
      'nonBillableHours': nonBillableHours.round(),
      'utilization': utilization,
    };
  }

  // ============ BANK STATEMENTS ============
  Future<List<Map<String, dynamic>>> getBankStatements(String companyId) async {
    final response = await _client
        .from('bank_statements')
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============ NOTIFICATIONS ============
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> markNotificationRead(String id) async {
    await _client.from('notifications').update({'read': true}).eq('id', id);
  }

  // ============ PROFILES ============
  Future<Map<String, dynamic>?> getProfileByClerkId(String clerkUserId) async {
    final response = await _client
        .from('profiles')
        .select('*, roles(*)')
        .eq('clerk_user_id', clerkUserId)
        .maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>?> getProfileByAuthId(String authUserId) async {
    final response = await _client
        .from('profiles')
        .select('*, roles(*)')
        .eq('id', authUserId)
        .maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>> createProfile(Map<String, dynamic> data) async {
    final response = await _client
        .from('profiles')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updateProfile(String id, Map<String, dynamic> data) async {
    await _client.from('profiles').update(data).eq('id', id);
  }

  // ============ ROLES ============
  Future<Map<String, dynamic>?> getRole(String roleId) async {
    final response = await _client
        .from('roles')
        .select()
        .eq('id', roleId)
        .maybeSingle();
    return response;
  }

  Future<List<Map<String, dynamic>>> getRolesByCompany(String companyId) async {
    final response = await _client
        .from('roles')
        .select()
        .eq('company_id', companyId)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  // ============ LEADS ============
  Future<List<Map<String, dynamic>>> getLeads(String companyId) async {
    final response = await _client
        .from('leads')
        .select('*, profiles!leads_assigned_to_fkey(first_name, last_name, avatar_url)')
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createLead(Map<String, dynamic> data) async {
    final response = await _client
        .from('leads')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updateLead(String id, Map<String, dynamic> data) async {
    await _client.from('leads').update(data).eq('id', id);
  }

  Future<void> deleteLead(String id) async {
    await _client.from('leads').delete().eq('id', id);
  }

  // ============ QUOTES ============
  Future<List<Map<String, dynamic>>> getQuotes(String companyId) async {
    final response = await _client
        .from('quotes')
        .select('*, leads(company_name, contact_name), clients(name)')
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> getQuote(String id) async {
    final response = await _client
        .from('quotes')
        .select('*, quote_items(*), leads(*), clients(*)')
        .eq('id', id)
        .single();
    return response;
  }

  Future<Map<String, dynamic>> createQuote(Map<String, dynamic> data) async {
    final response = await _client
        .from('quotes')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updateQuote(String id, Map<String, dynamic> data) async {
    await _client.from('quotes').update(data).eq('id', id);
  }

  Future<void> deleteQuote(String id) async {
    await _client.from('quotes').delete().eq('id', id);
  }

  // ============ QUOTE ITEMS ============
  Future<void> createQuoteItems(List<Map<String, dynamic>> items) async {
    await _client.from('quote_items').insert(items);
  }

  // ============ TASKS ============
  Future<List<Map<String, dynamic>>> getTasks(String projectId) async {
    final response = await _client
        .from('tasks')
        .select('*, profiles!tasks_assigned_to_fkey(first_name, last_name)')
        .eq('project_id', projectId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    final response = await _client
        .from('tasks')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    await _client.from('tasks').update(data).eq('id', id);
  }

  Future<void> deleteTask(String id) async {
    await _client.from('tasks').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getAllTasks(String companyId) async {
    final response = await _client
        .from('tasks')
        .select('*, projects!inner(company_id)')
        .eq('projects.company_id', companyId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============ TIME ENTRIES ============
  Future<List<Map<String, dynamic>>> getTimeEntries(String companyId, {String? userId}) async {
    var query = _client
        .from('time_entries')
        .select('*, tasks(name), projects(name)')
        .eq('company_id', companyId);
    
    if (userId != null) {
      query = query.eq('user_id', userId);
    }
    
    final response = await query.order('date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createTimeEntry(Map<String, dynamic> data) async {
    final response = await _client
        .from('time_entries')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updateTimeEntry(String id, Map<String, dynamic> data) async {
    await _client.from('time_entries').update(data).eq('id', id);
  }

  Future<void> deleteTimeEntry(String id) async {
    await _client.from('time_entries').delete().eq('id', id);
  }

  // ============ PROJECT ASSIGNMENTS ============
  Future<List<Map<String, dynamic>>> getProjectAssignments(String projectId) async {
    final response = await _client
        .from('project_assignments')
        .select('*, profiles(first_name, last_name, avatar_url)')
        .eq('project_id', projectId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> assignUserToProject(String projectId, String userId, String role) async {
    await _client.from('project_assignments').insert({
      'project_id': projectId,
      'user_id': userId,
      'role': role,
    });
  }

  // ============ TEAM ============
  Future<List<Map<String, dynamic>>> getTeamMembers(String companyId) async {
    final response = await _client
        .from('profiles')
        .select('*, roles(name, description)')
        .eq('company_id', companyId)
        .order('first_name');
    return List<Map<String, dynamic>>.from(response);
  }

  // ============ CONVERT LEAD TO CLIENT ============
  Future<Map<String, dynamic>> convertLeadToClient(String leadId) async {
    // Fetch lead data
    final lead = await _client
        .from('leads')
        .select()
        .eq('id', leadId)
        .single();

    // Create client from lead
    final client = await _client.from('clients').insert({
      'company_id': lead['company_id'],
      'name': lead['company_name'],
      'email': lead['contact_email'],
      'phone': lead['contact_phone'],
      'contact_person': lead['contact_name'],
    }).select().single();

    // Update lead status
    await _client.from('leads').update({
      'status': 'converted',
      'converted_at': DateTime.now().toIso8601String(),
    }).eq('id', leadId);

    return client;
  }

  // ============ CONSULTANTS (Owner's Contact List) ============
  Future<List<Map<String, dynamic>>> getConsultants(String companyId) async {
    final response = await _client
        .from('consultants')
        .select('*, collaborator_accounts(name, email, avatar_url)')
        .eq('company_id', companyId)
        .eq('status', 'active')
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createConsultant(Map<String, dynamic> data) async {
    final response = await _client
        .from('consultants')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updateConsultant(String id, Map<String, dynamic> data) async {
    await _client.from('consultants').update(data).eq('id', id);
  }

  // ============ COLLABORATOR ACCOUNTS ============
  Future<Map<String, dynamic>?> getCollaboratorAccountByEmail(String email) async {
    final response = await _client
        .from('collaborator_accounts')
        .select()
        .eq('email', email)
        .maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>?> getCollaboratorAccount(String clerkId) async {
    final response = await _client
        .from('collaborator_accounts')
        .select()
        .eq('clerk_id', clerkId)
        .maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>> createCollaboratorAccount(Map<String, dynamic> data) async {
    final response = await _client
        .from('collaborator_accounts')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updateCollaboratorAccount(String id, Map<String, dynamic> data) async {
    await _client.from('collaborator_accounts').update(data).eq('id', id);
  }

  // ============ PROPOSAL COLLABORATORS ============
  Future<List<Map<String, dynamic>>> getProposalCollaborators(String quoteId) async {
    final response = await _client
        .from('proposal_collaborators')
        .select('*, collaborator_accounts(name, email, company, avatar_url), consultants(name, email)')
        .eq('quote_id', quoteId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> inviteCollaborator(Map<String, dynamic> data) async {
    // Convert camelCase keys to snake_case for database
    final dbData = {
      'quote_id': data['quote_id'] ?? data['quoteId'],
      'consultant_id': data['consultant_id'] ?? data['consultantId'],
      'collaborator_account_id': data['collaborator_account_id'] ?? data['collaboratorAccountId'],
      'show_pricing': data['show_pricing'] ?? data['showPricing'] ?? false,
      'payment_mode': data['payment_mode'] ?? data['paymentMode'] ?? 'client',
      'display_mode': data['display_mode'] ?? data['displayMode'] ?? 'transparent',
      'deadline': data['deadline'],
      'status': data['status'] ?? 'invited',
      'invited_at': DateTime.now().toIso8601String(),
    };
    // Remove null values
    dbData.removeWhere((key, value) => value == null);
    
    final response = await _client
        .from('proposal_collaborators')
        .insert(dbData)
        .select()
        .single();
    return response;
  }

  Future<void> updateProposalCollaborator(String id, Map<String, dynamic> data) async {
    await _client.from('proposal_collaborators').update(data).eq('id', id);
  }

  Future<void> removeProposalCollaborator(String id) async {
    await _client.from('proposal_collaborators').delete().eq('id', id);
  }

  // Collaborator views their invitations
  Future<List<Map<String, dynamic>>> getCollaboratorInvitations(String collaboratorAccountId) async {
    final response = await _client
        .from('proposal_collaborators')
        .select('*, quotes(title, number, total, status, created_at, companies(name))')
        .eq('collaborator_account_id', collaboratorAccountId)
        .order('invited_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============ COLLABORATOR LINE ITEMS ============
  Future<List<Map<String, dynamic>>> getCollaboratorLineItems(String proposalCollaboratorId) async {
    final response = await _client
        .from('collaborator_line_items')
        .select()
        .eq('proposal_collaborator_id', proposalCollaboratorId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createCollaboratorLineItem(Map<String, dynamic> data) async {
    final response = await _client
        .from('collaborator_line_items')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updateCollaboratorLineItem(String id, Map<String, dynamic> data) async {
    await _client.from('collaborator_line_items').update(data).eq('id', id);
  }

  Future<void> deleteCollaboratorLineItem(String id) async {
    await _client.from('collaborator_line_items').delete().eq('id', id);
  }

  // ============ PAYMENTS ============
  Future<List<Map<String, dynamic>>> getPayments(String companyId) async {
    final response = await _client
        .from('payments')
        .select('*, collaborator_accounts(name, email)')
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getCollaboratorPayments(String collaboratorAccountId) async {
    final response = await _client
        .from('payments')
        .select('*, companies(name)')
        .eq('collaborator_account_id', collaboratorAccountId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createPayment(Map<String, dynamic> data) async {
    final response = await _client
        .from('payments')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updatePayment(String id, Map<String, dynamic> data) async {
    await _client.from('payments').update(data).eq('id', id);
  }

  // ============ COLLABORATOR DASHBOARD STATS ============
  Future<Map<String, dynamic>> getCollaboratorStats(String collaboratorAccountId) async {
    final invitations = await _client
        .from('proposal_collaborators')
        .select('status')
        .eq('collaborator_account_id', collaboratorAccountId);

    final payments = await _client
        .from('payments')
        .select('amount, status')
        .eq('collaborator_account_id', collaboratorAccountId);

    int pending = 0, toSubmit = 0, completed = 0;
    double totalEarned = 0;

    for (var inv in invitations) {
      switch (inv['status']) {
        case 'invited':
        case 'viewed':
          pending++;
          break;
        case 'in_progress':
          toSubmit++;
          break;
        case 'accepted':
        case 'locked':
          completed++;
          break;
      }
    }

    for (var pmt in payments) {
      if (pmt['status'] == 'completed') {
        totalEarned += (pmt['amount'] ?? 0).toDouble();
      }
    }

    return {
      'pendingInvites': pending,
      'toSubmit': toSubmit,
      'completed': completed,
      'totalEarned': totalEarned,
    };
  }

  // ============ SUBTASKS ============
  Future<List<Map<String, dynamic>>> getSubtasks(String taskId) async {
    final response = await _client
        .from('subtasks')
        .select()
        .eq('task_id', taskId)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createSubtask(Map<String, dynamic> data) async {
    final response = await _client.from('subtasks').insert(data).select().single();
    return response;
  }

  Future<void> updateSubtask(String id, Map<String, dynamic> data) async {
    await _client.from('subtasks').update(data).eq('id', id);
  }

  Future<void> deleteSubtask(String id) async {
    await _client.from('subtasks').delete().eq('id', id);
  }

  // ============ EXPENSE ENTRIES ============
  Future<List<Map<String, dynamic>>> getExpenseEntries(String companyId, {String? projectId}) async {
    var query = _client.from('expense_entries').select('*, projects(name)').eq('company_id', companyId);
    if (projectId != null) {
      query = query.eq('project_id', projectId);
    }
    final response = await query.order('entry_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createExpenseEntry(Map<String, dynamic> data) async {
    final response = await _client.from('expense_entries').insert(data).select().single();
    return response;
  }

  Future<void> updateExpenseEntry(String id, Map<String, dynamic> data) async {
    await _client.from('expense_entries').update(data).eq('id', id);
  }

  Future<void> deleteExpenseEntry(String id) async {
    await _client.from('expense_entries').delete().eq('id', id);
  }

  // ============ SERVICES ============
  Future<List<Map<String, dynamic>>> getServices(String companyId) async {
    final response = await _client
        .from('services')
        .select('*, categories(name, color)')
        .eq('company_id', companyId)
        .eq('is_active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createService(Map<String, dynamic> data) async {
    final response = await _client.from('services').insert(data).select().single();
    return response;
  }

  Future<void> updateService(String id, Map<String, dynamic> data) async {
    await _client.from('services').update(data).eq('id', id);
  }

  Future<void> deleteService(String id) async {
    await _client.from('services').update({'is_active': false}).eq('id', id);
  }

  // ============ CATEGORIES ============
  Future<List<Map<String, dynamic>>> getCategories(String companyId) async {
    final response = await _client
        .from('categories')
        .select()
        .eq('company_id', companyId)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    final response = await _client.from('categories').insert(data).select().single();
    return response;
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _client.from('categories').update(data).eq('id', id);
  }

  Future<void> deleteCategory(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }

  // ============ TERMS ============
  Future<List<Map<String, dynamic>>> getTerms(String companyId) async {
    final response = await _client
        .from('terms')
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createTerms(Map<String, dynamic> data) async {
    final response = await _client.from('terms').insert(data).select().single();
    return response;
  }

  Future<void> updateTerms(String id, Map<String, dynamic> data) async {
    await _client.from('terms').update({...data, 'updated_at': DateTime.now().toIso8601String()}).eq('id', id);
  }

  Future<void> deleteTerms(String id) async {
    await _client.from('terms').delete().eq('id', id);
  }

  Future<void> setDefaultTerms(String companyId, String termsId) async {
    // First unset all defaults
    await _client.from('terms').update({'is_default': false}).eq('company_id', companyId);
    // Then set the new default
    await _client.from('terms').update({'is_default': true}).eq('id', termsId);
  }

  // ============ CONSULTANT SPECIALTIES ============
  Future<List<Map<String, dynamic>>> getSpecialties(String companyId) async {
    final response = await _client
        .from('consultant_specialties')
        .select()
        .eq('company_id', companyId)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createSpecialty(Map<String, dynamic> data) async {
    final response = await _client.from('consultant_specialties').insert(data).select().single();
    return response;
  }

  Future<void> updateSpecialty(String id, Map<String, dynamic> data) async {
    await _client.from('consultant_specialties').update({...data, 'updated_at': DateTime.now().toIso8601String()}).eq('id', id);
  }

  Future<void> deleteSpecialty(String id) async {
    await _client.from('consultant_specialties').delete().eq('id', id);
  }

  // ============ NOTIFICATIONS ============
  Future<List<Map<String, dynamic>>> getNotifications(String userId, {int limit = 50}) async {
    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    final response = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
    return (response as List).length;
  }

  Future<void> markNotificationAsRead(String id) async {
    await _client.from('notifications').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    await _client.from('notifications').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId).eq('is_read', false);
  }

  Future<void> createNotification(Map<String, dynamic> data) async {
    await _client.from('notifications').insert(data);
  }

  Future<void> deleteNotification(String id) async {
    await _client.from('notifications').delete().eq('id', id);
  }

  // ============ PORTAL ACCESS (Public endpoints for clients/collaborators) ============
  
  /// Get proposal by portal token (for client view)
  Future<Map<String, dynamic>?> getProposalByPortalToken(String token) async {
    final response = await _client
        .from('quotes')
        .select('*, quote_line_items(*), clients(company, primary_contact)')
        .eq('portal_token', token)
        .maybeSingle();
    return response;
  }

  /// Mark proposal as viewed by client
  Future<void> markProposalViewed(String token) async {
    await _client.from('quotes').update({
      'viewed_at': DateTime.now().toIso8601String(),
      'status': 'viewed',
    }).eq('portal_token', token).isFilter('viewed_at', null);
  }

  /// Approve proposal from client portal
  Future<void> approveProposal(String token, String approvedBy) async {
    await _client.from('quotes').update({
      'status': 'approved',
      'approved_at': DateTime.now().toIso8601String(),
      'approved_by': approvedBy,
    }).eq('portal_token', token);
  }

  /// Reject proposal from client portal
  Future<void> rejectProposal(String token, String reason) async {
    await _client.from('quotes').update({
      'status': 'rejected',
      'rejection_reason': reason,
    }).eq('portal_token', token);
  }

  /// Get invoice by portal token (for client view)
  Future<Map<String, dynamic>?> getInvoiceByPortalToken(String token) async {
    final response = await _client
        .from('invoices')
        .select('*, invoice_line_items(*), clients(company, primary_contact), payments(*)')
        .eq('portal_token', token)
        .maybeSingle();
    return response;
  }

  /// Mark invoice as viewed by client
  Future<void> markInvoiceViewed(String token) async {
    await _client.from('invoices').update({
      'viewed_at': DateTime.now().toIso8601String(),
    }).eq('portal_token', token).isFilter('viewed_at', null);
  }

  /// Get collaborator invitation by token
  Future<Map<String, dynamic>?> getCollaboratorInvitation(String token) async {
    final response = await _client
        .from('proposal_collaborators')
        .select('*, quotes(title, recipient_name, start_date, total_days), consultants(name, email)')
        .eq('invite_token', token)
        .maybeSingle();
    return response;
  }

  /// Mark collaborator invitation as viewed
  Future<void> markCollaboratorInvitationViewed(String token) async {
    await _client.from('proposal_collaborators').update({
      'viewed_at': DateTime.now().toIso8601String(),
      'status': 'viewed',
    }).eq('invite_token', token).eq('status', 'invited');
  }

  /// Submit collaborator line items
  Future<void> submitCollaboratorItems(String token) async {
    await _client.from('proposal_collaborators').update({
      'submitted_at': DateTime.now().toIso8601String(),
      'status': 'submitted',
    }).eq('invite_token', token);
  }

  /// Generate new portal token for a quote
  Future<String> regenerateQuotePortalToken(String quoteId) async {
    final newToken = DateTime.now().millisecondsSinceEpoch.toString();
    await _client.from('quotes').update({'portal_token': newToken}).eq('id', quoteId);
    return newToken;
  }

  /// Generate new portal token for an invoice
  Future<String> regenerateInvoicePortalToken(String invoiceId) async {
    final newToken = DateTime.now().millisecondsSinceEpoch.toString();
    await _client.from('invoices').update({'portal_token': newToken}).eq('id', invoiceId);
    return newToken;
  }

  // ============ EMAIL FUNCTIONS ============

  /// Send payment reminder for an invoice
  Future<Map<String, dynamic>> sendPaymentReminder({
    required String invoiceId,
    required String clientEmail,
    required String clientName,
    required String invoiceNumber,
    required String totalAmount,
    String? dueDate,
    String? portalUrl,
  }) async {
    final response = await _client.functions.invoke('send-payment-reminder', body: {
      'invoiceId': invoiceId,
      'clientEmail': clientEmail,
      'clientName': clientName,
      'invoiceNumber': invoiceNumber,
      'totalAmount': totalAmount,
      'dueDate': dueDate,
      'portalUrl': portalUrl,
    });
    if (response.status != 200) {
      throw Exception(response.data?['error'] ?? 'Failed to send reminder');
    }
    return response.data;
  }

  /// Send proposal email to client
  Future<Map<String, dynamic>> sendProposal({
    required String quoteId,
    required String companyId,
    required String clientEmail,
    required String clientName,
    required String projectName,
    required String companyName,
    required String senderName,
    String? billingContactEmail,
    String? billingContactName,
    String? validUntil,
    String? portalUrl,
    String? letterContent,
  }) async {
    final response = await _client.functions.invoke('send-proposal', body: {
      'quoteId': quoteId,
      'companyId': companyId,
      'clientEmail': clientEmail,
      'clientName': clientName,
      'projectName': projectName,
      'companyName': companyName,
      'senderName': senderName,
      'billingContactEmail': billingContactEmail,
      'billingContactName': billingContactName,
      'validUntil': validUntil,
      'portalUrl': portalUrl,
      'letterContent': letterContent,
    });
    if (response.status != 200) {
      throw Exception(response.data?['error'] ?? 'Failed to send proposal');
    }
    return response.data;
  }

  /// Send invoice email to client
  Future<Map<String, dynamic>> sendInvoice({
    required String invoiceId,
    required String clientEmail,
    required String clientName,
    required String invoiceNumber,
    required String totalAmount,
    String? dueDate,
    String? portalUrl,
  }) async {
    final response = await _client.functions.invoke('send-invoice', body: {
      'invoiceId': invoiceId,
      'clientEmail': clientEmail,
      'clientName': clientName,
      'invoiceNumber': invoiceNumber,
      'totalAmount': totalAmount,
      'dueDate': dueDate,
      'portalUrl': portalUrl,
    });
    if (response.status != 200) {
      throw Exception(response.data?['error'] ?? 'Failed to send invoice');
    }
    return response.data;
  }
}
