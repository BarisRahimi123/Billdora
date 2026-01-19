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
  Map<String, dynamic>? get profile => _profile;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
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

      switch (event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
          if (session?.user != null) {
            _isAuthenticated = true;
            _user = _authService.getCurrentUserMap();
            // Load profile on auth state change
            _loadUserProfile(session!.user.id);
            notifyListeners();
          }
          break;
        case AuthChangeEvent.signedOut:
          _isAuthenticated = false;
          _user = null;
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
    _isLoading = true;
    notifyListeners();

    _isAuthenticated = _authService.isAuthenticated();
    if (_isAuthenticated) {
      _user = _authService.getCurrentUserMap();
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
        'company_id': _companyId,
        'role_id': ownerRole['id'],
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'full_name': '$firstName $lastName',
      });
    } catch (e) {
      debugPrint('Error creating user profile: $e');
    }
  }

  /// Load existing profile after sign in
  Future<void> _loadUserProfile(String authUserId) async {
    try {
      _profile = await _supabaseService.getProfileByAuthId(authUserId);
      if (_profile != null) {
        _companyId = _profile!['company_id'];
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
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
