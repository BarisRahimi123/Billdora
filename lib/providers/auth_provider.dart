import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SupabaseService _supabaseService = SupabaseService();
  StreamSubscription<AuthState>? _authSubscription;
  
  bool _isLoading = false;
  String? _companyId;
  Map<String, dynamic>? _profile;

  String? get companyId => _companyId;
  String? get currentCompanyId => _companyId;  // Alias for compatibility
  String? get currentCompanyName => _profile?['company_name'] ?? _profile?['company']?['name'];  // Company name from profile
  Map<String, dynamic>? get profile => _profile;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get currentUser => _user;  // Alias for compatibility
  String? get errorMessage => _errorMessage;
  
  String get userId => _user?['id'] ?? '';
  String get userEmail => _user?['email'] ?? '';
  String get userName {
    final firstName = _user?['first_name'] ?? '';
    final lastName = _user?['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isNotEmpty ? fullName : _user?['full_name'] ?? '';
  }

  AuthProvider() {
    _init();
  }

  void _init() {
    _checkAuthStatus();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSubscription = _authService.onAuthStateChange().listen((authState) {
      final event = authState.event;
      final session = authState.session;

      debugPrint('AuthProvider: Auth state changed - event=$event');

      switch (event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
          if (session?.user != null) {
            debugPrint('AuthProvider: User signed in - id=${session!.user.id}, email=${session.user.email}');
            _isAuthenticated = true;
            _user = _authService.getCurrentUserMap();
            // Load profile on auth state change
            _loadUserProfile(session.user.id);
            notifyListeners();
          }
          break;
        case AuthChangeEvent.signedOut:
          debugPrint('AuthProvider: User signed out');
          _isAuthenticated = false;
          _user = null;
          _profile = null;
          _companyId = null;
          notifyListeners();
          break;
        case AuthChangeEvent.userUpdated:
          _user = _authService.getCurrentUserMap();
          notifyListeners();
          break;
        default:
          break;
      }
    });
  }

  void _checkAuthStatus() {
    debugPrint('AuthProvider._checkAuthStatus: Starting...');
    _isLoading = true;
    notifyListeners();

    _isAuthenticated = _authService.isAuthenticated();
    debugPrint('AuthProvider._checkAuthStatus: isAuthenticated=$_isAuthenticated');
    
    if (_isAuthenticated) {
      _user = _authService.getCurrentUserMap();
      debugPrint('AuthProvider._checkAuthStatus: user=$_user');
      // Also load profile on initial check
      final userId = _user?['id'];
      if (userId != null) {
        debugPrint('AuthProvider._checkAuthStatus: Loading profile for userId=$userId');
        _loadUserProfile(userId);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signInWithEmail(email, password);
    
    if (result.success) {
      _isAuthenticated = true;
      _user = result.user;
      _errorMessage = null;
      
      // Load user profile after successful sign in
      if (result.user != null) {
        await _loadUserProfile(result.user!['id']);
      }
    } else {
      _isAuthenticated = false;
      _errorMessage = result.errorMessage;
    }

    _isLoading = false;
    notifyListeners();
    return result.success;
  }

  Future<AuthResult> signUp(String email, String password, String firstName, String lastName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signUpWithEmail(email, password, firstName, lastName);
    
    if (result.success && result.user != null) {
      _isAuthenticated = true;
      _user = result.user;
      
      // Create profile and company for new user
      await _createUserProfile(result.user!['id'], email, firstName, lastName);
    } else {
      _errorMessage = result.errorMessage;
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  /// Create profile, company, and assign owner role for new user
  Future<void> _createUserProfile(String authUserId, String email, String firstName, String lastName) async {
    try {
      // 1. Create a new company for the user
      final company = await _supabaseService.createCompany({
        'name': '$firstName\'s Company',
        'owner_id': authUserId,
      });
      _companyId = company['id'];

      // 2. Get the owner role for this company
      final roles = await _supabaseService.getRolesByCompany(_companyId!);
      final ownerRole = roles.firstWhere(
        (r) => r['name'] == 'owner',
        orElse: () => roles.first,
      );

      // 3. Create profile with owner role
      _profile = await _supabaseService.createProfile({
        'id': authUserId,
        'clerk_user_id': authUserId,
        'company_id': _companyId,
        'role_id': ownerRole['id'],
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'full_name': '$firstName $lastName',
      });
      
      debugPrint('AuthProvider._createUserProfile: Created company=$_companyId and profile for $email');
    } catch (e) {
      debugPrint('Error creating user profile: $e');
    }
  }

  /// Load existing profile after sign in (Supabase Auth)
  /// Auto-creates company and profile if none exists (e.g., for collaborator portal users)
  Future<void> _loadUserProfile(String authUserId) async {
    debugPrint('AuthProvider._loadUserProfile: Looking for profile with authUserId=$authUserId');
    try {
      // For Supabase Auth, the user ID is stored in clerk_user_id column (legacy naming)
      // Try by clerk_user_id first (most common case)
      _profile = await _supabaseService.getProfileBySupabaseUserId(authUserId);
      
      // If not found, try by profile id
      if (_profile == null) {
        debugPrint('AuthProvider._loadUserProfile: Not found by clerk_user_id, trying profile id');
        _profile = await _supabaseService.getProfileByAuthId(authUserId);
      }
      
      // If still not found, try by email
      if (_profile == null && _user?['email'] != null) {
        debugPrint('AuthProvider._loadUserProfile: Not found by id, trying email');
        _profile = await _supabaseService.getProfileByEmail(_user!['email']);
      }
      
      if (_profile != null) {
        _companyId = _profile!['company_id'];
        debugPrint('AuthProvider._loadUserProfile: Found profile! company_id=$_companyId');
        
        // Check if profile has a company_id - if not, create a company for them
        if (_companyId == null && _user != null) {
          debugPrint('AuthProvider._loadUserProfile: Profile exists but no company - creating one');
          await _createCompanyForExistingProfile(authUserId, _user!['email'] ?? 'user@example.com');
        }
      } else {
        // No profile found - check if user has a staff invitation first
        debugPrint('AuthProvider._loadUserProfile: No profile found - checking for staff invitation');
        if (_user != null) {
          final email = _user!['email'] ?? 'user@example.com';
          final metadata = _user!['user_metadata'] as Map<String, dynamic>? ?? {};
          final fullName = metadata['full_name'] ?? metadata['name'] ?? email.split('@').first;
          final nameParts = fullName.toString().split(' ');
          final firstName = nameParts.first;
          final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
          
          // Check for pending staff invitation
          final staffInvitation = await _supabaseService.getStaffInvitationByEmail(email);
          
          if (staffInvitation != null) {
            // User was invited to join an existing company - use that company
            debugPrint('AuthProvider._loadUserProfile: Found staff invitation - joining company ${staffInvitation['company_id']}');
            await _joinCompanyFromInvitation(authUserId, email, firstName, lastName, staffInvitation);
          } else {
            // No invitation - create their own company (independent user)
            debugPrint('AuthProvider._loadUserProfile: No staff invitation - creating own company');
            await _createUserProfile(authUserId, email, firstName, lastName);
          }
        }
      }
    } catch (e) {
      debugPrint('AuthProvider._loadUserProfile: Error - $e');
    }
  }
  
  /// Join an existing company via staff invitation
  Future<void> _joinCompanyFromInvitation(
    String authUserId, 
    String email, 
    String firstName, 
    String lastName, 
    Map<String, dynamic> invitation,
  ) async {
    try {
      _companyId = invitation['company_id'];
      
      // Get the appropriate role for this user (from invitation or default to staff)
      final roles = await _supabaseService.getRolesByCompany(_companyId!);
      final invitedRole = invitation['role'] ?? 'Staff';
      final role = roles.firstWhere(
        (r) => r['name'].toString().toLowerCase() == invitedRole.toString().toLowerCase(),
        orElse: () => roles.firstWhere(
          (r) => r['name'].toString().toLowerCase() == 'staff',
          orElse: () => roles.first,
        ),
      );

      // Create profile with the company's ID (joining existing company)
      _profile = await _supabaseService.createProfile({
        'id': authUserId,
        'clerk_user_id': authUserId,
        'company_id': _companyId,
        'role_id': role['id'],
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'full_name': '$firstName $lastName',
        'job_title': invitation['job_title'],
        'department': invitation['department'],
        'phone': invitation['phone'],
      });
      
      // Mark the invitation as accepted
      await _supabaseService.acceptStaffInvitation(invitation['id']);
      
      debugPrint('AuthProvider._joinCompanyFromInvitation: Joined company $_companyId with role ${role['name']}');
    } catch (e) {
      debugPrint('Error joining company from invitation: $e');
      // Fallback: create their own company
      await _createUserProfile(authUserId, email, firstName, lastName);
    }
  }

  /// Create a company for a user who has a profile but no company
  Future<void> _createCompanyForExistingProfile(String authUserId, String email) async {
    try {
      final userName = email.split('@').first;
      
      // Create company
      final company = await _supabaseService.createCompany({
        'name': '$userName\'s Company',
        'owner_id': authUserId,
      });
      _companyId = company['id'];
      debugPrint('AuthProvider._createCompanyForExistingProfile: Created company $_companyId');
      
      // Update profile with company_id
      await _supabaseService.updateProfile(_profile!['id'], {
        'company_id': _companyId,
      });
      _profile!['company_id'] = _companyId;
      debugPrint('AuthProvider._createCompanyForExistingProfile: Updated profile with company_id');
    } catch (e) {
      debugPrint('AuthProvider._createCompanyForExistingProfile: Error - $e');
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signInWithGoogle();
    
    if (!result.success) {
      _errorMessage = result.errorMessage;
    }

    _isLoading = false;
    notifyListeners();
    return result.success;
  }

  Future<bool> signInWithApple() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signInWithApple();
    
    if (!result.success) {
      _errorMessage = result.errorMessage;
    }

    _isLoading = false;
    notifyListeners();
    return result.success;
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.resetPassword(email);
    
    if (!result.success) {
      _errorMessage = result.errorMessage;
    }

    _isLoading = false;
    notifyListeners();
    return result.success;
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    await _authService.signOut();
    
    _isAuthenticated = false;
    _user = null;
    _profile = null;
    _companyId = null;
    _errorMessage = null;

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
