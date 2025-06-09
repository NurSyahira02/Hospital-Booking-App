class FeedbackData {
  final String name;
  final double rating;
  final String comment;

  FeedbackData(this.name, this.rating, this.comment);

  static final List<FeedbackData> _feedbackList = [];

  static void addOrUpdate(String name, double rating, String comment) {
    final index = _feedbackList.indexWhere((f) => f.name == name);
    if (index != -1) {
      _feedbackList[index] = FeedbackData(name, rating, comment);
    } else {
      _feedbackList.add(FeedbackData(name, rating, comment));
    }
  }

  static FeedbackData? getByName(String name) {
    try {
      return _feedbackList.firstWhere((f) => f.name == name);
    } catch (e) {
      return null;
    }
  }

  static List<FeedbackData> getAll() {
    return _feedbackList;
  }
}

