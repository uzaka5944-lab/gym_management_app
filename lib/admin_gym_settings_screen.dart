// lib/admin_gym_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for input formatters
import 'main.dart'; // Assuming supabase client is initialized here

class AdminGymSettingsScreen extends StatefulWidget {
  const AdminGymSettingsScreen({super.key});

  @override
  State<AdminGymSettingsScreen> createState() => _AdminGymSettingsScreenState();
}

class _AdminGymSettingsScreenState extends State<AdminGymSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _timingsSatThuController = TextEditingController();
  final _timingsFriController = TextEditingController();
  final _timingsSunController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _admissionFeeController =
      TextEditingController(); // Controller for Admission Fee
  final _addressController = TextEditingController(); // Controller for Address
  bool _isLoading = true; // To show loading indicator

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load existing settings from Supabase
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase.from('gym_settings').select();
      // Convert list of maps to a single map for easier access
      final settings = {for (var item in response) item['id']: item['value']};

      // Populate controllers, providing defaults if values don't exist
      _timingsSatThuController.text =
          settings['timings_sat_thu'] ?? '9:00 AM - 11:00 PM';
      _timingsFriController.text = settings['timings_fri'] ?? 'Closed';
      _timingsSunController.text =
          settings['timings_sun'] ?? '8:00 AM - 8:00 PM';
      _contactPhoneController.text =
          settings['contact_phone'] ?? '+92 123 4567890';
      _contactEmailController.text =
          settings['contact_email'] ?? 'luxury.gym@example.com';
      _admissionFeeController.text =
          settings['admission_fee'] ?? '500'; // Default to 500
      _addressController.text = settings['gym_address'] ??
          'Basement Iqra Mart Ikrampur Kharki, Pakistan';
    } catch (e) {
      _showSnackBar('Could not load settings: $e', isError: true);
      // Set defaults manually if loading fails
      _admissionFeeController.text = '500';
      _addressController.text = 'Basement Iqra Mart Ikrampur Kharki, Pakistan';
      // Consider setting other defaults too if necessary
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Save updated settings to Supabase
  Future<void> _saveSettings() async {
    // Validate the form before proceeding
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fix the errors in the form.', isError: true);
      return;
    }
    setState(() => _isLoading = true); // Show loading indicator
    try {
      // Use upsert to insert or update settings based on 'id'
      await supabase.from('gym_settings').upsert([
        {
          'id': 'timings_sat_thu',
          'value': _timingsSatThuController.text.trim()
        },
        {'id': 'timings_fri', 'value': _timingsFriController.text.trim()},
        {'id': 'timings_sun', 'value': _timingsSunController.text.trim()},
        {'id': 'contact_phone', 'value': _contactPhoneController.text.trim()},
        {'id': 'contact_email', 'value': _contactEmailController.text.trim()},
        {
          'id': 'admission_fee',
          'value': _admissionFeeController.text.trim()
        }, // Save Admission Fee
        {
          'id': 'gym_address',
          'value': _addressController.text.trim()
        }, // Save Address
      ]);
      _showSnackBar('Settings saved successfully!', isSuccess: true);
    } catch (e) {
      _showSnackBar('Error saving settings: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Hide loading indicator
      }
    }
  }

  // Helper to show Snackbars
  void _showSnackBar(String message,
      {bool isError = false, bool isSuccess = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? Colors.green
            : (isError ? Theme.of(context).colorScheme.error : Colors.grey),
      ));
    }
  }

  // Dispose controllers when the widget is removed
  @override
  void dispose() {
    _timingsSatThuController.dispose();
    _timingsFriController.dispose();
    _timingsSunController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _admissionFeeController.dispose(); // Dispose Admission Fee Controller
    _addressController.dispose(); // Dispose Address Controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gym Settings')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Show loading indicator
          : Form(
              // Wrap content in a Form
              key: _formKey, // Assign the form key
              child: ListView(
                // Use ListView for scrolling
                padding: const EdgeInsets.all(16.0),
                children: [
                  // --- Timings Section ---
                  Text('Gym Timings',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _timingsSatThuController,
                    decoration:
                        const InputDecoration(labelText: 'Saturday - Thursday'),
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Timings cannot be empty' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _timingsFriController,
                    decoration: const InputDecoration(labelText: 'Friday'),
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Timings cannot be empty' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _timingsSunController,
                    decoration: const InputDecoration(labelText: 'Sunday'),
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Timings cannot be empty' : null,
                  ),
                  const Divider(height: 40),

                  // --- Contact & Location Section ---
                  Text('Contact & Location',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactPhoneController,
                    decoration: const InputDecoration(
                        labelText: 'Contact Phone Number'),
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Phone cannot be empty' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _contactEmailController,
                      decoration: const InputDecoration(
                          labelText: 'Contact Email Address'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Email cannot be empty';
                        // Basic email format check
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim()))
                          return 'Enter a valid email';
                        return null;
                      }),
                  const SizedBox(height: 16),
                  TextFormField(
                    // Address Field
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Gym Address'),
                    keyboardType: TextInputType.streetAddress,
                    maxLines: 2, // Allow address to wrap
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Address cannot be empty' : null,
                  ),
                  const Divider(height: 40),

                  // --- Fees Section ---
                  Text('Fees',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextFormField(
                    // Admission Fee Field
                    controller: _admissionFeeController,
                    decoration: const InputDecoration(
                        labelText: 'Standard Admission Fee (PKR)',
                        hintText: 'e.g., 500'),
                    keyboardType: TextInputType.number, // Use number keyboard
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ], // Allow only digits
                    validator: (v) {
                      // Validation for the fee
                      if (v == null || v.trim().isEmpty)
                        return 'Fee cannot be empty';
                      if (double.tryParse(v.trim()) == null)
                        return 'Enter a valid number';
                      if (double.parse(v.trim()) < 0)
                        return 'Fee cannot be negative';
                      return null; // Return null if valid
                    },
                  ),
                  const SizedBox(height: 32),

                  // --- Save Button ---
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _saveSettings, // Disable while loading
                    style: ElevatedButton.styleFrom(
                        minimumSize:
                            const Size(double.infinity, 50) // Make button wider
                        ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white)) // Show loading inside button
                        : const Text('Save Settings'),
                  ),
                  const SizedBox(height: 20), // Add some padding at the bottom
                ],
              ),
            ),
    );
  }
}
