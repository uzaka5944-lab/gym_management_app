import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';
import 'admin_add_member_screen.dart';
import 'admin_member_details_screen.dart';

enum MemberStatus { all, paid, feeDue, frozen, removed }

enum SortOption { name, date }

class AdminMemberManagementScreen extends StatefulWidget {
  const AdminMemberManagementScreen({super.key});

  @override
  State<AdminMemberManagementScreen> createState() =>
      _AdminMemberManagementScreenState();
}

class _AdminMemberManagementScreenState
    extends State<AdminMemberManagementScreen> {
  MemberStatus _selectedStatus = MemberStatus.all;
  SortOption _sortOption = SortOption.name;
  String _searchQuery = '';
  late Future<List<Map<String, dynamic>>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = _fetchMembers();
  }

  Future<List<Map<String, dynamic>>> _fetchMembers() async {
    try {
      dynamic query = supabase
          .from('members')
          .select('user_id, name, phone, fee_due_date, status, avatar_url');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day).toIso8601String();

      switch (_selectedStatus) {
        case MemberStatus.all:
          break;
        case MemberStatus.paid:
          query = query.eq('status', 'active').gte('fee_due_date', today);
          break;
        case MemberStatus.feeDue:
          query = query.eq('status', 'active').lt('fee_due_date', today);
          break;
        case MemberStatus.frozen:
          query = query.eq('status', 'frozen');
          break;
        case MemberStatus.removed:
          query = query.eq('status', 'removed');
          break;
      }

      if (_searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$_searchQuery%');
      }

      switch (_sortOption) {
        case SortOption.name:
          query = query.order('name', ascending: true);
          break;
        case SortOption.date:
          query =
              query.order('fee_due_date', ascending: true, nullsFirst: true);
          break;
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error fetching members: $e', isError: true);
      }
      return [];
    }
  }

  void _refreshMemberList() {
    setState(() {
      _membersFuture = _fetchMembers();
    });
  }

  Future<void> _launchWhatsApp(Map<String, dynamic> member) async {
    final phone = member['phone'] as String?;
    final name = member['name'] as String? ?? 'Member';
    final memberId = member['user_id'] as String?;
    final expiryDateString = member['fee_due_date'] as String?;

    if (phone == null || phone.isEmpty) {
      _showSnackBar('No phone number available for $name', isError: true);
      return;
    }
    if (memberId == null) return;

    try {
      _showSnackBar('Generating message...');

      final lastPaymentResponse = await supabase
          .from('payments')
          .select('payment_date')
          .eq('member_id', memberId)
          .order('payment_date', ascending: false)
          .limit(1)
          .maybeSingle();

      final lastPaymentDate = lastPaymentResponse != null
          ? DateFormat('dd MMM yyyy')
              .format(DateTime.parse(lastPaymentResponse['payment_date']))
          : 'Not available';

      final expiryDate = expiryDateString != null
          ? DateFormat('dd MMM yyyy').format(DateTime.parse(expiryDateString))
          : 'Not available';

      final message = Uri.encodeComponent('Dear $name,\n'
          'This is a friendly reminder from Luxury Gym.\n'
          'Our records show that your membership expired on *$expiryDate*. Your last payment was on *$lastPaymentDate*.\n'
          'Please clear your remaining dues at your earliest convenience.\n'
          'Thank you,\n'
          'Luxury Gym Management');

      final whatsappUrl = Uri.parse('https://wa.me/$phone?text=$message');

      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not launch WhatsApp. Is it installed?',
            isError: true);
      }
    } catch (e) {
      _showSnackBar('Error generating message: $e', isError: true);
    }
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
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AdminAddMemberScreen()),
          );
          if (result == true) {
            _refreshMemberList();
          }
        },
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
            _buildChip(MemberStatus.all, 'All Members',
                Theme.of(context).primaryColor),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        backgroundColor: theme.cardColor,
        selectedColor: color,
        labelStyle: TextStyle(
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold),
        shape: StadiumBorder(
            side: BorderSide(color: isSelected ? color : Colors.transparent)),
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
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _refreshMemberList();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by Name...',
                prefixIcon: const Icon(Icons.search),
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
                value: SortOption.date,
                child: Text('Sort by Fee Due'),
              ),
            ],
            icon: Icon(Icons.sort, color: Theme.of(context).iconTheme.color),
            color: Theme.of(context).cardColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final dueDateString = member['fee_due_date'] != null
        ? 'Expires: ${DateFormat('dd MMM yyyy').format(DateTime.parse(member['fee_due_date']))}'
        : 'No due date set';
    final avatarUrl = member['avatar_url'];

    bool isFeeDue = false;
    if (member['status'] == 'active' && member['fee_due_date'] != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDate = DateTime.parse(member['fee_due_date']);
      if (dueDate.isBefore(today)) {
        isFeeDue = true;
      }
    }

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Icon(Icons.person, color: Colors.grey.shade600)
              : null,
        ),
        title: Text(member['name'] ?? 'No Name'),
        subtitle: Text(dueDateString),
        trailing: isFeeDue
            ? ElevatedButton.icon(
                icon: const Icon(Icons.message, size: 16),
                label: const Text('Notify'),
                onPressed: () => _launchWhatsApp(member),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              )
            : _buildStatusIcon(member['status'], member['fee_due_date']),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  AdminMemberDetailsScreen(memberId: member['user_id']),
            ),
          );
          _refreshMemberList();
        },
      ),
    );
  }

  Widget? _buildStatusIcon(String? status, String? feeDueDate) {
    if (feeDueDate == null) {
      return Icon(Icons.new_releases_rounded,
          color: Theme.of(context).primaryColor);
    }

    if (status == 'active') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDate = DateTime.parse(feeDueDate);

      if (dueDate.isBefore(today)) {
        return const Icon(Icons.warning_amber_rounded, color: Colors.orange);
      }
      return const Icon(Icons.check_circle, color: Colors.green);
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
