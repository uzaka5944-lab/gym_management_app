import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'member_database_helper.dart';

class Exercise {
  final String id;
  final String name;
  final String target;
  final String bodyPart;
  final String gifUrl;

  Exercise({
    required this.id,
    required this.name,
    required this.target,
    required this.bodyPart,
    required this.gifUrl,
  });

  // --- THIS IS THE FIX ---
  // This constructor is now safer and handles null values from the API.
  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'No Name',
      target: json['target'] as String? ?? 'N/A',
      bodyPart: json['bodyPart'] as String? ?? 'N/A',
      gifUrl: json['gifUrl'] as String? ?? '',
    );
  }
}

class MemberWorkoutScreen extends StatefulWidget {
  const MemberWorkoutScreen({super.key});

  @override
  State<MemberWorkoutScreen> createState() => _MemberWorkoutScreenState();
}

class _MemberWorkoutScreenState extends State<MemberWorkoutScreen> {
  List<Exercise> _exercises = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dbHelper = MemberDatabaseHelper.instance;
      final cachedExercises = await dbHelper.getExercises();

      if (cachedExercises.isNotEmpty) {
        setState(() {
          _exercises = cachedExercises;
          _isLoading = false;
        });
      } else {
        await _fetchAndCacheExercises();
      }
    } catch (e) {
      setState(() {
        _error = "Failed to load exercises. Please try syncing.";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAndCacheExercises() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://exercisedb.p.rapidapi.com/exercises'),
        headers: {
          'X-RapidAPI-Key':
              "0b6d61003amsh98527cb3bfb1cb3p16a096jsn299967b3ec8e",
          'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final exercisesFromApi =
            data.map((json) => Exercise.fromJson(json)).toList();

        await MemberDatabaseHelper.instance.cacheExercises(exercisesFromApi);

        setState(() {
          _exercises = exercisesFromApi;
          _isLoading = false;
        });
      } else {
        throw 'Failed to load exercises. Status code: ${response.statusCode}';
      }
    } catch (e) {
      setState(() {
        _error = 'Error syncing exercises: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchAndCacheExercises,
        tooltip: 'Sync with Server',
        child: const Icon(Icons.sync),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchAndCacheExercises,
                child: const Text('Try Syncing Again'),
              ),
            ],
          ),
        ),
      );
    }
    if (_exercises.isEmpty) {
      return const Center(child: Text('No exercises found.'));
    }

    return ListView.builder(
      itemCount: _exercises.length,
      itemBuilder: (context, index) {
        final exercise = _exercises[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Image.network(
              exercise.gifUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  width: 60,
                  height: 60,
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
            ),
            title: Text(
                exercise.name
                    .split(' ')
                    .map((word) => word[0].toUpperCase() + word.substring(1))
                    .join(' '),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text('Target: ${exercise.target}'),
          ),
        );
      },
    );
  }
}
