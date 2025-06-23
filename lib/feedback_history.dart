import 'package:flutter/material.dart';
import 'feedback_data.dart';

class FeedbackHistoryPage extends StatefulWidget {
  const FeedbackHistoryPage({super.key});

  @override
  State<FeedbackHistoryPage> createState() => _FeedbackHistoryPageState();
}

class _FeedbackHistoryPageState extends State<FeedbackHistoryPage> {
  List<FeedbackData> _allFeedback = [];
  List<FeedbackData> _filteredFeedback = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    final feedback =
        await FeedbackData.getAll(); // You can replace this with actual DB call
    setState(() {
      _allFeedback = feedback;
      _filteredFeedback = feedback;
    });
  }

  void _filterFeedback(String query) async {
    if (query.isEmpty) {
      setState(() => _filteredFeedback = _allFeedback);
    } else {
      final filtered = await FeedbackData.getByName(query);
      setState(() => _filteredFeedback = filtered);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by email or comment',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _filterFeedback,
            ),
          ),
          Expanded(
            child:
                _filteredFeedback.isEmpty
                    ? const Center(child: Text('No feedback found.'))
                    : ListView.builder(
                      itemCount: _filteredFeedback.length,
                      itemBuilder: (context, index) {
                        final feedback = _filteredFeedback[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.feedback,
                              color: Colors.blue,
                            ),
                            title: Text(
                              feedback.email,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rating: ${feedback.rating}',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '"${feedback.comment}"',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
