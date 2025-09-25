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
  List<String> _memberNames = []; // For member search dropdown
  String? _selectedMemberId;

  late Future<List<Map<String, dynamic>>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _fetchMemberNames(); // Load member names for filter
    _transactionsFuture = _fetchTransactions();
  }

  // --- Data Fetching and Processing ---

  Future<void> _fetchMemberNames() async {
    try {
      final response = await supabase.from('members').select('user_id, name').order('name', ascending: true);
      final names = <String>[];
      for (var m in response) {
        names.add(m['name']);
      }
      if (mounted) {
        setState(() {
          _memberNames = names;
        });
      }
    } catch (e) {
      debugPrint("Error fetching member names: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTransactions() async {
    try {
      // Build the base query
      dynamic query = supabase
          .from('payments')
          .select('*, member:members(user_id, name, avatar_url)') // Fetch member details
          .order('payment_date', ascending: false);

      // Apply date range filter
      query = query
          .gte('payment_date', _startDate.toIso8601String())
          .lte('payment_date', _endDate.toIso8601String());

      // Apply payment type filter
      if (_selectedPaymentType != null) {
        query = query.eq('payment_type', _selectedPaymentType);
      }

      // Apply member name/ID filter
      if (_selectedMemberId != null) {
        query = query.eq('member_id', _selectedMemberId);
      }

      // Apply search query (for transaction notes or member names if not filtered by ID)
      if (_searchQuery.isNotEmpty) {
        // This is a more complex filter that might require `or` if searching across multiple fields
        // For simplicity, let's assume searching for notes or member name (if not already filtered)
        query = query.ilike('notes', '%$_searchQuery%');
        // You could add .or('member.name.ilike', '%$_searchQuery%') but Supabase's `or` filter
        // structure for nested properties needs careful construction. For now, just notes.
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

  /// Processes raw transactions into data points for the line chart.
  Map<DateTime, double> _processTransactionsForChart(
      List<Map<String, dynamic>> transactions) {
    final Map<DateTime, double> dataPoints = {};

    for (var transaction in transactions) {
      final date = DateTime.parse(transaction['payment_date']);
      final amount = (transaction['amount'] as num).toDouble();

      DateTime keyDate;
      if (_currentAggregation == DateAggregation.weekly) {
        // Get the start of the week (Monday)
        keyDate = date.subtract(Duration(days: date.weekday - 1));
        keyDate = DateTime(keyDate.year, keyDate.month, keyDate.day); // Normalize to midnight
      } else {
        // Default to start of the month for monthly/custom (if custom is long)
        keyDate = DateTime(date.year, date.month, 1);
      }

      dataPoints.update(keyDate, (value) => value + amount,
          ifAbsent: () => amount);
    }

    // Sort data points by date
    final sortedKeys = dataPoints.keys.toList()..sort();
    final sortedData = <DateTime, double>{};
    for (var key in sortedKeys) {
      sortedData[key] = dataPoints[key]!;
    }

    return sortedData;
  }

  // --- UI Interactions ---

  void _refreshData() {
    setState(() {
      _transactionsFuture = _fetchTransactions();
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTime? pickedStart = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select Start Date',
    );

    if (pickedStart != null) {
      final DateTime? pickedEnd = await showDatePicker(
        context: context,
        initialDate: _endDate,
        firstDate: pickedStart,
        lastDate: DateTime.now(),
        helpText: 'Select End Date',
      );

      if (pickedEnd != null) {
        setState(() {
          _startDate = pickedStart;
          _endDate = DateTime(pickedEnd.year, pickedEnd.month, pickedEnd.day, 23, 59, 59); // Set to end of day
          _currentAggregation = DateAggregation.custom;
          _refreshData();
        });
      }
    }
  }

  Future<void> _confirmDeletePayment(int paymentId) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text(
            'Are you sure you want to permanently delete this payment record? This action cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await supabase.from('payments').delete().eq('id', paymentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Transaction deleted successfully.'),
                backgroundColor: Colors.green),
          );
        }
        _refreshData(); // Refresh the list after deletion
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error deleting transaction: $e'),
                backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    }
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        title: const Text('Financial Analytics'),
        backgroundColor: darkBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterControls(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final transactions = snapshot.data ?? [];

                if (transactions.isEmpty) {
                  return const Center(child: Text('No transactions found for the selected filters.'));
                }

                final chartData = _processTransactionsForChart(transactions);
                final totalRevenue = transactions.fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
                
                return RefreshIndicator(
                  onRefresh: () async => _refreshData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(totalRevenue),
                        const SizedBox(height: 20),
                        _buildLineChartCard(chartData),
                        const SizedBox(height: 20),
                        Text('All Transactions', style: Theme.of(context).textTheme.headlineSmall),
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
      ),
    );
  }

  Widget _buildFilterControls() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: cardBackgroundColor, // A subtle background for filters
      child: Column(
        children: [
          // Date Range & Aggregation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAggregationChip(DateAggregation.monthly, 'Monthly'),
              _buildAggregationChip(DateAggregation.weekly, 'Weekly'),
              ActionChip(
                label: Text(
                  _currentAggregation == DateAggregation.custom
                      ? '${DateFormat.yMMMd().format(_startDate)} - ${DateFormat.yMMMd().format(_endDate)}'
                      : 'Custom Date',
                ),
                onPressed: () => _selectDateRange(context),
                backgroundColor: _currentAggregation == DateAggregation.custom ? primaryColor : null,
                labelStyle: TextStyle(color: _currentAggregation == DateAggregation.custom ? Colors.black : Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Search and Payment Type Filter
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _refreshData();
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _selectedPaymentType,
                hint: const Text('Type', style: TextStyle(color: Colors.white70)),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Types')),
                  DropdownMenuItem(value: 'monthly_fee', child: Text('Monthly Fee')),
                  DropdownMenuItem(value: 'new_admission', child: Text('New Admission')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentType = value;
                    _refreshData();
                  });
                },
                dropdownColor: cardBackgroundColor,
                style: const TextStyle(color: Colors.white),
                iconEnabledColor: Colors.white,
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _selectedMemberId, // Displaying member ID for selection
                hint: const Text('Member', style: TextStyle(color: Colors.white70)),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Members')),
                  ..._memberNames.map((name) {
                    return DropdownMenuItem(
                      value: supabase.from('members').select('user_id').eq('name', name).single().toString(), // THIS IS A PLACEHOLDER. Actual ID lookup needed.
                      child: Text(name),
                    );
                  }).toList(),
                ],
                onChanged: (value) async {
                  String? memberId;
                  if (value != null) {
                    try {
                      final response = await supabase.from('members').select('user_id').eq('name', value).single();
                      memberId = response['user_id'];
                    } catch (e) {
                      debugPrint("Error finding member ID for name $value: $e");
                    }
                  }
                  setState(() {
                    _selectedMemberId = memberId;
                    _refreshData();
                  });
                },
                dropdownColor: cardBackgroundColor,
                style: const TextStyle(color: Colors.white),
                iconEnabledColor: Colors.white,
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
      onPressed: () {
        setState(() {
          _currentAggregation = aggregation;
          // Adjust _startDate and _endDate based on aggregation
          if (aggregation == DateAggregation.monthly) {
            _endDate = DateTime.now();
            _startDate = DateTime(_endDate.year, _endDate.month - 11, 1); // Last 12 months
          } else if (aggregation == DateAggregation.weekly) {
            _endDate = DateTime.now();
            _startDate = _endDate.subtract(const Duration(days: 7 * 12)); // Last 12 weeks
          }
          _refreshData();
        });
      },
      backgroundColor: _currentAggregation == aggregation ? primaryColor : null,
      labelStyle: TextStyle(color: _currentAggregation == aggregation ? Colors.black : Colors.white),
    );
  }

  Widget _buildSummaryCard(double totalRevenue) {
    return Card(
      color: cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Revenue in Selected Period:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'PKR ${NumberFormat('#,##0').format(totalRevenue)}',
              style: Theme.of(context).textTheme.displaySmall!.copyWith(color: primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChartCard(Map<DateTime, double> chartData) {
    if (chartData.isEmpty) {
      return Card(
        color: cardBackgroundColor,
        child: SizedBox(
          height: 250,
          child: Center(
            child: Text(
              'No data to display for the chart.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    final List<FlSpot> spots = [];
    final sortedKeys = chartData.keys.toList()..sort();
    double minX = 0, maxX = 0, minY = 0, maxY = 0;

    // Convert DateTime keys to double for x-axis
    if (sortedKeys.isNotEmpty) {
      minX = sortedKeys.first.millisecondsSinceEpoch.toDouble();
      maxX = sortedKeys.last.millisecondsSinceEpoch.toDouble();
      minY = chartData.values.reduce((a, b) => a < b ? a : b);
      maxY = chartData.values.reduce((a, b) => a > b ? a : b);
    }

    for (int i = 0; i < sortedKeys.length; i++) {
      final date = sortedKeys[i];
      spots.add(FlSpot(date.millisecondsSinceEpoch.toDouble(), chartData[date]!));
    }

    return Card(
      color: cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), // Adjust padding for chart
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Revenue Trend', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white12,
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.white12,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          String text;
                          if (_currentAggregation == DateAggregation.weekly) {
                            text = DateFormat('MMM d').format(date); // Show week start
                          } else {
                            text = DateFormat('MMM yy').format(date); // Show month/year
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8.0,
                            child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                          );
                        },
                        interval: (maxX - minX) / 5, // Approx 5 labels
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(NumberFormat.compact().format(value), style: const TextStyle(color: Colors.white70, fontSize: 10));
                        },
                        interval: (maxY - minY) / 3, // Approx 3 labels
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  minX: minX,
                  maxX: maxX,
                  minY: minY * 0.9, // Start chart slightly below min value
                  maxY: maxY * 1.1, // End chart slightly above max value
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: primaryColor,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.5),
                            primaryColor.withOpacity(0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
        final memberName = member?['name'] ?? 'N/A';
        final avatarUrl = member?['avatar_url'];

        return Card(
          color: cardBackgroundColor,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ExpansionTile( // Using ExpansionTile for detailed breakdown
            leading: CircleAvatar(
              backgroundColor: payment['payment_type'] == 'new_admission'
                  ? Colors.orange
                  : primaryColor,
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
              child: (avatarUrl == null || avatarUrl.isEmpty) ? Icon(Icons.person, color: Colors.black) : null,
            ),
            title: Text(
              'PKR ${NumberFormat('#,##0').format((payment['amount'] as num).toDouble())}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Paid by: $memberName - ${DateFormat.yMd().format(DateTime.parse(payment['payment_date']))}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDeletePayment(payment['id']),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type: ${payment['payment_type'] == 'monthly_fee' ? 'Monthly Fee' : 'New Admission'}', style: const TextStyle(color: Colors.white70)),
                    Text('Method: ${payment['payment_method']}', style: const TextStyle(color: Colors.white70)),
                    if (payment['notes'] != null && payment['notes'].isNotEmpty)
                      Text('Notes: ${payment['notes']}', style: const TextStyle(color: Colors.white70)),
                    Text('Transaction ID: ${payment['id']}', style: const TextStyle(color: Colors.white70)),
                    if (member != null)
                      Text('Member ID: ${member['user_id']}', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}