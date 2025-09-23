// lib/admin_edit_member_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart';
import 'theme.dart';

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
  late TextEditingController _planController;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.memberData['name']);
    _phoneController = TextEditingController(text: widget.memberData['phone']);
    _planController = TextEditingController(text: widget.memberData['membership_plan'] ?? 'Monthly');
    _startDate = widget.memberData['start_date'] != null ? DateTime.parse(widget.memberData['start_date']) : null;
    _endDate = widget.memberData['end_date'] != null ? DateTime.parse(widget.memberData['end_date']) : null;
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }
  
  Future<void> _updateMember() async {
    if(!_formKey.currentState!.validate()){ return; }
    setState(() => _isLoading = true);
    try {
      final response = await supabase.functions.invoke('update-member', body: {
        'member_id': widget.memberData['id'],
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'membership_plan': _planController.text.trim(),
        'start_date': _startDate?.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
      });

      if(response.status != 200){
        throw response.data['error'] ?? 'Unknown error';
      }
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member updated successfully'), backgroundColor: primaryColor));
        Navigator.of(context).pop(true);
      }

    } catch(e) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating member: $e'), backgroundColor: Theme.of(context).colorScheme.error));
      }
    } finally {
      if(mounted){
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Member')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 16),
            TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
            const SizedBox(height: 16),
            TextFormField(controller: _planController, decoration: const InputDecoration(labelText: 'Membership Plan')),
            const SizedBox(height: 24),
            ListTile(
              title: Text('Start Date: ${_startDate != null ? DateFormat.yMMMd().format(_startDate!) : 'Not Set'}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, true),
            ),
            ListTile(
              title: Text('End Date: ${_endDate != null ? DateFormat.yMMMd().format(_endDate!) : 'Not Set'}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, false),
            ),
            const SizedBox(height: 24),
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _updateMember, child: const Text('Save Changes')),
          ],
        ),
      ),
    );
  }
}