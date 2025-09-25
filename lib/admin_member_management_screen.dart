// lib/admin_member_management_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart';
import 'theme.dart';
import 'admin_add_member_screen.dart';
import 'admin_member_details_screen.dart';

class AdminMemberManagementScreen extends StatefulWidget {
  const AdminMemberManagementScreen({super.key});

  @override
  State<AdminMemberManagementScreen> createState() =>
      _AdminMemberManagementScreenState();
}

// Enums to manage filter and sort states cleanly
// NEW: Added 'allActive' status and renamed 'active' to 'paid' for clarity
enum MemberStatus { allActive, paid, feeDue, frozen, removed }
enum SortOption { name, date, feeDue }

class _AdminMemberManagementScreenState
    extends State<AdminMemberManagementScreen> {
  // State variables for managing filters, search, and the data future
  // CHANGED: The default view is now 'allActive'
  MemberStatus _selectedStatus = MemberStatus.allActive;
  SortOption _sortOption = SortOption.name;
  String _searchQuery = '';
  late Future<List<Map<String, dynamic>>> _membersFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initial fetch of members when the screen loads
    _membersFuture = _fetchMembers();
  }

  /// Fetches members from the Supabase database based on the current filters and search query.
  Future<List<Map<String, dynamic>>> _fetchMembers() async {
    try {
      dynamic query = supabase
          .from('members')
          .select('user_id, name, fee_due_date, status, avatar_url');

      // Use today's date at midnight for consistent date comparisons across timezones
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day).toIso8601String();

      // Apply filters based on the selected status chip
      switch (_selectedStatus) {
        // NEW: Case to show all members with an 'active' status, regardless of fee date
        case MemberStatus.allActive:
          query = query.eq('status', 'active');
          break;
        case MemberStatus.paid:
          // This was the old 'active' filter logic
          query = query.eq('status', 'active').gte('fee_due_date', today);
          break;
        case MemberStatus.frozen:
          query = query.eq('status', 'frozen');
          break;
        case MemberStatus.removed:
          query = query.eq('status', 'removed');
          break;
        case MemberStatus.feeDue:
          // Fee Due members have 'active' status AND their due date is in the past.
          query = query.eq('status', 'active').lt('fee_due_date', today);
          break;
      }

      // Apply search query if the user has typed in the search bar
      if (_searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$_searchQuery%');
      }

      // Apply sorting based on the selected sort option
      switch (_sortOption) {
        case SortOption.name:
          query = query.order('name', ascending: true);
          break;
        case SortOption.date:
          query = query.order('fee_due_date', ascending: false);
          break;
        case SortOption.feeDue:
          query = query.order('fee_due_date', ascending: true);
          break;
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Gracefully handle errors by showing a snackbar and returning an empty list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching members: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
      return [];
    }
  }
  
  /// A helper function to re-trigger the _fetchMembers future.
  void _refreshMemberList() {
    setState(() {
      _membersFuture = _fetchMembers();
    });
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
          // If a new member was added, refresh the list
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
                // Show a loading indicator while fetching data
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Show an error message if fetching fails
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                final members = snapshot.data!;
                // Show a message if no members match the current filters
                if (members.isEmpty) {
                  return const Center(
                    child: Text(
                      'No members found for this filter.',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  );
                }

                // If data is available, build the list with pull-to-refresh
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

  // --- UI Builder Functions ---

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // NEW and CHANGED Filters
            _buildChip(MemberStatus.allActive, 'All Active', Colors.blue),
            _buildChip(MemberStatus.paid, 'Paid', Colors.green),
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
        trailing: _buildStatusIcon(member['status'], member['fee_due_date']),
        onTap: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => AdminMemberDetailsScreen(memberId: member['user_id']),
            ),
          );
          // Refresh the list if data might have changed on the details screen
          if (result == true) {
            _refreshMemberList();
          }
        },
      ),
    );
  }

  Widget? _buildStatusIcon(String? status, String? feeDueDate) {
    if (status == 'active') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDate = feeDueDate != null ? DateTime.parse(feeDueDate) : today.subtract(const Duration(days: 1));
      
      if (dueDate.isBefore(today)) {
        return const Icon(Icons.warning_amber_rounded, color: Colors.orange); // Fee Due
      }
      return const Icon(Icons.check_circle, color: Colors.green); // Paid
    }

    switch (status) {
      case 'frozen':
        return const Icon(Icons.ac_unit, color: Colors.cyan);
      case 'removed':
        return const Icon(Icons.remove_circle_outline, color: Colors.grey);
      default:
        return null;
    }
  }
}