// lib/admin_dashboard_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // This import is needed
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

  @override
  void initState() {
    super.initState();
    _memberCountFuture = _fetchMemberCount();
  }

  // --- THIS IS THE CORRECTED FUNCTION ---
  Future<int> _fetchMemberCount() async {
    try {
      // The modern way to get a count is a single aggregate function call.
      final count = await supabase
          .from('profiles')
          .count(CountOption.exact) // This is the new, correct syntax
          .eq('role', 'member');

      return count;
    } catch (e) {
      debugPrint("Error fetching member count: $e");
      return 0;
    }
  }
  // ------------------------------------

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Theme.of(context).primaryColor,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Welcome, Admin!',
                style: Theme.of(context)
                    .textTheme
                    .displayMedium
                    ?.copyWith(color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Key Statistics',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              FutureBuilder<int>(
                future: _memberCountFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final count = snapshot.data ?? 0;
                  return StatCard(
                    title: 'Active Members',
                    value: count.toString(),
                    icon: Icons.people_alt_rounded,
                  );
                },
              ),
              const StatCard(
                title: 'Payments Due',
                value: '0',
                icon: Icons.payment_rounded,
                iconColor: Colors.orangeAccent,
              ),
              const StatCard(
                title: 'Workouts Created',
                value: '0',
                icon: Icons.fitness_center_rounded,
                iconColor: Colors.lightBlueAccent,
              ),
              const StatCard(
                title: 'Revenue (Month)',
                value: '\$0',
                icon: Icons.attach_money_rounded,
                iconColor: Colors.greenAccent,
              ),
            ],
          )
        ],
      ),
    );
  }
}