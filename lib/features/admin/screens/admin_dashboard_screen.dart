import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.warning.withOpacity(0.4)),
              ),
              child: const Text('ADMIN',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning)),
            ),
            const SizedBox(width: 10),
            const Text('Dashboard'),
          ],
        ),
        backgroundColor: Colors.transparent,
        leading: const BackButton(),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.darkSubtext,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Threats'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(),
          _UsersTab(),
          _ThreatsTab(),
          _AnalyticsTab(),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final _stats = [
    _AdminStat('Total Users', '1,247', Icons.people, AppColors.primary, '+12%'),
    _AdminStat('Scans Today', '4,832', Icons.security, AppColors.secondary, '+34%'),
    _AdminStat('Threats Blocked', '892', Icons.shield, AppColors.danger, '+8%'),
    _AdminStat('Active Reports', '47', Icons.report, AppColors.warning, '+5'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: _stats.asMap().entries.map((e) {
            return _AdminStatCard(stat: e.value)
                .animate(delay: Duration(milliseconds: 80 * e.key))
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.9, 0.9));
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Threat type chart
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Scam Types (This Week)',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                          value: 35,
                          title: '35%\nFake Jobs',
                          color: AppColors.danger,
                          radius: 60,
                          titleStyle: const TextStyle(
                              fontSize: 10, color: Colors.white)),
                      PieChartSectionData(
                          value: 28,
                          title: '28%\nPhishing',
                          color: AppColors.primary,
                          radius: 60,
                          titleStyle: const TextStyle(
                              fontSize: 10, color: Colors.white)),
                      PieChartSectionData(
                          value: 20,
                          title: '20%\nInternship',
                          color: AppColors.warning,
                          radius: 60,
                          titleStyle: const TextStyle(
                              fontSize: 10, color: Colors.white)),
                      PieChartSectionData(
                          value: 17,
                          title: '17%\nOther',
                          color: AppColors.secondary,
                          radius: 60,
                          titleStyle: const TextStyle(
                              fontSize: 10, color: Colors.white)),
                    ],
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
            ],
          ),
        ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

        const SizedBox(height: 16),

        // Daily scans chart
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Daily Scans (7 Days)',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText)),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: BarChart(
                  BarChartData(
                    barGroups: [
                      _buildBar(0, 3200),
                      _buildBar(1, 3800),
                      _buildBar(2, 4100),
                      _buildBar(3, 3600),
                      _buildBar(4, 4500),
                      _buildBar(5, 5100),
                      _buildBar(6, 4832),
                    ],
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      getDrawingHorizontalLine: (v) => FlLine(
                          color: AppColors.darkBorder, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, meta) {
                            const days = [
                              'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                            ];
                            return Text(days[v.toInt()],
                                style: TextStyle(
                                    fontSize: 10, color: AppColors.darkSubtext));
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).animate(delay: 600.ms).fadeIn(duration: 400.ms),

        const SizedBox(height: 80),
      ],
    );
  }

  BarChartGroupData _buildBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: AppColors.primaryGradient,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final _AdminStat stat;
  const _AdminStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: stat.color.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(stat.icon, color: stat.color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(stat.change,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stat.value,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: stat.color)),
              Text(stat.label,
                  style: TextStyle(fontSize: 12, color: AppColors.darkSubtext)),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('User Management',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText)),
              const SizedBox(height: 16),
              ...['user@example.com', 'student@college.edu', 'admin@org.com']
                  .asMap()
                  .entries
                  .map((e) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Text(
                            String.fromCharCode(65 + e.key),
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        ),
                        title: Text(e.value,
                            style: const TextStyle(
                                color: AppColors.darkText, fontSize: 14)),
                        subtitle: Text(
                            e.key == 2 ? 'Admin' : 'User',
                            style: TextStyle(
                                color: AppColors.darkSubtext, fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert,
                              color: AppColors.darkSubtext),
                          onPressed: () {},
                        ),
                      )),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThreatsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Threat Management', style: TextStyle(color: AppColors.darkText)),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Advanced Analytics', style: TextStyle(color: AppColors.darkText)),
    );
  }
}

class _AdminStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String change;
  const _AdminStat(this.label, this.value, this.icon, this.color, this.change);
}
