// lib/admin_financial_report_screen.dart
import 'package:flutter/material.dart'; // <--- THIS WAS THE MISSING LINE
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'main.dart';
import 'theme.dart';

// A helper class to hold the processed report data
class MonthlyReportData {
  final Map<String, double> summary;
  final List<Map<String, dynamic>> payments;
  final double total;

  MonthlyReportData({required this.summary, required this.payments, required this.total});
}

class AdminFinancialReportScreen extends StatefulWidget {
  const AdminFinancialReportScreen({super.key});

  @override
  State<AdminFinancialReportScreen> createState() =>
      _AdminFinancialReportScreenState();
}

class _AdminFinancialReportScreenState
    extends State<AdminFinancialReportScreen> {
  late DateTime _selectedDate;
  late Future<MonthlyReportData> _reportFuture;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _reportFuture = _fetchReportData(_selectedDate);
  }

  /// Fetches all payments for a given month and processes them for the report.
  Future<MonthlyReportData> _fetchReportData(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final response = await supabase
        .from('payments')
        .select('*, member:members(name)')
        .gte('payment_date', startOfMonth.toIso8601String())
        .lte('payment_date', endOfMonth.toIso8601String())
        .order('payment_date', ascending: false);
    
    final List<Map<String, dynamic>> payments = List<Map<String, dynamic>>.from(response);

    final Map<String, double> summary = {
      'monthly_fee': 0.0,
      'new_admission': 0.0
    };
    double total = 0.0;

    for (var p in payments) {
      final amount = (p['amount'] as num).toDouble();
      final type = p['payment_type'];
      if (summary.containsKey(type)) {
        summary[type] = summary[type]! + amount;
      }
      total += amount;
    }

    return MonthlyReportData(summary: summary, payments: payments, total: total);
  }
  
  void _changeMonth(int monthIncrement) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + monthIncrement, 1);
      _reportFuture = _fetchReportData(_selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Report'),
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(
            child: FutureBuilder<MonthlyReportData>(
              future: _reportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.payments.isEmpty) {
                  return const Center(child: Text('No payments found for this month.'));
                }

                final report = snapshot.data!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildPieChartCard(report),
                      const SizedBox(height: 24),
                      _buildPaymentList(report.payments),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
          Text(
            DateFormat.yMMMM().format(_selectedDate),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(MonthlyReportData report) {
    final monthlyFee = report.summary['monthly_fee']!;
    final newAdmissionFee = report.summary['new_admission']!;
    
    List<PieChartSectionData> sections = [];
    if (report.total > 0) {
      sections = [
        PieChartSectionData(
          value: monthlyFee,
          color: primaryColor,
          title: '${(monthlyFee / report.total * 100).toStringAsFixed(0)}%',
          radius: 80,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        PieChartSectionData(
          value: newAdmissionFee,
          color: Colors.orange,
          title: '${(newAdmissionFee / report.total * 100).toStringAsFixed(0)}%',
          radius: 80,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ];
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Total Revenue: PKR ${NumberFormat('#,##0').format(report.total)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: sections.isNotEmpty 
                ? PieChart(PieChartData(sections: sections, centerSpaceRadius: 0))
                : const Center(child: Text('No data for chart')),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(primaryColor, 'Monthly Fees'),
                const SizedBox(width: 20),
                _buildLegendItem(Colors.orange, 'New Admissions'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentList(List<Map<String, dynamic>> payments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('All Transactions', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            final memberName = payment['member']?['name'] ?? 'N/A';
            return Card(
              color: cardBackgroundColor,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: payment['payment_type'] == 'new_admission' ? Colors.orange : primaryColor,
                  child: const Icon(Icons.receipt_long, color: Colors.black),
                ),
                title: Text("PKR ${payment['amount']}"),
                subtitle: Text("Paid by: $memberName"),
                trailing: Text(DateFormat.yMd().format(DateTime.parse(payment['payment_date']))),
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
          width: 16,
          height: 16,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}