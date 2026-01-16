import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'clerk_session_token';
  static const String _userKey = 'clerk_user';

  // Clerk Frontend API base URL (derived from publishable key)
  String get _clerkFrontendApi {
    // Extract domain from publishable key
    final decoded = utf8.decode(base64.decode(
      Env.clerkPublishableKey.replaceFirst('pk_test_', '').replaceFirst('pk_live_', '')
    ));
    return 'https://$decoded';
  }

  // Sign in with email
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      // Create sign-in attempt
      final response = await http.post(
        Uri.parse('$_clerkFrontendApi/v1/client/sign_ins'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Env.clerkPublishableKey}',
        },
        body: jsonEncode({
          'identifier': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessionToken = data['response']['session_token'];
        final user = data['response']['user'];
        
        await _saveSession(sessionToken, user);
        return AuthResult.success(user);
      } else {
        final error = jsonDecode(response.body);
        return AuthResult.failure(error['errors']?[0]?['message'] ?? 'Sign in failed');
      }
    } catch (e) {
      return AuthResult.failure('Network error: ${e.toString()}');
    }
  }

  // Sign up with email
  Future<AuthResult> signUpWithEmail(String email, String password, String firstName, String lastName) async {
    try {
      final response = await http.post(
        Uri.parse('$_clerkFrontendApi/v1/client/sign_ups'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Env.clerkPublishableKey}',
        },
        body: jsonEncode({
          'email_address': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle email verification if required
        if (data['response']['status'] == 'missing_requirements') {
          return AuthResult.verificationRequired(data['response']['id']);
        }
        return AuthResult.success(data['response']);
      } else {
        final error = jsonDecode(response.body);
        return AuthResult.failure(error['errors']?[0]?['message'] ?? 'Sign up failed');
      }
    } catch (e) {
      return AuthResult.failure('Network error: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    final token = await getSessionToken();
    if (token != null) {
      try {
        await http.delete(
          Uri.parse('$_clerkFrontendApi/v1/client/sessions'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
      } catch (_) {}
    }
    await _clearSession();
  }

  // Get current session token
  Future<String?> getSessionToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Get current user
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getSessionToken();
    return token != null;
  }

  // Refresh session
  Future<bool> refreshSession() async {
    final token = await getSessionToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_clerkFrontendApi/v1/client/sessions/refresh'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Private methods
  Future<void> _saveSession(String token, Map<String, dynamic> user) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(user));
  }

  Future<void> _clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
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
    );
  }
}
