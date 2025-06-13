class FeedbackData {
  final String email;
  final int rating;
  final String comment;

  FeedbackData({
    required this.email,
    required this.rating,
    required this.comment,
  });

  /// Create a FeedbackData object from a map (e.g. from database)
  factory FeedbackData.fromMap(Map<String, dynamic> map) {
    return FeedbackData(
      email: map['email'],
      rating: map['rating'],
      comment: map['comment'],
    );
  }

  /// Convert FeedbackData object to a map (e.g. for saving to database)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'rating': rating,
      'comment': comment,
    };
  }

  /// Mock method: returns sample feedback data
  static Future<List<FeedbackData>> getAll() async {
    return [
      FeedbackData(email: 'patient1@example.com', rating: 5, comment: 'Excellent care and attention.'),
      FeedbackData(email: 'patient2@example.com', rating: 4, comment: 'Smooth appointment process.'),
      FeedbackData(email: 'patient3@example.com', rating: 3, comment: 'Average waiting time.'),
    ];
  }

  /// Mock search: filter feedback by email or comment keyword
  static Future<List<FeedbackData>> getByName(String query) async {
    final all = await getAll();
    return all.where((f) =>
      f.email.toLowerCase().contains(query.toLowerCase()) ||
      f.comment.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
