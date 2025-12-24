import 'dart:async';

class QuestionUpdateNotifier {
  static final QuestionUpdateNotifier _instance = QuestionUpdateNotifier._internal();
  factory QuestionUpdateNotifier() => _instance;
  QuestionUpdateNotifier._internal();

  final StreamController<void> _controller = StreamController<void>.broadcast();

  Stream<void> get onQuestionUpdated => _controller.stream;

  void notifyQuestionUpdated() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  void dispose() {
    _controller.close();
  }
}
