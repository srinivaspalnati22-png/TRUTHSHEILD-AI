import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.darkBg,
            flexibleSpace: FlexibleSpaceBar(
              background: currentUser.when(
                data: (user) => _buildProfileHeader(user?.displayName ?? 'User',
                    user?.email ?? '', user?.photoUrl),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.go('/settings'),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats row
                currentUser.when(
                  data: (user) => _buildStatsRow(
                    user?.totalScans ?? 0,
                    user?.threatsDetected ?? 0,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 20),

                // Role badge
                currentUser.when(
                  data: (user) {
                    if (user?.role == 'admin' || user?.role == 'moderator') {
                      return Column(
                        children: [
                          _buildRoleBadge(user!.role),
                          const SizedBox(height: 20),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Menu items
                _buildMenuSection('Account', [
                  _MenuItem(Icons.person_outline, 'Edit Profile', () {}),
                  _MenuItem(Icons.history, 'Scan History',
                      () => context.go('/history')),
                  _MenuItem(Icons.notifications_outlined, 'Notifications', () {}),
                ]),

                const SizedBox(height: 16),

                _buildMenuSection('Security', [
                  _MenuItem(Icons.lock_outline, 'Change Password', () {}),
                  _MenuItem(Icons.security, 'Two-Factor Auth', () {}),
                  _MenuItem(Icons.privacy_tip_outlined, 'Privacy Settings', () {}),
                ]),

                const SizedBox(height: 16),

                _buildMenuSection('App', [
                  _MenuItem(
                      Icons.settings_outlined, 'Settings',
                      () => context.go('/settings')),
                  _MenuItem(Icons.help_outline, 'Help & Support', () {}),
                  _MenuItem(Icons.info_outline, 'About TrustShield', () {}),
                  _MenuItem(Icons.star_outline, 'Rate the App', () {}),
                ]),

                const SizedBox(height: 16),

                // Admin access
                currentUser.when(
                  data: (user) {
                    if (user?.role == 'admin') {
                      return Column(
                        children: [
                          _buildMenuSection('Admin', [
                            _MenuItem(Icons.admin_panel_settings,
                                'Admin Dashboard',
                                () => context.go('/admin'),
                                color: AppColors.warning),
                          ]),
                          const SizedBox(height: 16),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Sign out
                GlassCard(
                  onTap: () async {
                    final authService = ref.read(authServiceProvider);
                    await authService.signOut();
                    if (context.mounted) context.go('/auth/login');
                  },
                  borderColor: AppColors.danger.withOpacity(0.3),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.danger.withOpacity(0.15),
                        ),
                        child: const Icon(Icons.logout, color: AppColors.danger, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Sign Out',
                          style: TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email, String? photoUrl) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.darkBg, AppColors.darkSurface.withOpacity(0.5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 3),
            ),
            child: photoUrl != null
                ? ClipOval(child: Image.network(photoUrl, fit: BoxFit.cover))
                : Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(name,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText)),
          Text(email,
              style: TextStyle(fontSize: 13, color: AppColors.darkSubtext)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int totalScans, int threatsDetected) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                Text('$totalScans',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                Text('Total Scans',
                    style: TextStyle(fontSize: 12, color: AppColors.darkSubtext)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                Text('$threatsDetected',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger)),
                Text('Threats Blocked',
                    style: TextStyle(fontSize: 12, color: AppColors.darkSubtext)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                const Text('A+',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary)),
                Text('Safety Rating',
                    style: TextStyle(fontSize: 12, color: AppColors.darkSubtext)),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildRoleBadge(String role) {
    final isAdmin = role == 'admin';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isAdmin
            ? AppColors.warning.withOpacity(0.15)
            : AppColors.primary.withOpacity(0.15),
        border: Border.all(
          color: isAdmin
              ? AppColors.warning.withOpacity(0.3)
              : AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.verified_user,
            color: isAdmin ? AppColors.warning : AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            isAdmin ? 'Administrator' : 'Moderator',
            style: TextStyle(
              color: isAdmin ? AppColors.warning : AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkSubtext)),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    onTap: item.onTap,
                    leading: Icon(item.icon,
                        color: item.color ?? AppColors.darkSubtext, size: 22),
                    title: Text(item.label,
                        style: TextStyle(
                            fontSize: 14,
                            color: item.color ?? AppColors.darkText,
                            fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppColors.darkSubtext),
                  ),
                  if (index < items.length - 1)
                    const Divider(height: 1, color: AppColors.darkBorder, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MenuItem(this.icon, this.label, this.onTap, {this.color});
}
