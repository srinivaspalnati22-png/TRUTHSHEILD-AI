import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/services/ai_service.dart';

class FactCheckScreen extends ConsumerStatefulWidget {
  const FactCheckScreen({super.key});

  @override
  ConsumerState<FactCheckScreen> createState() => _FactCheckScreenState();
}

class _FactCheckScreenState extends ConsumerState<FactCheckScreen> {
  final _controller = TextEditingController();
  bool _isChecking = false;
  Map<String, dynamic>? _result;

  Future<void> _checkFact() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _isChecking = true;
      _result = null;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final result = await aiService.factCheck(_controller.text.trim());
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fact check failed: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Fact Verification'),
        backgroundColor: Colors.transparent,
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              gradient: LinearGradient(colors: [
                AppColors.info.withOpacity(0.1),
                AppColors.darkCard,
              ]),
              borderColor: AppColors.info.withOpacity(0.2),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.info.withOpacity(0.2),
                  ),
                  child: const Icon(Icons.fact_check, color: AppColors.info),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AI Fact Verification',
                          style: TextStyle(
                              color: AppColors.darkText,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      Text('Claims • News • Social Media • Articles',
                          style: TextStyle(fontSize: 12, color: AppColors.darkSubtext)),
                    ],
                  ),
                ),
              ]),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            GlassCard(
              padding: EdgeInsets.zero,
              child: TextField(
                controller: _controller,
                maxLines: 6,
                style: const TextStyle(color: AppColors.darkText, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Paste a claim, news headline, or social media post...\n\nExample: "The government is distributing free laptops to all students who register here."',
                  hintStyle: TextStyle(
                      color: AppColors.darkSubtext.withOpacity(0.6), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            PrimaryButton(
              label: _isChecking ? 'Verifying...' : 'Check Facts',
              icon: _isChecking ? null : Icons.search,
              isLoading: _isChecking,
              onPressed: _checkFact,
              backgroundColor: AppColors.info,
            ).animate(delay: 200.ms).fadeIn(),

            const SizedBox(height: 24),

            if (_result != null) _buildResults(_result!),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(Map<String, dynamic> result) {
    final verdict = result['verdict'] as String? ?? 'unverifiable';
    final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.5;
    final summary = result['summary'] as String? ?? '';
    final evidence = List<String>.from(result['evidence'] ?? []);
    final explanation = result['explanation'] as String? ?? '';

    Color verdictColor;
    IconData verdictIcon;
    String verdictLabel;

    switch (verdict) {
      case 'true':
        verdictColor = AppColors.secondary;
        verdictIcon = Icons.verified;
        verdictLabel = '✅ TRUE';
        break;
      case 'partially_true':
        verdictColor = AppColors.warning;
        verdictIcon = Icons.info_outline;
        verdictLabel = '⚠️ PARTIALLY TRUE';
        break;
      case 'misleading':
        verdictColor = Colors.orange;
        verdictIcon = Icons.warning_amber;
        verdictLabel = '⚡ MISLEADING';
        break;
      case 'false':
        verdictColor = AppColors.danger;
        verdictIcon = Icons.cancel;
        verdictLabel = '❌ FALSE';
        break;
      default:
        verdictColor = AppColors.darkSubtext;
        verdictIcon = Icons.help_outline;
        verdictLabel = '❓ UNVERIFIABLE';
    }

    return Column(
      children: [
        GlassCard(
          borderColor: verdictColor.withOpacity(0.3),
          gradient: LinearGradient(colors: [
            verdictColor.withOpacity(0.1),
            AppColors.darkCard,
          ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(verdictIcon, color: verdictColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(verdictLabel,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: verdictColor)),
                      Text(summary,
                          style: TextStyle(
                              fontSize: 13, color: AppColors.darkSubtext)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Text('Confidence: ',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.darkSubtext)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: confidence,
                      backgroundColor: AppColors.darkBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(verdictColor),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(confidence * 100).round()}%',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: verdictColor)),
              ]),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),

        const SizedBox(height: 12),

        if (evidence.isNotEmpty)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.search, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text('Evidence Found',
                      style: TextStyle(
                          color: AppColors.darkText, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 12),
                ...evidence.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(e,
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
                Text('Detailed Analysis',
                    style: TextStyle(
                        color: AppColors.darkText, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 12),
              Text(explanation,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.darkSubtext, height: 1.6)),
            ],
          ),
        ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),

        const SizedBox(height: 80),
      ],
    );
  }
}
