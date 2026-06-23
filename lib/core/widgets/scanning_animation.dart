import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class ScanningAnimation extends StatefulWidget {
  final String? label;
  const ScanningAnimation({super.key, this.label});

  @override
  State<ScanningAnimation> createState() => _ScanningAnimationState();
}

class _ScanningAnimationState extends State<ScanningAnimation>
    with TickerProviderStateMixin {
  late AnimationController _rotateCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _radarCtrl;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _radarCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    _radarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: AnimatedBuilder(
                animation: Listenable.merge(
                    [_rotateCtrl, _pulseCtrl, _radarCtrl]),
                builder: (context, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulsing ring
                      Opacity(
                        opacity: 0.2 + _pulseCtrl.value * 0.3,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                      // Mid ring rotating
                      Transform.rotate(
                        angle: _rotateCtrl.value * 2 * math.pi,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.secondary.withOpacity(0.6),
                              width: 2,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.secondary,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary,
                                    blurRadius: 8,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Radar sweep
                      ClipOval(
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: CustomPaint(
                            painter: _RadarPainter(
                              angle: _radarCtrl.value * 2 * math.pi,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      // Core shield icon with glow
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(
                                  0.4 + _pulseCtrl.value * 0.3),
                              blurRadius: 20 + _pulseCtrl.value * 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.security,
                            color: Colors.white, size: 28),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
            // Animated dots label
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Gemini AI Analyzing',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                ...List.generate(3, (i) => Container(
                      margin: const EdgeInsets.only(left: 3),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .scale(
                          begin: const Offset(0.4, 0.4),
                          end: const Offset(1.0, 1.0),
                          duration: 600.ms,
                          delay: Duration(milliseconds: 200 * i),
                        )
                        .then()
                        .scale(
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(0.4, 0.4),
                          duration: 600.ms,
                        )),
              ],
            ).animate().fadeIn(duration: 600.ms),
            const SizedBox(height: 8),
            Text(
              widget.label ?? 'Scanning for phishing, fraud & anomalies',
              style: const TextStyle(
                color: AppColors.darkSubtext,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double angle;
  final Color color;
  _RadarPainter({required this.angle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw sweep gradient
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: angle - 1.2,
        endAngle: angle,
        colors: [
          color.withOpacity(0),
          color.withOpacity(0.35),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);

    // Draw sweep line
    final linePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      center,
      Offset(center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle)),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.angle != angle;
}
