import 'package:flutter_test/flutter_test.dart';
import 'package:inicet_app/app/inicet_prep_app.dart';
import 'package:inicet_app/data/question_repository.dart';
import 'package:inicet_app/domain/models/mcq_question.dart';

import 'support/question_fixtures.dart';

void main() {
  testWidgets('InicetPrepApp launches and toggles theme', (tester) async {
    final repo = _FakeQuestionRepository();
    await tester.pumpWidget(InicetPrepApp(questionRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('INICET MCQ Hub'), findsOneWidget);

    // Find and tap theme toggle button
    final themeButton = find.byTooltip('Dark theme');
    expect(themeButton, findsOneWidget);
    await tester.tap(themeButton);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Light theme'), findsOneWidget);
  });
}

class _FakeQuestionRepository extends QuestionRepository {
  _FakeQuestionRepository() : super(storage: MemoryQuestionStorage());
  @override
  bool get isInitialized => true;

  @override
  List<McqQuestion> get allQuestions => const [
    McqQuestion(
      id: 'test-1',
      subject: 'Anatomy',
      subTopic: 'General',
      stem: 'Test question stem',
      options: ['A', 'B', 'C', 'D'],
      correctIndex: 0,
      explanation: 'Test explanation',
    ),
  ];

  @override
  List<String> getAvailableSubjects() => const ['Anatomy'];

  @override
  List<String> getSubTopicsForSubject(String subject) => const ['General'];

  @override
  int getFilteredCount({
    Set<String>? selectedSubjects,
    Map<String, Set<String>>? selectedSubTopics,
    String examFilter = 'all',
    bool repeatsOnly = false,
  }) => 1;
}
