// lib/admin_dashboard_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../main.dart';
import '../theme.dart';
import 'qr_scanner_screen.dart'; // We will create this new screen next

class AdminDashboardSummaryScreen extends StatefulWidget {
  const AdminDashboardSummaryScreen({super.key});

  @override
  State<AdminDashboardSummaryScreen> createState() =>
      _AdminDashboardSummaryScreenState();
}

class _AdminDashboardSummaryScreenState extends State<AdminDashboardSummaryScreen>
    with TickerProviderStateMixin {
  late Future<String> _adminNameFuture;
  late Future<Map<String, double>> _newMembersFuture;
  late Future<Map<String, double>> _monthlyRevenueBreakdownFuture; // MODIFIED
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
        tween: AlignmentTween(begin: Alignment.topLeft, end: Alignment.topRight),
        weight: 1,
      ),
      TweenSequenceItem<Alignment>(
        tween: AlignmentTween(begin: Alignment.topRight, end: Alignment.bottomRight),
        weight: 1,
      ),
      TweenSequenceItem<Alignment>(
        tween: AlignmentTween(begin: Alignment.bottomRight, end: Alignment.bottomLeft),
        weight: 1,
      ),
      TweenSequenceItem<Alignment>(
        tween: AlignmentTween(begin: Alignment.bottomLeft, end: Alignment.topLeft),
        weight: 1,
      ),
    ]).animate(_animationController);

    _bottomAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem<Alignment>(
        tween: AlignmentTween(begin: Alignment.bottomRight, end: Alignment.bottomLeft),
        weight: 1,
      ),
      TweenSequenceItem<Alignment>(
        tween: AlignmentTween(begin: Alignment.bottomLeft, end: Alignment.topLeft),
        weight: 1,
      ),
      TweenSequenceItem<Alignment>(
        tween: AlignmentTween(begin: Alignment.topLeft, end: Alignment.topRight),
        weight: 1,
      ),
      TweenSequenceItem<Alignment>(
        tween: AlignmentTween(begin: Alignment.topRight, end: Alignment.bottomRight),
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
      _newMembersFuture = _fetchNewMembersWeekly();
      _monthlyRevenueBreakdownFuture = _fetchMonthlyRevenueBreakdown(); // MODIFIED
      _monthlyVisitorsFuture = _fetchMonthlyVisitors();
    });
  }

  Future<String> _fetchAdminName() async {
    // ... (this function remains the same)
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

  Future<Map<String, double>> _fetchNewMembersWeekly() async {
    // ... (this function remains the same)
     final Map<String, double> weeklyData = {
      'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0,
    };
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    try {
      final response = await supabase
          .from('profiles')
          .select('created_at')
          .eq('role', 'member')
          .gte('created_at', DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).toIso8601String());

      for (var record in response) {
        final createdAt = DateTime.parse(record['created_at']);
        final day = DateFormat('E').format(createdAt); // E.g., "Mon"
        if (weeklyData.containsKey(day)) {
          weeklyData[day] = weeklyData[day]! + 1;
        }
      }
      return weeklyData;
    } catch (e) {
      debugPrint("Error fetching weekly new members: $e");
      return weeklyData; // Return empty data on error
    }
  }

  // MODIFIED: Fetches revenue and splits it by new members vs renewals
  Future<Map<String, double>> _fetchMonthlyRevenueBreakdown() async {
    final Map<String, double> breakdown = {'new': 0.0, 'renewal': 0.0};
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

      final response = await supabase
          .from('payments')
          .select('amount, payment_type')
          .gte('payment_date', startOfMonth);

      for (var payment in response) {
        final amount = (payment['amount'] as num).toDouble();
        if (payment['payment_type'] == 'new_member') {
          breakdown['new'] = breakdown['new']! + amount;
        } else {
          breakdown['renewal'] = breakdown['renewal']! + amount;
        }
      }
      return breakdown;
    } catch (e) {
      debugPrint('Error fetching monthly revenue breakdown: $e');
      return breakdown;
    }
  }

  Future<Map<int, int>> _fetchMonthlyVisitors() async {
    // ... (this function remains the same)
    final Map<int, int> dailyCounts = {};
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      final response = await supabase
          .from('check_ins')
          .select('check_in_time')
          .gte('check_in_time', startOfMonth.toIso8601String());

      for(var checkIn in response) {
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
      backgroundColor: darkBackgroundColor,
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
                _buildAnimatedCard(),
                const SizedBox(height: 24),
                _buildRecentStatsSection(),
                const SizedBox(height: 24),
                _buildStatCardsRow(),
                const SizedBox(height: 24),
                _buildScanButton(), // ADDED: QR Scan Button
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ... (_buildHeader, _buildAnimatedCard, _buildRecentStatsSection remain the same)
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
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                Text(
                  name,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const CircleAvatar(
              backgroundColor: cardBackgroundColor,
              child: Icon(Icons.person, color: primaryColor),
              radius: 24,
            )
          ],
        );
      },
    );
  }

  Widget _buildAnimatedCard() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: const [primaryColor, Colors.greenAccent],
              begin: _topAlignmentAnimation.value,
              end: _bottomAlignmentAnimation.value,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt, color: Colors.black, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keep Moving Today!',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _currentQuote,
                      style: TextStyle(color: Colors.black87, fontSize: 14),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('New Members This Week',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, double>>(
            future: _newMembersFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final data = snapshot.data!;
              final maxValue = data.values.fold(0.0, (max, v) => v > max ? v : max);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBackgroundColor,
                  borderRadius: BorderRadius.circular(20)
                ),
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue == 0 ? 5 : maxValue + 2, // Ensure chart is not flat if no data
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.blueGrey,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                           return BarTooltipItem(
                            '${data.keys.elementAt(groupIndex)}\n',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            children: <TextSpan>[
                              TextSpan(
                                text: (rod.toY - 1).toInt().toString(),
                                style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)
                              )
                            ]
                          );
                        }
                      )
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(data.keys.elementAt(value.toInt()), style: const TextStyle(color: Colors.white70, fontSize: 12));
                          }
                        )
                      )
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    barGroups: data.entries.map((entry) {
                      final index = data.keys.toList().indexOf(entry.key);
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value + 1, // Add 1 to avoid 0 height
                            color: entry.value == maxValue && maxValue > 0 ? primaryColor : Colors.grey,
                            width: 16,
                            borderRadius: BorderRadius.circular(4)
                          )
                        ]
                      );
                    }).toList(),
                  )
                ),
              );
            })
      ],
    );
  }


  Widget _buildStatCardsRow() {
    return Column(
      children: [
        // MODIFIED: Revenue Card with Pie Chart
        FutureBuilder<Map<String, double>>(
          future: _monthlyRevenueBreakdownFuture,
          builder: (context, snapshot) {
            final breakdown = snapshot.data ?? {'new': 0.0, 'renewal': 0.0};
            final totalRevenue = breakdown['new']! + breakdown['renewal']!;
            final newRevenue = breakdown['new']!;
            
            List<PieChartSectionData> sections = [];
            if (totalRevenue > 0) {
              sections = [
                PieChartSectionData(
                  value: newRevenue,
                  color: Colors.orange,
                  title: '',
                  radius: 10,
                ),
                PieChartSectionData(
                  value: breakdown['renewal']!,
                  color: Colors.white24,
                   title: '',
                  radius: 10,
                ),
              ];
            } else {
               sections = [
                PieChartSectionData(
                  value: 1, // Full circle if no data
                  color: Colors.white24,
                   title: '',
                  radius: 10,
                ),
              ];
            }

            return StatInfoCard(
              title: "Amount Collected this Month",
              value: '\$${totalRevenue.toStringAsFixed(2)}',
              icon: Icons.monetization_on_outlined,
              iconColor: Colors.orange,
              chart: SizedBox(
                width: 60,
                height: 60,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    startDegreeOffset: -90,
                    centerSpaceRadius: 20,
                    sectionsSpace: 0,
                  )
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Visitors This Month Card (remains the same)
        FutureBuilder<Map<int, int>>(
          future: _monthlyVisitorsFuture,
          builder: (context, snapshot) {
            final visitorData = snapshot.data ?? {};
            final totalVisitors = visitorData.values.fold(0, (sum, item) => sum + item);
             final spots = visitorData.entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
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
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots.isNotEmpty ? spots : [FlSpot(0,0)],
                        isCurved: true,
                        color: Colors.cyan,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
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
  
  // ADDED: New widget for the scan button
  Widget _buildScanButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.qr_code_scanner_rounded),
      label: const Text('Scan Member QR for Check-in'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const QRScannerScreen()),
        );
      },
    );
  }
}

// ... (StatInfoCard widget remains the same)
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
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(color: Colors.white70)),
                ],
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              chart,
            ],
          )
        ],
      ),
    );
  }
}

