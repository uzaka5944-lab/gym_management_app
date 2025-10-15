// lib/admin_edit_member_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart';

class AdminEditMemberScreen extends StatefulWidget {
  final Map<String, dynamic> memberData;

  const AdminEditMemberScreen({super.key, required this.memberData});

  @override
  State<AdminEditMemberScreen> createState() => _AdminEditMemberScreenState();
}

class _AdminEditMemberScreenState extends State<AdminEditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _serialNumberController; // Add this controller
  DateTime? _feeDueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.memberData['name']);
    _phoneController = TextEditingController(text: widget.memberData['phone']);
    _addressController =
        TextEditingController(text: widget.memberData['address']);
    _serialNumberController = TextEditingController(
        text: widget.memberData['serial_number']); // Initialize it
    _feeDueDate = widget.memberData['fee_due_date'] != null
        ? DateTime.parse(widget.memberData['fee_due_date'])
        : null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _feeDueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _feeDueDate) {
      setState(() {
        _feeDueDate = picked;
      });
    }
  }

  Future<void> _updateMember() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      await supabase.from('members').update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'serial_number':
            _serialNumberController.text.trim(), // Save the serial number
        'fee_due_date': _feeDueDate?.toIso8601String(),
      }).eq('user_id', widget.memberData['user_id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Member updated successfully'),
            backgroundColor: Theme.of(context).primaryColor));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error updating member: $e'),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Member Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller:
                  _serialNumberController, // Add the serial number field
              decoration: const InputDecoration(labelText: 'Serial Number'),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (value) =>
                  value!.isEmpty ? 'Name cannot be empty' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                  'Fee Due Date: ${_feeDueDate != null ? DateFormat('dd MMM yyyy').format(_feeDueDate!) : 'Not Set'}'),
              trailing: Icon(Icons.calendar_today,
                  color: Theme.of(context).primaryColor),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _updateMember,
                    child: const Text('Save Changes')),
          ],
        ),
      ),
    );
  }
}
