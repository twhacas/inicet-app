import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inicet_app/app/inicet_prep_app.dart';
import 'package:inicet_app/data/question_repository.dart';
import 'package:inicet_app/design_system/theme/app_theme.dart';
import 'package:inicet_app/domain/models/test_config.dart';
import 'package:inicet_app/domain/models/test_result.dart';
import 'package:inicet_app/features/import/import_questions_dialog.dart';
import 'package:inicet_app/features/result/test_result_screen.dart';
import 'package:inicet_app/features/setup/test_setup_screen.dart';

import 'support/question_fixtures.dart';

void main() {
  testWidgets(
    'Bookmarks tab refreshes after bookmarking through an ordinary session',
    (tester) async {
      final repo = await fixtureRepository();
      await tester.pumpWidget(InicetPrepApp(questionRepository: repo));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start Test (3 MCQs)'));
      await tester.tap(find.text('Start Test (3 MCQs)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Bookmark question'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Exit test'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Exit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bookmarks'));
      await tester.pumpAndSettle();
      expect(find.text('Bookmarked Questions (1)'), findsOneWidget);
    },
  );

  testWidgets(
    'History tab refreshes after submitting through an ordinary session',
    (tester) async {
      final repo = await fixtureRepository();
      await tester.pumpWidget(InicetPrepApp(questionRepository: repo));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start Test (3 MCQs)'));
      await tester.tap(find.text('Start Test (3 MCQs)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit Now'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start New Test'));
      await tester.tap(find.text('Start New Test'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('No Test Attempts Yet'), findsNothing);
      expect(find.text('Review Full Test'), findsOneWidget);
    },
  );

  testWidgets('Clear All subjects disables the test launcher', (tester) async {
    final repo = await fixtureRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: TestSetupScreen(
          repository: repo,
          onToggleTheme: () {},
          isDark: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Clear All'));
    await tester.tap(find.text('Clear All'));
    await tester.pumpAndSettle();
    expect(find.text('Subjects (0 of 2)'), findsOneWidget);
    expect(find.text('Start Test (0 MCQs)'), findsOneWidget);
  });

  testWidgets(
    'review filters and bookmark clicks retain each question identity',
    (tester) async {
      final repo = await fixtureRepository();
      await repo.toggleBookmark('test-a');
      final result = TestSessionResult(
        config: const TestConfig(
          selectedSubjects: {'Anatomy'},
          selectedSubTopics: {},
          questionCount: 2,
        ),
        questions: repo.allQuestions.take(2).toList(),
        userAnswers: const {
          0: UserAnswer(questionIndex: 0, selectedOptionIndex: 0),
          1: UserAnswer(questionIndex: 1, selectedOptionIndex: 1),
        },
        startedAt: DateTime(2026, 10, 2),
        completedAt: DateTime(2026, 10, 2, 0, 1),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: TestResultScreen(result: result, repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Missed (1)'));
      await tester.tap(find.text('Missed (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Question B'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Bookmark'));
      await tester.tap(find.byTooltip('Bookmark'));
      await tester.pumpAndSettle();
      expect(repo.isBookmarked('test-b'), isTrue);
      expect(repo.isBookmarked('test-a'), isTrue);
    },
  );

  testWidgets('JSON import dialog fits a 360px phone with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = await fixtureRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ImportQuestionsDialog.show(context, repo),
              child: const Text('Open import'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open import'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close question manager'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('startup failure is visible and Retry uses the same repository', (
    tester,
  ) async {
    final storage = MemoryQuestionStorage()..failReads = true;
    final repo = QuestionRepository(
      storage: storage,
      bundle: FixtureQuestionBundle(),
    );
    await tester.pumpWidget(InicetPrepApp(questionRepository: repo));
    await tester.pumpAndSettle();
    expect(find.text('Could not open your question bank'), findsOneWidget);
    storage.failReads = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('INICET MCQ Hub'), findsOneWidget);
    expect(repo.allQuestions.length, 3);
  });
}
