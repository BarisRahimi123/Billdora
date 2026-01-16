import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      _emailSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.lock_reset, size: 32, color: AppColors.blue),
          ),
          const SizedBox(height: 24),
          Text('Reset Password', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text("Enter your email address and we'll send you a link to reset your password.", style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blue, width: 2)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your email';
              if (!value.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleResetPassword,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Send Reset Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: AppColors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.check_circle, size: 32, color: AppColors.green),
        ),
        const SizedBox(height: 24),
        Text('Check Your Email', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text("We've sent a password reset link to ${_emailController.text}", style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        const SizedBox(height: 32),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Back to Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
