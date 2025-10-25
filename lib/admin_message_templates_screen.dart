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
  // ADDED: Controller for the new template
  final _paymentConfirmationMessageController = TextEditingController();
  bool _isLoading = true;

  // Default messages (including the new one)
  final String _defaultWelcomeMessage =
      'Salaam {memberName},\n\nWelcome to Luxury Gym! We are excited to have you join our community. Your fitness journey starts now!\n\nBest Regards,\nLuxury Gym Management';
  final String _defaultReminderMessage =
      'Dear {memberName},\nThis is a friendly reminder from Luxury Gym.\nOur records show that your membership expired on *{expiryDate}*. Your last payment was on *{lastPaymentDate}*.\nPlease clear your remaining dues at your earliest convenience.\nThank you,\nLuxury Gym Management';
  // ADDED: Default for the new template
  final String _defaultPaymentConfirmationMessage =
      'Dear {memberName},\n\nThis message confirms that your payment of PKR {paymentAmount} on {paymentDate} has been successfully received by Luxury Gym.\n\nThank you for your payment. a report will be shared with you shortly containing all the payment information.\n\nBest Regards,\nLuxury Gym Management';

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
      // ADDED: Load the new template
      _paymentConfirmationMessageController.text =
          templates['payment_confirmation'] ??
              _defaultPaymentConfirmationMessage;
    } on PostgrestException catch (e) {
      _welcomeMessageController.text = _defaultWelcomeMessage;
      _reminderMessageController.text = _defaultReminderMessage;
      // ADDED: Set default on error
      _paymentConfirmationMessageController.text =
          _defaultPaymentConfirmationMessage;
      if (mounted) {
        _showSnackBar(
            'Error: ${e.message}. Please ensure the message_templates table exists.',
            isError: true);
      }
    } catch (e) {
      _welcomeMessageController.text = _defaultWelcomeMessage;
      _reminderMessageController.text = _defaultReminderMessage;
      // ADDED: Set default on error
      _paymentConfirmationMessageController.text =
          _defaultPaymentConfirmationMessage;
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
        // ADDED: Upsert the new template
        {
          'id': 'payment_confirmation',
          'template_text': _paymentConfirmationMessageController.text
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
    // ADDED: Dispose the new controller
    _paymentConfirmationMessageController.dispose();
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
                // ADDED: Editor for the new template
                const SizedBox(height: 24),
                _buildTemplateEditor(
                  'Payment Confirmation Message',
                  _paymentConfirmationMessageController,
                  'Placeholders: {memberName}, {paymentAmount}, {paymentDate}',
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
} //
