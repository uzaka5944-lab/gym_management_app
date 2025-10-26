// lib/admin_member_details_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Ensure this is imported
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'main.dart'; // Assuming supabase client is initialized here
import 'admin_edit_member_screen.dart';
import 'report_service.dart';

class AdminMemberDetailsScreen extends StatefulWidget {
  final String memberId;

  const AdminMemberDetailsScreen({super.key, required this.memberId});

  @override
  State<AdminMemberDetailsScreen> createState() =>
      _AdminMemberDetailsScreenState();
}

class _AdminMemberDetailsScreenState extends State<AdminMemberDetailsScreen> {
  // ValueNotifier to hold member data and trigger UI updates reactively
  final ValueNotifier<Map<String, dynamic>?> _memberNotifier =
      ValueNotifier(null);
  // Instance of the service used for generating PDF reports
  final ReportService _reportService = ReportService();
  // Map to store loaded message templates (welcome, reminder, payment confirmation)
  Map<String, String> _messageTemplates = {};
  // Loading state indicator, primarily for async operations like payment saving
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load initial member data and message templates when the screen is first built
    _loadData();
    _loadMessageTemplates();
  }

  /// Fetches message templates (welcome, reminder, payment confirmation)
  /// from the Supabase 'message_templates' table.
  /// Uses default values if fetching fails or the table doesn't exist.
  Future<void> _loadMessageTemplates() async {
    try {
      // Fetch all rows from the message_templates table
      final response = await supabase.from('message_templates').select();
      // Convert the list of maps response into a single map (id -> template_text)
      final templates = {
        for (var item in response)
          item['id'] as String: item['template_text'] as String
      };
      if (mounted) {
        // Update the state with the loaded templates
        setState(() {
          _messageTemplates = templates;
        });
      }
    } catch (e) {
      // Handle errors during template fetching
      if (mounted) {
        _showSnackBar('Could not load message templates, using defaults.',
            isError: true);
        // Set hardcoded default templates as a fallback
        setState(() {
          _messageTemplates = {
            'payment_confirmation':
                'Dear {memberName},\n\nThis message confirms that your payment of PKR {paymentAmount} on {paymentDate} has been successfully received by Luxury Gym.\n\nThank you for your payment. a report will be shared with you shortly containing all the payment information.\n\nBest Regards,\nLuxury Gym Management',
            'welcome_message':
                'Salaam {memberName},\n\nWelcome to Luxury Gym! We are excited to have you join our community. Your fitness journey starts now!\n\nBest Regards,\nLuxury Gym Management',
            'reminder_message':
                'Dear {memberName},\nThis is a friendly reminder from Luxury Gym.\nOur records show that your membership expired on *{expiryDate}*. Your last payment was on *{lastPaymentDate}*.\nPlease clear your remaining dues at your earliest convenience.\nThank you,\nLuxury Gym Management',
          };
        });
      }
    }
  }

  /// Fetches the details (including address and serial number) for the
  /// current member (identified by widget.memberId) from the Supabase 'members' table.
  /// Updates the _memberNotifier to refresh the UI.
  Future<void> _loadData() async {
    // Optionally indicate loading state for the whole screen
    // setState(() => _isLoading = true);
    try {
      // Fetch a single row matching the member's user_id
      final data = await supabase
          .from('members')
          .select('*, address, serial_number') // Select all columns + extras
          .eq('user_id', widget.memberId)
          .single(); // Throws error if 0 or >1 rows found
      if (mounted) {
        // Update the ValueNotifier, which triggers the ValueListenableBuilder in build()
        _memberNotifier.value = data;
      }
    } catch (e) {
      _showSnackBar("Error loading member data: $e", isError: true);
      if (mounted) {
        // Clear previous data on error to prevent showing stale information
        _memberNotifier.value = null;
      }
    } finally {
      // if (mounted) setState(() => _isLoading = false); // Hide screen loader if used
    }
  }

  /// Allows the admin to pick an image from the gallery and uploads it
  /// to Supabase Storage as the member's avatar. Updates the member's record.
  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    // Pick an image from the gallery, compressing it slightly
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Compress image to 50% quality
    );

    // If the user cancelled the picker, do nothing
    if (imageFile == null) return;

    // Show a loading dialog while uploading
    showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing by tapping outside
        builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      // Read the image file as bytes
      final fileBytes = await imageFile.readAsBytes();
      // Extract file extension (e.g., 'png', 'jpg')
      final fileExt = imageFile.path.split('.').last;
      // Create a unique file name using timestamp
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      // Define the storage path: {member_id}/{timestamp}.{ext}
      final filePath = '${widget.memberId}/$fileName';

      // Upload the image bytes to the 'avatars' bucket in Supabase Storage
      await supabase.storage.from('avatars').uploadBinary(
            filePath,
            fileBytes,
          );

      // Get the public URL for the newly uploaded file
      final imageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);

      // Update the 'avatar_url' column in the 'members' table for this user
      await supabase
          .from('members')
          .update({'avatar_url': imageUrl}).eq('user_id', widget.memberId);

      if (mounted) {
        Navigator.of(context).pop(); // Close the loading dialog
        _showSnackBar('Avatar updated successfully!');
        _loadData(); // Reload member data to display the new avatar
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog on error
        _showSnackBar('Error uploading avatar: $e', isError: true);
      }
    }
  }

  /// Navigates to the AdminEditMemberScreen, passing the current member's data.
  /// Refreshes the details screen if changes were saved on the edit screen.
  void _navigateToEditScreen(Map<String, dynamic> currentMemberData) async {
    // Navigate and wait for a boolean result (true if saved, false/null otherwise)
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            AdminEditMemberScreen(memberData: currentMemberData),
      ),
    );
    // If the result indicates changes were saved, reload the data on this screen
    if (result == true) {
      _loadData();
    }
  }

  /// Generates the member's financial report PDF (including payment history)
  /// and triggers the native share dialog.
  Future<void> _generateAndShareReport() async {
    final memberData = _memberNotifier.value;
    // Ensure member data is loaded before proceeding
    if (memberData == null) {
      _showSnackBar("Member data not loaded yet.", isError: true);
      return;
    }

    // Show a loading indicator during PDF generation
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      // Fetch the member's payment history, ordered by date descending
      final paymentHistory = await supabase
          .from('payments')
          .select()
          .eq('member_id', widget.memberId)
          .order('payment_date', ascending: false);

      // Call the ReportService to generate the PDF bytes
      final pdfBytes =
          await _reportService.generateMemberReport(memberData, paymentHistory);

      if (mounted) Navigator.of(context).pop(); // Close the loading dialog

      // Call the ReportService to share the generated PDF
      await _reportService.shareReport(pdfBytes, memberData['name']);
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Close loading dialog on error
      _showSnackBar("Error generating report: $e", isError: true);
    }
  }

  /// Shows an AlertDialog to collect details for a new payment record.
  /// On saving, inserts the payment, updates the member's due date via RPC,
  /// and then shows the post-payment actions dialog.
  void _showRenewFeeDialog(Map<String, dynamic> currentMemberData) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    // State variables within the dialog's scope
    String paymentMethod = 'cash';
    String feeType = 'monthly_fee';
    DateTime paymentDate = DateTime.now();
    bool isDialogLoading =
        false; // Loading state specific to the dialog's save action

    showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder to manage state changes within the dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: const Text('Add New Payment'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Amount Input
                      TextFormField(
                        controller: amountController,
                        decoration:
                            const InputDecoration(labelText: 'Amount (PKR)'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
                            return 'Enter a valid positive amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Payment Type Dropdown
                      DropdownButtonFormField<String>(
                        value: feeType,
                        dropdownColor: Theme.of(context).cardColor,
                        decoration:
                            const InputDecoration(labelText: 'Payment Type'),
                        items: const [
                          DropdownMenuItem(
                              value: 'monthly_fee', child: Text('Monthly Fee')),
                          DropdownMenuItem(
                              value: 'new_admission',
                              child: Text('New Admission')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            // Use setDialogState to update the dialog's UI
                            setDialogState(() => feeType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Payment Method Dropdown
                      DropdownButtonFormField<String>(
                        value: paymentMethod,
                        dropdownColor: Theme.of(context).cardColor,
                        decoration:
                            const InputDecoration(labelText: 'Payment Method'),
                        items: const [
                          DropdownMenuItem(value: 'cash', child: Text('Cash')),
                          DropdownMenuItem(
                              value: 'online', child: Text('Online')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => paymentMethod = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Payment Date Picker Tile
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Payment Date'),
                        subtitle:
                            Text(DateFormat('dd MMM yyyy').format(paymentDate)),
                        trailing: Icon(Icons.calendar_today,
                            color: Theme.of(context).primaryColor),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: paymentDate,
                            firstDate: DateTime(2020),
                            lastDate:
                                DateTime.now().add(const Duration(days: 1)),
                          );
                          if (pickedDate != null) {
                            setDialogState(() => paymentDate = pickedDate);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Optional Notes Input
                      TextFormField(
                          controller: notesController,
                          decoration: const InputDecoration(
                              labelText: 'Notes (Optional)'))
                    ],
                  ),
                ),
              ),
              actions: [
                // Cancel Button
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel')),
                // Save Button
                ElevatedButton(
                  // Disable button if dialog is currently saving
                  onPressed: isDialogLoading
                      ? null
                      : () async {
                          // Validate the form first
                          if (!formKey.currentState!.validate()) return;

                          // Capture necessary data before potential async gaps or dialog closing
                          final memberData = _memberNotifier.value;
                          final paymentAmount =
                              double.parse(amountController.text);
                          final recordedPaymentDate = paymentDate;

                          // Set loading state for the dialog
                          setDialogState(() => isDialogLoading = true);

                          try {
                            // Insert the new payment record
                            await supabase.from('payments').insert({
                              'member_id': widget.memberId,
                              'amount': paymentAmount,
                              'payment_type': feeType,
                              'payment_method': paymentMethod,
                              'notes': notesController.text.trim(),
                              'payment_date':
                                  recordedPaymentDate.toIso8601String(),
                            });

                            // Call the database function to update fee_due_date
                            await supabase.rpc(
                              'update_member_fee_due_date',
                              params: {'member_uuid': widget.memberId},
                            );

                            // If successful, close the payment dialog
                            if (mounted) Navigator.of(context).pop();
                            _showSnackBar('Payment recorded successfully!');
                            _loadData(); // Refresh the main screen's data

                            // Show the next actions dialog
                            if (memberData != null) {
                              _showPostPaymentActionsDialog(memberData,
                                  paymentAmount, recordedPaymentDate);
                            }
                          } catch (e) {
                            // Show error, but keep the dialog open for correction/retry
                            _showSnackBar('Error recording payment: $e',
                                isError: true);
                          } finally {
                            // Ensure loading state is reset, even on error
                            if (mounted)
                              setDialogState(() => isDialogLoading = false);
                          }
                        },
                  // Display loading indicator or text based on state
                  child: isDialogLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Shows a dialog after a payment is successfully saved, offering
  /// options to send a confirmation message or share the report PDF.
  void _showPostPaymentActionsDialog(
      Map<String, dynamic> member, double paymentAmount, DateTime paymentDate) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Payment Saved'),
          content: const Text('What would you like to do next?'),
          actions: <Widget>[
            // Send Confirmation Button
            TextButton.icon(
                icon: const Icon(Icons.send_outlined, color: Colors.green),
                label: const Text('Send Confirmation'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close this dialog
                  // Call the WhatsApp function with payment details
                  _launchPaymentConfirmationWhatsApp(
                      member, paymentAmount, paymentDate);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.green)),
            // Share Report Button
            TextButton.icon(
                icon: Icon(Icons.picture_as_pdf_outlined,
                    color: Theme.of(context).primaryColor),
                label: const Text('Share Report PDF'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close this dialog
                  _generateAndShareReport(); // Trigger the report generation/sharing
                },
                style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor)),
            // Close Button
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Simply close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  /// Formats the payment confirmation message template with actual data
  /// and attempts to launch WhatsApp to send it to the member's phone number.
  Future<void> _launchPaymentConfirmationWhatsApp(Map<String, dynamic> member,
      double paymentAmount, DateTime paymentDate) async {
    final phone = member['phone'] as String?;
    final name = member['name'] as String? ?? 'Member';

    // Check if phone number is available
    if (phone == null || phone.isEmpty) {
      _showSnackBar('No phone number available for $name to send confirmation.',
          isError: true);
      return;
    }

    // Retrieve the template, falling back to a default if not found
    String messageTemplate = _messageTemplates['payment_confirmation'] ??
        'Dear {memberName},\n\nThis message confirms that your payment of PKR {paymentAmount} on {paymentDate} has been successfully received by Luxury Gym.\n\nThank you for your payment. a report will be shared with you shortly containing all the payment information.\n\nBest Regards,\nLuxury Gym Management';

    // Format the amount and date nicely
    final formattedAmount = NumberFormat('#,##0').format(paymentAmount);
    final formattedDate = DateFormat('dd MMM yyyy').format(paymentDate);

    // Replace placeholders in the template string
    final message = messageTemplate
        .replaceAll('{memberName}', name)
        .replaceAll('{paymentAmount}', formattedAmount)
        .replaceAll('{paymentDate}', formattedDate);

    // Encode the message for the URL and create the WhatsApp URL
    final whatsappUrl =
        Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

    // Try launching the URL externally
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        // Use external application mode to open the WhatsApp app directly
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not launch WhatsApp. Is it installed?',
            isError: true);
      }
    } catch (e) {
      _showSnackBar('Error launching WhatsApp: $e', isError: true);
    }
  }

  /// Utility function to display a SnackBar message.
  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      // Check if the widget is still in the tree
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Colors.green, // Use error color or green
        duration:
            Duration(seconds: isError ? 4 : 3), // Show errors slightly longer
      ));
    }
  }

  @override
  void dispose() {
    // Clean up the ValueNotifier when the widget is disposed
    _memberNotifier.dispose();
    super.dispose();
  }

  /// Builds the main Scaffold and UI structure for the screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Details'),
        elevation: 0, // Remove shadow for a flatter look
        actions: [
          // PDF button in AppBar, shown conditionally using ValueListenableBuilder
          ValueListenableBuilder<Map<String, dynamic>?>(
              valueListenable: _memberNotifier,
              builder: (context, member, child) {
                // Only render the button if member data is not null
                return member != null
                    ? IconButton(
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        tooltip:
                            'Share Financial Report PDF', // Accessibility hint
                        onPressed: _generateAndShareReport, // Action on press
                      )
                    : const SizedBox
                        .shrink(); // Render nothing if member data is null
              }),
        ],
      ),
      // Use ValueListenableBuilder to rebuild parts of the UI when _memberNotifier changes
      body: ValueListenableBuilder<Map<String, dynamic>?>(
        valueListenable: _memberNotifier,
        builder: (context, member, child) {
          // If member data is null (either loading initially or failed to load)
          if (member == null) {
            // Show a loading indicator or error message
            return FutureBuilder(
              future:
                  _loadData(), // Re-trigger loadData for error state display
              builder: (context, snapshot) {
                // Show loading indicator while waiting
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _memberNotifier.value == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                // If loading finished but member is still null, show error message
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                        'Failed to load member details. Please check connection and try again.'),
                  ),
                );
              },
            );
          }
          // If member data is available, build the main content
          return RefreshIndicator(
            onRefresh: _loadData, // Enable pull-to-refresh
            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(), // Allow scrolling even if content fits
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(member), // Build the top header section
                  const SizedBox(height: 24),
                  _buildMemberInfoCard(member), // Build the info card section
                  const SizedBox(height: 24),
                  _buildActionButtons(
                      member['status']), // Build status action buttons
                  const SizedBox(height: 24),
                  // Button to open the 'Add Payment' dialog
                  ElevatedButton.icon(
                    onPressed: () => _showRenewFeeDialog(member),
                    icon: const Icon(Icons.add_card),
                    label: const Text('Add Payment'),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                  const SizedBox(height: 20), // Bottom padding
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the header section displaying the member's avatar, name, QR code, and key details.
  Widget _buildProfileHeader(Map<String, dynamic> member) {
    final theme = Theme.of(context);
    // Use onPrimary color for text on the primary-colored background
    final onPrimaryColor = theme.colorScheme.onPrimary;

    final avatarUrl = member['avatar_url'];
    final feeDueDateString = member['fee_due_date'];
    final feeDueDate =
        feeDueDateString != null ? DateTime.parse(feeDueDateString) : null;
    final serialNumber = member['serial_number']?.toString() ?? 'N/A';

    return Container(
      // Margin to position the avatar correctly relative to this container
      margin: const EdgeInsets.only(top: 50),
      child: Stack(
        clipBehavior: Clip.none, // Allow avatar to overflow the top
        alignment: Alignment.center,
        children: [
          // Background container with primary color
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
                20, 70, 20, 20), // Padding adjusted for avatar overlap
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                // Left column for member details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderInfoRow(
                          'Serial #', serialNumber, onPrimaryColor),
                      _buildHeaderInfoRow(
                          'ID Number',
                          member['user_id'].substring(0, 12) + '...',
                          onPrimaryColor), // Show partial ID
                      _buildHeaderInfoRow(
                          'Status',
                          (member['status'] as String).toUpperCase(),
                          onPrimaryColor),
                      _buildHeaderInfoRow(
                          'Expires On',
                          feeDueDate != null
                              ? DateFormat('dd MMM yyyy')
                                  .format(feeDueDate) // Format date
                              : 'N/A', // Handle null date
                          onPrimaryColor),
                    ],
                  ),
                ),
                // Right side container for QR code
                Container(
                  padding: const EdgeInsets.all(4), // Padding around QR code
                  decoration: BoxDecoration(
                    color:
                        Colors.white, // White background for QR code visibility
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(
                    // Generate QR code from member's user_id
                    data: member['user_id'],
                    version: QrVersions.auto, // Auto-detect QR version
                    size: 80.0, // Fixed size for the QR code
                  ),
                ),
              ],
            ),
          ),
          // Positioned Avatar (overlaps the top of the background container)
          Positioned(
            top: -50, // Position halfway above the container's top edge
            child: Stack(
              // Stack to allow placing the edit icon on the avatar
              children: [
                // Container for avatar border effect
                Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius:
                          BorderRadius.circular(20), // Rounded rectangle
                      // Border color matches scaffold background to create 'cutout' effect
                      border: Border.all(
                          color: theme.scaffoldBackgroundColor, width: 4)),
                  child: ClipRRect(
                    // Clip the image to rounded corners
                    borderRadius: BorderRadius.circular(16), // Inner rounding
                    child: (avatarUrl != null && avatarUrl.isNotEmpty)
                        // Display network image if URL exists
                        ? Image.network(
                            avatarUrl,
                            width: 80, height: 80, fit: BoxFit.cover,
                            // Error placeholder if image fails to load
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                    width: 80,
                                    height: 80,
                                    color: theme.cardColor,
                                    child: Icon(Icons.person,
                                        size: 40, color: Colors.grey.shade400)),
                          )
                        // Display placeholder icon if no avatar URL
                        : Container(
                            width: 80,
                            height: 80,
                            color: theme.cardColor,
                            child: Icon(Icons.person,
                                size: 40, color: Colors.grey.shade400),
                          ),
                  ),
                ),
                // Edit icon positioned at the bottom-right of the avatar
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    // Make the icon tappable
                    onTap: _uploadAvatar, // Call upload function on tap
                    child: CircleAvatar(
                      // Circular background for the icon
                      radius: 15,
                      backgroundColor:
                          theme.cardColor, // Use card color for contrast
                      child: Icon(Icons.edit,
                          size: 16, color: theme.primaryColor), // Edit icon
                    ),
                  ),
                )
              ],
            ),
          ),
          // Positioned Member Name (overlaps slightly below the avatar)
          Positioned(
            top: 40, // Position below the avatar
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 8), // Padding around name
              decoration: BoxDecoration(
                  color: theme.cardColor, // Background matching cards
                  borderRadius: BorderRadius.circular(30)), // Pill shape
              child: Text(
                  member['name'] ??
                      'Member Name', // Display member name or default
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the card displaying member's personal information (phone, address).
  Widget _buildMemberInfoCard(Map<String, dynamic> member) {
    final theme = Theme.of(context);
    final address = member['address'] as String?;
    final phone = member['phone'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row containing the section title and edit button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Personal Information',
                    style: theme.textTheme.headlineSmall),
                // Edit button navigates to the edit screen
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      color: theme.primaryColor, size: 20), // Changed icon
                  tooltip: 'Edit Member Info', // Added tooltip
                  onPressed: () =>
                      _navigateToEditScreen(member), // Action on press
                ),
              ],
            ),
            const Divider(height: 20), // Visual separator
            // Conditionally display phone number if available
            if (phone != null && phone.isNotEmpty)
              _buildInfoRow(Icons.phone_outlined, phone), // Changed icon
            // Conditionally display address if available
            if (address != null && address.isNotEmpty) ...[
              const SizedBox(height: 12), // Spacing if phone is also present
              _buildInfoRow(
                  Icons.location_on_outlined, address), // Changed icon
            ],
            // Display placeholder text if neither phone nor address is available
            if ((phone == null || phone.isEmpty) &&
                (address == null || address.isEmpty))
              Padding(
                // Added padding for better spacing
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No contact info available. Tap edit to add.',
                    style: theme.textTheme.bodyMedium),
              ),
          ],
        ),
      ),
    );
  }

  /// Updates the member's status ('active' or 'removed') in the database.
  Future<void> _updateMemberStatus(String newStatus) async {
    // Show loading indicator temporarily
    setState(() => _isLoading = true);
    try {
      // Update the 'status' column in the 'members' table
      await supabase
          .from('members')
          .update({'status': newStatus}).eq('user_id', widget.memberId);

      _showSnackBar('Member status updated to $newStatus');
      _loadData(); // Reload data to reflect the status change in the UI
    } catch (e) {
      _showSnackBar('Error updating status: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false); // Hide loading indicator
    }
  }

  /// Builds the row containing the 'Active' and 'Remove' action buttons.
  Widget _buildActionButtons(String currentStatus) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround, // Space buttons evenly
      children: [
        // 'Active' Button
        _actionButton(
          label: 'Active',
          icon: Icons.check_circle_outline, // Changed icon
          // Disable button if member is already active
          onPressed: currentStatus == 'active'
              ? null
              : () => _updateMemberStatus('active'),
          color: Colors.green.shade600, // Slightly darker green
        ),
        // 'Remove' Button
        _actionButton(
          label: 'Remove',
          icon: Icons.person_remove_outlined, // Changed icon
          // Disable button if member is already removed
          onPressed: currentStatus == 'removed'
              ? null
              : () => _updateMemberStatus('removed'),
          color: Colors.redAccent.shade400, // Slightly darker red
        ),
      ],
    );
  }

  /// Builds a single circular action button with an icon and label below it.
  Widget _actionButton(
      {required String label,
      required IconData icon,
      required VoidCallback?
          onPressed, // onPressed is null if button is disabled
      required Color color}) {
    final theme = Theme.of(context);
    // Use grey color for disabled state, otherwise use the specified color
    final effectiveColor = onPressed == null ? Colors.grey.shade700 : color;
    return Column(
      // Arrange icon and text vertically
      mainAxisSize: MainAxisSize.min, // Take minimum vertical space
      children: [
        // The circular button
        ElevatedButton(
          onPressed: onPressed, // Pass null to disable
          style: ElevatedButton.styleFrom(
              shape: const CircleBorder(), // Make it circular
              padding: const EdgeInsets.all(16), // Padding inside the circle
              backgroundColor: theme.cardColor, // Background matches cards
              foregroundColor: effectiveColor, // Color for the icon
              side:
                  BorderSide(color: effectiveColor, width: 1.5), // Border color
              elevation: onPressed == null ? 0 : 2 // No elevation if disabled
              ),
          child: Icon(icon, size: 28),
        ),
        const SizedBox(height: 8), // Space between icon and label
        // The label text below the button
        Text(label,
            style: TextStyle(
                color: effectiveColor,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  /// Builds a row for displaying a specific detail in the header section.
  Widget _buildHeaderInfoRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label text (e.g., 'Serial #')
          Text(label,
              style: TextStyle(
                  color: textColor.withAlpha(200), // Slightly transparent
                  fontSize: 12)),
          // Value text (e.g., '1024')
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1, // Prevent wrapping
            overflow: TextOverflow.ellipsis, // Add ellipsis if too long
          ),
        ],
      ),
    );
  }

  /// Builds a row for displaying information within the info card (icon + text).
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Align icon with top of text
      children: [
        Icon(icon,
            size: 20,
            color: Theme.of(context).primaryColor), // Icon on the left
        const SizedBox(width: 16), // Space between icon and text
        // Expanded text allows it to wrap if needed
        Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
      ],
    );
  }
} // End of _AdminMemberDetailsScreenState class
