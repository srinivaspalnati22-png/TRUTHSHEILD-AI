import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/services/background_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        await _requestPermissionsAndProceed();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _isGoogleLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      if (mounted) {
        await _requestPermissionsAndProceed();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  /// Shows permission dialog then navigates to home
  Future<void> _requestPermissionsAndProceed() async {
    final bgService = ref.read(backgroundServiceProvider);
    final isGranted = await bgService.isNotificationListenerGranted();

    if (!isGranted && mounted) {
      // Show permission dialog
      final granted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.15),
                ),
                child: const Icon(Icons.shield, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Enable Background Protection',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TrustShield AI can monitor your notifications to detect scams in real-time — even when the app is closed.',
                style: TextStyle(color: AppColors.darkSubtext, height: 1.5),
              ),
              const SizedBox(height: 16),
              _buildPermissionFeature(
                Icons.notifications_active,
                'Real-time scam detection',
                'Scans WhatsApp, SMS, Gmail, Telegram',
              ),
              const SizedBox(height: 8),
              _buildPermissionFeature(
                Icons.warning_amber,
                'Instant threat alerts',
                'Get notified before you respond',
              ),
              const SizedBox(height: 8),
              _buildPermissionFeature(
                Icons.lock_outline,
                'Privacy-first design',
                'Messages are analyzed locally, never stored',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Skip for now',
                  style: TextStyle(color: AppColors.darkSubtext)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enable Protection'),
            ),
          ],
        ),
      );

      if (granted == true && mounted) {
        await bgService.requestNotificationListenerPermission();
        // Small delay to let system settings open
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    if (mounted) context.go('/home');
  }

  Widget _buildPermissionFeature(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
              Text(subtitle,
                  style: TextStyle(
                    color: AppColors.darkSubtext,
                    fontSize: 11,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B1220), Color(0xFF0D1835), Color(0xFF0B1220)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Top glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.08),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Logo & Title
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.3),
                              AppColors.secondary.withOpacity(0.2),
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.5),
                          ),
                        ),
                        child: const Icon(
                          Icons.shield,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.primaryGradient.createShader(bounds),
                        child: const Text(
                          'TrustShield AI',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),

                  const SizedBox(height: 48),

                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ).animate(delay: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2),

                  const SizedBox(height: 8),

                  Text(
                    'Sign in to your TrustShield account',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.darkSubtext,
                    ),
                  ).animate(delay: 150.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2),

                  const SizedBox(height: 40),

                  // Login form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.darkText),
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'you@example.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email required';
                            if (!v.contains('@')) return 'Invalid email';
                            return null;
                          },
                        ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),

                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: AppColors.darkText),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password required';
                            if (v.length < 6) return 'Min 6 characters';
                            return null;
                          },
                        ).animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),

                        const SizedBox(height: 12),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.go('/auth/forgot-password'),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

                        const SizedBox(height: 24),

                        // Login button
                        PrimaryButton(
                          label: 'Sign In',
                          icon: Icons.login,
                          isLoading: _isLoading,
                          onPressed: _login,
                        ).animate(delay: 350.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),

                        const SizedBox(height: 20),

                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.darkBorder)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: AppColors.darkSubtext,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppColors.darkBorder)),
                          ],
                        ).animate(delay: 400.ms).fadeIn(),

                        const SizedBox(height: 20),

                        // Google Sign In
                        OutlinedButton.icon(
                          onPressed: _isGoogleLoading ? null : _googleLogin,
                          icon: _isGoogleLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.g_mobiledata, size: 24),
                          label: Text(
                            _isGoogleLoading ? 'Signing in...' : 'Continue with Google',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.darkText,
                            side: const BorderSide(color: AppColors.darkBorder),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 0),
                          ),
                        ).animate(delay: 450.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),

                        const SizedBox(height: 32),

                        // Sign up link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(color: AppColors.darkSubtext),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/auth/signup'),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
