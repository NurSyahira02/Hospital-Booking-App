import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'theme_provider.dart';
import 'locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsHelpPage extends StatefulWidget {
  const SettingsHelpPage({super.key});

  @override
  State<SettingsHelpPage> createState() => _SettingsHelpPageState();
}

class _SettingsHelpPageState extends State<SettingsHelpPage> {
  double _rating = 3.0;
  final _feedbackController = TextEditingController();
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profileImagePath');
    if (path != null && File(path).existsSync()) {
      setState(() => _profileImage = File(path));
    }
  }

  void _submitFeedback() {
    final loc = AppLocalizations.of(context)!;
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.enterFeedback)),
      );
      return;
    }

    _feedbackController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.feedbackThanks)),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
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
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(loc.settings)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(loc.appTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          SwitchListTile(
            title: Text(loc.darkMode),
            secondary: const Icon(Icons.brightness_6),
            value: isDarkMode,
            onChanged: (value) {
              final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
              themeProvider.toggleTheme(value);
            },
          ),

          ListTile(
            leading: const Icon(Icons.language),
            title: Text(loc.language),
            subtitle: Text(currentLang == 'en' ? 'English' : 'Bahasa Melayu'),
            onTap: () {
              final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
              final newLocale = currentLang == 'en' ? const Locale('ms') : const Locale('en');
              localeProvider.setLocale(newLocale);
            },
          ),

          const Divider(height: 32),
          Text(loc.helpSupport,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(loc.aboutApp),
            subtitle: Text(loc.aboutAppDetails),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(loc.howToUse),
            subtitle: Text(loc.howToUseDetails),
          ),
          ListTile(
            leading: const Icon(Icons.contact_support),
            title: Text(loc.contactSupport),
            subtitle: Text(loc.contactSupportDetails),
          ),

          const Divider(height: 32),
          Text(loc.sendFeedback,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Text(loc.rateExperience),
          RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemSize: 32,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (rating) => _rating = rating,
          ),

          const SizedBox(height: 16),
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: loc.yourFeedback,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.send),
            label: Text(loc.submitFeedback),
            onPressed: _submitFeedback,
          ),
        ],
      ),
    );
  }
}
