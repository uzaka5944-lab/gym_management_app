// lib/admin_workout_management_screen.dart
import 'package:flutter/material.dart';
import 'main.dart'; // Import main to get supabase client
import 'theme.dart'; // Import theme for styling
import 'admin_add_exercise_screen.dart'; // Import our new screen

class AdminWorkoutManagementScreen extends StatefulWidget {
  const AdminWorkoutManagementScreen({super.key});

  @override
  State<AdminWorkoutManagementScreen> createState() =>
      _AdminWorkoutManagementScreenState();
}

class _AdminWorkoutManagementScreenState
    extends State<AdminWorkoutManagementScreen> {
  List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  Future<void> _fetchExercises() async {
    setState(() { _isLoading = true; });
    try {
      final response = await supabase
          .from('exercises')
          .select()
          .order('name', ascending: true);
      setState(() {
        _exercises = response;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error fetching exercises: $e'),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to the add screen and refresh if an exercise was added
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AdminAddExerciseScreen()),
          );
          if (result == true) {
            _fetchExercises();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exercises.isEmpty
              ? const Center(
                  child: Text(
                    'No exercises found.\nTap the + button to add one!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchExercises,
                  child: ListView.builder(
                    itemCount: _exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = _exercises[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(exercise['name'] ?? 'No Name'),
                          subtitle: Text(
                            exercise['description'] ?? 'No Description',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading:
                              const Icon(Icons.fitness_center, color: primaryColor),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}