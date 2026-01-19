import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class InvoicesProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _quotes = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _companyId;

  List<Map<String, dynamic>> get invoices => _invoices;
  List<Map<String, dynamic>> get quotes => _quotes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Stats
  int get pendingInvoicesCount => _invoices.where((i) => i['status'] == 'pending').length;
  int get paidInvoicesCount => _invoices.where((i) => i['status'] == 'paid').length;
  int get overdueInvoicesCount => _invoices.where((i) => i['status'] == 'overdue').length;
  
  double get totalOutstanding => _invoices
      .where((i) => i['status'] == 'pending' || i['status'] == 'overdue')
      .fold(0.0, (sum, i) => sum + (i['total'] as num? ?? 0).toDouble());

  Future<void> loadInvoices(String companyId) async {
    _companyId = companyId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _invoices = await _supabaseService.getInvoices(companyId);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadQuotes(String companyId) async {
    _companyId = companyId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _quotes = await _supabaseService.getQuotes(companyId);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAll(String companyId) async {
    _companyId = companyId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _supabaseService.getInvoices(companyId),
        _supabaseService.getQuotes(companyId),
      ]);
      _invoices = results[0];
      _quotes = results[1];
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Invoice CRUD
  Future<void> addInvoice(Map<String, dynamic> invoice) async {
    try {
      final newInvoice = await _supabaseService.createInvoice({
        ...invoice,
        'company_id': _companyId,
      });
      _invoices.insert(0, newInvoice);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateInvoice(String id, Map<String, dynamic> data) async {
    try {
      await _supabaseService.updateInvoice(id, data);
      final index = _invoices.indexWhere((i) => i['id'] == id);
      if (index != -1) {
        _invoices[index] = {..._invoices[index], ...data};
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteInvoice(String id) async {
    try {
      await _supabaseService.deleteInvoice(id);
      _invoices.removeWhere((i) => i['id'] == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Quote CRUD
  Future<void> addQuote(Map<String, dynamic> quote) async {
    try {
      final newQuote = await _supabaseService.createQuote({
        ...quote,
        'company_id': _companyId,
      });
      _quotes.insert(0, newQuote);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateQuote(String id, Map<String, dynamic> data) async {
    try {
      await _supabaseService.updateQuote(id, data);
      final index = _quotes.indexWhere((q) => q['id'] == id);
      if (index != -1) {
        _quotes[index] = {..._quotes[index], ...data};
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteQuote(String id) async {
    try {
      await _supabaseService.deleteQuote(id);
      _quotes.removeWhere((q) => q['id'] == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Convert quote to invoice
  Future<void> convertQuoteToInvoice(String quoteId) async {
    try {
      final quote = _quotes.firstWhere((q) => q['id'] == quoteId);
      final invoice = await _supabaseService.createInvoice({
        'company_id': _companyId,
        'client_id': quote['client_id'],
        'project_id': quote['project_id'],
        'items': quote['items'],
        'subtotal': quote['subtotal'],
        'tax': quote['tax'],
        'total': quote['total'],
        'status': 'pending',
        'quote_id': quoteId,
      });
      _invoices.insert(0, invoice);
      
      // Update quote status
      await updateQuote(quoteId, {'status': 'converted'});
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearAll() {
    _invoices = [];
    _quotes = [];
    _companyId = null;
    notifyListeners();
  }
}
