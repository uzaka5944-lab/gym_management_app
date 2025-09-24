// lib/admin_member_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'main.dart';
import 'theme.dart';
import 'admin_edit_member_screen.dart';

class AdminMemberDetailsScreen extends StatefulWidget {
  final String memberId;

  const AdminMemberDetailsScreen({super.key, required this.memberId});

  @override
  State<AdminMemberDetailsScreen> createState() =>
      _AdminMemberDetailsScreenState();
}

class _AdminMemberDetailsScreenState extends State<AdminMemberDetailsScreen> {
  late Future<Map<String, dynamic>> _memberDetailsFuture;
  late Future<List<Map<String, dynamic>>> _paymentHistoryFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _memberDetailsFuture = _fetchMemberDetails();
      _paymentHistoryFuture = _fetchPaymentHistory();
    });
  }

  Future<Map<String, dynamic>> _fetchMemberDetails() async {
    final response = await supabase
        .from('members')
        .select()
        .eq('user_id', widget.memberId)
        .single();
    return response;
  }

  Future<List<Map<String, dynamic>>> _fetchPaymentHistory() async {
    final response = await supabase
        .from('payments')
        .select()
        .eq('member_id', widget.memberId)
        .order('payment_date', ascending: false);
    return response;
  }
  
  void _showLogPaymentDialog(Map<String, dynamic> memberData) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String paymentType = 'monthly_fee'; // Default value

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardBackgroundColor,
              title: const Text('Log New Payment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: paymentType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'monthly_fee', child: Text('Monthly Fee')),
                      DropdownMenuItem(value: 'new_admission', child: Text('New Admission Fee')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        paymentType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (PKR)',
                      prefixText: 'PKR ',
                    ),
                  ),
                   const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) {
                      // Show error
                      return;
                    }

                    try {
                      // 1. Insert into payments table
                      await supabase.from('payments').insert({
                        'member_id': widget.memberId,
                        'amount': amount,
                        'payment_type': paymentType,
                        'notes': notesController.text,
                      });

                      // 2. Update member's due date
                      final currentDueDate = DateTime.parse(memberData['fee_due_date']);
                      final newDueDate = DateTime(currentDueDate.year, currentDueDate.month + 1, currentDueDate.day);
                      await supabase.from('members').update({
                        'fee_due_date': newDueDate.toIso8601String()
                      }).eq('user_id', widget.memberId);

                      if (mounted) {
                        Navigator.of(context).pop();
                        _loadData(); // Refresh screen data
                      }

                    } catch(e) {
                      // Handle error
                    }
                  },
                  child: const Text('Confirm Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        title: const Text('Member Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _memberDetailsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final member = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(member),
                const SizedBox(height: 24),
                _buildPersonalInfoCard(member),
                const SizedBox(height: 24),
                Text('Payment History', style: Theme.of(context).textTheme.headlineSmall),
                _buildPaymentHistory(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> member) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        Positioned(
          top: -40,
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: darkBackgroundColor,
                child: CircleAvatar(
                  radius: 45,
                  backgroundImage: member['avatar_url'] != null
                      ? NetworkImage(member['avatar_url'])
                      : null,
                  child: member['avatar_url'] == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(member['name'] ?? 'Member', style: Theme.of(context).textTheme.displayMedium),
            ],
          ),
        ),
         Positioned(
          top: 10,
          right: 10,
          child: IconButton(
            icon: const Icon(Icons.edit, color: primaryColor),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => AdminEditMemberScreen(memberData: member),
                ),
              );
              if (result == true) {
                _loadData();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard(Map<String, dynamic> member) {
    final feeDueDate = DateTime.parse(member['fee_due_date'] ?? DateTime.now().toIso8601String());
    final feeStatus = feeDueDate.isBefore(DateTime.now()) ? "Overdue" : "Paid";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Member ID', member['user_id'].substring(0, 8)),
                    _buildInfoRow('Phone', member['phone'] ?? 'Not set'),
                    _buildInfoRow('Status', member['status'].toUpperCase()),
                    _buildInfoRow('Next Due Date', DateFormat.yMMMd().format(feeDueDate)),
                    _buildInfoRow('Fee Status', feeStatus, highlight: true),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: member['user_id'],
                  version: QrVersions.auto,
                  size: 100.0,
                  eyeStyle: const QrEyeStyle(color: Colors.black),
                  dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.payment),
              label: const Text('Log Payment'),
              onPressed: () => _showLogPaymentDialog(member),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          )
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _paymentHistoryFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final payments = snapshot.data!;
        if (payments.isEmpty) {
          return const Card(
            color: cardBackgroundColor,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No payment history found.'),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return Card(
              color: cardBackgroundColor,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.receipt_long, color: primaryColor),
                title: Text('PKR ${payment['amount']}'),
                subtitle: Text(payment['payment_type']?.replaceAll('_', ' ').toUpperCase() ?? 'MONTHLY FEE'),
                trailing: Text(DateFormat.yMd().format(DateTime.parse(payment['payment_date']))),
              ),
            );
          },
        );
      },
    );
  }
}
