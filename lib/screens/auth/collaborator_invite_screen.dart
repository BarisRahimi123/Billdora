import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';

class CollaboratorInviteScreen extends StatefulWidget {
  final String token;

  const CollaboratorInviteScreen({super.key, required this.token});

  @override
  State<CollaboratorInviteScreen> createState() => _CollaboratorInviteScreenState();
}

class _CollaboratorInviteScreenState extends State<CollaboratorInviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSigningUp = false;
  String? _error;
  Map<String, dynamic>? _invitation;

  @override
  void initState() {
    super.initState();
    _loadInvitation();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadInvitation() async {
    try {
      final supabase = SupabaseService();
      final response = await supabase.client
          .from('collaborator_invitations')
          .select('*, quotes(title, recipient_name, start_date)')
          .eq('token', widget.token)
          .maybeSingle();

      if (response == null) {
        setState(() {
          _error = 'Invitation not found or has expired';
          _isLoading = false;
        });
        return;
      }

      // Check if already accepted
      if (response['collaborator_profile_id'] != null) {
        setState(() {
          _error = 'This invitation has already been accepted';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _invitation = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load invitation: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSigningUp = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final email = _invitation!['collaborator_email'];
      final name = _invitation!['collaborator_name'];
      final nameParts = name.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Sign up with invite token in metadata
      final result = await authProvider.signUpWithInvite(
        email,
        _passwordController.text,
        firstName,
        lastName,
        widget.token,
      );

      if (result.success && mounted) {
        // Navigate to sales/proposals to see their draft
        context.go('/sales?tab=0');
      } else if (result.verificationRequired && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please check your email to verify your account, then log in'),
            backgroundColor: AppColors.cardBackground,
          ),
        );
        context.go('/login');
      } else if (mounted) {
        setState(() {
          _error = result.errorMessage ?? 'Signup failed';
          _isSigningUp = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Signup failed: $e';
        _isSigningUp = false;
      });
    }
  }

  Future<void> _handleLogin() async {
    // Redirect to login with return URL containing the token
    context.go('/login?inviteToken=${widget.token}');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _invitation == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.red),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final projectName = _invitation!['project_name'] ?? _invitation!['quotes']?['title'] ?? 'Project';
    final ownerName = _invitation!['owner_name'] ?? 'A colleague';
    final companyName = _invitation!['company_name'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Welcome header
                Icon(Icons.handshake_outlined, size: 64, color: AppColors.blue),
                const SizedBox(height: 24),
                
                Text(
                  'You\'ve Been Invited!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                Text(
                  '$ownerName${companyName.isNotEmpty ? ' from $companyName' : ''} has invited you to collaborate on:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_outlined, color: AppColors.blue),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          projectName,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Benefits section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'By joining, you\'ll get:',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBenefit('Your own professional invoicing platform'),
                      _buildBenefit('${companyName.isNotEmpty ? companyName : ownerName} as your first client'),
                      _buildBenefit('Submit your pricing for this project'),
                      _buildBenefit('Free to start, upgrade anytime'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Pre-filled info
                Text(
                  'Your Information',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                
                _buildReadOnlyField(
                  label: 'Name',
                  value: _invitation!['collaborator_name'] ?? '',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                
                _buildReadOnlyField(
                  label: 'Email',
                  value: _invitation!['collaborator_email'] ?? '',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),

                // Error message
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.red, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_error!, style: TextStyle(color: AppColors.red))),
                      ],
                    ),
                  ),

                // Password fields
                Text(
                  'Create Your Password',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                
                _buildPasswordField(
                  controller: _passwordController,
                  label: 'Password',
                  obscure: _obscurePassword,
                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Please enter a password';
                    if (v!.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  obscure: _obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) {
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Sign up button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSigningUp ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSigningUp
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Create Account & Join Project', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: _handleLogin,
                      child: Text('Sign in', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
              ],
            ),
          ),
          Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 16),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(Icons.lock_outlined, color: AppColors.textSecondary),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.textSecondary,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blue, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.red)),
      ),
      validator: validator,
    );
  }
}
