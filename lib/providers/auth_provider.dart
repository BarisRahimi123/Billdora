import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  String? get errorMessage => _errorMessage;
  
  String get userId => _user?['id'] ?? '';
  String get userEmail => _user?['email_addresses']?[0]?['email_address'] ?? '';
  String get userName => '${_user?['first_name'] ?? ''} ${_user?['last_name'] ?? ''}'.trim();

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    _isAuthenticated = await _authService.isAuthenticated();
    if (_isAuthenticated) {
      _user = await _authService.getCurrentUser();
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
    } else if (!result.verificationRequired) {
      _errorMessage = result.errorMessage;
    }

    _isLoading = false;
    notifyListeners();
    return result;
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
}
