// lib/admin_member_management_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart'; // Assuming 'supabase' is initialized and exported here
import 'theme.dart';
import 'admin_add_member_screen.dart';

class AdminMemberManagementScreen extends StatefulWidget {
  const AdminMemberManagementScreen({super.key});

  @override
  State<AdminMemberManagementScreen> createState() =>
      _AdminMemberManagementScreenState();
}

enum MemberStatus { active, frozen, feeDue, removed }
enum SortOption { name, date, feeDue }

class _AdminMemberManagementScreenState
    extends State<AdminMemberManagementScreen> {
  MemberStatus _selectedStatus = MemberStatus.active;
  SortOption _sortOption = SortOption.name;
  String _searchQuery = '';
  late Future<List<Map<String, dynamic>>> _membersFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _membersFuture = _fetchMembers();
  }

  Future<List<Map<String, dynamic>>> _fetchMembers() async {
    try {
      // FIX: Use 'dynamic' type to handle different builder return types.
      dynamic query = supabase
          .from('members')
          .select('user_id, name, fee_due_date, status, avatar_url');

      // --- Filter by Status ---
      final today = DateTime.now();
      final threeDaysAgo = today.subtract(const Duration(days: 3));

      switch (_selectedStatus) {
        case MemberStatus.active:
          query = query.eq('status', 'active');
          break;
        case MemberStatus.frozen:
          query = query.eq('status', 'frozen');
          break;
        case MemberStatus.removed:
          query = query.eq('status', 'removed');
          break;
        case MemberStatus.feeDue:
          query = query
              .lt('fee_due_date', threeDaysAgo.toIso8601String())
              .eq('status', 'active');
          break;
      }

      // --- Filter by Search Query ---
      if (_searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$_searchQuery%');
      }

      // --- Sort the results ---
      switch (_sortOption) {
        case SortOption.name:
          query = query.order('name', ascending: true);
          break;
        case SortOption.date:
          // Placeholder for future implementation if created_at is joined
          query = query.order('name', ascending: true);
          break;
        case SortOption.feeDue:
          query = query.order('fee_due_date', ascending: true);
          break;
      }

      final response = await query;
      // Safely cast the response to the expected type
      return List<Map<String, dynamic>>.from(response);
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

  Future<void> _updateMemberStatus(String userId, String newStatus) async {
    try {
        await supabase.from('members').update({'status': newStatus}).eq('user_id', userId);
        if(mounted) Navigator.of(context).pop(); // Close the bottom sheet
        _refreshMemberList();
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member status updated.'), backgroundColor: Colors.green)
        );
        }
    } catch (e) {
        if(mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating status: $e'), backgroundColor: Theme.of(context).colorScheme.error)
          );
        }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AdminAddMemberScreen()),
          );
          if (result == true) {
            _refreshMemberList();
          }
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          _buildSearchBarAndSort(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
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
                      'No members found for this filter.',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _refreshMemberList(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return _buildMemberCard(member);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip(MemberStatus.active, 'Active', Colors.green),
            _buildChip(MemberStatus.feeDue, 'Fee Due', Colors.orange),
            _buildChip(MemberStatus.frozen, 'Frozen', Colors.cyan),
            _buildChip(MemberStatus.removed, 'Removed', Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(MemberStatus status, String label, Color color) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedStatus = status;
              _refreshMemberList();
            });
          }
        },
        backgroundColor: cardBackgroundColor,
        selectedColor: color,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold
        ),
        shape: StadiumBorder(side: BorderSide(color: isSelected ? color : Colors.transparent)),
      ),
    );
  }

  Widget _buildSearchBarAndSort() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _refreshMemberList();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by Name...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: cardBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Simple sort button for now
          PopupMenuButton<SortOption>(
            onSelected: (SortOption result) {
              setState(() {
                _sortOption = result;
                _refreshMemberList();
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              const PopupMenuItem<SortOption>(
                value: SortOption.name,
                child: Text('Sort by Name'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.feeDue,
                child: Text('Sort by Fee Due'),
              ),
            ],
            icon: const Icon(Icons.sort, color: Colors.white),
            color: cardBackgroundColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final dueDateString = member['fee_due_date'] != null
        ? 'Expires: ${DateFormat.yMd().format(DateTime.parse(member['fee_due_date']))}'
        : 'No due date set';
    final avatarUrl = member['avatar_url'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: cardBackgroundColor,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey.shade800,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null ? const Icon(Icons.person, color: Colors.white70) : null,
        ),
        title: Text(member['name'] ?? 'No Name'),
        subtitle: Text(dueDateString, style: const TextStyle(color: Colors.white70)),
        trailing: _buildStatusIcon(member['status']),
        onTap: () => _showMemberActions(member),
      ),
    );
  }

  Widget? _buildStatusIcon(String? status) {
    switch (status) {
      case 'active':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'frozen':
        return const Icon(Icons.ac_unit, color: Colors.cyan);
      case 'removed':
        return const Icon(Icons.remove_circle_outline, color: Colors.grey);
      default:
        return null;
    }
  }

  void _showMemberActions(Map<String, dynamic> member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBackgroundColor,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            if (member['status'] != 'active')
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: const Text('Mark as Active'),
                onTap: () => _updateMemberStatus(member['user_id'], 'active'),
              ),
            if (member['status'] != 'frozen')
              ListTile(
                leading: const Icon(Icons.ac_unit, color: Colors.cyan),
                title: const Text('Mark as Frozen'),
                onTap: () => _updateMemberStatus(member['user_id'], 'frozen'),
              ),
            if (member['status'] != 'removed')
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Remove Member'),
                onTap: () => _updateMemberStatus(member['user_id'], 'removed'),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined, color: Colors.orange),
                title: const Text('Update Fee Date'),
                onTap: () async {
                    Navigator.pop(context); // Close sheet before showing date picker
                    final newDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                    );
                    if (newDate != null) {
                        await supabase.from('members').update({'fee_due_date': newDate.toIso8601String()}).eq('user_id', member['user_id']);
                        _refreshMemberList();
                    }
                },
              ),
          ],
        );
      },
    );
  }
}