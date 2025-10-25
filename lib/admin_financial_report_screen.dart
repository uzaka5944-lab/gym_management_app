import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'main.dart';
// IMPORT THE NEW SERVICE
import 'monthly_report_service.dart';

// THE MonthlyReportData CLASS IS NOW IN 'monthly_report_service.dart'

class AdminFinancialReportScreen extends StatefulWidget {
  const AdminFinancialReportScreen({super.key});

  @override
  State<AdminFinancialReportScreen> createState() =>
      _AdminFinancialReportScreenState();
}

class _AdminFinancialReportScreenState
    extends State<AdminFinancialReportScreen> {
  late DateTime _selectedDate;
  // USE THE NEW SERVICE
  final MonthlyReportService _monthlyReportService = MonthlyReportService();
  // STORE THE REPORT DATA FOR THE PDF BUTTON
  MonthlyReportData? _currentReportData;
  Future<MonthlyReportData>? _reportFuture;
  int _touchedIndex = -1;

  // STORE THE STANDARD ADMISSION FEE
  double _standardAdmissionFee = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadReportData();
  }

  // UPDATED TO AVOID RELYING ON _reportFuture in the build method
  void _loadReportData() {
    final future = _fetchReportData(_selectedDate);
    setState(() {
      _reportFuture = future;
    });
    future.then((data) {
      setState(() {
        _currentReportData = data;
      });
    }).catchError((error) {
      // Capture the error
      // Handle error if needed, maybe set _currentReportData to null
      setState(() {
        _currentReportData = null;
      });
      // Print the detailed error
      print('Error loading report data: $error');
      // Optionally show an error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error loading report data: $error'), // Show error details
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    });
  }

  Future<MonthlyReportData> _fetchReportData(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    // 1. Fetch Standard Admission Fee
    try {
      final settings = await supabase
          .from('gym_settings')
          .select('value')
          .eq('id', 'admission_fee')
          .maybeSingle();
      if (settings != null && settings['value'] != null) {
        _standardAdmissionFee = double.tryParse(settings['value']) ?? 0;
      } else {
        _standardAdmissionFee = 0;
      }
    } catch (_) {
      _standardAdmissionFee = 0;
    }

    // 2. Fetch Payments and join ONLY with profiles (Reverted Query)
    final response = await supabase
        .from('payments')
        .select('*, profiles!inner(id, full_name)') // Reverted select
        .gte('payment_date', startOfMonth.toIso8601String())
        .lte('payment_date', endOfMonth.toIso8601String())
        .order('payment_date', ascending: false);

    // The rest of the data processing remains largely the same
    final List<Map<String, dynamic>> payments =
        List<Map<String, dynamic>>.from(response);

    final Map<String, double> summary = {
      'monthly_fee': 0.0,
      'new_admission': 0.0,
      'admission_fee_portion': 0.0,
      'advance_monthly_portion': 0.0,
    };
    int monthlyFeeCount = 0;
    int newAdmissionCount = 0;
    double total = 0.0;

    for (var p in payments) {
      final amount = (p['amount'] as num).toDouble();
      final type = p['payment_type'];
      total += amount;

      if (type == 'monthly_fee') {
        summary['monthly_fee'] = summary['monthly_fee']! + amount;
        monthlyFeeCount++;
      } else if (type == 'new_admission') {
        summary['new_admission'] = summary['new_admission']! + amount;
        newAdmissionCount++;

        // Only add to portions if standard fee is positive
        if (_standardAdmissionFee > 0) {
          if (amount >= _standardAdmissionFee) {
            summary['admission_fee_portion'] =
                summary['admission_fee_portion']! + _standardAdmissionFee;
            summary['advance_monthly_portion'] =
                summary['advance_monthly_portion']! +
                    (amount - _standardAdmissionFee);
          } else {
            // Case where admission was less than standard (e.g., a discount)
            summary['admission_fee_portion'] =
                summary['admission_fee_portion']! + amount;
          }
        } else {
          // If standard fee is 0 or not set, consider the whole amount as advance monthly
          summary['advance_monthly_portion'] =
              summary['advance_monthly_portion']! + amount;
        }
      }
    }

    return MonthlyReportData(
      summary: summary,
      monthlyFeeCount: monthlyFeeCount,
      newAdmissionCount: newAdmissionCount,
      payments: payments, // Pass payments data (without direct member info)
      total: total,
    );
  }

  void _refreshReport() {
    _loadReportData();
  }

  void _changeMonth(int monthIncrement) {
    setState(() {
      _selectedDate =
          DateTime(_selectedDate.year, _selectedDate.month + monthIncrement, 1);
    });
    _loadReportData();
  }

  // PDF Export Function
  Future<void> _exportAsPdf() async {
    // Check if report data is available (it might be null if fetch failed)
    if (_currentReportData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text(
                'Report data is not available. Please try refreshing.'),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating Multi-Page PDF...',
                    style: TextStyle(color: Colors.white, fontSize: 16))
              ],
            )));

    try {
      // Pass the already fetched data to the service.
      // The service will re-fetch with the complex join internally for the PDF.
      final pdfBytes =
          await _monthlyReportService.generateMonthlyFinancialReport(
        _currentReportData!, // Now we know it's not null
        _selectedDate,
      );
      if (mounted) Navigator.of(context).pop(); // Close loading dialog
      await _monthlyReportService.shareReport(pdfBytes,
          'Monthly_Report_${DateFormat('MMM_yyyy').format(_selectedDate)}');
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Transaction deleted successfully.'),
                backgroundColor: Colors.green),
          );
        }
        _refreshReport();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Report'),
        actions: [
          // ADDED PDF EXPORT BUTTON
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _currentReportData == null ? null : _exportAsPdf,
            tooltip: 'Export as PDF',
          ),
        ],
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
                  // Display the actual error for debugging
                  print('Error in FutureBuilder: ${snapshot.error}');
                  // Use a more user-friendly error message
                  return const Center(
                      child:
                          Text('Error loading report data. Please try again.'));
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
            // Use Wrap for better responsive layout of legend
            Wrap(
              alignment: WrapAlignment.center, // Keep center alignment
              spacing: 16.0, // Horizontal space between items
              runSpacing: 12.0, // Vertical space between lines
              children: [
                _buildLegendItem(theme.primaryColor, 'Monthly Fee Payments',
                    monthlyFee, currencyFormat),
                _buildAdmissionLegend(
                    'New Admission Payments', report.summary, currencyFormat),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCountIndicator(
                  'Monthly Payments',
                  report.monthlyFeeCount,
                  theme.primaryColor,
                ),
                _buildCountIndicator(
                  'New Admissions',
                  report.newAdmissionCount,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountIndicator(String title, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context)
              .textTheme
              .displayMedium
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildPaymentList(List<Map<String, dynamic>> payments) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('All Transactions', style: theme.textTheme.displayMedium),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            // Extract data safely
            final memberName = payment['profiles']?['full_name'] ?? 'N/A';
            final memberId = payment['member_id'];
            final onPrimaryColor = theme.colorScheme.onPrimary;

            // Determine the icon based on payment type
            IconData paymentIcon;
            Color iconBgColor;
            Color iconColor;

            if (payment['payment_type'] == 'new_admission') {
              paymentIcon = Icons.person_add_alt_1; // Icon for new admission
              iconBgColor = Colors.orange;
              iconColor = Colors.black;
            } else {
              paymentIcon = Icons.autorenew; // Icon for monthly fee
              iconBgColor = theme.primaryColor;
              iconColor = onPrimaryColor;
            }

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: iconBgColor,
                  child:
                      Icon(paymentIcon, color: iconColor), // Use dynamic icon
                ),
                title: Text("PKR ${payment['amount']}"),
                subtitle: Text("Paid by: $memberName"), // Serial number removed
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

  // MODIFIED: Wrapped text column in Expanded for alignment
  Widget _buildLegendItem(
      Color color, String title, double value, NumberFormat format) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min, // Keep row compact
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          margin: const EdgeInsets.only(top: 4), // Align circle with first line
        ),
        const SizedBox(width: 8),
        Expanded(
          // Allow this column to expand and align left
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: theme.textTheme.bodyMedium),
              Text('PKR ${format.format(value)}',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
    );
  }

  // MODIFIED: Wrapped text column in Expanded for alignment
  Widget _buildAdmissionLegend(
      String title, Map<String, double> summary, NumberFormat format) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min, // Keep row compact
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration:
              const BoxDecoration(shape: BoxShape.circle, color: Colors.orange),
          margin: const EdgeInsets.only(top: 4), // Align circle with first line
        ),
        const SizedBox(width: 8),
        Expanded(
          // Allow this column to expand and align left
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: theme.textTheme.bodyMedium),
              Text('PKR ${format.format(summary['new_admission'])}',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '↳ Fee Portion: PKR ${format.format(summary['admission_fee_portion'])}',
                        style:
                            theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
                    Text(
                        '↳ Monthly Portion: PKR ${format.format(summary['advance_monthly_portion'])}',
                        style:
                            theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
