import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Community Threat Network'),
        backgroundColor: Colors.transparent,
        leading: const BackButton(),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.darkSubtext,
          tabs: const [
            Tab(text: 'Threats'),
            Tab(text: 'Reports'),
            Tab(text: 'My Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ThreatFeedTab(),
          _ReportTab(),
          _MyReportsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportDialog,
        backgroundColor: AppColors.danger,
        icon: const Icon(Icons.add_alert, color: Colors.white),
        label: const Text('Report Threat',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showReportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _ReportBottomSheet(),
    );
  }
}

class _ThreatFeedTab extends StatelessWidget {
  final _threats = const [
    _CommunityThreat(
      type: 'Fake Internship',
      title: 'Amazon Internship Scam',
      description: 'Fake Amazon internship with ₹999 registration fee. Multiple reports from students.',
      reportCount: 47,
      dangerLevel: 'CRITICAL',
      timeAgo: '2 hours ago',
    ),
    _CommunityThreat(
      type: 'Phishing URL',
      title: 'Fake HDFC Bank Login Page',
      description: 'URL: hdfc-secure-login.com - Phishing site stealing banking credentials.',
      reportCount: 32,
      dangerLevel: 'HIGH',
      timeAgo: '5 hours ago',
    ),
    _CommunityThreat(
      type: 'Fake Job',
      title: 'Work From Home Data Entry Scam',
      description: 'Pays ₹50,000/month for typing from home. Advance payment required.',
      reportCount: 28,
      dangerLevel: 'HIGH',
      timeAgo: '1 day ago',
    ),
    _CommunityThreat(
      type: 'Investment Fraud',
      title: 'Crypto 10x Returns Scam',
      description: 'WhatsApp group promising 1000% returns on crypto investments.',
      reportCount: 19,
      dangerLevel: 'MEDIUM',
      timeAgo: '2 days ago',
    ),
    _CommunityThreat(
      type: 'Fake Scholarship',
      title: 'Government Scholarship Fraud',
      description: 'Fake scholarship with processing fee of ₹500. Impersonates Education Ministry.',
      reportCount: 15,
      dangerLevel: 'HIGH',
      timeAgo: '3 days ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _threats.length,
      itemBuilder: (context, index) {
        final threat = _threats[index];
        return _ThreatCard(threat: threat)
            .animate(delay: Duration(milliseconds: 80 * index))
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.1);
      },
    );
  }
}

class _ThreatCard extends StatelessWidget {
  final _CommunityThreat threat;
  const _ThreatCard({required this.threat});

  Color get dangerColor {
    switch (threat.dangerLevel) {
      case 'CRITICAL':
        return AppColors.danger;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return AppColors.warning;
      default:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dangerColor.withOpacity(0.3)),
        gradient: LinearGradient(
          colors: [dangerColor.withOpacity(0.05), AppColors.darkCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: dangerColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: dangerColor.withOpacity(0.3)),
              ),
              child: Text(
                threat.dangerLevel,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: dangerColor),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.darkBorder,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                threat.type,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.darkSubtext),
              ),
            ),
            const Spacer(),
            Text(threat.timeAgo,
                style: TextStyle(fontSize: 11, color: AppColors.darkSubtext)),
          ]),
          const SizedBox(height: 10),
          Text(
            threat.title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText),
          ),
          const SizedBox(height: 6),
          Text(
            threat.description,
            style: TextStyle(fontSize: 12, color: AppColors.darkSubtext, height: 1.5),
          ),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.people, size: 14, color: AppColors.darkSubtext),
            const SizedBox(width: 4),
            Text(
              '${threat.reportCount} reports',
              style: TextStyle(fontSize: 12, color: AppColors.darkSubtext),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Report Similar',
                  style: TextStyle(fontSize: 12, color: AppColors.primary)),
            ),
          ]),
        ],
      ),
    );
  }
}

class _ReportTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_alert_outlined,
              size: 64, color: AppColors.darkSubtext),
          const SizedBox(height: 16),
          const Text('Report a Threat',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText)),
          const SizedBox(height: 8),
          Text('Help protect the community by reporting scams',
              style: TextStyle(color: AppColors.darkSubtext),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Submit Report',
            icon: Icons.send,
            onPressed: () {},
            width: 200,
          ),
        ],
      ),
    );
  }
}

class _MyReportsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: AppColors.darkSubtext),
          const SizedBox(height: 16),
          const Text('No Reports Yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText)),
          Text('Your submitted reports will appear here',
              style: TextStyle(color: AppColors.darkSubtext)),
        ],
      ),
    );
  }
}

class _ReportBottomSheet extends StatefulWidget {
  const _ReportBottomSheet();

  @override
  State<_ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<_ReportBottomSheet> {
  final _descController = TextEditingController();
  String _selectedType = 'Fake Job';

  final _types = [
    'Fake Job',
    'Fake Internship',
    'Phishing URL',
    'Investment Fraud',
    'Fake Scholarship',
    'Bank Alert Scam',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Report a Threat',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText)),
          const SizedBox(height: 4),
          Text('Help protect the TrustShield community',
              style: TextStyle(color: AppColors.darkSubtext, fontSize: 13)),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedType,
            dropdownColor: AppColors.darkCard,
            style: const TextStyle(color: AppColors.darkText),
            decoration: const InputDecoration(labelText: 'Threat Type'),
            items: _types
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _selectedType = v ?? _selectedType),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            maxLines: 4,
            style: const TextStyle(color: AppColors.darkText),
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Describe the threat in detail...',
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Submit Report',
            icon: Icons.send,
            backgroundColor: AppColors.danger,
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('✅ Report submitted. Thank you!')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CommunityThreat {
  final String type;
  final String title;
  final String description;
  final int reportCount;
  final String dangerLevel;
  final String timeAgo;
  const _CommunityThreat({
    required this.type,
    required this.title,
    required this.description,
    required this.reportCount,
    required this.dangerLevel,
    required this.timeAgo,
  });
}
