import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/auth/login');
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // Animated background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0B1220),
                  Color(0xFF0D1A35),
                  Color(0xFF0B1220),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Particle dots in background
          ...List.generate(20, (i) => _buildParticle(i)),

          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Shield logo with glow
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(
                              0.3 + _pulseController.value * 0.4,
                            ),
                            blurRadius: 40 + _pulseController.value * 20,
                            spreadRadius: 10 + _pulseController.value * 10,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.2),
                          AppColors.primary.withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.shield,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 500.ms),

                const SizedBox(height: 32),

                // App name
                ShaderMask(
                  shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                  child: const Text(
                    'TrustShield AI',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, duration: 600.ms, curve: Curves.easeOut),

                const SizedBox(height: 8),

                Text(
                  'Know Before You Trust',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.darkSubtext,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w400,
                  ),
                )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, duration: 600.ms, curve: Curves.easeOut),

                const SizedBox(height: 80),

                // Loading indicator
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.darkBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
                    .animate(delay: 800.ms)
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 16),

                Text(
                  'Initializing AI Shield...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.darkSubtext,
                  ),
                )
                    .animate(delay: 1000.ms)
                    .fadeIn(duration: 400.ms),
              ],
            ),
          ),

          // Version tag at bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'v1.0.0 • Powered by Gemini AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.darkSubtext.withOpacity(0.6),
              ),
            ).animate(delay: 1200.ms).fadeIn(duration: 500.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildParticle(int index) {
    final positions = [
      const Offset(0.1, 0.1), const Offset(0.9, 0.1),
      const Offset(0.3, 0.2), const Offset(0.7, 0.15),
      const Offset(0.05, 0.4), const Offset(0.95, 0.35),
      const Offset(0.15, 0.7), const Offset(0.85, 0.65),
      const Offset(0.4, 0.85), const Offset(0.6, 0.9),
      const Offset(0.25, 0.5), const Offset(0.75, 0.5),
      const Offset(0.5, 0.1), const Offset(0.5, 0.95),
      const Offset(0.2, 0.35), const Offset(0.8, 0.4),
      const Offset(0.35, 0.65), const Offset(0.65, 0.7),
      const Offset(0.1, 0.85), const Offset(0.9, 0.8),
    ];
    final pos = positions[index % positions.length];

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width * pos.dx,
          top: MediaQuery.of(context).size.height * pos.dy,
          child: Opacity(
            opacity: _particleController.value * 0.6,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index.isEven ? AppColors.primary : AppColors.secondary,
                boxShadow: [
                  BoxShadow(
                    color: (index.isEven ? AppColors.primary : AppColors.secondary)
                        .withOpacity(0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
