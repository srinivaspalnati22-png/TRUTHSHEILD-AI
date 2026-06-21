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

class MessageScannerScreen extends ConsumerStatefulWidget {
  const MessageScannerScreen({super.key});

  @override
  ConsumerState<MessageScannerScreen> createState() =>
      _MessageScannerScreenState();
}

class _MessageScannerScreenState extends ConsumerState<MessageScannerScreen> {
  final _controller = TextEditingController();
  bool _isAnalyzing = false;
  ScanResult? _result;
  String _selectedType = 'message';

  final _types = [
    {'value': 'message', 'label': 'SMS/WhatsApp', 'icon': Icons.message},
    {'value': 'email', 'label': 'Email', 'icon': Icons.email},
    {'value': 'telegram', 'label': 'Telegram', 'icon': Icons.telegram},
    {'value': 'job_offer', 'label': 'Job Offer', 'icon': Icons.work},
    {'value': 'internship', 'label': 'Internship', 'icon': Icons.school},
  ];

  Future<void> _analyze() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste a message to analyze')),
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
      final result = await aiService.analyzeMessage(
        userId: user?.uid ?? 'anonymous',
        content: _controller.text.trim(),
        contentType: _selectedType,
      );

      // Save to history
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
        title: const Text('Message Scanner'),
        backgroundColor: Colors.transparent,
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _types.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final type = _types[index];
                  final isSelected = _selectedType == type['value'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type['value'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.2)
                            : AppColors.darkCard,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.darkBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type['icon'] as IconData,
                            size: 16,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.darkSubtext,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            type['label'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.darkSubtext,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // Text input
            GlassCard(
              padding: EdgeInsets.zero,
              child: TextField(
                controller: _controller,
                maxLines: 8,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontSize: 14,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Paste the suspicious message here...\n\nExample: "Congratulations! You\'ve been selected for Amazon internship. Pay ₹999 registration fee to confirm your slot."',
                  hintStyle: TextStyle(
                    color: AppColors.darkSubtext.withOpacity(0.6),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _result = null);
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1),

            const SizedBox(height: 16),

            // Analyze button or Animation
            if (_isAnalyzing)
              const ScanningAnimation()
            else ...[
              PrimaryButton(
                label: 'Analyze with AI',
                icon: Icons.security,
                onPressed: _analyze,
              ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

              const SizedBox(height: 24),

              // Results
              if (_result != null) _buildResults(_result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults(ScanResult result) {
    final color = AppColors.trustScoreColor(result.trustScore);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trust Score Card
        GlassCard(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              AppColors.darkCard,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: color.withOpacity(0.3),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.threatLevelLabel,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.summary,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.darkSubtext,
                          ),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: result.trustScore / 100,
                          backgroundColor: AppColors.darkBorder,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Trust Score: ${result.trustScore}/100',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.darkSubtext,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  TrustScoreGauge(score: result.trustScore, size: 100),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),

        const SizedBox(height: 16),

        // Red Flags
        if (result.redFlags.isNotEmpty) ...[
          _buildFlagSection(
            title: 'Red Flags Detected',
            items: result.redFlags,
            color: AppColors.danger,
            icon: Icons.flag,
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 12),
        ],

        // Positive Signals
        if (result.positiveSignals.isNotEmpty) ...[
          _buildFlagSection(
            title: 'Positive Signals',
            items: result.positiveSignals,
            color: AppColors.secondary,
            icon: Icons.check_circle,
          ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 12),
        ],

        // Explanation (XAI)
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Explanation',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(result.confidence * 100).round()}% confident',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                result.explanation,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.darkSubtext,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildFlagSection({
    required String title,
    required List<String> items,
    required Color color,
    required IconData icon,
  }) {
    return GlassCard(
      borderColor: color.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (flag) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      flag,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.darkSubtext,
                      ),
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
