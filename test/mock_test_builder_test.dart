import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inicet_app/data/mock_test_builder.dart';
import 'package:inicet_app/data/question_repository.dart';
import 'package:inicet_app/domain/models/mcq_question.dart';
import 'package:inicet_app/domain/models/mock_blueprint.dart';

import 'support/question_fixtures.dart';

/// The builder reads the blueprint, but the repository loads the bank and the
/// practice sets, so both must share one bundle for a paper to be assembled.
Future<MockTestBuilder> builderWith(MockAssetBundle bundle) async {
  final repository = QuestionRepository(
    storage: MemoryQuestionStorage(),
    bundle: bundle,
  );
  await repository.init();
  return MockTestBuilder(repository: repository, bundle: bundle);
}

/// Bank questions used as the previous-year pool. Ids match `pyqIds` below.
List<Map<String, Object?>> _bank() {
  final questions = <Map<String, Object?>>[];
  for (final subject in ['Anatomy', 'Physiology']) {
    for (var index = 1; index <= 40; index++) {
      questions.add(
        McqQuestion(
          id: '${subject.toLowerCase()}_pyq_$index',
          subject: subject,
          subTopic: 'Past paper',
          stem: '$subject past-paper question $index',
          options: const ['Right', 'Wrong one', 'Wrong two', 'Wrong three'],
          correctIndex: 0,
          explanation: 'Recorded answer.',
        ).toJson(),
      );
    }
  }
  return questions;
}

List<Map<String, Object?>> _practice(String subject, String prefix) {
  return [
    for (var index = 1; index <= 40; index++)
      McqQuestion(
        id: '${prefix}_practice_$index',
        subject: subject,
        subTopic: 'Authored',
        stem: '$subject practice question $index',
        options: const ['Right', 'Wrong one', 'Wrong two', 'Wrong three'],
        correctIndex: 0,
        explanation: 'Authored answer.',
      ).toJson(),
  ];
}

/// Serves the bank, the blueprint and two practice sets from one fake bundle.
class MockAssetBundle extends CachingAssetBundle {
  MockAssetBundle({this.anatomyPyqAvailable = 40});

  final int anatomyPyqAvailable;

  @override
  Future<ByteData> load(String key) async {
    final payload = switch (key) {
      MockTestBuilder.blueprintAsset => jsonEncode({
        'version': 1,
        'blueprintYears': ['2024'],
        'recordedTotal': 30,
        'subjects': [
          {
            'name': 'Anatomy',
            'weight': 20,
            'bankSubject': 'Anatomy',
            'practiceFile': 'anatomy_150.json',
            'pyqAvailable': anatomyPyqAvailable,
            'practiceAvailable': 40,
          },
          {
            'name': 'Physiology',
            'weight': 10,
            'bankSubject': 'Physiology',
            'practiceFile': 'physiology_150.json',
            'pyqAvailable': 40,
            'practiceAvailable': 40,
          },
        ],
        'pyqIds': [
          for (var index = 1; index <= anatomyPyqAvailable; index++)
            'anatomy_pyq_$index',
          for (var index = 1; index <= 40; index++) 'physiology_pyq_$index',
        ],
      }),
      'assets/fixtures/practice_sets/anatomy_150.json' => jsonEncode(
        _practice('Anatomy', 'anat'),
      ),
      'assets/fixtures/practice_sets/physiology_150.json' => jsonEncode(
        _practice('Physiology', 'phys'),
      ),
      _ => jsonEncode(_bank()),
    };
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(payload)));
  }
}

void main() {
  test('blueprint apportions a paper exactly, by recorded weight', () async {
    final plan = await (await builderWith(MockAssetBundle())).loadBlueprint();

    final allocation = plan.allocate(30);
    expect(allocation.values.reduce((a, b) => a + b), 30);
    // Anatomy carries twice Physiology's weight, so twice its questions.
    expect(allocation['Anatomy'], 20);
    expect(allocation['Physiology'], 10);
    // Odd totals still sum exactly rather than losing a question to rounding.
    expect(plan.allocate(7).values.reduce((a, b) => a + b), 7);
    expect(plan.allocate(199).values.reduce((a, b) => a + b), 199);
  });

  test('a paper honours the requested previous-year share', () async {
    final builder = await builderWith(MockAssetBundle());

    final paper = await builder.build(total: 60, pyqPercent: 75, seed: 3);

    expect(paper.length, 60);
    expect(paper.pyqCount, 45);
    expect(paper.practiceCount, 15);
    expect(paper.shortfalls, isEmpty);
    // 2:1 weighting survives into the paper itself.
    final bySubject = <String, int>{};
    for (final question in paper.questions) {
      bySubject[question.subject] = (bySubject[question.subject] ?? 0) + 1;
    }
    expect(bySubject['Anatomy'], 40);
    expect(bySubject['Physiology'], 20);
  });

  test('no question appears twice, and 0% and 100% mixes both work', () async {
    final builder = await builderWith(MockAssetBundle());

    final allPyq = await builder.build(total: 30, pyqPercent: 100, seed: 1);
    expect(allPyq.pyqCount, 30);
    expect(allPyq.practiceCount, 0);

    final allPractice = await builder.build(total: 30, pyqPercent: 0, seed: 1);
    expect(allPractice.pyqCount, 0);
    expect(allPractice.practiceCount, 30);

    final ids = allPractice.questions.map((question) => question.id).toSet();
    expect(ids.length, allPractice.length);
  });

  test('a subject with no previous-year pool is filled from practice', () async {
    final builder = await builderWith(
      MockAssetBundle(anatomyPyqAvailable: 0),
    );

    final paper = await builder.build(total: 30, pyqPercent: 100, seed: 5);

    // The paper keeps its length and its weighting; only the origin changes.
    expect(paper.length, 30);
    expect(paper.shortfalls, isEmpty);
    expect(paper.practiceCount, 20);
    expect(paper.pyqCount, 10);
  });

  test('answers are spread across the options, not parked on A', () async {
    final builder = await builderWith(MockAssetBundle());

    final paper = await builder.build(total: 60, pyqPercent: 50, seed: 11);

    final letters = <int, int>{};
    for (final question in paper.questions) {
      letters[question.correctIndex] = (letters[question.correctIndex] ?? 0) + 1;
    }
    expect(letters.keys.toSet(), {0, 1, 2, 3});
    for (final count in letters.values) {
      expect(count, 15);
    }
    // Swapping options must not break which option is correct.
    for (final question in paper.questions) {
      expect(question.options[question.correctIndex], 'Right');
    }
  });

  test('a malformed blueprint is rejected rather than silently empty', () {
    expect(
      () => MockBlueprint.fromJson(const {'subjects': <Object?>[]}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => MockBlueprint.fromJson(const {
        'subjects': [
          {'name': 'Anatomy', 'weight': 0},
        ],
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
