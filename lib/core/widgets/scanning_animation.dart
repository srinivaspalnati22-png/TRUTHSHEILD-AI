import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class ScanningAnimation extends StatelessWidget {
  const ScanningAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulsing rings
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                 .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5), duration: 2000.ms)
                 .fadeOut(duration: 2000.ms),
                 
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.secondary.withOpacity(0.4), width: 2),
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                 .scale(begin: const Offset(0.2, 0.2), end: const Offset(1.2, 1.2), duration: 2000.ms, delay: 1000.ms)
                 .fadeOut(duration: 2000.ms, delay: 1000.ms),

                // Core shield icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.security, color: Colors.white, size: 36)
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.5)),
                ),
                
                // Scanning laser line
                Positioned(
                  top: 0,
                  child: Container(
                    width: 60,
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                   .moveY(begin: 10, end: 60, duration: 800.ms, curve: Curves.easeInOut),
                )
              ],
            ),
            const SizedBox(height: 32),
            
            // Animated text
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Gemini AI is analyzing',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('...')
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeIn(duration: 400.ms)
                    .then()
                    .fadeOut(duration: 400.ms),
              ],
            ).animate().fadeIn(duration: 600.ms),
            
            const SizedBox(height: 8),
            const Text(
              'Scanning for phishing, fraud, and anomalies',
              style: TextStyle(
                color: AppColors.darkSubtext,
                fontSize: 13,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
