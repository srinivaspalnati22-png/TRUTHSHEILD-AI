import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/services/scan_history_service.dart';
import '../../../core/services/background_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _bgActive = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _checkBgStatus();
  }

  Future<void> _checkBgStatus() async {
    final svc = ref.read(backgroundServiceProvider);
    final granted = await svc.isNotificationListenerGranted();
    if (mounted) setState(() => _bgActive = granted);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.darkBg,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(currentUser),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.go('/notifications'),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.go('/settings'),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 12),
                _buildProtectionStatus(),
                const SizedBox(height: 20),
                _buildSectionTitle('Quick Scan', delay: 200),
                const SizedBox(height: 12),
                _buildQuickScanGrid(context),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Recent Scans', delay: 300),
                    TextButton(
                      onPressed: () => context.go('/history'),
                      child: const Text('View All',
                          style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildRecentScans(context, ref),
                const SizedBox(height: 20),
                _buildCommunityAlert(context),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {int delay = 0}) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay));
  }

  Widget _buildHeader(AsyncValue currentUser) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1A35), Color(0xFF0B1220)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          currentUser.when(
            data: (user) => Row(
              children: [
                ShaderMask(
                  shaderCallback: (b) =>
                      AppColors.primaryGradient.createShader(b),
                  child: Text(
                    'Hello, ${_displayName(user?.displayName, user?.email)} 👋',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox(height: 32),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _bgActive ? AppColors.secondary : AppColors.warning,
                    boxShadow: [
                      BoxShadow(
                        color: (_bgActive
                                ? AppColors.secondary
                                : AppColors.warning)
                            .withOpacity(0.3 + _pulseCtrl.value * 0.4),
                        blurRadius: 6 + _pulseCtrl.value * 4,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _bgActive
                    ? 'AI Shield protecting you in background'
                    : 'Enable notification access for full protection',
                style:
                    const TextStyle(fontSize: 13, color: AppColors.darkSubtext),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionStatus() {
    return GestureDetector(
      onTap: () async {
        if (!_bgActive) {
          await ref
              .read(backgroundServiceProvider)
              .requestNotificationListenerPermission();
          _checkBgStatus();
        }
      },
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, child) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: _bgActive
                  ? [
                      AppColors.secondary.withOpacity(0.12),
                      AppColors.primary.withOpacity(0.08),
                    ]
                  : [
                      AppColors.warning.withOpacity(0.12),
                      AppColors.darkCard,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: (_bgActive ? AppColors.secondary : AppColors.warning)
                  .withOpacity(0.3 + _pulseCtrl.value * 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (_bgActive ? AppColors.secondary : AppColors.warning)
                    .withOpacity(0.05 + _pulseCtrl.value * 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _bgActive
                    ? AppColors.secondaryGradient
                    : const LinearGradient(
                        colors: [Color(0xFFFFB020), Color(0xFFE08000)]),
              ),
              child: Icon(
                _bgActive ? Icons.verified_user : Icons.warning_amber_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _bgActive ? 'Protection Active' : 'Enable Protection',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _bgActive ? AppColors.secondary : AppColors.warning,
                    ),
                  ),
                  Text(
                    _bgActive
                        ? 'Monitoring notifications 24/7 for scams'
                        : 'Tap to grant notification access',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.darkSubtext),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (_bgActive ? AppColors.secondary : AppColors.warning)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (_bgActive ? AppColors.secondary : AppColors.warning)
                      .withOpacity(0.3),
                ),
              ),
              child: Text(
                _bgActive ? 'LIVE' : 'SETUP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _bgActive ? AppColors.secondary : AppColors.warning,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
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
        desc: 'SMS & WhatsApp',
      ),
      _ScanItem(
        icon: Icons.link_rounded,
        label: 'URL\nScanner',
        color: AppColors.secondary,
        path: '/scanner/url',
        desc: 'Detect phishing',
      ),
      _ScanItem(
        icon: Icons.description_outlined,
        label: 'Offer Letter\nVerify',
        color: AppColors.warning,
        path: '/document/offer-letter',
        desc: 'Job fraud check',
      ),
      _ScanItem(
        icon: Icons.fact_check_outlined,
        label: 'Fact\nCheck',
        color: AppColors.info,
        path: '/fact-check',
        desc: 'Verify claims',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _QuickScanCard(item: item)
            .animate(delay: Duration(milliseconds: 80 * index))
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.3, curve: Curves.easeOut);
      }).toList(),
    );
  }

  Widget _buildRecentScans(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final user = currentUser.value;

    if (user == null) {
      return _emptyCard(
          Icons.login, 'Sign in to see your scan history');
    }

    final historyService = ref.read(scanHistoryServiceProvider);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: historyService.getUserScans(user.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            ),
          );
        }

        final scans = snap.data ?? [];
        if (scans.isEmpty) {
          return _emptyCard(Icons.radar, 'No scans yet — try scanning a message!');
        }

        return Column(
          children: scans.take(3).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final scan = entry.value;
            final trustScore = (scan['trustScore'] as num?)?.toInt() ?? 50;
            final scoreColor = AppColors.trustScoreColor(trustScore);
            final threatLevel = scan['threatLevel'] as String? ?? 'medium';
            final preview =
                scan['contentPreview'] as String? ?? 'Scan complete';
            final scanType = scan['scanType'] as String? ?? 'message';
            final timestamp =
                (scan['timestamp'] as dynamic)?.toDate?.call() as DateTime?;
            final isDanger =
                threatLevel == 'high' || threatLevel == 'critical';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDanger
                      ? AppColors.danger.withOpacity(0.3)
                      : AppColors.darkBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scoreColor.withOpacity(0.15),
                    ),
                    child: Center(
                      child: Text(
                        '$trustScore',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
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
                          preview,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${scanType.toUpperCase()} • ${_formatTime(timestamp)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.darkSubtext),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isDanger ? '⚠ THREAT' : '✓ SAFE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: scoreColor,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: 80 * index))
                .fadeIn()
                .slideX(begin: -0.08);
          }).toList(),
        );
      },
    );
  }

  Widget _emptyCard(IconData icon, String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.darkSubtext, size: 20),
          const SizedBox(width: 12),
          Text(msg,
              style: const TextStyle(
                  color: AppColors.darkSubtext, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCommunityAlert(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/community'),
      child: GlassCard(
        gradient: LinearGradient(
          colors: [
            AppColors.danger.withOpacity(0.15),
            AppColors.warning.withOpacity(0.08),
          ],
        ),
        borderColor: AppColors.danger.withOpacity(0.25),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.danger.withOpacity(0.2),
              ),
              child: const Icon(Icons.warning_amber,
                  color: AppColors.danger, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔥 Community Threat Reports',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  Text(
                    'Fake internship scam wave detected in your region',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.darkSubtext),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.darkSubtext),
          ],
        ),
      ),
    ).animate(delay: 500.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }

  String _displayName(String? displayName, String? email) {
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim().split(' ').first;
    }
    if (email != null && email.trim().isNotEmpty) {
      return email.split('@').first;
    }
    return 'User';
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Just now';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _QuickScanCard extends StatefulWidget {
  final _ScanItem item;
  const _QuickScanCard({required this.item});

  @override
  State<_QuickScanCard> createState() => _QuickScanCardState();
}

class _QuickScanCardState extends State<_QuickScanCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        context.go(widget.item.path);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                widget.item.color.withOpacity(_pressed ? 0.2 : 0.12),
                AppColors.darkCard,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: widget.item.color.withOpacity(_pressed ? 0.5 : 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.item.color.withOpacity(_pressed ? 0.15 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.item.color.withOpacity(0.15),
                ),
                child: Icon(widget.item.icon,
                    color: widget.item.color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                widget.item.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                  height: 1.3,
                ),
              ),
              Text(
                widget.item.desc,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.darkSubtext),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanItem {
  final IconData icon;
  final String label;
  final Color color;
  final String path;
  final String desc;
  const _ScanItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.path,
    required this.desc,
  });
}
