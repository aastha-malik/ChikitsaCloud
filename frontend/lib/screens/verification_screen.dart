import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../presentation/providers/auth_provider.dart';
import '../routes/app_routes.dart';

class VerificationScreen extends StatefulWidget {
  final String email;

  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.verifyEmail(
        widget.email,
        _codeController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully!')),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.userInfo);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? 'Verification failed')),
        );
      }
    }
  }

  Future<void> _handleResend() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resendVerification(widget.email);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Verification code sent successfully!' 
                : (authProvider.errorMessage ?? 'Failed to resend code'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F2F1),
              Color(0xFFECEFF1),
              Color(0xFFE0F7FA),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mark_email_read_outlined,
                      color: AppTheme.primaryColor,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Verify Email",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enter the 6-digit code sent to ${widget.email}",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomTextField(
                      label: "Verification Code",
                      controller: _codeController,
                      hintText: "123456",
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the code';
                        }
                        if (value.length < 4) {
                          return 'Invalid code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: "Verify",
                      isLoading: authProvider.isLoading,
                      onPressed: _handleVerify,
                    ),
                    const SizedBox(height: 16),
                    authProvider.isLoading 
                      ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                      : TextButton(
                          onPressed: _handleResend,
                          child: const Text("Resend Code"),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
