import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../presentation/providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isResetStep = false;
  String? _email;
  bool _isAutoInitiated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final String? args = ModalRoute.of(context)?.settings.arguments as String?;
      
      if (authProvider.isAuthenticated && authProvider.userEmail != null) {
        setState(() {
          _email = authProvider.userEmail;
          _emailController.text = _email!;
          _isAutoInitiated = true;
        });
      } else if (args != null && args.isNotEmpty) {
        setState(() {
          _emailController.text = args;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = context.read<AuthProvider>();
    
    if (!_isResetStep) {
      // Request Reset Code
      final success = await authProvider.forgotPassword(_emailController.text.trim());
      if (success && mounted) {
        setState(() {
          _email = _emailController.text.trim();
          _isResetStep = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reset code sent to your email')),
        );
      } else if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? 'Failed to send code')),
        );
      }
    } else {
      // Confirm Reset
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      final success = await authProvider.resetPassword(
        _email!,
        _codeController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully. Please login.')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? 'Failed to reset password')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isResetStep 
          ? 'Set New Password' 
          : (_isAutoInitiated ? 'Reset Password' : 'Forgot Password')),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                _isResetStep ? Icons.lock_open : Icons.lock_reset,
                size: 60,
                color: AppTheme.primaryColor
              ),
              const SizedBox(height: 24),
              Text(
                _isResetStep 
                  ? 'Enter the 6-digit code sent to $_email and your new password.'
                  : (_isAutoInitiated 
                      ? 'We will send a password reset code to your registered email: $_email'
                      : 'Enter your email address to receive a password reset code.'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16),
              ),
              const SizedBox(height: 32),
              
              if (!_isResetStep && !_isAutoInitiated)
                CustomTextField(
                  label: 'Email Address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Email is required';
                    if (!val.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
              
              if (_isResetStep) ...[
                CustomTextField(
                  label: 'Verification Code',
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  validator: (val) => (val == null || val.length < 6) ? 'Enter valid 6-digit code' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'New Password',
                  controller: _passwordController,
                  obscureText: true,
                  validator: (val) => (val == null || val.length < 6) ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Confirm New Password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  validator: (val) => val != _passwordController.text ? 'Passwords do not match' : null,
                ),
              ],
              
              const SizedBox(height: 40),
              PrimaryButton(
                text: _isResetStep ? 'Reset Password' : 'Send Reset Code',
                isLoading: authProvider.isLoading,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
