import 'package:cloud_firestore/cloud_firestore.dart';

class ConfigService {
  static const String _collection = 'config';
  static const String _quizDoc = 'quiz';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Returns questions-per-quiz; defaults to 10 if not set
  Future<int> getQuestionsPerQuiz({int fallback = 10}) async {
    try {
      final snap = await _firestore.collection(_collection).doc(_quizDoc).get();
      if (!snap.exists) return fallback;
      final data = snap.data();
      final val = data?['questionsPerQuiz'];
      if (val is int && val > 0) return val;
      if (val is num && val.toInt() > 0) return val.toInt();
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  // Stream updates to questions-per-quiz
  Stream<int> streamQuestionsPerQuiz({int fallback = 10}) {
    return _firestore.collection(_collection).doc(_quizDoc).snapshots().map((snap) {
      final data = snap.data();
      final val = data?['questionsPerQuiz'];
      if (val is int && val > 0) return val;
      if (val is num && val.toInt() > 0) return val.toInt();
      return fallback;
    });
  }

  // Update questions-per-quiz
  Future<void> setQuestionsPerQuiz(int value) async {
    final v = value.clamp(1, 1000); // reasonable guard
    await _firestore.collection(_collection).doc(_quizDoc).set({
      'questionsPerQuiz': v,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
