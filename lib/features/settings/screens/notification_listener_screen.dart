import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

/// Provider for notification data arriving from the Android native service
final notificationDataProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

class NotificationListenerScreen extends ConsumerStatefulWidget {
  const NotificationListenerScreen({super.key});

  @override
  ConsumerState<NotificationListenerScreen> createState() =>
      _NotificationListenerScreenState();
}

class _NotificationListenerScreenState
    extends ConsumerState<NotificationListenerScreen> {
  final List<Map<String, dynamic>> _alerts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Notification Monitor'),
        backgroundColor: Colors.transparent,
        actions: [
          if (_alerts.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() => _alerts.clear()),
              icon: const Icon(Icons.clear_all, color: AppColors.darkSubtext),
              label: const Text('Clear',
                  style: TextStyle(color: AppColors.darkSubtext)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Status Header
          _StatusHeader(alertCount: _alerts.length),

          // Alert List
          Expanded(
            child: _alerts.isEmpty
                ? _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      final alert = _alerts[_alerts.length - 1 - index];
                      return _AlertCard(alert: alert)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: 0.1);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final int alertCount;
  const _StatusHeader({required this.alertCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withOpacity(0.15),
            ),
            child: const Icon(Icons.notifications_active,
                color: AppColors.secondary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monitoring Active',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Watching WhatsApp, Gmail, Telegram & more',
                  style: TextStyle(
                      color: AppColors.darkSubtext, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: alertCount > 0
                  ? AppColors.danger.withOpacity(0.15)
                  : AppColors.darkCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$alertCount alert${alertCount != 1 ? 's' : ''}',
              style: TextStyle(
                color: alertCount > 0
                    ? AppColors.danger
                    : AppColors.darkSubtext,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final trustScore = alert['trustScore'] as int? ?? 50;
    final color = AppColors.trustScoreColor(trustScore);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert['appName'] as String? ?? 'Unknown App',
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Trust: $trustScore',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (alert['title'] != null && (alert['title'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              alert['title'] as String,
              style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            alert['content'] as String? ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: AppColors.darkSubtext, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time,
                  size: 12, color: AppColors.darkSubtext),
              const SizedBox(width: 4),
              Text(
                _formatTime(alert['timestamp'] as int?),
                style: TextStyle(
                    color: AppColors.darkSubtext, fontSize: 11),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View Details',
                    style: TextStyle(
                        color: AppColors.primary, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  String _formatTime(int? ms) {
    if (ms == null) return 'Just now';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withOpacity(0.1),
            ),
            child: const Icon(Icons.shield_outlined,
                size: 40, color: AppColors.secondary),
          ),
          const SizedBox(height: 20),
          const Text(
            'All Clear',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No suspicious notifications detected.\nYour inbox is clean.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.darkSubtext,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle,
                    size: 14, color: AppColors.secondary),
                SizedBox(width: 6),
                Text(
                  'Monitoring 7 apps',
                  style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9));
  }
}
