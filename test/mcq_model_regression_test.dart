import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:inicet_app/domain/models/mcq_question.dart';
import 'package:inicet_app/domain/models/test_config.dart';
import 'package:inicet_app/domain/models/test_result.dart';

import 'support/question_fixtures.dart';

void main() {
  test(
    'legacy exports recover repeat counts without treating every x as a repeat',
    () {
      final old = fixtureQuestions.first.toJson()
        ..['tag'] = 'INI (3x)'
        ..['repeats'] = 1;
      expect(McqQuestion.fromJson(old).repeats, 3);
      final single = fixtureQuestions.first.toJson()
        ..['tag'] = 'INI (1x)'
        ..['exam'] = 'Example exam';
      expect(McqQuestion.fromJson(single).repeats, 1);
    },
  );

  test('explicit note clearing differs from an omitted note update', () {
    final annotated = fixtureQuestions.first.copyWith(userNote: 'Stored note');
    expect(annotated.copyWith(isBookmarked: true).userNote, 'Stored note');
    expect(annotated.copyWith(clearUserNote: true).userNote, isNull);
  });

  test(
    'option shuffling tracks the answer identity even with duplicate labels',
    () {
      final question = fixtureQuestions.first.copyWith(
        options: ['Same', 'Same', 'Other', 'Last'],
        correctIndex: 1,
      );
      for (var seed = 0; seed < 20; seed++) {
        final random = Random(seed);
        final order = [0, 1, 2, 3]..shuffle(Random(seed));
        final shuffled = question.shuffleOptions(random: random);
        expect(shuffled.correctIndex, order.indexOf(1));
      }
    },
  );

  test('active session duration and expiry round-trip while old history remains readable', () {
    final result = TestSessionResult(
      config: const TestConfig(
        selectedSubjects: {'Anatomy'},
        selectedSubTopics: {},
        questionCount: 1,
      ),
      questions: [fixtureQuestions.first],
      userAnswers: const {},
      startedAt: DateTime(2026, 10, 2),
      completedAt: DateTime(2026, 10, 2, 0, 2),
      activeTimeSpentSeconds: 15,
      timedOut: true,
    );
    final restored = TestSessionResult.fromJson(result.toJson());
    expect(restored.totalTimeSpentSeconds, 15);
    expect(restored.timedOut, isTrue);
    final legacy = result.toJson()
      ..remove('activeTimeSpentSeconds')
      ..remove('timedOut');
    final old = TestSessionResult.fromJson(legacy);
    expect(old.totalTimeSpentSeconds, 120);
    expect(old.timedOut, isFalse);
  });
}
