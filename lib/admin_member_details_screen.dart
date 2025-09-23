// lib/admin_member_details_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'theme.dart';
import 'admin_edit_member_screen.dart';

class AdminMemberDetailsScreen extends StatefulWidget {
  final String memberId;
  final String memberName;

  const AdminMemberDetailsScreen({
    super.key,
    required this.memberId,
    required this.memberName,
  });

  @override
  State<AdminMemberDetailsScreen> createState() =>
      _AdminMemberDetailsScreenState();
}

class _AdminMemberDetailsScreenState extends State<AdminMemberDetailsScreen> {
  late Future<Map<String, dynamic>> _memberDetailsFuture;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _memberDetailsFuture = _fetchMemberDetails();
  }

  Future<Map<String, dynamic>> _fetchMemberDetails() async {
    try {
      final response = await supabase
          .from('members')
          .select()
          .eq('user_id', widget.memberId)
          .single();
      if (mounted) {
        setState(() {
          _avatarUrl = response['avatar_url'];
        });
      }
      return response;
    } catch (e) {
      // If no member record exists, create a default one
      final profileResponse = await supabase
          .from('profiles')
          .select('full_name, id')
          .eq('id', widget.memberId)
          .single();
      final memberResponse = await supabase
          .from('members')
          .insert({
            'user_id': profileResponse['id'],
            'name': profileResponse['full_name'],
          })
          .select()
          .single();
      return memberResponse;
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final imagePicker = ImagePicker();
    final imageFile = await imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
    );

    if (imageFile == null) return;

    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      await supabase.storage.from('avatars').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: imageFile.mimeType),
          );

      final imageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);

      await supabase
          .from('members')
          .update({'avatar_url': imageUrl}).eq('user_id', widget.memberId);

      if (mounted) {
        // Re-fetch all member details to ensure the UI is fully consistent with the database
        setState(() {
          _memberDetailsFuture = _fetchMemberDetails();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error uploading image: $e'),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.memberName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
               final memberData = await _memberDetailsFuture;
                final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => AdminEditMemberScreen(memberData: memberData),
                    ),
                  );
                  if (result == true) {
                    setState(() { _memberDetailsFuture = _fetchMemberDetails(); });
                  }
            },
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _memberDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error: ${snapshot.error ?? "No data"}'));
          }
          final member = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildProfileCard(member),
              const SizedBox(height: 24),
              _buildInfoCard(member),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> member) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade800,
                  backgroundImage:
                      _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null
                      ? const Icon(Icons.person, size: 50, color: Colors.white70)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickAndUploadAvatar,
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: primaryColor,
                      child: Icon(Icons.edit, size: 20, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              member['name'] ?? 'Member Name',
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> member) {
    final plan = member['membership_plan'] ?? 'N/A';
    final endDate = member['end_date'] != null
        ? DateFormat.yMMMd().format(DateTime.parse(member['end_date']))
        : 'N/A';

    return Card(
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Membership Details',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plan',
                          style: Theme.of(context).textTheme.bodyMedium),
                      Text(plan, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Text('Expires On',
                          style: Theme.of(context).textTheme.bodyMedium),
                      Text(endDate,
                          style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: member['user_id'],
                    version: QrVersions.auto,
                    size: 100.0,
                    dataModuleStyle: const QrDataModuleStyle(
                      color: Colors.black,
                      dataModuleShape: QrDataModuleShape.square
                    ),
                    eyeStyle: const QrEyeStyle(
                      color: Colors.black,
                      eyeShape: QrEyeShape.square
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}