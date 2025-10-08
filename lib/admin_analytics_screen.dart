// lib/admin_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'main.dart';
import 'theme.dart';
import 'admin_member_payment_history_screen.dart';

// Enum for sorting options to keep the code clean and readable.
enum SortOption { name, feeDueDate }

// A simple class to hold our chart data
class MonthlyRevenue {
  final DateTime month;
  final double total;
  MonthlyRevenue(this.month, this.total);
}

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  late Future<List<Map<String, dynamic>>> _membersFuture;
  late Future<List<MonthlyRevenue>> _revenueFuture;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.name;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _membersFuture = _fetchMembers();
      _revenueFuture = _fetchLast12MonthsRevenue();
    });
  }

  Future<List<MonthlyRevenue>> _fetchLast12MonthsRevenue() async {
    try {
      final response = await supabase.rpc('get_monthly_revenue');
      final List<MonthlyRevenue> revenueData = (response as List)
          .map((item) => MonthlyRevenue(
                DateTime.parse(item['month']),
                (item['total_revenue'] as num).toDouble(),
              ))
          .toList();
      // Ensure the data is sorted by month
      revenueData.sort((a, b) => a.month.compareTo(b.month));
      return revenueData;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching revenue data: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMembers() async {
    try {
      dynamic query = supabase
          .from('members')
          .select('user_id, name, fee_due_date, avatar_url');
      if (_searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$_searchQuery%');
      }
      switch (_sortOption) {
        case SortOption.name:
          query = query.order('name', ascending: true);
          break;
        case SortOption.feeDueDate:
          query =
              query.order('fee_due_date', ascending: true, nullsFirst: true);
          break;
      }
      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching members: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
      return [];
    }
  }

  void _refreshMembers() {
    setState(() {
      _membersFuture = _fetchMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 16),
          children: [
            _buildSearchBarAndSort(),
            _buildRevenueChart(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('All Members',
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _membersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final members = snapshot.data!;
                if (members.isEmpty) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No members found.'),
                  ));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    return _buildMemberCard(members[index]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ## This is the updated, more detailed chart widget
  Widget _buildRevenueChart() {
    return FutureBuilder<List<MonthlyRevenue>>(
      future: _revenueFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 250,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 250,
            child: Center(child: Text('No revenue data to display.')),
          );
        }

        final revenueData = snapshot.data!;
        final spots = revenueData.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.total);
        }).toList();

        final maxRevenue = revenueData
            .map((e) => e.total)
            .fold(0.0, (max, v) => v > max ? v : max);

        // --- THIS IS THE FIX ---
        // 1. Simplified the maxY calculation for better stability.
        final chartMaxY =
            maxRevenue > 0 ? maxRevenue * 1.25 : 5000.0; // Add 25% padding

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Monthly Revenue',
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
            const SizedBox(height: 16),
            Container(
              height: 250,
              padding: const EdgeInsets.fromLTRB(16, 24, 24, 12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: cardBackgroundColor,
                  borderRadius: BorderRadius.circular(16)),
              child: LineChart(
                LineChartData(
                    minY: 0,
                    maxY: chartMaxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return const FlLine(
                          color: Colors.white10,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < revenueData.length) {
                              final month = revenueData[index].month;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(DateFormat('MMM').format(month),
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          // 2. Removed the manual interval to let the library handle it.
                          getTitlesWidget: (value, meta) {
                            // Don't show label for 0 or for the very top of the chart
                            if (value == meta.min || value == meta.max) {
                              return const SizedBox();
                            }

                            String text;
                            if (value < 1000) {
                              text = value.toInt().toString();
                            } else {
                              text =
                                  '${NumberFormat('0.#').format(value / 1000)}k';
                            }
                            return Text(text,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                                textAlign: TextAlign.left);
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => darkBackgroundColor,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final monthData = revenueData[spot.spotIndex];
                                return LineTooltipItem(
                                    '${DateFormat.yMMMM().format(monthData.month)}\n',
                                    const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                    children: [
                                      TextSpan(
                                        text:
                                            'PKR ${NumberFormat('#,##0').format(monthData.total)}',
                                        style: const TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      )
                                    ]);
                              }).toList();
                            })),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: primaryColor,
                          barWidth: 4,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                  colors: [
                                    primaryColor.withOpacity(0.3),
                                    primaryColor.withOpacity(0.0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter)))
                    ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBarAndSort() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _refreshMembers();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by Member Name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: cardBackgroundColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort, color: Colors.white),
            color: cardBackgroundColor,
            onSelected: (option) {
              setState(() {
                _sortOption = option;
                _refreshMembers();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortOption.name,
                child: Text('Sort by Name'),
              ),
              const PopupMenuItem(
                value: SortOption.feeDueDate,
                child: Text('Sort by Fee Due Date'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final String name = member['name'] ?? 'N/A';
    final String? avatarUrl = member['avatar_url'];
    // --- DATE FORMAT FIX ---
    final String feeDueDate = member['fee_due_date'] != null
        ? 'Fee Due: ${DateFormat('dd MMM yyyy').format(DateTime.parse(member['fee_due_date']))}'
        : 'Fee date not set';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(feeDueDate,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AdminMemberPaymentHistoryScreen(
                      memberId: member['user_id'],
                      memberName: name,
                      memberAvatarUrl: avatarUrl,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('View History'),
            ),
          ],
        ),
      ),
    );
  }
}
