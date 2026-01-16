import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<AuthState>? _authSubscription;
  
  bool _isLoading = false;
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
    
    if (result.success) {
      _isAuthenticated = true;
      _user = result.user;
    } else {
      _errorMessage = result.errorMessage;
    }

    _isLoading = false;
    notifyListeners();
    return result;
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
