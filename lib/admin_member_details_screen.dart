// lib/admin_member_details_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart';
// import 'admin_edit_member_screen.dart'; // We will use this later

class AdminMemberDetailsScreen extends StatefulWidget {
  final String memberId;
  final String memberName; // <-- ADDED THIS LINE

  const AdminMemberDetailsScreen({
    super.key,
    required this.memberId,
    required this.memberName, // <-- AND THIS LINE
  });

  @override
  State<AdminMemberDetailsScreen> createState() =>
      _AdminMemberDetailsScreenState();
}

class _AdminMemberDetailsScreenState extends State<AdminMemberDetailsScreen> {
  late Future<Map<String, dynamic>> _memberDetailsFuture;

  @override
  void initState() {
    super.initState();
    _memberDetailsFuture = _fetchMemberDetails();
  }

  Future<Map<String, dynamic>> _fetchMemberDetails() async {
    try {
      final response = await supabase
          .from('members')
          .select()
          .eq('user_id', widget.memberId)
          .single();
      return response;
    } catch (e) {
      final profileResponse = await supabase.from('profiles').select('full_name, id').eq('id', widget.memberId).single();
      return {
        'user_id': profileResponse['id'],
        'name': profileResponse['full_name'],
        'email': 'Loading...',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.memberName), // This now works correctly
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Edit Member screen coming soon!'),
              ));
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _memberDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final member = snapshot.data!;
          final startDate = member['start_date'] != null ? DateTime.parse(member['start_date']) : null;
          final endDate = member['end_date'] != null ? DateTime.parse(member['end_date']) : null;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _memberDetailsFuture = _fetchMemberDetails();
              });
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                ListTile(leading: const Icon(Icons.person), title: Text(member['name'] ?? 'N/A'), subtitle: const Text('Full Name')),
                ListTile(leading: const Icon(Icons.email), title: Text(member['email'] ?? 'Not set'), subtitle: const Text('Email')),
                ListTile(leading: const Icon(Icons.phone), title: Text(member['phone'] ?? 'Not set'), subtitle: const Text('Phone')),
                const Divider(),
                ListTile(leading: const Icon(Icons.credit_card), title: Text(member['membership_plan'] ?? 'Monthly'), subtitle: const Text('Membership Plan')),
                ListTile(leading: const Icon(Icons.date_range), title: Text(startDate != null ? DateFormat.yMMMd().format(startDate) : 'Not set'), subtitle: const Text('Start Date')),
                ListTile(leading: const Icon(Icons.date_range_outlined), title: Text(endDate != null ? DateFormat.yMMMd().format(endDate) : 'Not set'), subtitle: const Text('End Date')),
              ],
            ),
          );
        },
      ),
    );
  }
}