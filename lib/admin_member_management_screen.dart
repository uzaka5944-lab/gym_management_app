// lib/admin_member_management_screen.dart
import 'package:flutter/material.dart';
import 'main.dart'; // To get the global supabase client
import 'theme.dart'; // For theme colors
import 'admin_add_member_screen.dart'; // Import the add member screen

class AdminMemberManagementScreen extends StatefulWidget {
  const AdminMemberManagementScreen({super.key});

  @override
  State<AdminMemberManagementScreen> createState() =>
      _AdminMemberManagementScreenState();
}

class _AdminMemberManagementScreenState
    extends State<AdminMemberManagementScreen> {
  // Use a List to hold the data so we can update it
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  // Function to fetch members from the 'profiles' table
  Future<void> _fetchMembers() async {
    setState(() { _isLoading = true; });
    try {
      final response = await supabase
          .from('profiles')
          .select('id, full_name') // We only need the name and id
          .eq('role', 'member')
          .order('full_name', ascending: true);
      
      setState(() {
        _members = response;
        _isLoading = false;
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching members: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to add member screen and wait for a result
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AdminAddMemberScreen()),
          );
          // If the result is true, it means a member was added, so refresh the list
          if (result == true) {
            _fetchMembers();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? const Center(
                  child: Text(
                    'No members found.\nTap the + button to add one!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchMembers, // Allows pull-to-refresh
                  child: ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(member['full_name'] ?? 'No Name'),
                          subtitle: Text('ID: ${member['id']}'),
                          leading: const Icon(Icons.person, color: primaryColor),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}