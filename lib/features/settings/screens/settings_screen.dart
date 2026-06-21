import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifListener = true;
  bool _autoScan = true;
  bool _biometricAuth = false;
  bool _deleteAfterScan = true;
  bool _communityReports = true;
  bool _emailAlerts = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme
          _buildSection('Appearance', [
            _SwitchTile(
              icon: Icons.dark_mode_outlined,
              label: 'Dark Mode',
              value: themeMode == ThemeMode.dark,
              onChanged: (v) => ref.read(themeModeProvider.notifier).toggle(),
            ),
          ]).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          // Protection
          _buildSection('Protection', [
            _SwitchTile(
              icon: Icons.notifications_active_outlined,
              label: 'Notification Listener',
              subtitle: 'Monitor WhatsApp, SMS, Gmail in real-time',
              value: _notifListener,
              onChanged: (v) => setState(() => _notifListener = v),
            ),
            _SwitchTile(
              icon: Icons.auto_mode,
              label: 'Auto-Scan Messages',
              subtitle: 'Automatically analyze incoming notifications',
              value: _autoScan,
              onChanged: (v) => setState(() => _autoScan = v),
            ),
            _SwitchTile(
              icon: Icons.people_outline,
              label: 'Community Reports',
              subtitle: 'Contribute anonymous threat data',
              value: _communityReports,
              onChanged: (v) => setState(() => _communityReports = v),
            ),
          ]).animate(delay: 100.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          // Privacy
          _buildSection('Privacy', [
            _SwitchTile(
              icon: Icons.delete_outline,
              label: 'Delete After Analysis',
              subtitle: 'Auto-delete message content after scanning',
              value: _deleteAfterScan,
              onChanged: (v) => setState(() => _deleteAfterScan = v),
            ),
            _SwitchTile(
              icon: Icons.fingerprint,
              label: 'Biometric Auth',
              subtitle: 'Unlock app with fingerprint',
              value: _biometricAuth,
              onChanged: (v) => setState(() => _biometricAuth = v),
            ),
            _SwitchTile(
              icon: Icons.email_outlined,
              label: 'Email Alerts',
              subtitle: 'Receive threat summaries via email',
              value: _emailAlerts,
              onChanged: (v) => setState(() => _emailAlerts = v),
            ),
          ]).animate(delay: 200.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          // AI Settings
          _buildSection('AI Settings', [
            ListTile(
              leading: const Icon(Icons.model_training, color: AppColors.primary),
              title: const Text('AI Analysis Model',
                  style: TextStyle(color: AppColors.darkText, fontSize: 14)),
              subtitle: Text('Gemini 2.0 Flash',
                  style: TextStyle(color: AppColors.darkSubtext, fontSize: 12)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Active',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.tune, color: AppColors.darkSubtext),
              title: const Text('Sensitivity Level',
                  style: TextStyle(color: AppColors.darkText, fontSize: 14)),
              subtitle: const Text('High (Recommended)',
                  style: TextStyle(color: AppColors.darkSubtext, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.darkSubtext),
              onTap: () {},
            ),
          ]).animate(delay: 300.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          // Data Management
          _buildSection('Data', [
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: AppColors.danger),
              title: const Text('Clear Scan History',
                  style: TextStyle(color: AppColors.danger, fontSize: 14)),
              subtitle: Text('Remove all stored scan metadata',
                  style: TextStyle(color: AppColors.darkSubtext, fontSize: 12)),
              onTap: () => _showClearDataDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined, color: AppColors.darkSubtext),
              title: const Text('Export Data',
                  style: TextStyle(color: AppColors.darkText, fontSize: 14)),
              subtitle: Text('Download your scan history as CSV',
                  style: TextStyle(color: AppColors.darkSubtext, fontSize: 12)),
              onTap: () {},
            ),
          ]).animate(delay: 400.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          // App info
          GlassCard(
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.shield, color: AppColors.primary, size: 32),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                    child: const Text('TrustShield AI',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ]),
                const SizedBox(height: 8),
                Text('Version 1.0.0',
                    style: TextStyle(fontSize: 13, color: AppColors.darkSubtext)),
                Text('Powered by Gemini AI',
                    style: TextStyle(fontSize: 12, color: AppColors.darkSubtext)),
              ],
            ),
          ).animate(delay: 500.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
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
            children: children.asMap().entries.map((e) {
              return Column(
                children: [
                  e.value,
                  if (e.key < children.length - 1)
                    const Divider(
                        height: 1, color: AppColors.darkBorder, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Clear Scan History',
            style: TextStyle(color: AppColors.darkText)),
        content: Text(
          'This will permanently delete all your scan history. This action cannot be undone.',
          style: TextStyle(color: AppColors.darkSubtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scan history cleared')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.darkSubtext, size: 22),
      title: Text(label,
          style: const TextStyle(color: AppColors.darkText, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(color: AppColors.darkSubtext, fontSize: 12))
          : null,
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }
}
