import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const ProfilePage({super.key, required this.userProfile});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final prefs = await SharedPreferences.getInstance();
    final email = widget.userProfile['email'];
    final path = prefs.getString(
      'profileImagePath_$email',
    ); // Unique to each user
    if (path != null && File(path).existsSync()) {
      setState(() => _profileImage = File(path));
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      final email = widget.userProfile['email'];
      await prefs.setString(
        'profileImagePath_$email',
        picked.path,
      ); // Save with email key
      setState(() => _profileImage = File(picked.path));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final name = widget.userProfile['name'] ?? 'N/A';
    final email = widget.userProfile['email'] ?? 'N/A';
    final gender = widget.userProfile['gender'] ?? 'N/A';
    final phone = widget.userProfile['phone'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(title: Text(loc.profile)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        _profileImage != null
                            ? FileImage(_profileImage!)
                            : const AssetImage('assets/default_avatar.png')
                                as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(name),
              subtitle: Text(loc.fullName),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(email),
              subtitle: Text(loc.email),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(phone),
              subtitle: Text(loc.phoneNumber),
            ),
            ListTile(
              leading: const Icon(Icons.transgender),
              title: Text(gender),
              subtitle: Text(loc.gender),
            ),
          ],
        ),
      ),
    );
  }
}
