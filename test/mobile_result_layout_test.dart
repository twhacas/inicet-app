import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inicet_app/design_system/theme/app_theme.dart';
import 'package:inicet_app/domain/models/test_config.dart';
import 'package:inicet_app/domain/models/test_result.dart';
import 'package:inicet_app/features/result/test_result_screen.dart';

import 'support/question_fixtures.dart';

void main() {
  Future<void> openMobileResult(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = await fixtureRepository();
    final result = TestSessionResult(
      config: const TestConfig(
        selectedSubjects: {'Anatomy'},
        selectedSubTopics: {},
        questionCount: 1,
      ),
      questions: [fixtureQuestions.first.copyWith(subTopic: 'General Anatomy')],
      userAnswers: const {
        0: UserAnswer(
          questionIndex: 0,
          selectedOptionIndex: 1,
          isFlagged: true,
        ),
      },
      startedAt: DateTime(2026, 10, 2),
      completedAt: DateTime(2026, 10, 2, 0, 1),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: TestResultScreen(result: result, repository: repo),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('compact score labels remain readable with enlarged text', (
    tester,
  ) async {
    await openMobileResult(tester);
    for (final label in ['Accuracy', 'Correct', 'Incorrect', 'Skipped']) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      expect(
        paragraph
            .getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: label.length),
            )
            .map((box) => box.top)
            .toSet()
            .length,
        1,
        reason: '$label must not split across lines',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'flagged review keeps the bookmark control visible and operable',
    (tester) async {
      await openMobileResult(tester);
      await tester.ensureVisible(find.text('Flagged (1)'));
      await tester.tap(find.text('Flagged (1)'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Bookmark'));
      final bookmark = find.byTooltip('Bookmark');
      final bounds = tester.getRect(bookmark);
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(360));
      await tester.tap(bookmark);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
