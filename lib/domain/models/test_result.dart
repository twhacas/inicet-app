import 'mcq_question.dart';
import 'test_config.dart';

final class UserAnswer {
  const UserAnswer({
    required this.questionIndex,
    this.selectedOptionIndex,
    this.isFlagged = false,
    this.timeSpentSeconds = 0,
  });

  final int questionIndex;
  final int? selectedOptionIndex;
  final bool isFlagged;
  final int timeSpentSeconds;

  bool get isAttempted => selectedOptionIndex != null;

  UserAnswer copyWith({
    int? questionIndex,
    int? selectedOptionIndex,
    bool? isFlagged,
    int? timeSpentSeconds,
  }) {
    return UserAnswer(
      questionIndex: questionIndex ?? this.questionIndex,
      selectedOptionIndex: selectedOptionIndex ?? this.selectedOptionIndex,
      isFlagged: isFlagged ?? this.isFlagged,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'questionIndex': questionIndex,
      'selectedOptionIndex': selectedOptionIndex,
      'isFlagged': isFlagged,
      'timeSpentSeconds': timeSpentSeconds,
    };
  }

  factory UserAnswer.fromJson(Map<String, Object?> json) {
    return UserAnswer(
      questionIndex: (json['questionIndex'] as num?)?.toInt() ?? 0,
      selectedOptionIndex: (json['selectedOptionIndex'] as num?)?.toInt(),
      isFlagged: json['isFlagged'] == true,
      timeSpentSeconds: (json['timeSpentSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}

final class TestSessionResult {
  const TestSessionResult({
    required this.config,
    required this.questions,
    required this.userAnswers,
    required this.startedAt,
    required this.completedAt,
    this.id,
    this.activeTimeSpentSeconds,
    this.timedOut = false,
  });

  final String? id;
  final TestConfig config;
  final List<McqQuestion> questions;
  final Map<int, UserAnswer> userAnswers;
  final DateTime startedAt;
  final DateTime completedAt;
  final int? activeTimeSpentSeconds;
  final bool timedOut;

  int get totalQuestions => questions.length;

  int get attemptedCount =>
      userAnswers.values.where((a) => a.isAttempted).length;

  int get unattemptedCount => totalQuestions - attemptedCount;

  int get correctCount {
    var count = 0;
    for (var i = 0; i < questions.length; i++) {
      final ans = userAnswers[i];
      if (ans != null && ans.selectedOptionIndex == questions[i].correctIndex) {
        count++;
      }
    }
    return count;
  }

  int get incorrectCount => attemptedCount - correctCount;

  double get accuracyPercent =>
      attemptedCount > 0 ? (correctCount / attemptedCount) * 100 : 0.0;

  int get totalTimeSpentSeconds =>
      activeTimeSpentSeconds ?? completedAt.difference(startedAt).inSeconds;

  List<McqQuestion> get incorrectQuestions {
    final list = <McqQuestion>[];
    for (var i = 0; i < questions.length; i++) {
      final ans = userAnswers[i];
      if (ans != null &&
          ans.isAttempted &&
          ans.selectedOptionIndex != questions[i].correctIndex) {
        list.add(questions[i]);
      }
    }
    return list;
  }

  List<McqQuestion> get flaggedQuestions {
    final list = <McqQuestion>[];
    for (var i = 0; i < questions.length; i++) {
      final ans = userAnswers[i];
      if (ans != null && ans.isFlagged) {
        list.add(questions[i]);
      }
    }
    return list;
  }

  Map<String, (int correct, int total)> get subjectBreakdown {
    final map = <String, (int correct, int total)>{};
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final current = map[q.subject] ?? (0, 0);
      final isCorrect = userAnswers[i]?.selectedOptionIndex == q.correctIndex;
      map[q.subject] = (current.$1 + (isCorrect ? 1 : 0), current.$2 + 1);
    }
    return map;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id ?? startedAt.millisecondsSinceEpoch.toString(),
      'config': config.toJson(),
      'questions': questions.map((q) => q.toJson()).toList(),
      'userAnswers': userAnswers.map(
        (k, v) => MapEntry(k.toString(), v.toJson()),
      ),
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
      if (activeTimeSpentSeconds != null)
        'activeTimeSpentSeconds': activeTimeSpentSeconds,
      'timedOut': timedOut,
    };
  }

  factory TestSessionResult.fromJson(Map<String, Object?> json) {
    final rawConfig = json['config'];
    final config = rawConfig is Map<String, Object?>
        ? TestConfig.fromJson(rawConfig)
        : const TestConfig(
            selectedSubjects: {},
            selectedSubTopics: {},
            questionCount: 25,
          );

    final rawQuestions = json['questions'];
    final questions = rawQuestions is List
        ? rawQuestions
              .map((q) => McqQuestion.fromJson(q as Map<String, Object?>))
              .toList()
        : <McqQuestion>[];

    final rawAnswers = json['userAnswers'];
    final userAnswers = <int, UserAnswer>{};
    if (rawAnswers is Map) {
      rawAnswers.forEach((k, v) {
        final idx = int.tryParse(k.toString());
        if (idx != null && v is Map<String, Object?>) {
          userAnswers[idx] = UserAnswer.fromJson(v);
        }
      });
    }

    final startedAt =
        DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
        DateTime.now();
    final completedAt =
        DateTime.tryParse(json['completedAt']?.toString() ?? '') ??
        DateTime.now();

    return TestSessionResult(
      id: json['id']?.toString(),
      config: config,
      questions: questions,
      userAnswers: userAnswers,
      startedAt: startedAt,
      completedAt: completedAt,
      activeTimeSpentSeconds: (json['activeTimeSpentSeconds'] as num?)?.toInt(),
      timedOut: json['timedOut'] == true,
    );
  }
}
