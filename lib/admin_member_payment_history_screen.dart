// lib/admin_member_payment_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart';
import 'theme.dart';

class AdminMemberPaymentHistoryScreen extends StatefulWidget {
  final String memberId;
  final String memberName;
  final String? memberAvatarUrl;

  const AdminMemberPaymentHistoryScreen({
    super.key,
    required this.memberId,
    required this.memberName,
    this.memberAvatarUrl,
  });

  @override
  State<AdminMemberPaymentHistoryScreen> createState() => _AdminMemberPaymentHistoryScreenState();
}

class _AdminMemberPaymentHistoryScreenState extends State<AdminMemberPaymentHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _paymentsFuture = _fetchPaymentHistory();
  }

  /// Fetches the complete payment history for the selected member.
  Future<List<Map<String, dynamic>>> _fetchPaymentHistory() async {
    try {
      final response = await supabase
          .from('payments')
          .select()
          .eq('member_id', widget.memberId)
          .order('payment_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching payment history: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.memberName}'s History"),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _paymentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final payments = snapshot.data!;
                if (payments.isEmpty) {
                  return const Center(child: Text('No payment history found for this member.'));
                }
                return ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    return _buildPaymentCard(payments[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the header section with the member's avatar and name.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: (widget.memberAvatarUrl != null && widget.memberAvatarUrl!.isNotEmpty)
                ? NetworkImage(widget.memberAvatarUrl!)
                : null,
            child: (widget.memberAvatarUrl == null || widget.memberAvatarUrl!.isEmpty)
                ? const Icon(Icons.person, size: 30)
                : null,
          ),
          const SizedBox(width: 16),
          Text(widget.memberName, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }

  /// Builds a card to display the details of a single payment.
  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final paymentDate = DateTime.parse(payment['payment_date'] ?? DateTime.now().toIso8601String());
    final paymentType = (payment['payment_type'] as String?)?.replaceAll('_', ' ').toUpperCase() ?? 'N/A';
    final paymentMethod = (payment['payment_method'] as String?)?.toUpperCase() ?? 'N/A';
    final notes = payment['notes'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PKR ${NumberFormat('#,##0').format(amount)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: primaryColor),
                ),
                Text(
                  DateFormat.yMMMd().format(paymentDate),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.white24),
            Text('Type: $paymentType', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('Method: $paymentMethod', style: Theme.of(context).textTheme.bodyLarge),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: $notes', style: Theme.of(context).textTheme.bodyMedium),
            ]
          ],
        ),
      ),
    );
  }
}
