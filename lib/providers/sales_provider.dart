import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class SalesProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _companyId;

  // Data lists
  List<Map<String, dynamic>> _leads = [];
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _consultants = [];
  List<Map<String, dynamic>> _quotes = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get leads => _leads;
  List<Map<String, dynamic>> get clients => _clients;
  List<Map<String, dynamic>> get consultants => _consultants;
  List<Map<String, dynamic>> get quotes => _quotes;

  // Counts
  int get leadsCount => _leads.length;
  int get clientsCount => _clients.length;
  int get consultantsCount => _consultants.length;
  int get quotesCount => _quotes.length;

  /// Initialize with company ID and load all data
  Future<void> initialize(String companyId) async {
    _companyId = companyId;
    await loadAll();
  }

  /// Load all sales data
  Future<void> loadAll() async {
    if (_companyId == null) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load all in parallel
      final results = await Future.wait([
        _supabaseService.getLeads(_companyId!),
        _supabaseService.getClients(_companyId!),
        _supabaseService.getConsultants(_companyId!),
        _supabaseService.getQuotes(_companyId!),
      ]);

      _leads = results[0];
      _clients = results[1];
      _consultants = results[2];
      _quotes = results[3];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ LEADS ============
  Future<void> loadLeads() async {
    if (_companyId == null) return;
    try {
      _leads = await _supabaseService.getLeads(_companyId!);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<bool> createLead(Map<String, dynamic> data) async {
    if (_companyId == null) return false;
    try {
      data['company_id'] = _companyId;
      final newLead = await _supabaseService.createLead(data);
      _leads.insert(0, newLead);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateLead(String id, Map<String, dynamic> data) async {
    try {
      await _supabaseService.updateLead(id, data);
      final index = _leads.indexWhere((l) => l['id'] == id);
      if (index != -1) {
        _leads[index] = {..._leads[index], ...data};
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> deleteLead(String id) async {
    try {
      await _supabaseService.deleteLead(id);
      _leads.removeWhere((l) => l['id'] == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<Map<String, dynamic>?> convertLeadToClient(String leadId) async {
    try {
      final client = await _supabaseService.convertLeadToClient(leadId);
      _clients.insert(0, client);
      
      // Update lead status
      final index = _leads.indexWhere((l) => l['id'] == leadId);
      if (index != -1) {
        _leads[index]['status'] = 'converted';
      }
      notifyListeners();
      return client;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  // ============ CLIENTS ============
  Future<void> loadClients() async {
    if (_companyId == null) return;
    try {
      _clients = await _supabaseService.getClients(_companyId!);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<bool> createClient(Map<String, dynamic> data) async {
    if (_companyId == null) return false;
    try {
      data['company_id'] = _companyId;
      final newClient = await _supabaseService.createClient(data);
      _clients.insert(0, newClient);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateClient(String id, Map<String, dynamic> data) async {
    try {
      await _supabaseService.updateClient(id, data);
      final index = _clients.indexWhere((c) => c['id'] == id);
      if (index != -1) {
        _clients[index] = {..._clients[index], ...data};
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> deleteClient(String id) async {
    try {
      await _supabaseService.deleteClient(id);
      _clients.removeWhere((c) => c['id'] == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // ============ CONSULTANTS ============
  Future<void> loadConsultants() async {
    if (_companyId == null) return;
    try {
      _consultants = await _supabaseService.getConsultants(_companyId!);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<bool> createConsultant(Map<String, dynamic> data) async {
    if (_companyId == null) return false;
    try {
      data['company_id'] = _companyId;
      final newConsultant = await _supabaseService.createConsultant(data);
      _consultants.insert(0, newConsultant);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateConsultant(String id, Map<String, dynamic> data) async {
    try {
      await _supabaseService.updateConsultant(id, data);
      final index = _consultants.indexWhere((c) => c['id'] == id);
      if (index != -1) {
        _consultants[index] = {..._consultants[index], ...data};
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // ============ QUOTES ============
  Future<void> loadQuotes() async {
    if (_companyId == null) return;
    try {
      _quotes = await _supabaseService.getQuotes(_companyId!);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<bool> createQuote(Map<String, dynamic> data) async {
    if (_companyId == null) return false;
    try {
      data['company_id'] = _companyId;
      final newQuote = await _supabaseService.createQuote(data);
      _quotes.insert(0, newQuote);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateQuote(String id, Map<String, dynamic> data) async {
    try {
      await _supabaseService.updateQuote(id, data);
      final index = _quotes.indexWhere((q) => q['id'] == id);
      if (index != -1) {
        _quotes[index] = {..._quotes[index], ...data};
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // ============ PROPOSAL COLLABORATORS ============
  Future<List<Map<String, dynamic>>> getProposalCollaborators(String quoteId) async {
    try {
      return await _supabaseService.getProposalCollaborators(quoteId);
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    }
  }

  Future<bool> inviteCollaborator(Map<String, dynamic> data) async {
    try {
      await _supabaseService.inviteCollaborator(data);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateProposalCollaborator(String id, Map<String, dynamic> data) async {
    try {
      await _supabaseService.updateProposalCollaborator(id, data);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // ============ HELPERS ============
  List<Map<String, dynamic>> getLeadsByStatus(String status) {
    if (status == 'all') return _leads;
    return _leads.where((l) => l['status'] == status).toList();
  }

  List<Map<String, dynamic>> getActiveClients() {
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    return _clients.where((c) {
      final lastActivity = c['updated_at'] != null 
          ? DateTime.parse(c['updated_at']) 
          : null;
      return lastActivity != null && lastActivity.isAfter(cutoff);
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> getConsultantsBySpecialty() {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final consultant in _consultants) {
      final specialty = consultant['specialty'] as String? ?? 'Other';
      if (!groups.containsKey(specialty)) {
        groups[specialty] = [];
      }
      groups[specialty]!.add(consultant);
    }
    return groups;
  }

  List<Map<String, dynamic>> getQuotesByStatus(String status) {
    if (status == 'all') return _quotes;
    return _quotes.where((q) => q['status'] == status).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
