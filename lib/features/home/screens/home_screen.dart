import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/trust_score_gauge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.darkBg,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(currentUser),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.go('/settings'),
              ),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Protection Status Card
                _buildProtectionStatus(),

                const SizedBox(height: 20),

                // Quick Scan Actions
                Text(
                  'Quick Scan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 12),

                _buildQuickScanGrid(context),

                const SizedBox(height: 20),

                // Recent Threats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Scans',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/history'),
                      child: const Text(
                        'View All',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 12),

                _buildRecentScans(),

                const SizedBox(height: 20),

                // Community Threats
                _buildCommunityAlert(context),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AsyncValue currentUser) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.darkBg,
            AppColors.darkSurface.withOpacity(0.5),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          currentUser.when(
            data: (user) => Text(
              'Hello, ${user?.displayName.split(' ').first ?? 'User'} 👋',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),
          Text(
            'Your shield is active and protecting you',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.darkSubtext,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionStatus() {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.secondaryGradient,
            ),
            child: const Icon(Icons.verified_user, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Protection Active',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  'AI Shield monitoring your messages',
                  style: TextStyle(fontSize: 13, color: AppColors.darkSubtext),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2);
  }

  Widget _buildQuickScanGrid(BuildContext context) {
    final items = [
      _ScanItem(
        icon: Icons.message_outlined,
        label: 'Message\nScanner',
        color: AppColors.primary,
        path: '/scanner/message',
      ),
      _ScanItem(
        icon: Icons.link,
        label: 'URL\nScanner',
        color: AppColors.secondary,
        path: '/scanner/url',
      ),
      _ScanItem(
        icon: Icons.description_outlined,
        label: 'Offer Letter\nVerify',
        color: AppColors.warning,
        path: '/document/offer-letter',
      ),
      _ScanItem(
        icon: Icons.fact_check_outlined,
        label: 'Fact\nCheck',
        color: AppColors.info,
        path: '/fact-check',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _QuickScanCard(item: item)
            .animate(delay: Duration(milliseconds: 100 * index))
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.3, curve: Curves.easeOut);
      }).toList(),
    );
  }

  Widget _buildRecentScans() {
    final mockScans = [
      _MockScan(
        label: 'Amazon Job Message',
        type: 'Message',
        score: 12,
        time: '2 min ago',
        isDanger: true,
      ),
      _MockScan(
        label: 'LinkedIn Recruiter',
        type: 'Message',
        score: 78,
        time: '1 hr ago',
        isDanger: false,
      ),
      _MockScan(
        label: 'http://bit.ly/job-offer',
        type: 'URL',
        score: 8,
        time: '3 hr ago',
        isDanger: true,
      ),
    ];

    return Column(
      children: mockScans.asMap().entries.map((entry) {
        final index = entry.key;
        final scan = entry.value;
        return _RecentScanItem(scan: scan)
            .animate(delay: Duration(milliseconds: 100 * index))
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.1);
      }).toList(),
    );
  }

  Widget _buildCommunityAlert(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/community'),
      child: GlassCard(
        gradient: LinearGradient(
          colors: [
            AppColors.danger.withOpacity(0.15),
            AppColors.warning.withOpacity(0.1),
          ],
        ),
        borderColor: AppColors.danger.withOpacity(0.3),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.danger.withOpacity(0.2),
              ),
              child: const Icon(Icons.warning_amber, color: AppColors.danger, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '47 New Community Reports',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  Text(
                    'Fake internship scam wave detected in your region',
                    style: TextStyle(fontSize: 12, color: AppColors.darkSubtext),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.darkSubtext),
          ],
        ),
      ).animate(delay: 500.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
    );
  }
}

class _QuickScanCard extends StatelessWidget {
  final _ScanItem item;
  const _QuickScanCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(item.path),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.darkCard,
          border: Border.all(color: item.color.withOpacity(0.2)),
          gradient: LinearGradient(
            colors: [item.color.withOpacity(0.1), AppColors.darkCard],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: item.color, size: 28),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentScanItem extends StatelessWidget {
  final _MockScan scan;
  const _RecentScanItem({required this.scan});

  @override
  Widget build(BuildContext context) {
    final scoreColor = AppColors.trustScoreColor(scan.score);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withOpacity(0.15),
            ),
            child: Center(
              child: Text(
                '${scan.score}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${scan.type} • ${scan.time}',
                  style: TextStyle(fontSize: 11, color: AppColors.darkSubtext),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              scan.isDanger ? 'THREAT' : 'SAFE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: scoreColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanItem {
  final IconData icon;
  final String label;
  final Color color;
  final String path;
  const _ScanItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.path,
  });
}

class _MockScan {
  final String label;
  final String type;
  final int score;
  final String time;
  final bool isDanger;
  const _MockScan({
    required this.label,
    required this.type,
    required this.score,
    required this.time,
    required this.isDanger,
  });
}
