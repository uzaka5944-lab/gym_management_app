// lib/admin_member_management_screen.dart
import 'package:flutter/material.dart';
import 'main.dart'; // To get the global supabase client
import 'theme.dart'; // For theme colors
import 'admin_add_member_screen.dart'; // Import the add member screen
import 'admin_member_details_screen.dart'; // Import the new details screen

class AdminMemberManagementScreen extends StatefulWidget {
  const AdminMemberManagementScreen({super.key});

  @override
  State<AdminMemberManagementScreen> createState() =>
      _AdminMemberManagementScreenState();
}

class _AdminMemberManagementScreenState
    extends State<AdminMemberManagementScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      final response = await supabase
          .from('profiles')
          .select('id, full_name')
          .eq('role', 'member')
          .order('full_name', ascending: true);
      
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AdminAddMemberScreen()),
          );
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
                  onRefresh: _fetchMembers,
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
                          // --- ADD THIS ONTAP HANDLER ---
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AdminMemberDetailsScreen(
                                  memberId: member['id'],
                                  memberName: member['full_name'] ?? 'Member',
                                ),
                              ),
                            ).then((_) => _fetchMembers()); // Refresh list when returning
                          },
                          // -------------------------------
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}