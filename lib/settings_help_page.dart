import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme_provider.dart';
import 'locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsHelpPage extends StatefulWidget {
  const SettingsHelpPage({super.key});

  @override
  State<SettingsHelpPage> createState() => _SettingsHelpPageState();
}

class _SettingsHelpPageState extends State<SettingsHelpPage> {
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('loggedInEmail');
    final path = prefs.getString('profileImagePath_$email');
    if (path != null && File(path).existsSync()) {
      setState(() => _profileImage = File(path));
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=App Support&body=Hi, I need help with...',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open email app.")),
      );
    }
  }

  Future<void> _launchPhone(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open dialer.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentLang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage:
                  _profileImage != null
                      ? FileImage(_profileImage!)
                      : const AssetImage('assets/default_avatar.png')
                          as ImageProvider,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(loc.settings)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            loc.appTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          SwitchListTile(
            title: Text(loc.darkMode),
            secondary: const Icon(Icons.brightness_6),
            value: isDarkMode,
            onChanged: (value) {
              final themeProvider = Provider.of<ThemeProvider>(
                context,
                listen: false,
              );
              themeProvider.toggleTheme(value);
            },
          ),

          ListTile(
            leading: const Icon(Icons.language),
            title: Text(loc.language),
            subtitle: Text(currentLang == 'en' ? 'English' : 'Bahasa Melayu'),
            onTap: () {
              final localeProvider = Provider.of<LocaleProvider>(
                context,
                listen: false,
              );
              final newLocale =
                  currentLang == 'en' ? const Locale('ms') : const Locale('en');
              localeProvider.setLocale(newLocale);
            },
          ),

          const Divider(height: 32),
          Text(
            loc.helpSupport,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(loc.aboutApp),
            subtitle: Text(loc.aboutAppDetails),
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text(loc.aboutApp),
                      content: Text(loc.aboutAppDetails),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(loc.ok),
                        ),
                      ],
                    ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.contact_support),
            title: Text(loc.contactSupport),
            subtitle: Text(loc.contactSupportDetails),
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text(loc.contactSupport),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.email),
                            title: const Text('support@hospitalapp.com'),
                            subtitle: const Text('Send us your queries'),
                            onTap:
                                () => _launchEmail('support@hospitalapp.com'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.phone),
                            title: const Text('+6012-345-6789'),
                            subtitle: const Text('Call our support team'),
                            onTap: () => _launchPhone('+60123456789'),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          child: Text(loc.ok),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
    );
  }
}
