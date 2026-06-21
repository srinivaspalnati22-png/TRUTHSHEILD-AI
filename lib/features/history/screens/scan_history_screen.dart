import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/scan_history_service.dart';

class ScanHistoryScreen extends ConsumerWidget {
  const ScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Scan History'),
        backgroundColor: Colors.transparent,
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please login to view history'));
          }

          final historyService = ref.watch(scanHistoryServiceProvider);
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: historyService.getUserScans(user.uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary));
              }

              final scans = snap.data ?? [];

              if (scans.isEmpty) {
                return _buildEmptyState();
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Analytics card
                  _buildAnalyticsCard(scans).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 20),
                  Text(
                    'Recent Scans',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText),
                  ).animate(delay: 100.ms).fadeIn(),
                  const SizedBox(height: 12),
                  ...scans.asMap().entries.map((entry) {
                    final index = entry.key;
                    final scan = entry.value;
                    return _ScanHistoryCard(scan: scan)
                        .animate(
                            delay: Duration(milliseconds: 80 * index))
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.1);
                  }),
                  const SizedBox(height: 80),
                ],
              );
            },
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 80, color: AppColors.darkSubtext),
          const SizedBox(height: 16),
          const Text('No Scans Yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText)),
          Text('Your scan history will appear here',
              style: TextStyle(color: AppColors.darkSubtext)),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _buildAnalyticsCard(List<Map<String, dynamic>> scans) {
    final total = scans.length;
    final threats = scans
        .where((s) =>
            s['threatLevel'] == 'high' || s['threatLevel'] == 'critical')
        .length;
    final safe = scans.where((s) => s['threatLevel'] == 'safe').length;
    final avgTrust = total > 0
        ? scans
                .map((s) => (s['trustScore'] as num?)?.toInt() ?? 50)
                .reduce((a, b) => a + b) /
            total
        : 0.0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Safety Stats',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText)),
          const SizedBox(height: 16),
          Row(children: [
            _StatItem(value: '$total', label: 'Total\nScans', color: AppColors.primary),
            _StatItem(value: '$threats', label: 'Threats\nDetected', color: AppColors.danger),
            _StatItem(value: '$safe', label: 'Safe\nItems', color: AppColors.secondary),
            _StatItem(
                value: '${avgTrust.round()}',
                label: 'Avg\nTrust Score',
                color: AppColors.warning),
          ]),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatItem({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color)),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.darkSubtext, height: 1.3)),
        ],
      ),
    );
  }
}

class _ScanHistoryCard extends StatelessWidget {
  final Map<String, dynamic> scan;
  const _ScanHistoryCard({required this.scan});

  @override
  Widget build(BuildContext context) {
    final trustScore = (scan['trustScore'] as num?)?.toInt() ?? 50;
    final scoreColor = AppColors.trustScoreColor(trustScore);
    final threatLevel = scan['threatLevel'] as String? ?? 'medium';
    final scanType = scan['scanType'] as String? ?? 'message';
    final preview = scan['contentPreview'] as String? ?? '';
    final timestamp = (scan['timestamp'] as dynamic)?.toDate?.call();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withOpacity(0.15),
            ),
            child: Center(
              child: Text(
                '$trustScore',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scoreColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.darkBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        scanType.toUpperCase(),
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkSubtext),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        threatLevel.toUpperCase(),
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: scoreColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  preview.isNotEmpty ? preview : 'Scan complete',
                  style: TextStyle(fontSize: 13, color: AppColors.darkText),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (timestamp != null)
                  Text(
                    _formatTime(timestamp),
                    style: TextStyle(fontSize: 11, color: AppColors.darkSubtext),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
