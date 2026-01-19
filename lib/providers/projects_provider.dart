import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class ProjectsProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _companyId;

  List<Map<String, dynamic>> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProjects(String companyId) async {
    _companyId = companyId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _projects = await _supabaseService.getProjects(companyId);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProject(Map<String, dynamic> project) async {
    try {
      final newProject = await _supabaseService.createProject({
        ...project,
        'company_id': _companyId,
      });
      _projects.insert(0, newProject);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProject(String id, Map<String, dynamic> data) async {
    try {
      await _supabaseService.updateProject(id, data);
      final index = _projects.indexWhere((p) => p['id'] == id);
      if (index != -1) {
        _projects[index] = {..._projects[index], ...data};
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await _supabaseService.deleteProject(id);
      _projects.removeWhere((p) => p['id'] == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearProjects() {
    _projects = [];
    _companyId = null;
    notifyListeners();
  }
}
