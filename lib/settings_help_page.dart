import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'theme_provider.dart';

class SettingsHelpPage extends StatefulWidget {
  const SettingsHelpPage({super.key});

  @override
  State<SettingsHelpPage> createState() => _SettingsHelpPageState();
}

class _SettingsHelpPageState extends State<SettingsHelpPage> {
  double _rating = 3.0;
  final _feedbackController = TextEditingController();

  void _submitFeedback() {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter feedback.')),
      );
      return;
    }

    // ✅ Simulate saving feedback (e.g., store or send to server)
    _feedbackController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback!')),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings & Help")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("App Settings",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          SwitchListTile(
            title: const Text("Dark Mode"),
            secondary: const Icon(Icons.brightness_6),
            value: isDarkMode,
            onChanged: (value) {
              final themeProvider =
                  Provider.of<ThemeProvider>(context, listen: false);
              themeProvider.toggleTheme(value);
            },
          ),

          const Divider(height: 32),

          const Text("Help & Support",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("About This App"),
            subtitle: const Text("Version 1.0.0\nHospital Booking App for Patients"),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("How to use"),
            subtitle: const Text("Login, book appointments, order medication, view history."),
          ),
          ListTile(
            leading: const Icon(Icons.contact_support),
            title: const Text("Contact Support"),
            subtitle: const Text("Email: support@hospitalapp.com"),
          ),

          const Divider(height: 32),
          const Text("Send Feedback",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          const Text("Rate your experience:"),
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
              labelText: 'Your feedback',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('Submit Feedback'),
            onPressed: _submitFeedback,
          ),
        ],
      ),
    );
  }
}
