// lib/admin_dashboard_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../main.dart';
import '../widgets/stat_card.dart';

class AdminDashboardSummaryScreen extends StatefulWidget {
  const AdminDashboardSummaryScreen({super.key});

  @override
  State<AdminDashboardSummaryScreen> createState() =>
      _AdminDashboardSummaryScreenState();
}

class _AdminDashboardSummaryScreenState
    extends State<AdminDashboardSummaryScreen> {
  late Future<int> _memberCountFuture;
  late Future<List<Map<String, dynamic>>> _expiringMembersFuture;

  @override
  void initState() {
    super.initState();
    _memberCountFuture = _fetchMemberCount();
    _expiringMembersFuture = _fetchExpiringMembers();
  }

  Future<int> _fetchMemberCount() async {
    try {
      final count = await supabase
          .from('profiles')
          .count(CountOption.exact)
          .eq('role', 'member');
      return count;
    } catch (e) {
      debugPrint("Error fetching member count: $e");
      return 0;
    }
  }

  // New function to fetch members with expiring memberships
  Future<List<Map<String, dynamic>>> _fetchExpiringMembers() async {
    try {
      final today = DateTime.now();
      final inAWeek = today.add(const Duration(days: 7));
      
      final response = await supabase
          .from('members')
          .select('name, end_date')
          .gte('end_date', today.toIso8601String()) // Greater than or equal to today
          .lte('end_date', inAWeek.toIso8601String()) // Less than or equal to a week from now
          .order('end_date', ascending: true);
          
      return response;
    } catch (e) {
      debugPrint("Error fetching expiring members: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... (Welcome Card and Key Statistics GridView are the same) ...
            Card(
              color: Theme.of(context).primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Welcome, Admin!', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.black)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Key Statistics', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                FutureBuilder<int>(
                  future: _memberCountFuture,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return StatCard(
                      title: 'Active Members',
                      value: count.toString(),
                      icon: Icons.people_alt_rounded,
                    );
                  },
                ),
                const StatCard(title: 'Payments Due', value: '0', icon: Icons.payment_rounded, iconColor: Colors.orangeAccent),
                const StatCard(title: 'Workouts Created', value: '0', icon: Icons.fitness_center_rounded, iconColor: Colors.lightBlueAccent),
                const StatCard(title: 'Revenue (Month)', value: '\$0', icon: Icons.attach_money_rounded, iconColor: Colors.greenAccent),
              ],
            ),
            
            // --- NEW SECTION FOR EXPIRING MEMBERSHIPS ---
            const SizedBox(height: 24),
            Text('Memberships Expiring Soon', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _expiringMembersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No memberships expiring in the next 7 days.'),
                    ),
                  );
                }

                final expiringMembers = snapshot.data!;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expiringMembers.length,
                  itemBuilder: (context, index) {
                    final member = expiringMembers[index];
                    final endDate = DateTime.parse(member['end_date']);
                    final daysLeft = endDate.difference(DateTime.now()).inDays;
                    
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(member['name'] ?? 'N/A'),
                        trailing: Text(
                          'Expires in $daysLeft days',
                          style: TextStyle(
                            color: daysLeft < 3 ? Colors.redAccent : Colors.orangeAccent,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        subtitle: Text('On ${DateFormat.yMMMd().format(endDate)}'),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}