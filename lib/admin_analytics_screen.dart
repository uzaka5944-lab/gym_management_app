// lib/admin_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart';
import 'theme.dart';
import 'admin_member_payment_history_screen.dart';

// Enum for sorting options to keep the code clean and readable.
enum SortOption { name, feeDueDate }

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  // State variables to hold the list of members, the current search query, and the sorting option.
  late Future<List<Map<String, dynamic>>> _membersFuture;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.name; // Default sort is by name.

  @override
  void initState() {
    super.initState();
    // Fetch the initial list of members when the screen loads.
    _membersFuture = _fetchMembers();
  }

  /// Fetches a list of all members from the database.
  /// This is a robust query that won't fail if a payment record is orphaned.
  Future<List<Map<String, dynamic>>> _fetchMembers() async {
    try {
      dynamic query = supabase.from('members').select('user_id, name, fee_due_date, avatar_url');

      // Apply the search query to filter members by name.
      if (_searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$_searchQuery%');
      }

      // Apply the selected sorting option.
      switch (_sortOption) {
        case SortOption.name:
          query = query.order('name', ascending: true);
          break;
        case SortOption.feeDueDate:
          query = query.order('fee_due_date', ascending: true, nullsFirst: false);
          break;
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // If there's an error, show a message to the user and return an empty list.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching members: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
      return [];
    }
  }

  /// Refreshes the member list by re-fetching the data.
  void _refreshMembers() {
    setState(() {
      _membersFuture = _fetchMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      body: Column(
        children: [
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
                  return const Center(child: Text('No members found.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => _refreshMembers(),
                  child: ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      return _buildMemberCard(members[index]);
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

  /// Builds the search bar and sort button UI.
  Widget _buildSearchBarAndSort() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _refreshMembers();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by Member Name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: cardBackgroundColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort, color: Colors.white),
            color: cardBackgroundColor,
            onSelected: (option) {
              setState(() {
                _sortOption = option;
                _refreshMembers();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortOption.name,
                child: Text('Sort by Name'),
              ),
              const PopupMenuItem(
                value: SortOption.feeDueDate,
                child: Text('Sort by Fee Due Date'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a card for a single member in the list.
  Widget _buildMemberCard(Map<String, dynamic> member) {
    final String name = member['name'] ?? 'N/A';
    final String? avatarUrl = member['avatar_url'];
    final String feeDueDate = member['fee_due_date'] != null
        ? 'Fee Due: ${DateFormat.yMMMd().format(DateTime.parse(member['fee_due_date']))}'
        : 'Fee date not set';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
              child: (avatarUrl == null || avatarUrl.isEmpty) ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(feeDueDate, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AdminMemberPaymentHistoryScreen(
                      memberId: member['user_id'],
                      memberName: name,
                      memberAvatarUrl: avatarUrl,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('View History'),
            ),
          ],
        ),
      ),
    );
  }
}
