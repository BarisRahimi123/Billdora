import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class ExpensesProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _companyId;

  List<Map<String, dynamic>> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Stats
  double get totalExpenses => _expenses.fold(0.0, (sum, e) => sum + (e['amount'] as num? ?? 0).toDouble());
  double get pendingExpenses => _expenses
      .where((e) => e['status'] == 'submitted')
      .fold(0.0, (sum, e) => sum + (e['amount'] as num? ?? 0).toDouble());
  double get billableExpenses => _expenses
      .where((e) => e['billable'] == true && e['invoice_id'] == null)
      .fold(0.0, (sum, e) => sum + (e['amount'] as num? ?? 0).toDouble());

  Future<void> loadExpenses(String companyId, {String? projectId}) async {
    _companyId = companyId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expenses = await _supabaseService.getExpenseEntries(companyId, projectId: projectId);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense(Map<String, dynamic> expense) async {
    try {
      final newExpense = await _supabaseService.createExpenseEntry({
        ...expense,
        'company_id': _companyId,
      });
      _expenses.insert(0, newExpense);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateExpense(String id, Map<String, dynamic> data) async {
    try {
      await _supabaseService.updateExpenseEntry(id, data);
      final index = _expenses.indexWhere((e) => e['id'] == id);
      if (index != -1) {
        _expenses[index] = {..._expenses[index], ...data};
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _supabaseService.deleteExpenseEntry(id);
      _expenses.removeWhere((e) => e['id'] == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearExpenses() {
    _expenses = [];
    _companyId = null;
    notifyListeners();
  }
}
