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
    int paidCount = 0;
    int pendingCount = 0;

    for (var inv in invoices) {
      final total = (inv['total'] ?? 0).toDouble();
      totalRevenue += total;
      if (inv['status'] == 'paid') {
        paidCount++;
      } else {
        outstanding += total;
        pendingCount++;
      }
    }

    // Get expense totals
    final expenses = await _client
        .from('expenses')
        .select('amount')
        .eq('company_id', companyId);
    
    double totalExpenses = 0;
    for (var exp in expenses) {
      totalExpenses += (exp['amount'] ?? 0).toDouble();
    }

    return {
      'totalRevenue': totalRevenue,
      'outstanding': outstanding,
      'totalExpenses': totalExpenses,
      'profit': totalRevenue - totalExpenses,
      'invoiceCount': invoices.length,
      'paidCount': paidCount,
      'pendingCount': pendingCount,
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
}
