import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inicet_app/data/question_repository.dart';
import 'package:inicet_app/design_system/components/app_button.dart';
import 'package:inicet_app/design_system/theme/app_theme.dart';
import 'package:inicet_app/domain/models/mcq_question.dart';
import 'package:inicet_app/domain/models/test_config.dart';
import 'package:inicet_app/features/bookmarks/bookmark_practice_modal.dart';
import 'package:inicet_app/features/bookmarks/bookmarks_screen.dart';
import 'package:inicet_app/features/test/mcq_session_screen.dart';

import '../support/question_fixtures.dart';

Future<QuestionRepository> _createSixQuestionRepo() async {
  final questions = [
    const McqQuestion(
      id: 'anat-1',
      subject: 'Anatomy',
      subTopic: 'Upper Limb',
      stem: 'Anatomy Q1',
      options: ['A1', 'B1', 'C1', 'D1'],
      correctIndex: 0,
      explanation: 'Explanation 1',
    ),
    const McqQuestion(
      id: 'anat-2',
      subject: 'Anatomy',
      subTopic: 'Upper Limb',
      stem: 'Anatomy Q2',
      options: ['A2', 'B2', 'C2', 'D2'],
      correctIndex: 1,
      explanation: 'Explanation 2',
    ),
    const McqQuestion(
      id: 'anat-3',
      subject: 'Anatomy',
      subTopic: 'Thorax',
      stem: 'Anatomy Q3',
      options: ['A3', 'B3', 'C3', 'D3'],
      correctIndex: 2,
      explanation: 'Explanation 3',
    ),
    const McqQuestion(
      id: 'phys-1',
      subject: 'Physiology',
      subTopic: 'Cardiovascular',
      stem: 'Physiology Q1',
      options: ['A4', 'B4', 'C4', 'D4'],
      correctIndex: 0,
      explanation: 'Explanation 4',
    ),
    const McqQuestion(
      id: 'phys-2',
      subject: 'Physiology',
      subTopic: 'Cardiovascular',
      stem: 'Physiology Q2',
      options: ['A5', 'B5', 'C5', 'D5'],
      correctIndex: 3,
      explanation: 'Explanation 5',
    ),
    const McqQuestion(
      id: 'phys-3',
      subject: 'Physiology',
      subTopic: 'Respiratory',
      stem: 'Physiology Q3',
      options: ['A6', 'B6', 'C6', 'D6'],
      correctIndex: 0,
      explanation: 'Explanation 6',
    ),
  ];
  final bundle = FixtureQuestionBundle(
    json: jsonEncode(questions.map((q) => q.toJson()).toList()),
  );
  final repo = QuestionRepository(
    storage: MemoryQuestionStorage(),
    bundle: bundle,
  );
  await repo.init();
  return repo;
}

Future<QuestionRepository> _createCustomRepo(List<McqQuestion> questions) async {
  final bundle = FixtureQuestionBundle(
    json: jsonEncode(questions.map((q) => q.toJson()).toList()),
  );
  final repo = QuestionRepository(
    storage: MemoryQuestionStorage(),
    bundle: bundle,
  );
  await repo.init();
  return repo;
}

