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

  // --- WIDGET BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.memberName}'s History"),
        backgroundColor: darkBackgroundColor,
        elevation: 0,
      ),
      backgroundColor: darkBackgroundColor,
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
            // Also build the header even if there are no payments
            return Column(
              children: [
                _buildHeader(),
                const Expanded(
                  child: Center(
                    child: Text('No payment history found for this member.'),
                  ),
                ),
              ],
            );
          }
          // Using a ListView to combine the header and the payment timeline
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 20),
            itemCount: payments.length + 1, // +1 for the header
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildHeader();
              }
              final payment = payments[index - 1];
              // Pass the isLast flag to the card builder
              return _buildTimelinePaymentCard(payment, isLast: index == payments.length);
            },
          );
        },
      ),
    );
  }

  /// **NEW:** Builds the redesigned, centered header.
  Widget _buildHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50, // Increased size
          backgroundColor: cardBackgroundColor,
          backgroundImage: (widget.memberAvatarUrl != null && widget.memberAvatarUrl!.isNotEmpty)
              ? NetworkImage(widget.memberAvatarUrl!)
              : null,
          child: (widget.memberAvatarUrl == null || widget.memberAvatarUrl!.isEmpty)
              ? const Icon(Icons.person, size: 50, color: Colors.white70)
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          widget.memberName,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 24),
        const Divider(color: Colors.white24, indent: 20, endIndent: 20),
      ],
    );
  }

  /// **NEW:** Builds the visually appealing timeline-style payment card.
  Widget _buildTimelinePaymentCard(Map<String, dynamic> payment, {bool isLast = false}) {
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final paymentDate = DateTime.parse(payment['payment_date'] ?? DateTime.now().toIso8601String());
    final paymentType = (payment['payment_type'] as String?)?.replaceAll('_', ' ').toUpperCase() ?? 'N/A';
    final paymentMethod = (payment['payment_method'] as String?)?.toUpperCase() ?? 'N/A';
    final notes = payment['notes'] as String?;

    IconData typeIcon;
    switch(payment['payment_type']) {
      case 'new_admission':
        typeIcon = Icons.person_add_alt_1_rounded;
        break;
      case 'monthly_fee':
      default:
        typeIcon = Icons.autorenew_rounded;
        break;
    }
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // This column builds the timeline's line and dot
          SizedBox(
            width: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.3)
                  ),
                  child: const Icon(Icons.check, size: 16, color: primaryColor),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: Colors.white24,
                    ),
                  )
              ],
            ),
          ),
          // This is the actual content card
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(right: 20, bottom: 20),
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
                    _buildInfoRow(typeIcon, 'Type: $paymentType'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.payment_rounded, 'Method: $paymentMethod'),
                    if (notes != null && notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.notes_rounded, 'Notes: $notes'),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to build a consistent row with an icon and text.
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
      ],
    );
  }
}