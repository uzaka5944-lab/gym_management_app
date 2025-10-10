// lib/admin_dashboard_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../main.dart';
import 'qr_scanner_screen.dart';
import 'admin_financial_report_screen.dart';
import 'admin_member_management_screen.dart';

class AdminDashboardSummaryScreen extends StatefulWidget {
  const AdminDashboardSummaryScreen({super.key});

  @override
  State<AdminDashboardSummaryScreen> createState() =>
      _AdminDashboardSummaryScreenState();
}

class _AdminDashboardSummaryScreenState
    extends State<AdminDashboardSummaryScreen> with TickerProviderStateMixin {
  // ... (no changes to this upper part of the file)
  void refreshData() {
    _loadDashboardData();
  }

  late Future<String> _adminNameFuture;
  late Future<Map<String, int>> _statusCountsFuture;
  late Future<Map<String, double>> _newMembersFuture;
  late Future<Map<String, double>> _monthlyRevenueBreakdownFuture;
  late Future<Map<int, int>> _monthlyVisitorsFuture;

  late AnimationController _animationController;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  final List<String> _motivationalQuotes = [
    "The only bad workout is the one that didn't happen.",
    "Sweat is just fat crying.",
    "Strive for progress, not perfection.",
    "Your body can stand almost anything. It’s your mind that you have to convince."
  ];
  late String _currentQuote;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _currentQuote = _motivationalQuotes[0];

    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _topAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem<Alignment>(
        tween:
            AlignmentTween(begin: Alignment.topLeft, end: Alignment.topRight),
        weight: 1,
      ),
      TweenSequenceItem<Alignment>(
        tween: AlignmentTween(
            begin: Alignment.topRight, end: Alignment.bottomRight),
        weight: 1,
      ),
      TweenSequenceItem<Alignment>(
        tween: AlignmentTween(
            begin: Alignment.bottomRight, end: Alignment.bottomLeft),
        weight: 1,
      ),
      TweenSequenceItem<Alignment>(
        tween:
            AlignmentTween(begin: Alignment.bottomLeft, end: Alignment.topLeft),
        weight: 1,
      ),
    ]).animate(_animationController);

    _bottomAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem<Alignment>(
        tween: AlignmentTween(
            begin: Alignment.bottomRight, end: Alignment.bottomLeft),
        weight: 1,
      ),
      TweenSequenceItem<Alignment>(
        tween:
            AlignmentTween(begin: Alignment.bottomLeft, end: Alignment.topLeft),
        weight: 1,
      ),
      TweenSequenceItem<Alignment>(
        tween:
            AlignmentTween(begin: Alignment.topLeft, end: Alignment.topRight),
        weight: 1,
      ),
      TweenSequenceItem<Alignment>(
        tween: AlignmentTween(
            begin: Alignment.topRight, end: Alignment.bottomRight),
        weight: 1,
      ),
    ]).animate(_animationController);

    _animationController.repeat();

    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _currentQuote = (_motivationalQuotes..shuffle()).first;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadDashboardData() {
    setState(() {
      _adminNameFuture = _fetchAdminName();
      _statusCountsFuture = _fetchStatusCounts();
      _newMembersFuture = _fetchNewMembersWeekly();
      _monthlyRevenueBreakdownFuture = _fetchMonthlyRevenueBreakdown();
      _monthlyVisitorsFuture = _fetchMonthlyVisitors();
    });
  }

  // ... (no changes to the data fetching methods)
  Future<String> _fetchAdminName() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return "Admin";
      final response = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .single();
      return response['full_name'] ?? 'Admin';
    } catch (e) {
      return "Admin";
    }
  }

  Future<Map<String, int>> _fetchStatusCounts() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day).toIso8601String();

      final feeDueResponse = await supabase
          .from('members')
          .select('user_id')
          .eq('status', 'active')
          .lt('fee_due_date', today);

      final feeDueCount = feeDueResponse.length;

      return {
        'feeDue': feeDueCount,
      };
    } catch (e) {
      debugPrint("Error fetching status counts: $e");
      return {'feeDue': 0};
    }
  }

  Future<Map<String, double>> _fetchNewMembersWeekly() async {
    final Map<String, double> weeklyData = {
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    };
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    try {
      final response = await supabase
          .from('payments')
          .select('payment_date')
          .eq('payment_type', 'new_admission')
          .gte('payment_date', startOfWeekDate.toIso8601String());

      for (var record in response) {
        final paymentDate = DateTime.parse(record['payment_date']);
        final day = DateFormat('E').format(paymentDate);
        if (weeklyData.containsKey(day)) {
          weeklyData[day] = weeklyData[day]! + 1;
        }
      }
      return weeklyData;
    } catch (e) {
      debugPrint("Error fetching weekly new members by payment: $e");
      return weeklyData;
    }
  }

  Future<Map<String, double>> _fetchMonthlyRevenueBreakdown() async {
    final breakdown = {'monthly_fee': 0.0, 'new_admission': 0.0};
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final response = await supabase
          .from('payments')
          .select('amount, payment_type')
          .gte('payment_date', startOfMonth.toIso8601String())
          .lte('payment_date', endOfMonth.toIso8601String());

      for (var payment in response) {
        final amount = (payment['amount'] as num).toDouble();
        final type = payment['payment_type'];
        if (breakdown.containsKey(type)) {
          breakdown[type] = breakdown[type]! + amount;
        }
      }
      return breakdown;
    } catch (e) {
      debugPrint('Error fetching monthly revenue breakdown: $e');
      return breakdown;
    }
  }

  Future<Map<int, int>> _fetchMonthlyVisitors() async {
    final Map<int, int> dailyCounts = {};
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final response = await supabase
          .from('check_ins')
          .select('check_in_time')
          .gte('check_in_time', startOfMonth.toIso8601String());

      for (var checkIn in response) {
        final day = DateTime.parse(checkIn['check_in_time']).day;
        dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
      }
      return dailyCounts;
    } catch (e) {
      debugPrint('Error fetching monthly visitors: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadDashboardData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildNotificationSection(),
                const SizedBox(height: 24),
                _buildAnimatedCard(),
                const SizedBox(height: 24),
                _buildRecentStatsSection(),
                const SizedBox(height: 24),
                _buildStatCardsRow(),
                const SizedBox(height: 24),
                _buildScanButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FutureBuilder<String>(
      future: _adminNameFuture,
      builder: (context, snapshot) {
        final name = snapshot.data ?? 'Admin';
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello,',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 18),
                ),
                Text(
                  name,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ],
            ),
            CircleAvatar(
              backgroundColor: Theme.of(context).cardColor,
              child: Icon(Icons.person, color: Theme.of(context).primaryColor),
              radius: 24,
            )
          ],
        );
      },
    );
  }

  Widget _buildNotificationSection() {
    return FutureBuilder<Map<String, int>>(
      future: _statusCountsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final counts = snapshot.data!;
        final feeDueCount = counts['feeDue'] ?? 0;

        if (feeDueCount == 0) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Action Required',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            if (feeDueCount > 0)
              _buildNotificationCard(
                count: feeDueCount,
                title: 'Members with Fee Due',
                color: Colors.orange,
                icon: Icons.warning_amber_rounded,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminMemberManagementScreen(),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationCard({
    required int count,
    required String title,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text('$count $title'),
        subtitle: const Text('Tap to view and take action'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAnimatedCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Define colors for both themes
    final gradientColors = isDark
        ? [
            const Color(0xFFC3FF41),
            Colors.greenAccent
          ] // Lime green for dark mode
        : [
            Colors.teal.shade200,
            Colors.teal.shade400
          ]; // Lighter teal for light mode

    // CORRECTED: Text/icon colors are now dark for the light theme to ensure readability
    final textColor = isDark
        ? Colors.black.withAlpha((255 * 0.9).round())
        : Colors.teal.shade900;
    final headingColor = isDark ? Colors.black : Colors.teal.shade900;
    final iconColor = isDark ? Colors.black : Colors.teal.shade900;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: _topAlignmentAnimation.value,
              end: _bottomAlignmentAnimation.value,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.bolt, color: iconColor, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keep Moving Today!',
                      style: TextStyle(
                          color: headingColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _currentQuote,
                      style: TextStyle(color: textColor, fontSize: 14),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentStatsSection() {
    // ... (no changes to the rest of the file below this point)
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('New Members This Week', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, double>>(
            future: _newMembersFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!;

              final maxValue =
                  data.values.fold(0.0, (max, v) => v > max ? v : max);
              final chartMaxY =
                  maxValue < 5 ? 5.0 : (maxValue * 1.2).ceilToDouble();

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20)),
                height: 200,
                child: BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: chartMaxY,
                  barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => Colors.blueGrey,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                                '${data.keys.elementAt(groupIndex)}\n',
                                TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.bold),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: rod.toY.toInt().toString(),
                                      style: TextStyle(
                                          color: theme.primaryColor,
                                          fontWeight: FontWeight.bold))
                                ]);
                          })),
                  titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(data.keys.elementAt(value.toInt()),
                                    style: TextStyle(
                                        color:
                                            theme.textTheme.bodyMedium?.color,
                                        fontSize: 12));
                              })),
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                if (value == 0 || value > maxValue) {
                                  return const SizedBox();
                                }
                                return Text(value.toInt().toString(),
                                    style: TextStyle(
                                        color:
                                            theme.textTheme.bodyMedium?.color,
                                        fontSize: 12));
                              }))),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: data.entries.map((entry) {
                    final index = data.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(x: index, barRods: [
                      BarChartRodData(
                          toY: entry.value,
                          color: entry.value == maxValue && maxValue > 0
                              ? theme.primaryColor
                              : Colors.grey,
                          width: 16,
                          borderRadius: BorderRadius.circular(4))
                    ]);
                  }).toList(),
                )),
              );
            })
      ],
    );
  }

  Widget _buildStatCardsRow() {
    final theme = Theme.of(context);

    return Column(
      children: [
        FutureBuilder<Map<String, double>>(
          future: _monthlyRevenueBreakdownFuture,
          builder: (context, snapshot) {
            final breakdown =
                snapshot.data ?? {'monthly_fee': 0.0, 'new_admission': 0.0};
            final monthlyFee = breakdown['monthly_fee']!;
            final newAdmissionFee = breakdown['new_admission']!;
            final totalRevenue = monthlyFee + newAdmissionFee;

            List<PieChartSectionData> sections = [];
            if (totalRevenue > 0) {
              sections = [
                PieChartSectionData(
                    value: monthlyFee,
                    color: theme.primaryColor,
                    title: '',
                    radius: 12),
                PieChartSectionData(
                    value: newAdmissionFee,
                    color: Colors.orange,
                    title: '',
                    radius: 12),
              ];
            } else {
              sections = [
                PieChartSectionData(
                    value: 1,
                    color: Colors.grey.shade300,
                    title: '',
                    radius: 12)
              ];
            }

            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const AdminFinancialReportScreen()),
                );
              },
              child: StatInfoCard(
                title: "Amount Collected this Month",
                value: 'PKR ${NumberFormat('#,##0').format(totalRevenue)}',
                icon: Icons.monetization_on_outlined,
                iconColor: Colors.orange,
                chart: Wrap(
                  spacing: 16.0,
                  runSpacing: 8.0,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: PieChart(PieChartData(
                        sections: sections,
                        startDegreeOffset: -90,
                        centerSpaceRadius: 20,
                        sectionsSpace: 2,
                      )),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem(theme.primaryColor, 'Monthly Fees'),
                        const SizedBox(height: 4),
                        _buildLegendItem(Colors.orange, 'New Admissions'),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<int, int>>(
          future: _monthlyVisitorsFuture,
          builder: (context, snapshot) {
            final visitorData = snapshot.data ?? {};
            final totalVisitors =
                visitorData.values.fold(0, (sum, item) => sum + item);
            final spots = visitorData.entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                .toList();
            return StatInfoCard(
              title: "Visitors this Month",
              value: totalVisitors.toString(),
              icon: Icons.trending_up,
              iconColor: Colors.cyan,
              chart: SizedBox(
                width: 100,
                height: 40,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots.isNotEmpty ? spots : [const FlSpot(0, 0)],
                        isCurved: true,
                        color: Colors.cyan,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildScanButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.qr_code_scanner_rounded),
      label: const Text('Scan Member QR for Check-in'),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const QRScannerScreen()),
        );
      },
    );
  }
}

class StatInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Widget chart;

  const StatInfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 16),
          chart,
        ],
      ),
    );
  }
}