void main() {
  group('Tier 1: Feature Coverage', () {
    testWidgets('renders empty state when there are no bookmarks', (tester) async {
      final repo = await fixtureRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bookmarked Questions (0)'), findsOneWidget);
      expect(find.text('No bookmarked questions yet'), findsOneWidget);
      expect(
        find.text('Bookmark challenging questions during test or practice sessions.'),
        findsOneWidget,
      );
      expect(find.byType(BookmarkPracticeModal), findsNothing);
      expect(find.textContaining('Practice Selected'), findsNothing);
      expect(find.byKey(const Key('select-all-button')), findsNothing);
    });

    testWidgets('renders hierarchical Subject cards, counts, and expands/collapses both levels', (tester) async {
      final repo = await fixtureRepository();
      await repo.toggleBookmark('test-a'); // Anatomy -> Topic A
      await repo.toggleBookmark('test-b'); // Anatomy -> Topic B
      await repo.toggleBookmark('test-c'); // Physiology -> Topic C

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Top title and toolbar
      expect(find.text('Bookmarked Questions (3)'), findsOneWidget);
      expect(find.text('3 of 3 selected'), findsOneWidget);
      expect(find.text('Practice Selected (3)'), findsOneWidget);

      // Subject headers visible
      expect(find.byKey(const Key('subject-card-Anatomy')), findsOneWidget);
      expect(find.byKey(const Key('subject-card-Physiology')), findsOneWidget);

      // Chapters are collapsed initially
      expect(find.byKey(const Key('chapter-section-Anatomy-Topic A')), findsNothing);
      expect(find.byKey(const Key('chapter-section-Anatomy-Topic B')), findsNothing);

      // Tap Anatomy subject header to expand
      await tester.tap(find.byKey(const Key('subject-header-Anatomy')));
      await tester.pumpAndSettle();

      // Chapters in Anatomy now visible
      expect(find.byKey(const Key('chapter-section-Anatomy-Topic A')), findsOneWidget);
      expect(find.byKey(const Key('chapter-section-Anatomy-Topic B')), findsOneWidget);

      // Tap Topic A chapter to expand question cards
      await tester.tap(find.byKey(const Key('chapter-header-Anatomy-Topic A')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('question-card-test-a')), findsOneWidget);

      // Tap Topic A chapter header again to collapse
      await tester.tap(find.byKey(const Key('chapter-header-Anatomy-Topic A')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('question-card-test-a')), findsNothing);

      // Tap Anatomy subject header again to collapse
      await tester.tap(find.byKey(const Key('subject-header-Anatomy')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chapter-section-Anatomy-Topic A')), findsNothing);
    });

    testWidgets('displays complete question card details: stem, options, pill, explanation, note', (tester) async {
      final repo = await fixtureRepository();
      await repo.toggleBookmark('test-a');
      await repo.saveQuestionNote('test-a', 'High yield pearl for Topic A');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Expand Anatomy -> Topic A
      await tester.tap(find.byKey(const Key('subject-header-Anatomy')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chapter-header-Anatomy-Topic A')));
      await tester.pumpAndSettle();

      // Question card elements for test-a
      expect(find.byKey(const Key('question-card-test-a')), findsOneWidget);
      expect(find.text('Question A'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
      expect(find.text('Delta'), findsOneWidget);
      expect(find.text('Correct: Alpha'), findsOneWidget);
      expect(find.text('Explanation'), findsOneWidget);
      expect(find.text('Alpha is correct.'), findsOneWidget);
      expect(find.text('Personal Note'), findsOneWidget);
      expect(find.text('High yield pearl for Topic A'), findsOneWidget);
      expect(find.byKey(const Key('unbookmark-test-a')), findsOneWidget);
    });

    testWidgets('omits explanation and personal note sections when empty or absent', (tester) async {
      final repo = await _createCustomRepo([
        const McqQuestion(
          id: 'bare-1',
          subject: 'Biochemistry',
          subTopic: 'Genetics',
          stem: 'Bare Question without explanation or note',
          options: ['Opt1', 'Opt2', 'Opt3', 'Opt4'],
          correctIndex: 1,
          explanation: '',
          userNote: null,
        ),
      ]);
      await repo.toggleBookmark('bare-1');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Expand Biochemistry -> Genetics
      await tester.tap(find.byKey(const Key('subject-header-Biochemistry')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chapter-header-Biochemistry-Genetics')));
      await tester.pumpAndSettle();

      expect(find.text('Bare Question without explanation or note'), findsOneWidget);
      expect(find.text('Explanation'), findsNothing);
      expect(find.text('Personal Note'), findsNothing);
    });

    testWidgets('multi-selection toggles subject, chapters, and Select All / Deselect All', (tester) async {
      final repo = await fixtureRepository();
      await repo.toggleBookmark('test-a'); // Anatomy -> Topic A
      await repo.toggleBookmark('test-b'); // Anatomy -> Topic B
      await repo.toggleBookmark('test-c'); // Physiology -> Topic C

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 of 3 selected'), findsOneWidget);

      // Tap Deselect All
      await tester.tap(find.byKey(const Key('deselect-all-button')));
      await tester.pumpAndSettle();

      expect(find.text('0 of 3 selected'), findsOneWidget);
      expect(find.text('Practice Selected (0)'), findsOneWidget);

      // Practice button should be disabled when 0 selected
      final practiceButtonFinder = find.widgetWithText(AppButton, 'Practice Selected (0)');
      expect(practiceButtonFinder, findsOneWidget);
      final AppButton buttonWidget = tester.widget(practiceButtonFinder);
      expect(buttonWidget.onPressed, isNull);

      // Tap Select All
      await tester.tap(find.byKey(const Key('select-all-button')));
      await tester.pumpAndSettle();
      expect(find.text('3 of 3 selected'), findsOneWidget);
      expect(find.text('Practice Selected (3)'), findsOneWidget);

      // Expand Anatomy
      await tester.tap(find.byKey(const Key('subject-header-Anatomy')));
      await tester.pumpAndSettle();

      // Toggle Topic A checkbox off
      final topicACheckbox = find.byKey(const Key('chapter-checkbox-Anatomy-Topic A'));
      await tester.tap(topicACheckbox);
      await tester.pumpAndSettle();

      expect(find.text('2 of 3 selected'), findsOneWidget);
      expect(find.text('Practice Selected (2)'), findsOneWidget);

      // Anatomy checkbox should be indeterminate
      final anatomyCheckboxFinder = find.byKey(const Key('subject-checkbox-Anatomy'));
      final Checkbox anatomyCheckbox = tester.widget(anatomyCheckboxFinder);
      expect(anatomyCheckbox.value, isNull);

      // Tapping indeterminate Anatomy checkbox selects all chapters in Anatomy
      await tester.tap(anatomyCheckboxFinder);
      await tester.pumpAndSettle();
      expect(find.text('3 of 3 selected'), findsOneWidget);

      // Tapping Anatomy checkbox again when fully selected deselects all in Anatomy
      await tester.tap(anatomyCheckboxFinder);
      await tester.pumpAndSettle();
      expect(find.text('1 of 3 selected'), findsOneWidget);
      expect(find.text('Practice Selected (1)'), findsOneWidget);
    });

    testWidgets('dynamic practice button opens modal when questions are selected', (tester) async {
      final repo = await fixtureRepository();
      await repo.toggleBookmark('test-a');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      final practiceButton = find.text('Practice Selected (1)');
      expect(practiceButton, findsOneWidget);

      await tester.tap(practiceButton);
      await tester.pumpAndSettle();

      expect(find.byType(BookmarkPracticeModal), findsOneWidget);
      expect(find.text('Practice Configuration'), findsOneWidget);
      expect(find.text('1 Selected Bookmarked Question'), findsOneWidget);
    });

    testWidgets('pre-launch modal displays and interacts with all controls and dismisses cleanly', (tester) async {
      final repo = await fixtureRepository();
      await repo.toggleBookmark('test-a');
      await repo.toggleBookmark('test-b');
      await repo.toggleBookmark('test-c');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Practice Selected (3)'));
      await tester.pumpAndSettle();

      // Test Mode toggle
      expect(find.text('Practice Mode'), findsOneWidget);
      expect(find.text('Exam Mode'), findsOneWidget);
      await tester.tap(find.text('Exam Mode'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Exam simulation: timed questions recorded quietly'), findsOneWidget);

      // Timer toggle and type
      expect(find.text('Per-Question'), findsOneWidget);
      expect(find.text('Total Exam'), findsOneWidget);
      await tester.tap(find.text('Total Exam'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Total duration:'), findsOneWidget);

      // Randomization toggles
      await tester.scrollUntilVisible(
        find.text('Shuffle Options (A, B, C, D)'),
        100.0,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Shuffle Options (A, B, C, D)'));
      await tester.pumpAndSettle();

      // Close modal
      final closeButton = find.byTooltip('Close');
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(find.byType(BookmarkPracticeModal), findsNothing);
    });

    testWidgets('launches practice session navigating to McqSessionScreen with default TestConfig', (tester) async {
      final repo = await fixtureRepository();
      await repo.toggleBookmark('test-a');
      await repo.toggleBookmark('test-b');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Practice Selected (2)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Session (2 MCQs)'));
      await tester.pumpAndSettle();

      expect(find.byType(McqSessionScreen), findsOneWidget);
      final session = tester.widget<McqSessionScreen>(find.byType(McqSessionScreen));
      expect(session.questions.length, 2);
      expect(session.config.mode, TestMode.practice);
      expect(session.config.questionCount, 2);
    });
  });

  group('Tier 2: Boundary & Corner Cases', () {
    testWidgets('unbookmarking last question in chapter immediately prunes chapter accordion', (tester) async {
      final repo = await fixtureRepository();
      await repo.toggleBookmark('test-a'); // Anatomy -> Topic A
      await repo.toggleBookmark('test-b'); // Anatomy -> Topic B

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Expand Anatomy -> Topic A
      await tester.tap(find.byKey(const Key('subject-header-Anatomy')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chapter-header-Anatomy-Topic A')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('question-card-test-a')), findsOneWidget);

      // Unbookmark test-a
      await tester.tap(find.byKey(const Key('unbookmark-test-a')));
      await tester.pumpAndSettle();

      // Topic A is pruned immediately; Topic B remains
      expect(find.byKey(const Key('chapter-section-Anatomy-Topic A')), findsNothing);
      expect(find.byKey(const Key('chapter-section-Anatomy-Topic B')), findsOneWidget);
      expect(find.text('Bookmarked Questions (1)'), findsOneWidget);
    });

    testWidgets('unbookmarking last question in subject immediately prunes subject card', (tester) async {
      final repo = await fixtureRepository();
      await repo.toggleBookmark('test-a'); // Anatomy -> Topic A
      await repo.toggleBookmark('test-c'); // Physiology -> Topic C

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('subject-card-Anatomy')), findsOneWidget);
      expect(find.byKey(const Key('subject-card-Physiology')), findsOneWidget);

      // Expand Anatomy -> Topic A and unbookmark test-a
      await tester.tap(find.byKey(const Key('subject-header-Anatomy')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chapter-header-Anatomy-Topic A')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('unbookmark-test-a')));
      await tester.pumpAndSettle();

      // Anatomy subject card completely removed from tree
      expect(find.byKey(const Key('subject-card-Anatomy')), findsNothing);
      expect(find.byKey(const Key('subject-card-Physiology')), findsOneWidget);
      expect(find.text('Bookmarked Questions (1)'), findsOneWidget);
    });

    testWidgets('unbookmarking final question in entire app transitions smoothly to empty state', (tester) async {
      final repo = await fixtureRepository();
      await repo.toggleBookmark('test-c');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bookmarked Questions (1)'), findsOneWidget);

      // Expand Physiology -> Topic C and unbookmark
      await tester.tap(find.byKey(const Key('subject-header-Physiology')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chapter-header-Physiology-Topic C')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('unbookmark-test-c')));
      await tester.pumpAndSettle();

      // Transitions to empty state
      expect(find.text('Bookmarked Questions (0)'), findsOneWidget);
      expect(find.text('No bookmarked questions yet'), findsOneWidget);
      expect(find.textContaining('Practice Selected'), findsNothing);
    });

    testWidgets('normalizes blank and whitespace-only subTopics to General chapter and badge', (tester) async {
      final repo = await _createCustomRepo([
        const McqQuestion(
          id: 'blank-subtopic',
          subject: 'Pathology',
          subTopic: '   ',
          stem: 'Blank subtopic question stem',
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 0,
          explanation: 'Exp',
        ),
      ]);
      await repo.toggleBookmark('blank-subtopic');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Expand Pathology
      await tester.tap(find.byKey(const Key('subject-header-Pathology')));
      await tester.pumpAndSettle();

      // Chapter section should be named General
      expect(find.byKey(const Key('chapter-section-Pathology-General')), findsOneWidget);
      expect(find.text('General'), findsWidgets);

      // Expand General chapter
      await tester.tap(find.byKey(const Key('chapter-header-Pathology-General')));
      await tester.pumpAndSettle();
      expect(find.text('Blank subtopic question stem'), findsOneWidget);
    });

    testWidgets('verifies tri-state checkbox transitions: false -> true -> indeterminate -> true -> false', (tester) async {
      final repo = await fixtureRepository();
      await repo.toggleBookmark('test-a'); // Anatomy Topic A
      await repo.toggleBookmark('test-b'); // Anatomy Topic B

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      final anatomyCheckboxFinder = find.byKey(const Key('subject-checkbox-Anatomy'));

      // Initially fully selected
      expect((tester.widget(anatomyCheckboxFinder) as Checkbox).value, isTrue);

      // Deselect All -> checkbox is false
      await tester.tap(find.byKey(const Key('deselect-all-button')));
      await tester.pumpAndSettle();
      expect((tester.widget(anatomyCheckboxFinder) as Checkbox).value, isFalse);

      // Expand Anatomy
      await tester.tap(find.byKey(const Key('subject-header-Anatomy')));
      await tester.pumpAndSettle();

      // Select Topic A -> checkbox becomes indeterminate (null)
      await tester.tap(find.byKey(const Key('chapter-checkbox-Anatomy-Topic A')));
      await tester.pumpAndSettle();
      expect((tester.widget(anatomyCheckboxFinder) as Checkbox).value, isNull);

      // Select Topic B -> checkbox becomes true
      await tester.tap(find.byKey(const Key('chapter-checkbox-Anatomy-Topic B')));
      await tester.pumpAndSettle();
      expect((tester.widget(anatomyCheckboxFinder) as Checkbox).value, isTrue);

      // Tap subject checkbox -> deselects all -> false
      await tester.tap(anatomyCheckboxFinder);
      await tester.pumpAndSettle();
      expect((tester.widget(anatomyCheckboxFinder) as Checkbox).value, isFalse);
    });

    testWidgets('renders cleanly without overflow on narrow 360x800 viewport with 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(() {
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = await fixtureRepository();
      await repo.toggleBookmark('test-a');
      await repo.toggleBookmark('test-b');
      await repo.toggleBookmark('test-c');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Bookmarked Questions (3)'), findsOneWidget);

      // Expand Anatomy and Topic A
      await tester.tap(find.byKey(const Key('subject-header-Anatomy')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('chapter-header-Anatomy-Topic A')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Open Modal on scaled screen
      await tester.tap(find.text('Practice Selected (3)'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Practice Configuration'), findsOneWidget);
    });
  });

  group('Tier 3: Cross-Feature Combinations', () {
    testWidgets('Select All then deselecting one chapter updates indeterminate state and modal count', (tester) async {
      final repo = await fixtureRepository();
      await repo.toggleBookmark('test-a'); // Anatomy -> Topic A
      await repo.toggleBookmark('test-b'); // Anatomy -> Topic B
      await repo.toggleBookmark('test-c'); // Physiology -> Topic C

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Expand Anatomy and uncheck Topic A
      await tester.tap(find.byKey(const Key('subject-header-Anatomy')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chapter-checkbox-Anatomy-Topic A')));
      await tester.pumpAndSettle();

      expect(find.text('2 of 3 selected'), findsOneWidget);
      expect(find.text('Practice Selected (2)'), findsOneWidget);

      final anatomyCheckboxFinder = find.byKey(const Key('subject-checkbox-Anatomy'));
      expect((tester.widget(anatomyCheckboxFinder) as Checkbox).value, isNull);

      // Open modal -> header reflects 2 selected
      await tester.tap(find.text('Practice Selected (2)'));
      await tester.pumpAndSettle();
      expect(find.text('2 Selected Bookmarked Questions'), findsOneWidget);
      expect(find.text('Start Session (2 MCQs)'), findsOneWidget);
    });

    testWidgets('unbookmarking an actively selected question prunes it from selection and decrements count', (tester) async {
      final repo = await fixtureRepository();
      await repo.toggleBookmark('test-a'); // Anatomy -> Topic A
      await repo.toggleBookmark('test-b'); // Anatomy -> Topic B
      await repo.toggleBookmark('test-c'); // Physiology -> Topic C

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 of 3 selected'), findsOneWidget);

      // Expand Anatomy -> Topic A
      await tester.tap(find.byKey(const Key('subject-header-Anatomy')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chapter-header-Anatomy-Topic A')));
      await tester.pumpAndSettle();

      // Unbookmark test-a
      await tester.tap(find.byKey(const Key('unbookmark-test-a')));
      await tester.pumpAndSettle();

      // 2 remaining, both still selected
      expect(find.text('Bookmarked Questions (2)'), findsOneWidget);
      expect(find.text('2 of 2 selected'), findsOneWidget);
      expect(find.text('Practice Selected (2)'), findsOneWidget);
    });

    testWidgets('configures Exam Mode with Total Exam timer, shuffled options, and launches session', (tester) async {
      final repo = await fixtureRepository();
      await repo.toggleBookmark('test-a');
      await repo.toggleBookmark('test-b');
      await repo.toggleBookmark('test-c');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Practice Selected (3)'));
      await tester.pumpAndSettle();

      // Select Exam Mode
      await tester.tap(find.text('Exam Mode'));
      await tester.pumpAndSettle();

      // Select Total Exam timer
      await tester.tap(find.text('Total Exam'));
      await tester.pumpAndSettle();

      // Toggle Shuffle Options
      await tester.scrollUntilVisible(
        find.text('Shuffle Options (A, B, C, D)'),
        100.0,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Shuffle Options (A, B, C, D)'));
      await tester.pumpAndSettle();

      // Start Session
      await tester.tap(find.text('Start Session (3 MCQs)'));
      await tester.pumpAndSettle();

      expect(find.byType(McqSessionScreen), findsOneWidget);
      final session = tester.widget<McqSessionScreen>(find.byType(McqSessionScreen));
      expect(session.questions.length, 3);
      expect(session.config.mode, TestMode.exam);
      expect(session.config.timerType, TimerType.totalExam);
      expect(session.config.shuffleOptions, isTrue);
    });
  });

  group('Tier 4: Real-World Scenarios', () {
    testWidgets('Scenario 1: Complete student workflow across multiple subjects, targeted selection, and exam practice', (tester) async {
      final repo = await fixtureRepository();
      await repo.toggleBookmark('test-a'); // Anatomy -> Topic A
      await repo.toggleBookmark('test-b'); // Anatomy -> Topic B
      await repo.toggleBookmark('test-c'); // Physiology -> Topic C

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Student verifies initial state
      expect(find.text('Bookmarked Questions (3)'), findsOneWidget);
      expect(find.text('3 of 3 selected'), findsOneWidget);

      // 2. Student decides to deselect Topic B in Anatomy
      await tester.tap(find.byKey(const Key('subject-header-Anatomy')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chapter-checkbox-Anatomy-Topic B')));
      await tester.pumpAndSettle();

      expect(find.text('2 of 3 selected'), findsOneWidget);
      expect(find.text('Practice Selected (2)'), findsOneWidget);

      // 3. Student opens practice configuration
      await tester.tap(find.text('Practice Selected (2)'));
      await tester.pumpAndSettle();

      // 4. Student chooses Exam Mode
      await tester.tap(find.text('Exam Mode'));
      await tester.pumpAndSettle();

      // 5. Student launches session
      await tester.tap(find.text('Start Session (2 MCQs)'));
      await tester.pumpAndSettle();

      // 6. Verifies session correctly launched with chosen subset
      expect(find.byType(McqSessionScreen), findsOneWidget);
      final session = tester.widget<McqSessionScreen>(find.byType(McqSessionScreen));
      expect(session.questions.length, 2);
      expect(session.config.mode, TestMode.exam);
      expect(session.questions.any((q) => q.id == 'test-b'), isFalse);
    });

    testWidgets('Scenario 2: Prune to Empty State workflow unbookmarking across multiple subjects', (tester) async {
      final repo = await fixtureRepository();
      await repo.toggleBookmark('test-a'); // Anatomy
      await repo.toggleBookmark('test-c'); // Physiology

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Unbookmark test-a
      await tester.tap(find.byKey(const Key('subject-header-Anatomy')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chapter-header-Anatomy-Topic A')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('unbookmark-test-a')));
      await tester.pumpAndSettle();

      // Anatomy is gone, only Physiology remains
      expect(find.byKey(const Key('subject-card-Anatomy')), findsNothing);
      expect(find.byKey(const Key('subject-card-Physiology')), findsOneWidget);
      expect(find.text('Bookmarked Questions (1)'), findsOneWidget);

      // Unbookmark test-c
      await tester.tap(find.byKey(const Key('subject-header-Physiology')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chapter-header-Physiology-Topic C')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('unbookmark-test-c')));
      await tester.pumpAndSettle();

      // Completely empty state
      expect(find.text('Bookmarked Questions (0)'), findsOneWidget);
      expect(find.text('No bookmarked questions yet'), findsOneWidget);
      expect(find.byKey(const Key('subject-card-Physiology')), findsNothing);
      expect(find.textContaining('Practice Selected'), findsNothing);
    });

    testWidgets('Scenario 3: Subset custom practice drill with > 5 questions', (tester) async {
      final repo = await _createSixQuestionRepo();
      await repo.toggleBookmark('anat-1');
      await repo.toggleBookmark('anat-2');
      await repo.toggleBookmark('anat-3');
      await repo.toggleBookmark('phys-1');
      await repo.toggleBookmark('phys-2');
      await repo.toggleBookmark('phys-3');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bookmarked Questions (6)'), findsOneWidget);
      expect(find.text('6 of 6 selected'), findsOneWidget);

      await tester.tap(find.text('Practice Selected (6)'));
      await tester.pumpAndSettle();

      // Subset chip '5' should be visible since totalAvailable >= 5
      final chip5 = find.widgetWithText(ChoiceChip, '5');
      expect(chip5, findsOneWidget);

      await tester.tap(chip5);
      await tester.pumpAndSettle();

      expect(find.text('5 of 6 MCQs'), findsOneWidget);
      expect(find.text('Start Session (5 MCQs)'), findsOneWidget);

      await tester.tap(find.text('Start Session (5 MCQs)'));
      await tester.pumpAndSettle();

      expect(find.byType(McqSessionScreen), findsOneWidget);
      final session = tester.widget<McqSessionScreen>(find.byType(McqSessionScreen));
      expect(session.questions.length, 5);
      expect(session.config.questionCount, 5);
    });

    testWidgets('Scenario 4: Rapid selection cycling (Select All, Deselect All, Chapter toggling, and button state integrity)', (tester) async {
      final repo = await fixtureRepository();
      await repo.toggleBookmark('test-a');
      await repo.toggleBookmark('test-b');
      await repo.toggleBookmark('test-c');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Cycle 1: Deselect All
      await tester.tap(find.byKey(const Key('deselect-all-button')));
      await tester.pumpAndSettle();
      expect(find.text('0 of 3 selected'), findsOneWidget);
      expect((tester.widget(find.widgetWithText(AppButton, 'Practice Selected (0)')) as AppButton).onPressed, isNull);

      // Cycle 2: Select All
      await tester.tap(find.byKey(const Key('select-all-button')));
      await tester.pumpAndSettle();
      expect(find.text('3 of 3 selected'), findsOneWidget);
      expect((tester.widget(find.widgetWithText(AppButton, 'Practice Selected (3)')) as AppButton).onPressed, isNotNull);

      // Cycle 3: Deselect All again
      await tester.tap(find.byKey(const Key('deselect-all-button')));
      await tester.pumpAndSettle();
      expect(find.text('0 of 3 selected'), findsOneWidget);

      // Cycle 4: Select individual chapter (Topic A in Anatomy)
      await tester.tap(find.byKey(const Key('subject-header-Anatomy')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chapter-checkbox-Anatomy-Topic A')));
      await tester.pumpAndSettle();
      expect(find.text('1 of 3 selected'), findsOneWidget);
      expect((tester.widget(find.widgetWithText(AppButton, 'Practice Selected (1)')) as AppButton).onPressed, isNotNull);

      // Cycle 5: Re-select all
      await tester.tap(find.byKey(const Key('select-all-button')));
      await tester.pumpAndSettle();
      expect(find.text('3 of 3 selected'), findsOneWidget);
    });

    testWidgets('Scenario 5: Narrow 360x800 viewport with 1.5x font scale complete walkthrough', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(() {
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = await fixtureRepository();
      await repo.toggleBookmark('test-a');
      await repo.toggleBookmark('test-b');
      await repo.toggleBookmark('test-c');
      await repo.saveQuestionNote('test-a', 'Extensive study note under high accessibility text scaling');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BookmarksScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Expand Anatomy
      await tester.tap(find.byKey(const Key('subject-header-Anatomy')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Expand Topic A
      await tester.tap(find.byKey(const Key('chapter-header-Anatomy-Topic A')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Verify question card renders cleanly
      expect(find.text('Extensive study note under high accessibility text scaling'), findsOneWidget);

      // Open Modal
      await tester.tap(find.text('Practice Selected (3)'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Scroll inside modal
      await tester.scrollUntilVisible(
        find.text('Start Session (3 MCQs)'),
        100.0,
        scrollable: find.byType(Scrollable).last,
      );
      expect(tester.takeException(), isNull);

      // Close modal
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
