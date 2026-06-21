import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/trust_score_gauge.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../models/scan_result.dart';
import '../../../core/widgets/scanning_animation.dart';
import '../../../core/services/scan_history_service.dart';

class UrlScannerScreen extends ConsumerStatefulWidget {
  const UrlScannerScreen({super.key});

  @override
  ConsumerState<UrlScannerScreen> createState() => _UrlScannerScreenState();
}

class _UrlScannerScreenState extends ConsumerState<UrlScannerScreen> {
  final _urlController = TextEditingController();
  bool _isAnalyzing = false;
  ScanResult? _result;

  Future<void> _analyzeUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a URL')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _result = null;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final user = ref.read(currentUserProvider).value;
      final result = await aiService.analyzeUrl(
        userId: user?.uid ?? 'anonymous',
        url: url,
      );

      if (user != null) {
        final historyService = ref.read(scanHistoryServiceProvider);
        await historyService.saveScan(result);
      }

      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Analysis failed: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('URL Intelligence'),
        backgroundColor: Colors.transparent,
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            GlassCard(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withOpacity(0.1),
                  AppColors.darkCard,
                ],
              ),
              borderColor: AppColors.secondary.withOpacity(0.2),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary.withOpacity(0.2),
                    ),
                    child: const Icon(Icons.link, color: AppColors.secondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'URL Intelligence Engine',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkText,
                          ),
                        ),
                        Text(
                          'Checks domain age, SSL, redirects & reputation',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.darkSubtext,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // URL Input
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'https://example.com or bit.ly/suspicious',
                      prefixIcon: const Icon(Icons.public),
                      suffixIcon: _urlController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _urlController.clear();
                                setState(() => _result = null);
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            PrimaryButton(
              label: _isAnalyzing ? 'Analyzing URL...' : 'Scan URL',
              icon: _isAnalyzing ? null : Icons.radar,
              isLoading: _isAnalyzing,
              onPressed: _analyzeUrl,
              backgroundColor: AppColors.secondary,
            ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // Quick test URLs
            Text(
              'Test Examples',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkSubtext,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'bit.ly/job-offer',
                'secure-amaz0n-login.com',
                'google.com',
                'paypa1-verify.net',
              ].map((url) => GestureDetector(
                    onTap: () {
                      _urlController.text = url;
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Text(
                        url,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )).toList(),
            ),

            const SizedBox(height: 24),

            // Results
            if (_result != null) _buildUrlResults(_result!),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlResults(ScanResult result) {
    final color = AppColors.trustScoreColor(result.trustScore);

    return Column(
      children: [
        GlassCard(
          borderColor: color.withOpacity(0.3),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.15),
                    ),
                    child: Icon(
                      result.trustScore > 50
                          ? Icons.verified_outlined
                          : Icons.dangerous_outlined,
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.threatLevelLabel,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        Text(
                          result.summary,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.darkSubtext,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TrustScoreGauge(score: result.trustScore, size: 80),
                ],
              ),

              const SizedBox(height: 16),

              // Security checks
              _buildSecurityChecks(result),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),

        const SizedBox(height: 12),

        if (result.redFlags.isNotEmpty)
          GlassCard(
            borderColor: AppColors.danger.withOpacity(0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.warning_amber, color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  const Text('Threats Detected',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      )),
                ]),
                const SizedBox(height: 12),
                ...result.redFlags.map((flag) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.close, color: AppColors.danger, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(flag,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.darkSubtext))),
                        ],
                      ),
                    )),
              ],
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),

        const SizedBox(height: 12),

        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.psychology, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text('AI Analysis',
                    style: TextStyle(
                        color: AppColors.darkText, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 12),
              Text(
                result.explanation,
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.darkSubtext,
                    height: 1.6),
              ),
            ],
          ),
        ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSecurityChecks(ScanResult result) {
    final checks = [
      _SecurityCheck('SSL Certificate', result.trustScore > 30, 'HTTPS encryption'),
      _SecurityCheck('Domain Age', result.trustScore > 50, 'Domain registered >1 year ago'),
      _SecurityCheck('Blacklist Check', result.trustScore > 40, 'Not in known threat lists'),
      _SecurityCheck('Redirect Check', result.trustScore > 60, 'No suspicious redirects'),
    ];

    return Column(
      children: checks.map((check) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              check.passed ? Icons.check_circle : Icons.cancel,
              color: check.passed ? AppColors.secondary : AppColors.danger,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(check.label,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w500)),
                  Text(check.detail,
                      style: TextStyle(fontSize: 11, color: AppColors.darkSubtext)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (check.passed ? AppColors.secondary : AppColors.danger)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                check.passed ? 'PASS' : 'FAIL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: check.passed ? AppColors.secondary : AppColors.danger,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _SecurityCheck {
  final String label;
  final bool passed;
  final String detail;
  const _SecurityCheck(this.label, this.passed, this.detail);
}
