import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'main.dart';
import 'admin_member_payment_history_screen.dart';

enum SortOption { name, feeDueDate }

class MonthlyRevenue {
  final DateTime month;
  final double total;
  MonthlyRevenue(this.month, this.total);
}

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key, this.analyticsKey});
  final Key? analyticsKey;

  @override
  AdminAnalyticsScreenState createState() => AdminAnalyticsScreenState();
}

class AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  late Future<List<Map<String, dynamic>>> _membersFuture;
  late Future<List<MonthlyRevenue>> _revenueFuture;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.name;

  // THIS IS THE CORRECT LOCATION FOR THE REFRESH METHOD
  void refreshData() {
    _loadData();
  }

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
                  style: Theme.of(context).textTheme.displayMedium),
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

  Widget _buildRevenueChart() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

        final chartMaxY = maxRevenue > 0 ? maxRevenue * 1.25 : 5000.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child:
                  Text('Monthly Revenue', style: theme.textTheme.displayMedium),
            ),
            const SizedBox(height: 16),
            Container(
              height: 250,
              padding: const EdgeInsets.fromLTRB(16, 24, 24, 12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16)),
              child: LineChart(
                LineChartData(
                    minY: 0,
                    maxY: chartMaxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          // FIXED: Replaced deprecated 'withOpacity'
                          color: theme.textTheme.bodyMedium!.color!
                              .withAlpha((255 * 0.1).round()),
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
                                    style: TextStyle(
                                        color:
                                            theme.textTheme.bodyMedium?.color,
                                        fontSize: 12)),
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
                          getTitlesWidget: (value, meta) {
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
                                style: TextStyle(
                                    color: theme.textTheme.bodyMedium?.color,
                                    fontSize: 12),
                                textAlign: TextAlign.left);
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) =>
                                isDark ? const Color(0xFF131414) : Colors.white,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final monthData = revenueData[spot.spotIndex];
                                return LineTooltipItem(
                                    '${DateFormat.yMMMM().format(monthData.month)}\n',
                                    TextStyle(
                                        color: theme.textTheme.bodyLarge?.color,
                                        fontWeight: FontWeight.bold),
                                    children: [
                                      TextSpan(
                                        text:
                                            'PKR ${NumberFormat('#,##0').format(monthData.total)}',
                                        style: TextStyle(
                                            color: theme.primaryColor,
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
                          color: theme.primaryColor,
                          barWidth: 4,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                  colors: [
                                    // FIXED: Replaced deprecated 'withOpacity'
                                    theme.primaryColor
                                        .withAlpha((255 * 0.3).round()),
                                    theme.primaryColor.withAlpha(0),
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
              decoration: const InputDecoration(
                hintText: 'Search by Member Name...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<SortOption>(
            icon: Icon(Icons.sort,
                color: Theme.of(context).textTheme.bodyLarge?.color),
            color: Theme.of(context).cardColor,
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
    final String feeDueDate = member['fee_due_date'] != null
        ? 'Fee Due: ${DateFormat('dd MMM yyyy').format(DateTime.parse(member['fee_due_date']))}'
        : 'Fee date not set';

    return Card(
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
              child: const Text('View History'),
            ),
          ],
        ),
      ),
    );
  }
}
