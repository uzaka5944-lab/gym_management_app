// lib/admin_add_exercise_screen.dart
import 'package:flutter/material.dart'; // This line is now corrected
import 'main.dart';
import 'theme.dart';

class AdminAddExerciseScreen extends StatefulWidget {
  const AdminAddExerciseScreen({super.key});

  @override
  State<AdminAddExerciseScreen> createState() => _AdminAddExerciseScreenState();
}

class _AdminAddExerciseScreenState extends State<AdminAddExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addExercise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isLoading = true; });

    try {
      await supabase.from('exercises').insert({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise added successfully!'), backgroundColor: primaryColor),
        );
        Navigator.of(context).pop(true); // Pop and return true to refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding exercise: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Exercise')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Exercise Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 5,
                validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _addExercise,
                      child: const Text('Save Exercise'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}