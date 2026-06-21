import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../../../core/widgets/primary_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  Future<void> _sendReset() async {
    if (_emailController.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) setState(() => _emailSent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => context.go('/auth/login'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _emailSent ? _buildSuccessState() : _buildFormState(),
      ),
    );
  }

  Widget _buildFormState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.15),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: const Icon(Icons.lock_reset, color: AppColors.primary, size: 32),
        ).animate().scale(begin: const Offset(0, 0)).fadeIn(),

        const SizedBox(height: 24),

        const Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),

        const SizedBox(height: 8),

        Text(
          'Enter your email and we\'ll send you a reset link.',
          style: TextStyle(fontSize: 14, color: AppColors.darkSubtext),
        ).animate(delay: 150.ms).fadeIn(),

        const SizedBox(height: 32),

        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppColors.darkText),
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),

        const SizedBox(height: 24),

        PrimaryButton(
          label: 'Send Reset Link',
          icon: Icons.send,
          isLoading: _isLoading,
          onPressed: _sendReset,
        ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.2),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.secondary.withOpacity(0.15),
            border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
          ),
          child: const Icon(Icons.mark_email_read, color: AppColors.secondary, size: 50),
        ).animate().scale(begin: const Offset(0, 0), curve: Curves.elasticOut),

        const SizedBox(height: 24),

        const Text(
          'Email Sent!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ).animate(delay: 300.ms).fadeIn(),

        const SizedBox(height: 8),

        Text(
          'Check your inbox for a password reset link.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.darkSubtext),
        ).animate(delay: 400.ms).fadeIn(),

        const SizedBox(height: 32),

        PrimaryButton(
          label: 'Back to Login',
          icon: Icons.arrow_back,
          onPressed: () => context.go('/auth/login'),
        ).animate(delay: 500.ms).fadeIn(),
      ],
    );
  }
}
