// lib/admin_message_templates_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';

class AdminMessageTemplatesScreen extends StatefulWidget {
  const AdminMessageTemplatesScreen({super.key});

  @override
  State<AdminMessageTemplatesScreen> createState() =>
      _AdminMessageTemplatesScreenState();
}

class _AdminMessageTemplatesScreenState
    extends State<AdminMessageTemplatesScreen> {
  final _welcomeMessageController = TextEditingController();
  final _reminderMessageController = TextEditingController();
  bool _isLoading = true;

  final String _defaultWelcomeMessage =
      'Salaam {memberName},\n\nWelcome to Luxury Gym! We are excited to have you join our community. Your fitness journey starts now!\n\nBest Regards,\nLuxury Gym Management';
  final String _defaultReminderMessage =
      'Dear {memberName},\nThis is a friendly reminder from Luxury Gym.\nOur records show that your membership expired on *{expiryDate}*. Your last payment was on *{lastPaymentDate}*.\nPlease clear your remaining dues at your earliest convenience.\nThank you,\nLuxury Gym Management';

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase.from('message_templates').select();
      final templates = {
        for (var item in response) item['id']: item['template_text']
      };

      _welcomeMessageController.text =
          templates['welcome_message'] ?? _defaultWelcomeMessage;
      _reminderMessageController.text =
          templates['reminder_message'] ?? _defaultReminderMessage;
    } on PostgrestException catch (e) {
      _welcomeMessageController.text = _defaultWelcomeMessage;
      _reminderMessageController.text = _defaultReminderMessage;
      if (mounted) {
        _showSnackBar(
            'Error: ${e.message}. Please ensure the message_templates table exists.',
            isError: true);
      }
    } catch (e) {
      _welcomeMessageController.text = _defaultWelcomeMessage;
      _reminderMessageController.text = _defaultReminderMessage;
      if (mounted) {
        _showSnackBar('Could not load templates, showing defaults.',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveTemplates() async {
    setState(() => _isLoading = true);
    try {
      await supabase.from('message_templates').upsert([
        {
          'id': 'welcome_message',
          'template_text': _welcomeMessageController.text
        },
        {
          'id': 'reminder_message',
          'template_text': _reminderMessageController.text
        },
      ]);
      if (mounted) {
        _showSnackBar('Templates saved successfully!');
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        _showSnackBar(
            'Error saving templates: ${e.message}. Please ensure the message_templates table exists.',
            isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error saving templates: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
  void dispose() {
    _welcomeMessageController.dispose();
    _reminderMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message Templates')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildTemplateEditor(
                  'Welcome Message',
                  _welcomeMessageController,
                  'Placeholders: {memberName}',
                ),
                const SizedBox(height: 24),
                _buildTemplateEditor(
                  'Fee Reminder Message',
                  _reminderMessageController,
                  'Placeholders: {memberName}, {expiryDate}, {lastPaymentDate}',
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveTemplates,
                  child: const Text('Save Templates'),
                ),
              ],
            ),
    );
  }

  Widget _buildTemplateEditor(
      String title, TextEditingController controller, String placeholders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          placeholders,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Enter your message template here...',
          ),
        ),
      ],
    );
  }
}
