import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class TimeProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _timeEntries = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _companyId;
  String? _userId;

  List<Map<String, dynamic>> get timeEntries => _timeEntries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get total hours for today
  double get todayHours {
    final today = DateTime.now();
    return _timeEntries
        .where((e) {
          final date = DateTime.tryParse(e['date'] ?? '');
          return date != null &&
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        })
        .fold(0.0, (sum, e) => sum + (e['hours'] as num? ?? 0).toDouble());
  }

  // Get total hours for this week
  double get weekHours {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return _timeEntries
        .where((e) {
          final date = DateTime.tryParse(e['date'] ?? '');
          return date != null && date.isAfter(startOfWeek.subtract(const Duration(days: 1)));
        })
        .fold(0.0, (sum, e) => sum + (e['hours'] as num? ?? 0).toDouble());
  }

  Future<void> loadTimeEntries(String companyId, {String? userId}) async {
    _companyId = companyId;
    _userId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _timeEntries = await _supabaseService.getTimeEntries(companyId, userId: userId);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTimeEntry(Map<String, dynamic> entry) async {
    try {
      final newEntry = await _supabaseService.createTimeEntry({
        ...entry,
        'company_id': _companyId,
        'user_id': entry['user_id'] ?? _userId,
      });
      _timeEntries.insert(0, newEntry);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTimeEntry(String id, Map<String, dynamic> data) async {
    try {
      await _supabaseService.updateTimeEntry(id, data);
      final index = _timeEntries.indexWhere((t) => t['id'] == id);
      if (index != -1) {
        _timeEntries[index] = {..._timeEntries[index], ...data};
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTimeEntry(String id) async {
    try {
      await _supabaseService.deleteTimeEntry(id);
      _timeEntries.removeWhere((t) => t['id'] == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearTimeEntries() {
    _timeEntries = [];
    _companyId = null;
    _userId = null;
    notifyListeners();
  }
}
