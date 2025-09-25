// lib/admin_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'main.dart';
import 'theme.dart';

// Enum to define different time aggregations for the graph
enum DateAggregation { monthly, weekly, custom }

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  // Filters and state for the analytics screen
  DateAggregation _currentAggregation = DateAggregation.monthly;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365)); // Default to last year
  DateTime _endDate = DateTime.now();
  String _searchQuery = '';
  String? _selectedPaymentType; // 'monthly_fee' or 'new_admission'

  // Store members for the dropdown filter
  List<Map<String, dynamic>> _membersList = [];
  String? _selectedMemberId;

  late Future<List<Map<String, dynamic>>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _fetchMembersForFilter();
    _transactionsFuture = _fetchTransactions();
  }

  // --- Data Fetching and Processing ---

  Future<void> _fetchMembersForFilter() async {
    try {
      final response = await supabase.from('members').select('user_id, name').order('name', ascending: true);
      if (mounted) {
        setState(() {
          _membersList = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint("Error fetching member names for filter: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTransactions() async {
    try {
      dynamic query = supabase
          .from('payments')
          .select('*, member:members(user_id, name, avatar_url)')
          .order('payment_date', ascending: false);

      query = query
          .gte('payment_date', _startDate.toIso8601String())
          .lte('payment_date', _endDate.toIso8601String());

      if (_selectedPaymentType != null) {
        query = query.eq('payment_type', _selectedPaymentType);
      }
      if (_selectedMemberId != null) {
        query = query.eq('member_id', _selectedMemberId);
      }
      if (_searchQuery.isNotEmpty) {
        // Simple search on member name for now
         query = query.ilike('member.name', '%$_searchQuery%');
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching transactions: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
      return [];
    }
  }

  Map<DateTime, double> _processTransactionsForChart(List<Map<String, dynamic>> transactions) {
    final Map<DateTime, double> dataPoints = {};
    for (var transaction in transactions) {
      final date = DateTime.parse(transaction['payment_date']);
      final amount = (transaction['amount'] as num).toDouble();
      DateTime keyDate;
      if (_currentAggregation == DateAggregation.weekly) {
        keyDate = date.subtract(Duration(days: date.weekday - 1));
        keyDate = DateTime(keyDate.year, keyDate.month, keyDate.day);
      } else {
        keyDate = DateTime(date.year, date.month, 1);
      }
      dataPoints.update(keyDate, (value) => value + amount, ifAbsent: () => amount);
    }
    final sortedKeys = dataPoints.keys.toList()..sort();
    return {for (var key in sortedKeys) key: dataPoints[key]!};
  }

  // --- UI Interactions ---

  void _refreshData() {
    setState(() {
      _transactionsFuture = _fetchTransactions();
    });
  }

  Future<void> _selectDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = DateTime(pickedRange.end.year, pickedRange.end.month, pickedRange.end.day, 23, 59, 59);
        _currentAggregation = DateAggregation.custom;
        _refreshData();
      });
    }
  }
  
  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterControls(),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _transactionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final transactions = snapshot.data ?? [];
              final chartData = _processTransactionsForChart(transactions);
              final totalRevenue = transactions.fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
              
              if (transactions.isEmpty) {
                return const Center(child: Text('No transactions found.'));
              }

              return RefreshIndicator(
                onRefresh: () async => _refreshData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSummaryCard(totalRevenue),
                      const SizedBox(height: 20),
                      _buildLineChartCard(chartData),
                      const SizedBox(height: 20),
                      Text('Transactions', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 10),
                      _buildTransactionList(transactions),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterControls() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: cardBackgroundColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAggregationChip(DateAggregation.monthly, 'Monthly'),
              _buildAggregationChip(DateAggregation.weekly, 'Weekly'),
              ActionChip(
                label: const Text('Custom'),
                onPressed: _selectDateRange,
                backgroundColor: _currentAggregation == DateAggregation.custom ? primaryColor : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Search by member...'),
                  onChanged: (value) => setState(() {
                    _searchQuery = value;
                    _refreshData();
                  }),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _selectedPaymentType,
                hint: const Text('Type'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Types')),
                  DropdownMenuItem(value: 'monthly_fee', child: Text('Monthly')),
                  DropdownMenuItem(value: 'new_admission', child: Text('Admission')),
                ],
                onChanged: (value) => setState(() {
                  _selectedPaymentType = value;
                  _refreshData();
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAggregationChip(DateAggregation aggregation, String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () => setState(() {
        _currentAggregation = aggregation;
        if (aggregation == DateAggregation.monthly) {
          _endDate = DateTime.now();
          _startDate = DateTime(_endDate.year - 1, _endDate.month, _endDate.day);
        } else if (aggregation == DateAggregation.weekly) {
          _endDate = DateTime.now();
          _startDate = _endDate.subtract(const Duration(days: 84)); // 12 weeks
        }
        _refreshData();
      }),
      backgroundColor: _currentAggregation == aggregation ? primaryColor : null,
    );
  }

  Widget _buildSummaryCard(double totalRevenue) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Total Revenue in Period'),
            Text('PKR ${NumberFormat('#,##0').format(totalRevenue)}', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLineChartCard(Map<DateTime, double> chartData) {
  final spots = chartData.entries.map((entry) => FlSpot(entry.key.millisecondsSinceEpoch.toDouble(), entry.value)).toList();

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: primaryColor,
                barWidth: 3,
                belowBarData: BarAreaData(
                  show: true,
                  color: primaryColor.withOpacity(0.3),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    return Text(DateFormat.MMM().format(date), style: const TextStyle(fontSize: 10));
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Text(NumberFormat.compact().format(value), style: const TextStyle(fontSize: 10)),
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
          ),
        ),
      ),
    ),
  );
}


  Widget _buildTransactionList(List<Map<String, dynamic>> transactions) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final payment = transactions[index];
        final member = payment['member'];
        final avatarUrl = member?['avatar_url'];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
              child: (avatarUrl == null || avatarUrl.isEmpty) ? const Icon(Icons.person) : null,
            ),
            title: Text('PKR ${payment['amount']} - ${member?['name'] ?? 'N/A'}'),
            subtitle: Text('${payment['payment_type']} on ${DateFormat.yMd().format(DateTime.parse(payment['payment_date']))}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _confirmDeletePayment(payment['id']),
            ),
          ),
        );
      },
    );
  }
}