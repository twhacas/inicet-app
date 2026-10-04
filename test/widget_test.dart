import 'package:flutter_test/flutter_test.dart';
import 'package:inicet_app/app/inicet_prep_app.dart';
import 'package:inicet_app/data/question_repository.dart';
import 'package:inicet_app/domain/models/mcq_question.dart';

import 'support/question_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testQuestions = [
    const McqQuestion(
      id: 'q1',
      subject: 'Anatomy',
      subTopic: 'Head & Neck',
      stem: 'Which structure passes through Guyon canal?',
      options: [
        'Ulnar nerve and artery',
        'Radial nerve',
        'Median nerve',
        'Axillary nerve',
      ],
      correctIndex: 0,
      explanation: 'Guyon canal transmits ulnar nerve and artery.',
      tag: 'INI-CET',
      exam: '2024 INI-CET',
    ),
    const McqQuestion(
      id: 'q2',
      subject: 'Physiology',
      subTopic: 'Cardiovascular',
      stem: 'First heart sound is caused by closure of which valves?',
      options: [
        'Atrioventricular valves',
        'Semilunar valves',
        'Aortic valve only',
        'Pulmonic valve only',
      ],
      correctIndex: 0,
      explanation: 'S1 is due to mitral and tricuspid valve closure.',
      tag: 'INI-CET',
      exam: '2023 INI-CET',
    ),
  ];

  testWidgets('Setup screen renders and starts MCQ practice session', (
    tester,
  ) async {
    final repo = _FakeQuestionRepository(testQuestions);
    await tester.pumpWidget(InicetPrepApp(questionRepository: repo));
    await tester.pumpAndSettle();

    // Verify Title & setup widgets
    expect(find.text('INICET MCQ Hub'), findsOneWidget);
    expect(find.text('Study Mode'), findsOneWidget);
    expect(find.text('Practice Mode'), findsOneWidget);
    expect(find.text('Exam Mode'), findsOneWidget);
    expect(find.text('Timer'), findsOneWidget);
    expect(find.text('Shuffle Options (A, B, C, D)'), findsOneWidget);

    // Verify subjects appear
    expect(find.text('Anatomy'), findsOneWidget);
    expect(find.text('Physiology'), findsOneWidget);

    // Find and tap start button
    final startBtn = find.textContaining('Start Test');
    expect(startBtn, findsOneWidget);
    await tester.ensureVisible(startBtn);
    await tester.tap(startBtn);
    await tester.pumpAndSettle();

    // Now in McqSessionScreen
    expect(find.text('Q1 of 2'), findsOneWidget);
    expect(
      find.text('Which structure passes through Guyon canal?'),
      findsOneWidget,
    );
    expect(find.text('Ulnar nerve and artery'), findsOneWidget);

    // Tap option in Practice Mode
    await tester.tap(find.text('Ulnar nerve and artery'));
    await tester.pumpAndSettle();

    // Verify instant high-yield explanation is revealed
    expect(find.text('Explanation & Rationale'), findsOneWidget);
    expect(find.text('HIGH-YIELD PEARL'), findsOneWidget);
    expect(
      find.text('Guyon canal transmits ulnar nerve and artery.'),
      findsWidgets,
    );

    // Open Question Palette
    await tester.tap(find.byTooltip('Question palette'));
    await tester.pumpAndSettle();

    expect(find.text('Question Palette'), findsOneWidget);
    // Tap Q2 in palette
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    // Verify Q2 is loaded
    expect(find.text('Q2 of 2'), findsOneWidget);
    expect(
      find.text('First heart sound is caused by closure of which valves?'),
      findsOneWidget,
    );

    // Submit test
    final submitBtn = find.text('Submit Test');
    expect(submitBtn, findsOneWidget);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Confirm dialog
    expect(find.text('Submit Test?'), findsOneWidget);
    await tester.tap(find.text('Submit Now'));
    await tester.pumpAndSettle();

    // Now in TestResultScreen
    expect(find.text('Performance & Review'), findsOneWidget);
    expect(find.text('Review Questions'), findsOneWidget);
    expect(find.text('Subject Breakdown'), findsOneWidget);
  });
}

class _FakeQuestionRepository extends QuestionRepository {
  _FakeQuestionRepository(this._initial)
    : super(storage: MemoryQuestionStorage());

  final List<McqQuestion> _initial;

  @override
  bool get isInitialized => true;

  @override
  List<McqQuestion> get allQuestions => _initial;

  @override
  Future<void> init() async {}

  @override
  List<String> getAvailableSubjects() {
    return _initial.map((q) => q.subject).toSet().toList()..sort();
  }

  @override
  List<String> getSubTopicsForSubject(String subject) {
    return _initial
        .where((q) => q.subject == subject)
        .map((q) => q.subTopic)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  int getFilteredCount({
    Set<String>? selectedSubjects,
    Map<String, Set<String>>? selectedSubTopics,
    String examFilter = 'all',
    bool repeatsOnly = false,
  }) {
    if (selectedSubjects == null || selectedSubjects.isEmpty) {
      return _initial.length;
    }
    return _initial.where((q) => selectedSubjects.contains(q.subject)).length;
  }

  @override
  List<McqQuestion> generateTest(dynamic config) {
    return List.from(_initial);
  }
}
