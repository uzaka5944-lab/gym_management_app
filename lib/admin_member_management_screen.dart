// lib/admin_member_management_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';
import 'admin_add_member_screen.dart';
import 'admin_member_details_screen.dart';
import 'report_service.dart';

enum MemberStatus { all, paid, feeDue, removed }

enum SortOption { name, date, serialNumber }

class AdminMemberManagementScreen extends StatefulWidget {
  // Parameter to set the initial tab
  final MemberStatus initialStatus;

  const AdminMemberManagementScreen({
    super.key,
    this.initialStatus = MemberStatus.all,
  });

  @override
  State<AdminMemberManagementScreen> createState() =>
      _AdminMemberManagementScreenState();
}

class _AdminMemberManagementScreenState
    extends State<AdminMemberManagementScreen> {
  late MemberStatus _selectedStatus;
  SortOption _sortOption = SortOption.name; // Default sort
  String _searchQuery = '';
  late Future<List<Map<String, dynamic>>> _membersFuture;
  final ReportService _reportService = ReportService();
  Map<String, String> _messageTemplates = {};

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _loadData();
  }

  void _loadData() {
    setState(() {
      _membersFuture = _fetchMembers();
      _loadMessageTemplates();
    });
  }

  Future<void> _loadMessageTemplates() async {
    try {
      final response = await supabase.from('message_templates').select();
      final templates = {
        for (var item in response)
          item['id'] as String: item['template_text'] as String
      };
      if (mounted) {
        setState(() {
          _messageTemplates = templates;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messageTemplates = {
            'welcome_message':
                'Salaam {memberName},\n\nWelcome to Luxury Gym! We are excited to have you join our community. Your fitness journey starts now!\n\nBest Regards,\nLuxury Gym Management',
            'reminder_message':
                'Dear {memberName},\nThis is a friendly reminder from Luxury Gym.\nOur records show that your membership expired on *{expiryDate}*. Your last payment was on *{lastPaymentDate}*.\nPlease clear your remaining dues at your earliest convenience.\nThank you,\nLuxury Gym Management',
          };
        });
      }
      _showSnackBar('Could not load message templates, using defaults.',
          isError: true);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMembers() async {
    try {
      dynamic query = supabase.from('members').select(
          'user_id, name, phone, fee_due_date, status, avatar_url, serial_number, email');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day).toIso8601String();

      switch (_selectedStatus) {
        case MemberStatus.all:
          // UPDATED: Exclude 'removed' members from the 'All' tab
          query = query.neq('status', 'removed');
          break;
        case MemberStatus.paid:
          query = query.eq('status', 'active').gte('fee_due_date', today);
          break;
        case MemberStatus.feeDue:
          query = query.eq('status', 'active').lt('fee_due_date', today);
          break;
        case MemberStatus.removed:
          // Only show removed members here
          query = query.eq('status', 'removed');
          break;
      }

      if (_searchQuery.isNotEmpty) {
        query = query.or(
          'name.ilike.%$_searchQuery%,serial_number.ilike.%$_searchQuery%',
        );
      }

      switch (_sortOption) {
        case SortOption.name:
          query = query.order('name', ascending: true);
          break;
        case SortOption.date:
          query =
              query.order('fee_due_date', ascending: true, nullsFirst: true);
          break;
        case SortOption.serialNumber:
          query =
              query.order('serial_number', ascending: true, nullsFirst: true);
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

  Future<void> _confirmPermanentDelete(Map<String, dynamic> member) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Confirm Deletion'),
        content: Text(
            'Are you sure you want to permanently delete ${member['name']}? This will remove them from the authentication system and cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Permanently'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _permanentlyDeleteMember(member['user_id']);
    }
  }

  Future<void> _permanentlyDeleteMember(String userId) async {
    try {
      final response = await supabase.functions.invoke(
        'delete-user',
        body: {'user_id': userId},
      );

      if (response.status != 200) {
        throw response.data['error'] ?? 'An unknown error occurred.';
      }

      _showSnackBar('Member permanently deleted successfully.');
      _refreshMemberList();
    } catch (e) {
      _showSnackBar('Error deleting member: $e', isError: true);
    }
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

      String messageTemplate = _messageTemplates['reminder_message'] ??
          'Dear {memberName},\nThis is a friendly reminder from Luxury Gym.\nOur records show that your membership expired on *{expiryDate}*. Your last payment was on *{lastPaymentDate}*.\nPlease clear your remaining dues at your earliest convenience.\nThank you,\nLuxury Gym Management';

      final message = messageTemplate
          .replaceAll('{memberName}', name)
          .replaceAll('{expiryDate}', expiryDate)
          .replaceAll('{lastPaymentDate}', lastPaymentDate);

      final whatsappUrl = Uri.parse(
          'https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

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

  Future<void> _launchWelcomeWhatsApp(Map<String, dynamic> member) async {
    final phone = member['phone'] as String?;
    final name = member['name'] as String? ?? 'Member';

    if (phone == null || phone.isEmpty) {
      _showSnackBar('No phone number available for $name', isError: true);
      return;
    }

    String messageTemplate = _messageTemplates['welcome_message'] ??
        'Salaam {memberName},\n\nWelcome to Luxury Gym! We are excited to have you join our community. Your fitness journey starts now!\n\nBest Regards,\nLuxury Gym Management';

    final message = messageTemplate.replaceAll('{memberName}', name);

    final whatsappUrl =
        Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Could not launch WhatsApp. Is it installed?',
          isError: true);
    }
  }

  Future<void> _generateAndShareWelcomePdf(Map<String, dynamic> member) async {
    try {
      _showSnackBar('Generating Welcome PDF...');
      final pdfBytes = await _reportService.generateWelcomePdf(member);
      await _reportService.shareReport(pdfBytes, 'Welcome_${member['name']}');
    } catch (e) {
      _showSnackBar("Error generating welcome PDF: $e", isError: true);
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
                  onRefresh: () async => _loadData(),
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
                hintText: 'Search by Name or Serial...',
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
              const PopupMenuItem<SortOption>(
                value: SortOption.serialNumber,
                child: Text('Sort by Serial #'),
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
    final serialNumber =
        member['serial_number'] != null && member['serial_number'].isNotEmpty
            ? 'Serial: ${member['serial_number']}'
            : 'No Serial #';

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

    Color cardColor;
    if (member['status'] == 'removed') {
      cardColor = Colors.red.shade100;
    } else if (isFeeDue) {
      cardColor = Colors.orange.shade200;
    } else {
      cardColor = Colors.white;
    }

    return Card(
      color: cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Icon(Icons.person, color: Colors.grey.shade600)
              : null,
        ),
        title: Text(
          member['name'] ?? 'No Name',
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$serialNumber | $dueDateString',
          style: const TextStyle(color: Colors.black54),
        ),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  AdminMemberDetailsScreen(memberId: member['user_id']),
            ),
          );
          _refreshMemberList();
        },
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'welcome_msg') {
              _launchWelcomeWhatsApp(member);
            } else if (value == 'welcome_pdf') {
              _generateAndShareWelcomePdf(member);
            } else if (value == 'reminder') {
              _launchWhatsApp(member);
            } else if (value == 'delete') {
              _confirmPermanentDelete(member);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'welcome_msg',
              child: ListTile(
                leading: Icon(Icons.send),
                title: Text('Send Welcome Message'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'welcome_pdf',
              child: ListTile(
                leading: Icon(Icons.picture_as_pdf),
                title: Text('Generate Welcome PDF'),
              ),
            ),
            if (isFeeDue)
              const PopupMenuItem<String>(
                value: 'reminder',
                child: ListTile(
                  leading: Icon(Icons.message, color: Colors.orange),
                  title: Text('Send Fee Reminder'),
                ),
              ),
            if (member['status'] == 'removed')
              const PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.redAccent),
                  title: Text('Delete Permanently'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
 
