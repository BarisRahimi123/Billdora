import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _terms = [];
  List<Map<String, dynamic>> _specialties = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _companyId;

  List<Map<String, dynamic>> get services => _services;
  List<Map<String, dynamic>> get categories => _categories;
  List<Map<String, dynamic>> get terms => _terms;
  List<Map<String, dynamic>> get specialties => _specialties;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? get defaultTerms => _terms.cast<Map<String, dynamic>?>().firstWhere(
    (t) => t?['is_default'] == true,
    orElse: () => null,
  );

  Future<void> loadAll(String companyId) async {
    _companyId = companyId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _supabaseService.getServices(companyId),
        _supabaseService.getCategories(companyId),
        _supabaseService.getTerms(companyId),
        _supabaseService.getSpecialties(companyId),
      ]);
      _services = results[0];
      _categories = results[1];
      _terms = results[2];
      _specialties = results[3];
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Services CRUD
  Future<void> addService(Map<String, dynamic> service) async {
    try {
      await _supabaseService.createService({
        ...service,
        'company_id': _companyId,
      });
      // Reload services to get proper structure
      _services = await _supabaseService.getServices(_companyId!);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateService(String id, Map<String, dynamic> data) async {
    try {
      await _supabaseService.updateService(id, data);
      // Reload services to get proper structure
      _services = await _supabaseService.getServices(_companyId!);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteService(String id) async {
    try {
      await _supabaseService.deleteService(id);
      _services.removeWhere((s) => s['id'] == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Categories CRUD
  Future<void> addCategory(Map<String, dynamic> category) async {
    try {
      final newCategory = await _supabaseService.createCategory({
        ...category,
        'company_id': _companyId,
      });
      _categories.add(newCategory);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      await _supabaseService.updateCategory(id, data);
      final index = _categories.indexWhere((c) => c['id'] == id);
      if (index != -1) {
        _categories[index] = {..._categories[index], ...data};
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _supabaseService.deleteCategory(id);
      _categories.removeWhere((c) => c['id'] == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Terms CRUD
  Future<void> addTerms(Map<String, dynamic> termsData) async {
    try {
      final newTerms = await _supabaseService.createTerms({
        ...termsData,
        'company_id': _companyId,
      });
      _terms.add(newTerms);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTerms(String id, Map<String, dynamic> data) async {
    try {
      await _supabaseService.updateTerms(id, data);
      final index = _terms.indexWhere((t) => t['id'] == id);
      if (index != -1) {
        _terms[index] = {..._terms[index], ...data};
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTerms(String id) async {
    try {
      await _supabaseService.deleteTerms(id);
      _terms.removeWhere((t) => t['id'] == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> setDefaultTerms(String termsId) async {
    try {
      await _supabaseService.setDefaultTerms(_companyId!, termsId);
      // Update local state
      for (var t in _terms) {
        t['is_default'] = t['id'] == termsId;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Specialties CRUD
  Future<void> addSpecialty(Map<String, dynamic> specialty) async {
    try {
      final newSpecialty = await _supabaseService.createSpecialty({
        ...specialty,
        'company_id': _companyId,
      });
      _specialties.add(newSpecialty);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateSpecialty(String id, Map<String, dynamic> data) async {
    try {
      await _supabaseService.updateSpecialty(id, data);
      final index = _specialties.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        _specialties[index] = {..._specialties[index], ...data};
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteSpecialty(String id) async {
    try {
      await _supabaseService.deleteSpecialty(id);
      _specialties.removeWhere((s) => s['id'] == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearAll() {
    _services = [];
    _categories = [];
    _terms = [];
    _specialties = [];
    _companyId = null;
    notifyListeners();
  }
}
