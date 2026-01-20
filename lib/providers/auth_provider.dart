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

  /// Sign up with collaborator invite token - implements the viral loop
  Future<AuthResult> signUpWithInvite(String email, String password, String firstName, String lastName, String inviteToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signUpWithEmail(email, password, firstName, lastName);
    
    if (result.success && result.user != null) {
      _isAuthenticated = true;
      _user = result.user;
      
      // Create profile and company for new user
      await _createUserProfile(result.user!['id'], email, firstName, lastName);
      
      // Process the invite - create viral loop connections
      await _processCollaboratorInvite(inviteToken, result.user!['id']);
    } else {
      _errorMessage = result.errorMessage;
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  /// Process collaborator invite: link profile, create client, create draft proposal
  Future<void> _processCollaboratorInvite(String inviteToken, String newUserId) async {
    try {
      debugPrint('AuthProvider: Processing collaborator invite token=$inviteToken');
      
      // 1. Get the invitation details
      final invitation = await _supabaseService.client
          .from('collaborator_invitations')
          .select('*, quotes(id, title, recipient_name, line_items, start_date, total_days)')
          .eq('token', inviteToken)
          .maybeSingle();
      
      if (invitation == null) {
        debugPrint('AuthProvider: Invitation not found');
        return;
      }

      // 2. Update invitation with the new profile
      await _supabaseService.client
          .from('collaborator_invitations')
          .update({
            'collaborator_profile_id': newUserId,
            'status': 'accepted',
          })
          .eq('token', inviteToken);

      // 3. Create the inviter's company as a client for the new user
      final inviterCompanyId = invitation['company_id'];
      final inviterCompanyName = invitation['company_name'] ?? 'Client';
      final ownerName = invitation['owner_name'] ?? '';
      
      // Fetch inviter company details if available
      Map<String, dynamic>? inviterCompany;
      if (inviterCompanyId != null) {
        inviterCompany = await _supabaseService.client
            .from('companies')
            .select()
            .eq('id', inviterCompanyId)
            .maybeSingle();
      }
      
      // Create client record for the new user
      final clientData = {
        'company_id': _companyId,
        'company_name': inviterCompany?['name'] ?? inviterCompanyName,
        'primary_name': ownerName,
        'primary_email': inviterCompany?['email'] ?? '',
        'type': 'referral',
        'notes': 'Added via collaborator invitation',
        'is_active': true,
      };
      
      final newClient = await _supabaseService.createClient(clientData);
      debugPrint('AuthProvider: Created client from inviter - ${newClient['id']}');
      
      // 4. Create a draft proposal with the collaborator's line items
      final originalQuote = invitation['quotes'];
      final collaboratorLineItems = invitation['line_items'] as List<dynamic>?;
      
      if (originalQuote != null) {
        final proposalData = {
          'company_id': _companyId,
          'client_id': newClient['id'],
          'title': originalQuote['title'] ?? 'Project Proposal',
          'recipient_name': ownerName,
          'status': 'draft',
          'line_items': collaboratorLineItems ?? [],
          'notes': 'Created from collaboration invite',
          'start_date': originalQuote['start_date'],
          'total_days': originalQuote['total_days'],
        };
        
        final newProposal = await _supabaseService.createQuote(proposalData);
        debugPrint('AuthProvider: Created draft proposal - ${newProposal['id']}');
      }
      
      debugPrint('AuthProvider: Viral loop complete!');
    } catch (e) {
      debugPrint('AuthProvider: Error processing collaborator invite - $e');
      // Don't fail the signup if invite processing fails
    }
  }

  /// Process invite for existing user who logs in (simpler flow - just accept invite)
  Future<void> processInviteForExistingUser(String inviteToken) async {
    if (_profile == null || _companyId == null) return;
    
    try {
      debugPrint('AuthProvider: Processing invite for existing user');
      
      // Get invitation
      final invitation = await _supabaseService.client
          .from('collaborator_invitations')
          .select('*, quotes(id, title, recipient_name, line_items, start_date, total_days)')
          .eq('token', inviteToken)
          .maybeSingle();
      
      if (invitation == null || invitation['collaborator_profile_id'] != null) {
        return; // Already processed or not found
      }

      // Update invitation
      await _supabaseService.client
          .from('collaborator_invitations')
          .update({
            'collaborator_profile_id': userId,
            'status': 'accepted',
          })
          .eq('token', inviteToken);

      // Check if inviter's company is already a client
      final inviterCompanyId = invitation['company_id'];
      final existingClients = await _supabaseService.client
          .from('clients')
          .select('id')
          .eq('company_id', _companyId!)
          .eq('company_name', invitation['company_name'] ?? '');
      
      String clientId;
      if (existingClients.isEmpty) {
        // Create client
        final clientData = {
          'company_id': _companyId,
          'company_name': invitation['company_name'] ?? 'Client',
          'primary_name': invitation['owner_name'] ?? '',
          'type': 'referral',
          'is_active': true,
        };
        final newClient = await _supabaseService.createClient(clientData);
        clientId = newClient['id'];
      } else {
        clientId = existingClients.first['id'];
      }

      // Create draft proposal if quote exists
      final originalQuote = invitation['quotes'];
      if (originalQuote != null) {
        final proposalData = {
          'company_id': _companyId,
          'client_id': clientId,
          'title': originalQuote['title'] ?? 'Project Proposal',
          'recipient_name': invitation['owner_name'] ?? '',
          'status': 'draft',
          'line_items': invitation['line_items'] ?? [],
          'notes': 'Created from collaboration invite',
        };
        await _supabaseService.createQuote(proposalData);
      }
      
      debugPrint('AuthProvider: Invite processed for existing user');
    } catch (e) {
      debugPrint('AuthProvider: Error processing invite for existing user - $e');
    }
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

  /// Load existing profile after sign in (Supabase Auth)
  Future<void> _loadUserProfile(String authUserId) async {
    debugPrint('AuthProvider._loadUserProfile: Looking for profile with authUserId=$authUserId');
    try {
      // For Supabase Auth, the user ID is stored in clerk_id column (legacy naming)
      // Try by clerk_id first (most common case)
      _profile = await _supabaseService.getProfileBySupabaseUserId(authUserId);
      
      // If not found, try by profile id
      if (_profile == null) {
        debugPrint('AuthProvider._loadUserProfile: Not found by clerk_id, trying profile id');
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
      } else {
        debugPrint('AuthProvider._loadUserProfile: No profile found - will need to create one');
      }
    } catch (e) {
      debugPrint('AuthProvider._loadUserProfile: Error - $e');
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
