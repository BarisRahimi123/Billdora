import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class TeamProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _members = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _companyId;

  List<Map<String, dynamic>> get members => _members;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadTeamMembers(String companyId) async {
    _companyId = companyId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _members = await _supabaseService.getTeamMembers(companyId);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> search(String query) {
    if (query.isEmpty) return _members;
    final lowerQuery = query.toLowerCase();
    return _members.where((m) {
      final firstName = (m['first_name'] ?? '').toLowerCase();
      final lastName = (m['last_name'] ?? '').toLowerCase();
      final email = (m['email'] ?? '').toLowerCase();
      return firstName.contains(lowerQuery) ||
          lastName.contains(lowerQuery) ||
          email.contains(lowerQuery);
    }).toList();
  }

  void clearAll() {
    _members = [];
    _companyId = null;
    notifyListeners();
  }
}
