// lib/admin_add_member_screen.dart
import 'package:flutter/material.dart';
// The unused import for supabase_flutter has been removed.
import 'main.dart';
import 'theme.dart';

class AdminAddMemberScreen extends StatefulWidget {
  const AdminAddMemberScreen({super.key});

  @override
  State<AdminAddMemberScreen> createState() => _AdminAddMemberScreenState();
}

class _AdminAddMemberScreenState extends State<AdminAddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = '${name.split(' ').first.toLowerCase()}123';

      final response = await supabase.functions.invoke('create-member', body: {
        'name': name,
        'email': email,
      });

      if (response.status != 200) {
        throw response.data['error'] ?? 'An unknown error occurred.';
      }

      if (mounted) {
        _showSnackBar(
            'Member created successfully! Password: $password', primaryColor);
        Navigator.of(context)
            .pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
            'Error creating member: $e', Theme.of(context).colorScheme.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Member')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    (value!.isEmpty || !value.contains('@'))
                        ? 'Please enter a valid email'
                        : null,
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _addMember,
                      child: const Text('Add Member'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}