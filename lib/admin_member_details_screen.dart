// lib/admin_member_details_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (imageFile == null) return;

    try {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()));

      final fileBytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '${widget.memberId}/$fileName';

      await supabase.storage.from('avatars').uploadBinary(
            filePath,
            fileBytes,
          );

      final imageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);

      await supabase
          .from('members')
          .update({'avatar_url': imageUrl}).eq('user_id', widget.memberId);

      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar('Avatar updated successfully!');
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar('Error uploading avatar: $e', isError: true);
      }
    }
  }

  void _showEditProfileDialog(Map<String, dynamic> currentMemberData) {
    final formKey = GlobalKey<FormState>();
    final nameController =
        TextEditingController(text: currentMemberData['name']);
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
    // Expiry date is now calculated by the database, so we don't need it here.

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardBackgroundColor,
              title: const Text('Add New Payment'),
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
                          if (value == null ||
                              value.isEmpty ||
                              double.tryParse(value) == null) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: feeType,
                        dropdownColor: cardBackgroundColor,
                        decoration:
                            const InputDecoration(labelText: 'Payment Type'),
                        items: const [
                          DropdownMenuItem(
                              value: 'monthly_fee', child: Text('Monthly Fee')),
                          DropdownMenuItem(
                              value: 'new_admission',
                              child: Text('New Admission')),
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
                          DropdownMenuItem(
                              value: 'online', child: Text('Online')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => paymentMethod = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Payment Date'),
                        subtitle: Text(DateFormat.yMMMd().format(paymentDate)),
                        trailing: const Icon(Icons.calendar_today,
                            color: primaryColor),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: paymentDate,
                            firstDate: DateTime(2020),
                            lastDate:
                                DateTime.now().add(const Duration(days: 1)),
                          );
                          if (pickedDate != null) {
                            setDialogState(() => paymentDate = pickedDate);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: notesController,
                          decoration: const InputDecoration(
                              labelText: 'Notes (Optional)'))
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
                      // Insert the new payment record
                      await supabase.from('payments').insert({
                        'member_id': widget.memberId,
                        'amount': double.parse(amountController.text),
                        'payment_type': feeType,
                        'payment_method': paymentMethod,
                        'notes': notesController.text.trim(),
                        'payment_date': paymentDate.toIso8601String(),
                      });

                      // --- THIS IS THE FIX ---
                      // Call our smart database function to recalculate the due date
                      await supabase.rpc(
                        'update_member_fee_due_date',
                        params: {'member_uuid': widget.memberId},
                      );

                      if (mounted) Navigator.of(context).pop();
                      _showSnackBar('Payment recorded successfully!');
                      _loadData(); // Refresh the screen
                    } catch (e) {
                      _showSnackBar('Error recording payment: $e',
                          isError: true);
                    }
                  },
                  child: const Text('Save Payment'),
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
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : Colors.green,
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
        title: const Text('Member Details'),
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
                  icon: const Icon(Icons.add_card),
                  label: const Text('Add Payment'),
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
    final feeDueDateString = member['fee_due_date'];
    final feeDueDate =
        feeDueDateString != null ? DateTime.parse(feeDueDateString) : null;

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
                      _buildInfoRow(
                          'ID Number', member['user_id'].substring(0, 12)),
                      _buildInfoRow(
                          'Status', (member['status'] as String).toUpperCase()),
                      _buildInfoRow(
                          'Expires On',
                          feeDueDate != null
                              ? DateFormat.yMMMd().format(feeDueDate)
                              : 'N/A'),
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
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: darkBackgroundColor, width: 4)),
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
                            child: const Icon(Icons.person,
                                size: 40, color: Colors.white54),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _uploadAvatar,
                    child: const CircleAvatar(
                      radius: 15,
                      backgroundColor: cardBackgroundColor,
                      child: Icon(Icons.edit, size: 16, color: primaryColor),
                    ),
                  ),
                )
              ],
            ),
          ),
          Positioned(
            top: 40,
            child: GestureDetector(
              onTap: () => _showEditProfileDialog(member),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      member['name'] ?? 'Member Name',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.grey.shade700,
                    )
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
          .update({'status': newStatus}).eq('user_id', widget.memberId);

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
          onPressed: currentStatus == 'frozen'
              ? null
              : () => _updateMemberStatus('frozen'),
          color: Colors.cyan,
        ),
        _actionButton(
          label: 'Active',
          icon: Icons.check_circle,
          onPressed: currentStatus == 'active'
              ? null
              : () => _updateMemberStatus('active'),
          color: Colors.green,
        ),
        _actionButton(
          label: 'Remove',
          icon: Icons.delete_forever,
          onPressed: currentStatus == 'removed'
              ? null
              : () => _updateMemberStatus('removed'),
          color: Colors.redAccent,
        ),
      ],
    );
  }

  Widget _actionButton(
      {required String label,
      required IconData icon,
      required VoidCallback? onPressed,
      required Color color}) {
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
              side: BorderSide(color: effectiveColor)),
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
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
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
