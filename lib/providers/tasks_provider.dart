import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class TasksProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentProjectId;

  List<Map<String, dynamic>> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadTasks(String projectId) async {
    _currentProjectId = projectId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _supabaseService.getTasks(projectId);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllTasks(String companyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _supabaseService.getAllTasks(companyId);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTask(Map<String, dynamic> task) async {
    try {
      final newTask = await _supabaseService.createTask({
        ...task,
        'project_id': task['project_id'] ?? _currentProjectId,
      });
      _tasks.insert(0, newTask);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    try {
      await _supabaseService.updateTask(id, data);
      final index = _tasks.indexWhere((t) => t['id'] == id);
      if (index != -1) {
        _tasks[index] = {..._tasks[index], ...data};
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _supabaseService.deleteTask(id);
      _tasks.removeWhere((t) => t['id'] == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearTasks() {
    _tasks = [];
    _currentProjectId = null;
    notifyListeners();
  }
}
