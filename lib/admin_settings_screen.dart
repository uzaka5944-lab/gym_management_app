// lib/admin_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_gym_settings_screen.dart';
import 'main.dart';
import 'login_screen.dart';
import 'theme_notifier.dart';
import 'admin_message_templates_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _fullNameController = TextEditingController();
  bool _isLoading = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  Future<void> _loadAdminProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('profiles')
            .select('full_name, avatar_url')
            .eq('id', user.id)
            .single();
        _fullNameController.text = response['full_name'] ?? '';
        _avatarUrl = response['avatar_url'];
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load profile: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfileName() async {
    if (_fullNameController.text.trim().isEmpty) {
      _showSnackBar('Full name cannot be empty', isError: true);
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final user = supabase.auth.currentUser!;
      await supabase.from('profiles').update(
          {'full_name': _fullNameController.text.trim()}).eq('id', user.id);
      _showSnackBar('Profile name updated successfully!');
    } catch (e) {
      _showSnackBar('An unexpected error occurred: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (imageFile == null) return;

    setState(() {
      _isLoading = true;
    });
    try {
      final user = supabase.auth.currentUser!;
      final fileBytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '${user.id}/$fileName';

      await supabase.storage.from('avatars').uploadBinary(filePath, fileBytes);
      final imageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
      await supabase
          .from('profiles')
          .update({'avatar_url': imageUrl}).eq('id', user.id);

      setState(() {
        _avatarUrl = imageUrl;
      });
      _showSnackBar('Avatar updated successfully!');
    } catch (e) {
      _showSnackBar('Error uploading avatar: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showChangeEmailDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Change Email'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'New Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final newEmail = emailController.text.trim();
                if (newEmail.isNotEmpty) {
                  try {
                    await supabase.auth
                        .updateUser(UserAttributes(email: newEmail));
                    if (mounted) Navigator.of(context).pop();
                    _showSnackBar('Confirmation link sent to your new email!');
                  } catch (e) {
                    if (mounted) Navigator.of(context).pop();
                    _showSnackBar('Failed to update email: $e', isError: true);
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Change Password'),
          content: TextField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: 'New Password'),
            obscureText: true,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final newPassword = passwordController.text;
                if (newPassword.length >= 6) {
                  try {
                    await supabase.auth
                        .updateUser(UserAttributes(password: newPassword));
                    if (mounted) Navigator.of(context).pop();
                    _showSnackBar('Password updated successfully!');
                  } catch (e) {
                    if (mounted) Navigator.of(context).pop();
                    _showSnackBar('Failed to update password: $e',
                        isError: true);
                  }
                } else {
                  _showSnackBar('Password must be at least 6 characters',
                      isError: true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => const LoginScreen(role: 'admin')),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Theme.of(context).colorScheme.error : Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor))
          : RefreshIndicator(
              onRefresh: _loadAdminProfile,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(context).cardColor,
                          backgroundImage: _avatarUrl != null
                              ? NetworkImage(_avatarUrl!)
                              : null,
                          child: _avatarUrl == null
                              ? Icon(Icons.person,
                                  size: 60, color: Colors.grey.shade400)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: IconButton(
                              icon: Icon(Icons.edit,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary),
                              onPressed: _uploadAvatar,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updateProfileName,
                    child: const Text('Save Name'),
                  ),
                  const Divider(height: 40),
                  _buildSectionHeader(context, 'Customization'),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('App Theme'),
                    trailing: Consumer<ThemeNotifier>(
                      builder: (context, themeNotifier, child) {
                        return DropdownButton<String>(
                          value: themeNotifier.themeName,
                          underline: const SizedBox(),
                          items: themeNotifier.allThemes.keys.map((String key) {
                            return DropdownMenuItem<String>(
                              value: key,
                              child:
                                  Text(key[0].toUpperCase() + key.substring(1)),
                            );
                          }).toList(),
                          onChanged: (String? newTheme) {
                            if (newTheme != null) {
                              themeNotifier.setTheme(newTheme);
                            }
                          },
                        );
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.message_outlined),
                    title: const Text('Message Templates'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            const AdminMessageTemplatesScreen(),
                      ));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_suggest_outlined),
                    title: const Text('Gym Settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const AdminGymSettingsScreen(),
                      ));
                    },
                  ),
                  const Divider(height: 40),
                  _buildSectionHeader(context, 'Account'),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email Address'),
                    subtitle: Text(
                        supabase.auth.currentUser?.email ?? 'Not available'),
                    trailing: const Icon(Icons.edit, size: 20),
                    onTap: _showChangeEmailDialog,
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline_rounded),
                    title: const Text('Password'),
                    subtitle: const Text('Last updated ●●●●●●'),
                    trailing: const Icon(Icons.edit, size: 20),
                    onTap: _showChangePasswordDialog,
                  ),
                  const Divider(height: 40),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out'),
                    onPressed: _signOut,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
