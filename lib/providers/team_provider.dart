import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class TeamProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _pendingInvitations = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _companyId;

  List<Map<String, dynamic>> get members => _members;
  List<Map<String, dynamic>> get pendingInvitations => _pendingInvitations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadTeamMembers(String companyId) async {
    _companyId = companyId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load both members and pending invitations
      final results = await Future.wait([
        _supabaseService.getTeamMembers(companyId),
        _supabaseService.getStaffInvitations(companyId),
      ]);
      _members = results[0];
      _pendingInvitations = results[1].where((i) => i['status'] == 'pending').toList();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('TeamProvider.loadTeamMembers error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Invite a new staff member to join the company
  Future<bool> inviteStaffMember({
    required String email,
    required String fullName,
    required String role,
    required String inviterName,
    required String companyName,
    String? phone,
    String? jobTitle,
    String? department,
  }) async {
    if (_companyId == null) {
      _errorMessage = 'No company ID available';
      notifyListeners();
      return false;
    }

    try {
      // 1. Create the invitation record
      final invitation = await _supabaseService.createStaffInvitation({
        'company_id': _companyId,
        'email': email.toLowerCase().trim(),
        'full_name': fullName,
        'role': role,
        'phone': phone,
        'job_title': jobTitle,
        'department': department,
        'status': 'pending',
        'invited_by': inviterName,
      });

      // 2. Send the invitation email
      await _supabaseService.sendStaffInviteEmail(
        email: email,
        inviterName: inviterName,
        companyName: companyName,
        role: role,
        invitationId: invitation['id'],
      );

      // 3. Add to pending list
      _pendingInvitations.add(invitation);
      notifyListeners();

      debugPrint('Staff invitation sent to $email for company $_companyId');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('TeamProvider.inviteStaffMember error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Resend an invitation email
  Future<bool> resendInvitation(Map<String, dynamic> invitation, String inviterName, String companyName) async {
    try {
      await _supabaseService.sendStaffInviteEmail(
        email: invitation['email'],
        inviterName: inviterName,
        companyName: companyName,
        role: invitation['role'] ?? 'Staff',
        invitationId: invitation['id'],
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
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
    _pendingInvitations = [];
    _companyId = null;
    notifyListeners();
  }
}
