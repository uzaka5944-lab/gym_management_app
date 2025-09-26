// lib/admin_member_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'main.dart';
import 'theme.dart';

class AdminMemberDetailsScreen extends StatefulWidget {
  final String memberId;

  const AdminMemberDetailsScreen({super.key, required this.memberId});

  @override
  State<AdminMemberDetailsScreen> createState() =>
      _AdminMemberDetailsScreenState();
}

class _AdminMemberDetailsScreenState extends State<AdminMemberDetailsScreen> {
  final ValueNotifier<Map<String, dynamic>?> _memberNotifier =
      ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await supabase
          .from('members')
          .select()
          .eq('user_id', widget.memberId)
          .single();
      if (mounted) {
        _memberNotifier.value = data;
      }
    } catch (e) {
      _showSnackBar("Error loading member data: $e", isError: true);
    }
  }

  void _showEditProfileDialog(Map<String, dynamic> currentMemberData) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: currentMemberData['name']);
    final phoneController =
        TextEditingController(text: currentMemberData['phone']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardBackgroundColor,
          title: const Text('Edit Member Info'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) =>
                      value!.isEmpty ? 'Name cannot be empty' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                try {
                  await supabase.from('members').update({
                    'name': nameController.text.trim(),
                    'phone': phoneController.text.trim(),
                  }).eq('user_id', widget.memberId);

                  Navigator.of(context).pop();
                  _showSnackBar('Profile updated successfully!');
                  _loadData();
                } catch (e) {
                  _showSnackBar('Error updating profile: $e', isError: true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showRenewFeeDialog(Map<String, dynamic> currentMemberData) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    String paymentMethod = 'cash';
    String feeType = 'monthly_fee';
    DateTime paymentDate = DateTime.now();
    DateTime expiryDate = DateTime(paymentDate.year, paymentDate.month + 1, paymentDate.day);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardBackgroundColor,
              title: const Text('Renew Membership Fee'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: amountController,
                        decoration:
                            const InputDecoration(labelText: 'Amount (PKR)'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty || double.tryParse(value) == null) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: feeType,
                        dropdownColor: cardBackgroundColor,
                        decoration: const InputDecoration(labelText: 'Fee Type'),
                        items: const [
                          DropdownMenuItem(value: 'monthly_fee', child: Text('Monthly Fee')),
                          DropdownMenuItem(value: 'new_admission', child: Text('New Admission')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => feeType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: paymentMethod,
                        dropdownColor: cardBackgroundColor,
                        decoration:
                            const InputDecoration(labelText: 'Payment Method'),
                        items: const [
                          DropdownMenuItem(value: 'cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'online', child: Text('Online')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => paymentMethod = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('Payment Date'),
                        subtitle: Text(DateFormat.yMMMd().format(paymentDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: paymentDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            setDialogState(() {
                              paymentDate = pickedDate;
                              expiryDate = DateTime(pickedDate.year, pickedDate.month + 1, pickedDate.day);
                            });
                          }
                        },
                      ),
                      ListTile(
                        title: const Text('New Expiry Date'),
                        subtitle: Text(DateFormat.yMMMd().format(expiryDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: expiryDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (pickedDate != null) {
                            setDialogState(() => expiryDate = pickedDate);
                          }
                        },
                      ),
                       const SizedBox(height: 16),
                       TextFormField(
                         controller: notesController,
                         decoration: const InputDecoration(labelText: 'Notes (Optional)')
                       )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    
                    try {
                      // --- NEW: Check for duplicate monthly fee payment ---
                      if (feeType == 'monthly_fee') {
                        final startOfMonth = DateTime(paymentDate.year, paymentDate.month, 1);
                        final endOfMonth = DateTime(paymentDate.year, paymentDate.month + 1, 0, 23, 59, 59);

                        final existingPayment = await supabase
                          .from('payments')
                          .select('id')
                          .eq('member_id', widget.memberId)
                          .eq('payment_type', 'monthly_fee')
                          .gte('payment_date', startOfMonth.toIso8601String())
                          .lte('payment_date', endOfMonth.toIso8601String())
                          .maybeSingle();
                        
                        if (existingPayment != null) {
                           if (mounted) Navigator.of(context).pop();
                          _showSnackBar('This member has already paid their fee for this month.', isError: true);
                          return; // Stop execution
                        }
                      }
                      
                      await supabase.from('payments').insert({
                        'member_id': widget.memberId,
                        'amount': double.parse(amountController.text),
                        'payment_type': feeType, 
                        'payment_method': paymentMethod,
                        'notes': notesController.text.trim(),
                        'payment_date': paymentDate.toIso8601String(),
                      });

                      // +++ START OF THE FIX +++
                      // Get the current due date from the member's profile
                      final currentDueDateString = currentMemberData['fee_due_date'];
                      final currentDueDate = currentDueDateString != null ? DateTime.parse(currentDueDateString) : DateTime(1970);

                      // Only update the member's due date if the new one is later than the current one
                      if (expiryDate.isAfter(currentDueDate)) {
                         await supabase.from('members').update({
                          'fee_due_date': expiryDate.toIso8601String()
                        }).eq('user_id', widget.memberId);
                      }
                      // +++ END OF THE FIX +++

                      if (mounted) Navigator.of(context).pop();
                      _showSnackBar('Membership renewed successfully!');
                      _loadData();
                    } catch(e) {
                      _showSnackBar('Error renewing fee: $e', isError: true);
                    }
                  },
                  child: const Text('Renew'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      ));
    }
  }

  @override
  void dispose() {
    _memberNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: darkBackgroundColor,
        elevation: 0,
      ),
      body: ValueListenableBuilder<Map<String, dynamic>?>(
        valueListenable: _memberNotifier,
        builder: (context, member, child) {
          if (member == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileHeader(member),
                const SizedBox(height: 24),
                _buildActionButtons(member['status']),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showRenewFeeDialog(member),
                  icon: const Icon(Icons.autorenew),
                  label: const Text('Renew Fee'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> member) {
    final avatarUrl = member['avatar_url'];
    final feeDueDate =
        DateTime.parse(member['fee_due_date'] ?? DateTime.now().toIso8601String());

    return Container(
      margin: const EdgeInsets.only(top: 50),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('ID Number', member['user_id'].substring(0, 12)),
                      _buildInfoRow('Status', (member['status'] as String).toUpperCase()),
                      _buildInfoRow('Expires On', DateFormat.yMMMd().format(feeDueDate)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(
                    data: member['user_id'],
                    version: QrVersions.auto,
                    size: 80.0,
                  ),
                ),
              ],
            ),
          ),
          
          Positioned(
            top: -50,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: darkBackgroundColor, width: 4)
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? Image.network(
                        avatarUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: cardBackgroundColor,
                        child: const Icon(Icons.person, size: 40, color: Colors.white54),
                      ),
              ),
            ),
          ),

          Positioned(
            top: 40,
            child: GestureDetector(
              onTap: () => _showEditProfileDialog(member),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30)
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     Text(
                      member['name'] ?? 'Member Name',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.edit, size: 16, color: Colors.grey.shade700,)
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
   Future<void> _updateMemberStatus(String newStatus) async {
     try {
      await supabase
          .from('members')
          .update({'status': newStatus})
          .eq('user_id', widget.memberId);
      
      _showSnackBar('Member status updated to $newStatus');
      _loadData(); 
    } catch (e) {
       _showSnackBar('Error updating status: $e', isError: true);
    }
  }

  Widget _buildActionButtons(String currentStatus) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _actionButton(
          label: 'Freeze',
          icon: Icons.ac_unit,
          onPressed: currentStatus == 'frozen' ? null : () => _updateMemberStatus('frozen'),
          color: Colors.cyan,
        ),
         _actionButton(
          label: 'Active',
          icon: Icons.check_circle,
          onPressed: currentStatus == 'active' ? null : () => _updateMemberStatus('active'),
          color: Colors.green,
        ),
        _actionButton(
          label: 'Remove',
          icon: Icons.delete_forever,
          onPressed: currentStatus == 'removed' ? null : () => _updateMemberStatus('removed'),
          color: Colors.redAccent,
        ),
      ],
    );
  }

  Widget _actionButton({required String label, required IconData icon, required VoidCallback? onPressed, required Color color}) {
    final effectiveColor = onPressed == null ? Colors.grey.shade700 : color;
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            backgroundColor: cardBackgroundColor,
            foregroundColor: effectiveColor,
            side: BorderSide(color: effectiveColor)
          ),
          child: Icon(icon, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: effectiveColor)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}