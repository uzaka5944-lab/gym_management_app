import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'main.dart';

class MonthlyReportData {
  final Map<String, double> summary;
  final List<Map<String, dynamic>> payments;
  final double total;

  MonthlyReportData(
      {required this.summary, required this.payments, required this.total});
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
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _reportFuture = _fetchReportData(_selectedDate);
  }

  Future<MonthlyReportData> _fetchReportData(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final response = await supabase
        .from('payments')
        .select('*, member:members(name, user_id)')
        .gte('payment_date', startOfMonth.toIso8601String())
        .lte('payment_date', endOfMonth.toIso8601String())
        .order('payment_date', ascending: false);

    final List<Map<String, dynamic>> payments =
        List<Map<String, dynamic>>.from(response);

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

    return MonthlyReportData(
        summary: summary, payments: payments, total: total);
  }

  void _refreshReport() {
    setState(() {
      _reportFuture = _fetchReportData(_selectedDate);
    });
  }

  void _changeMonth(int monthIncrement) {
    setState(() {
      _selectedDate =
          DateTime(_selectedDate.year, _selectedDate.month + monthIncrement, 1);
      _reportFuture = _fetchReportData(_selectedDate);
    });
  }

  Future<void> _confirmDeletePayment(int paymentId, String? memberId) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
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

        if (memberId != null) {
          await supabase.rpc(
            'update_member_fee_due_date',
            params: {'member_uuid': memberId},
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Transaction deleted successfully.'),
              backgroundColor: Colors.green),
        );
        _refreshReport();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error deleting transaction: $e'),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
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
                  return const Center(
                      child: Text('No payments found for this month.'));
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
          IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeMonth(-1)),
          Text(
            DateFormat.yMMMM().format(_selectedDate),
            style: Theme.of(context).textTheme.displayMedium,
          ),
          IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeMonth(1)),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(MonthlyReportData report) {
    final theme = Theme.of(context);
    final monthlyFee = report.summary['monthly_fee']!;
    final newAdmissionFee = report.summary['new_admission']!;
    final currencyFormat = NumberFormat('#,##0');
    final onPrimaryColor = theme.colorScheme.onPrimary;

    final List<PieChartSectionData> sections = report.total > 0
        ? [
            PieChartSectionData(
              value: monthlyFee,
              color: theme.primaryColor,
              title: _touchedIndex == 0
                  ? 'PKR\n${currencyFormat.format(monthlyFee)}'
                  : '${(monthlyFee / report.total * 100).toStringAsFixed(0)}%',
              radius: _touchedIndex == 0 ? 90 : 80,
              titleStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: onPrimaryColor,
                  fontSize: 14),
            ),
            PieChartSectionData(
              value: newAdmissionFee,
              color: Colors.orange,
              title: _touchedIndex == 1
                  ? 'PKR\n${currencyFormat.format(newAdmissionFee)}'
                  : '${(newAdmissionFee / report.total * 100).toStringAsFixed(0)}%',
              radius: _touchedIndex == 1 ? 90 : 80,
              titleStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 14),
            ),
          ]
        : [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Total Revenue: PKR ${currencyFormat.format(report.total)}',
              style: theme.textTheme.displayMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: report.total > 0
                  ? PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sections: sections,
                        centerSpaceRadius: 0,
                      ),
                    )
                  : const Center(child: Text('No data for chart')),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20.0,
              runSpacing: 10.0,
              children: [
                _buildLegendItem(theme.primaryColor,
                    'Monthly Fees: PKR ${currencyFormat.format(monthlyFee)}'),
                _buildLegendItem(Colors.orange,
                    'Admissions: PKR ${currencyFormat.format(newAdmissionFee)}'),
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
        Text('All Transactions',
            style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            final memberName = payment['member']?['name'] ?? 'N/A';
            final memberId = payment['member']?['user_id'];
            final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: payment['payment_type'] == 'new_admission'
                      ? Colors.orange
                      : Theme.of(context).primaryColor,
                  child: Icon(Icons.receipt_long,
                      color: payment['payment_type'] == 'new_admission'
                          ? Colors.black
                          : onPrimaryColor),
                ),
                title: Text("PKR ${payment['amount']}"),
                subtitle: Text("Paid by: $memberName"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(DateFormat('dd MMM yyyy')
                        .format(DateTime.parse(payment['payment_date']))),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      onPressed: () =>
                          _confirmDeletePayment(payment['id'], memberId),
                    ),
                  ],
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
