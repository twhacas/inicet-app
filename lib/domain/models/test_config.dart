enum TestMode {
  practice('Practice Mode', 'Instant answer check & detailed explanation upon selection'),
  exam('Exam Mode', 'Standard exam environment with timer, flag for review, and final scorecard');

  const TestMode(this.title, this.description);
  final String title;
  final String description;
}

enum TimerType {
  perQuestion('Pace per Question', 'e.g. 50s per question'),
  totalExam('Total Exam Timer', 'Fixed countdown for entire test');

  const TimerType(this.label, this.description);
  final String label;
  final String description;
}

final class TestConfig {
  const TestConfig({
    required this.selectedSubjects,
    required this.selectedSubTopics,
    required this.questionCount,
    this.title = '',
    this.examFilter = 'all',
    this.repeatsOnly = false,
    this.shuffleQuestions = true,
    this.shuffleOptions = true,
    this.repeatsPriority = false,
    this.mode = TestMode.practice,
    this.timerEnabled = true,
    this.timerType = TimerType.perQuestion,
    this.timePerQuestionSeconds = 50,
    this.totalDurationMinutes = 20,
  });

  final String title;
  final String examFilter;
  final bool repeatsOnly;
  final Set<String> selectedSubjects;
  final Map<String, Set<String>> selectedSubTopics;
  final int questionCount;
  final bool shuffleQuestions;
  final bool shuffleOptions;
  final bool repeatsPriority;
  final TestMode mode;
  final bool timerEnabled;
  final TimerType timerType;
  final int timePerQuestionSeconds;
  final int totalDurationMinutes;

  int calculateTotalSeconds(int actualQuestionCount) {
    if (!timerEnabled) return 0;
    if (timerType == TimerType.perQuestion) {
      return actualQuestionCount * timePerQuestionSeconds;
    } else {
      return totalDurationMinutes * 60;
    }
  }

  TestConfig copyWith({
    String? title,
    String? examFilter,
    bool? repeatsOnly,
    Set<String>? selectedSubjects,
    Map<String, Set<String>>? selectedSubTopics,
    int? questionCount,
    bool? shuffleQuestions,
    bool? shuffleOptions,
    bool? repeatsPriority,
    TestMode? mode,
    bool? timerEnabled,
    TimerType? timerType,
    int? timePerQuestionSeconds,
    int? totalDurationMinutes,
  }) {
    return TestConfig(
      title: title ?? this.title,
      examFilter: examFilter ?? this.examFilter,
      repeatsOnly: repeatsOnly ?? this.repeatsOnly,
      selectedSubjects: selectedSubjects ?? this.selectedSubjects,
      selectedSubTopics: selectedSubTopics ?? this.selectedSubTopics,
      questionCount: questionCount ?? this.questionCount,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      shuffleOptions: shuffleOptions ?? this.shuffleOptions,
      repeatsPriority: repeatsPriority ?? this.repeatsPriority,
      mode: mode ?? this.mode,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      timerType: timerType ?? this.timerType,
      timePerQuestionSeconds:
          timePerQuestionSeconds ?? this.timePerQuestionSeconds,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'title': title,
      'examFilter': examFilter,
      'repeatsOnly': repeatsOnly,
      'selectedSubjects': selectedSubjects.toList(),
      'selectedSubTopics': selectedSubTopics.map((k, v) => MapEntry(k, v.toList())),
      'questionCount': questionCount,
      'shuffleQuestions': shuffleQuestions,
      'shuffleOptions': shuffleOptions,
      'repeatsPriority': repeatsPriority,
      'mode': mode.name,
      'timerEnabled': timerEnabled,
      'timerType': timerType.name,
      'timePerQuestionSeconds': timePerQuestionSeconds,
      'totalDurationMinutes': totalDurationMinutes,
    };
  }

  factory TestConfig.fromJson(Map<String, Object?> json) {
    final rawSubs = json['selectedSubjects'];
    final subjects = rawSubs is List ? rawSubs.map((e) => e.toString()).toSet() : <String>{};

    final rawTopics = json['selectedSubTopics'];
    final topics = <String, Set<String>>{};
    if (rawTopics is Map) {
      rawTopics.forEach((k, v) {
        if (v is List) {
          topics[k.toString()] = v.map((e) => e.toString()).toSet();
        }
      });
    }

    final modeName = json['mode']?.toString() ?? 'practice';
    final mode = TestMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => TestMode.practice,
    );

    final timerName = json['timerType']?.toString() ?? 'perQuestion';
    final timerType = TimerType.values.firstWhere(
      (t) => t.name == timerName,
      orElse: () => TimerType.perQuestion,
    );

    return TestConfig(
      title: json['title']?.toString() ?? '',
      examFilter: json['examFilter']?.toString() ?? 'all',
      repeatsOnly: json['repeatsOnly'] == true,
      selectedSubjects: subjects,
      selectedSubTopics: topics,
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 25,
      shuffleQuestions: json['shuffleQuestions'] != false,
      shuffleOptions: json['shuffleOptions'] != false,
      repeatsPriority: json['repeatsPriority'] == true,
      mode: mode,
      timerEnabled: json['timerEnabled'] != false,
      timerType: timerType,
      timePerQuestionSeconds: (json['timePerQuestionSeconds'] as num?)?.toInt() ?? 50,
      totalDurationMinutes: (json['totalDurationMinutes'] as num?)?.toInt() ?? 20,
    );
  }
}
