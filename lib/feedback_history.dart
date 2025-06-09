import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'feedback_data.dart';
import 'user_session.dart';

class FeedbackHistoryScreen extends StatelessWidget {
  const FeedbackHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feedbackList = FeedbackData.getAll();

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback History')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: feedbackList.length,
        itemBuilder: (context, index) {
          final feedback = feedbackList[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text(feedback.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  RatingBarIndicator(
                    rating: feedback.rating,
                    itemBuilder: (context, index) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    itemCount: 5,
                    itemSize: 20.0,
                    direction: Axis.horizontal,
                  ),
                  const SizedBox(height: 4),
                  Text(feedback.comment),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.teal),
                onPressed: () => Navigator.pushNamed(context, '/feedback'),
              ),
            ),
          );
        },
      ),
    );
  }
}