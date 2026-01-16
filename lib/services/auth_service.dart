import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _storage = const FlutterSecureStorage();
  static const String _sessionKey = 'billdora_session';

  // Sign in with email and password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null && response.session != null) {
        await _saveSession(response.session!.accessToken);
        return AuthResult.success(_userToMap(response.user!));
      } else {
        return AuthResult.failure('Sign in failed. Please check your credentials.');
      }
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('Network error: ${e.toString()}');
    }
  }

  // Sign up with email and password
  Future<AuthResult> signUpWithEmail(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'full_name': '$firstName $lastName',
        },
      );

      if (response.user != null) {
        // Check if email confirmation is required
        if (response.user!.emailConfirmedAt == null) {
          return AuthResult.verificationRequired(response.user!.id);
        }
        
        if (response.session != null) {
          await _saveSession(response.session!.accessToken);
        }
        return AuthResult.success(_userToMap(response.user!));
      } else {
        return AuthResult.failure('Sign up failed. Please try again.');
      }
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('Network error: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
    await _clearSession();
  }

  // Get current session
  Session? getCurrentSession() {
    return _supabase.auth.currentSession;
  }

  // Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Get current user as Map
  Map<String, dynamic>? getCurrentUserMap() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      return _userToMap(user);
    }
    return null;
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _supabase.auth.currentSession != null;
  }

  // Listen to auth state changes
  Stream<AuthState> onAuthStateChange() {
    return _supabase.auth.onAuthStateChange;
  }

  // Request password reset
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return AuthResult.success({'message': 'Password reset email sent'});
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('Failed to send reset email');
    }
  }

  // Update password
  Future<AuthResult> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return AuthResult.success({'message': 'Password updated successfully'});
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('Failed to update password');
    }
  }

  // Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.billdora://login-callback/',
      );
      
      if (response) {
        return AuthResult.success({'message': 'Google sign-in initiated'});
      }
      return AuthResult.failure('Google sign-in failed');
    } catch (e) {
      return AuthResult.failure('Google sign-in error: ${e.toString()}');
    }
  }

  // Sign in with Apple
  Future<AuthResult> signInWithApple() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.billdora://login-callback/',
      );
      
      if (response) {
        return AuthResult.success({'message': 'Apple sign-in initiated'});
      }
      return AuthResult.failure('Apple sign-in failed');
    } catch (e) {
      return AuthResult.failure('Apple sign-in error: ${e.toString()}');
    }
  }

  // Helper to convert User to Map
  Map<String, dynamic> _userToMap(User user) {
    return {
      'id': user.id,
      'email': user.email,
      'first_name': user.userMetadata?['first_name'] ?? '',
      'last_name': user.userMetadata?['last_name'] ?? '',
      'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? '',
      'avatar_url': user.userMetadata?['avatar_url'],
      'created_at': user.createdAt,
    };
  }

  // Private methods
  Future<void> _saveSession(String token) async {
    await _storage.write(key: _sessionKey, value: token);
  }

  Future<void> _clearSession() async {
    await _storage.delete(key: _sessionKey);
  }
}

class AuthResult {
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? user;
  final bool verificationRequired;
  final String? signUpId;

  AuthResult._({
    required this.success,
    this.errorMessage,
    this.user,
    this.verificationRequired = false,
    this.signUpId,
  });

  factory AuthResult.success(Map<String, dynamic> user) {
    return AuthResult._(success: true, user: user);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(success: false, errorMessage: message);
  }

  factory AuthResult.verificationRequired(String signUpId) {
    return AuthResult._(
      success: false,
      verificationRequired: true,
      signUpId: signUpId,
      errorMessage: 'Please check your email to verify your account.',
    );
  }
}
