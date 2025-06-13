import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'database_helper.dart';

class FeedbackPage extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  const FeedbackPage({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _commentController = TextEditingController();
    double _rating = 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Submit Feedback')),
      body: StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const Text('Rate your experience:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) => setState(() => _rating = rating),
              ),
              const SizedBox(height: 24),
              const Text('Comments:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Enter your comments here...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Submit Feedback'),
                onPressed: () async {
                  if (_rating == 0 || _commentController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please provide both rating and comment')),
                    );
                    return;
                  }

                  final feedback = {
                    'email': userProfile['email'],
                    'rating': _rating.round(),
                    'comment': _commentController.text.trim(),
                  };

                  await DatabaseHelper().insertFeedback(feedback);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feedback submitted successfully!')),
                    );
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
