// lib/admin_member_management_screen.dart
import 'package:flutter/material.dart';
import 'main.dart'; // To get the global supabase client
import 'theme.dart'; // For theme colors
import 'admin_add_member_screen.dart';
import 'admin_member_details_screen.dart';

class AdminMemberManagementScreen extends StatefulWidget {
  const AdminMemberManagementScreen({super.key});

  @override
  State<AdminMemberManagementScreen> createState() =>
      _AdminMemberManagementScreenState();
}

class _AdminMemberManagementScreenState
    extends State<AdminMemberManagementScreen> {
  late Future<List<Map<String, dynamic>>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = _fetchMembers();
  }

  Future<List<Map<String, dynamic>>> _fetchMembers() async {
    try {
      final response = await supabase
          .from('profiles')
          .select('id, full_name')
          .eq('role', 'member')
          .order('full_name', ascending: true);
      return response;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching members: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
      return [];
    }
  }

  void _refreshMemberList() {
    setState(() {
      _membersFuture = _fetchMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AdminAddMemberScreen()),
          );
          if (result == true && mounted) {
            _refreshMemberList();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final members = snapshot.data!;
          if (members.isEmpty) {
            return const Center(
              child: Text(
                'No members found.\nTap the + button to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshMemberList(),
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(member['full_name'] ?? 'No Name'),
                    subtitle: Text('ID: ${member['id']}'),
                    leading: const Icon(Icons.person, color: primaryColor),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AdminMemberDetailsScreen(
                            memberId: member['id'],
                            memberName: member['full_name'] ?? 'Member',
                          ),
                        ),
                      ).then((_) => _refreshMemberList());
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
