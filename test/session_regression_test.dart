import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inicet_app/data/question_repository.dart';
import 'package:inicet_app/design_system/theme/app_theme.dart';
import 'package:inicet_app/domain/models/test_config.dart';
import 'package:inicet_app/features/result/test_result_screen.dart';
import 'package:inicet_app/features/test/mcq_session_screen.dart';

import 'support/question_fixtures.dart';

Future<void> openSession(
  WidgetTester tester,
  QuestionRepository repo, {
  bool timed = false,
  int seconds = 50,
}) async {
  addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: McqSessionScreen(
        repository: repo,
        questions: fixtureQuestions,
        clock: () => DateTime(2026, 10, 2),
        config: TestConfig(
          selectedSubjects: {'Anatomy', 'Physiology'},
          selectedSubTopics: {},
          questionCount: 3,
          mode: TestMode.exam,
          timerEnabled: timed,
          timePerQuestionSeconds: seconds,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an old result snapshot cannot restore a deleted personal note', (
    tester,
  ) async {
    final repo = await fixtureRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: McqSessionScreen(
          repository: repo,
          questions: [
            fixtureQuestions.first.copyWith(userNote: 'Deleted note'),
          ],
          config: const TestConfig(
            selectedSubjects: {'Anatomy'},
            selectedSubTopics: {},
            questionCount: 1,
            timerEnabled: false,
          ),
        ),
      ),
    );
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpAndSettle();
    expect(find.text('Deleted note'), findsNothing);
    expect(find.byTooltip('Add personal note'), findsOneWidget);
  });
  testWidgets('untimed stopwatch advances and excludes a paused interval', (
    tester,
  ) async {
    final repo = await fixtureRepository();
    await openSession(tester, repo);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('00:03'), findsOneWidget);
    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('00:03'), findsOneWidget);
    await tester.tap(find.text('Resume Test'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('00:05'), findsOneWidget);
  });

  testWidgets(
    'bookmark completion after Next updates only its original question',
    (tester) async {
      final repo = _DelayedBookmarkRepository();
      await repo.init();
      await openSession(tester, repo);
      await tester.tap(find.byTooltip('Bookmark question'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      repo.release.complete();
      await tester.pumpAndSettle();
      expect(find.text('Q2 of 3'), findsOneWidget);
      expect(find.text('Question B'), findsOneWidget);
      expect(repo.getBookmarkedQuestions().single.id, 'test-a');
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();
      expect(find.text('Question A'), findsOneWidget);
      expect(find.byTooltip('Remove bookmark'), findsOneWidget);
    },
  );

  testWidgets(
    'bookmark completion after exiting the screen does not update disposed state',
    (tester) async {
      final repo = _DelayedBookmarkRepository();
      await repo.init();
      await openSession(tester, repo);
      await tester.tap(find.byTooltip('Bookmark question'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      repo.release.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(repo.isBookmarked('test-a'), isTrue);
    },
  );

  testWidgets(
    'deleting a note clears its callout and edit action immediately',
    (tester) async {
      final repo = await fixtureRepository();
      await openSession(tester, repo);
      await tester.tap(find.byTooltip('Add personal note'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Remove this note');
      await tester.tap(find.text('Save Note'));
      await tester.pumpAndSettle();
      expect(find.text('MY HIGH-YIELD NOTE'), findsOneWidget);
      await tester.tap(find.byTooltip('Edit personal note'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('MY HIGH-YIELD NOTE'), findsNothing);
      expect(find.text('Remove this note'), findsNothing);
      expect(find.byTooltip('Add personal note'), findsOneWidget);
      expect(repo.allQuestions.first.userNote, isNull);
    },
  );

  testWidgets(
    'expiration submits once and Back cannot return to an expired session',
    (tester) async {
      final repo = await fixtureRepository();
      await openSession(tester, repo, timed: true, seconds: 1);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byType(TestResultScreen), findsOneWidget);
      expect(find.byType(McqSessionScreen), findsNothing);
      final history = await repo.getPastTestSessions();
      expect(history.length, 1);
      expect(history.single.timedOut, isTrue);
      expect(history.single.totalTimeSpentSeconds, 3);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(McqSessionScreen), findsNothing);
      expect((await repo.getPastTestSessions()).length, 1);
    },
  );

  testWidgets(
    'expiration closes an open note dialog and replaces the session',
    (tester) async {
      final repo = await fixtureRepository();
      await openSession(tester, repo, timed: true, seconds: 1);
      await tester.tap(find.byTooltip('Add personal note'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(McqSessionScreen), findsNothing);
      expect(find.byType(TestResultScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed submission keeps answers and Retry saves a single result',
    (tester) async {
      final storage = MemoryQuestionStorage();
      final repo = await fixtureRepository(storage: storage);
      await openSession(tester, repo);
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      storage.failWrites = true;
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit Now'));
      await tester.pumpAndSettle();
      expect(find.text('Test not saved'), findsOneWidget);
      expect(find.text('Solved: 1'), findsOneWidget);
      expect(find.byType(TestResultScreen), findsNothing);
      storage.failWrites = false;
      await tester.tap(find.text('Retry Save'));
      await tester.pumpAndSettle();
      expect(find.byType(TestResultScreen), findsOneWidget);
      final history = await repo.getPastTestSessions();
      expect(history.length, 1);
      expect(history.single.correctCount, 1);
    },
  );

  testWidgets('a narrow session keeps navigation and actions reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = await fixtureRepository();
    await openSession(tester, repo);
    expect(find.byTooltip('Session options'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    await tester.tap(find.byTooltip('Session options'));
    await tester.pumpAndSettle();
    expect(find.text('Add personal note'), findsOneWidget);
    expect(find.text('Question palette'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _DelayedBookmarkRepository extends QuestionRepository {
  _DelayedBookmarkRepository()
    : super(storage: MemoryQuestionStorage(), bundle: FixtureQuestionBundle());
  final release = Completer<void>();
  @override
  Future<void> toggleBookmark(String id) async {
    await release.future;
    await super.toggleBookmark(id);
  }
}
