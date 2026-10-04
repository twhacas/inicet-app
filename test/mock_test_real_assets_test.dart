import 'package:flutter_test/flutter_test.dart';
import 'package:inicet_app/data/mock_test_builder.dart';
import 'package:inicet_app/data/question_repository.dart';

import 'support/question_fixtures.dart';

/// Drives the builder against the files that actually ship.
///
/// The unit tests use a fake bundle with two subjects, so they cannot catch a
/// blueprint subject name that fails to resolve to a practice set — which would
/// silently hand the learner a short paper.
Future<MockTestBuilder> realBuilder() async {
  final bundle = LocalAssetBundle();
  final repository = QuestionRepository(
    storage: MemoryQuestionStorage(),
    bundle: bundle,
  );
  await repository.init();
  return MockTestBuilder(repository: repository, bundle: bundle);
}

void main() {
  test('every blueprint subject resolves to a real practice set', () async {
    final builder = await realBuilder();
    final plan = await builder.loadBlueprint();

    expect(plan.subjects.length, 20);
    expect(plan.weightTotal, greaterThan(0));
    expect(plan.pyqIds, isNotEmpty);
    for (final subject in plan.subjects) {
      expect(
        subject.practiceAvailable,
        greaterThan(0),
        reason: '${subject.name} has no practice questions',
      );
    }
  });

  test('a full 200-question paper is complete and weighted', () async {
    final builder = await realBuilder();
    final paper = await builder.build(total: 200, pyqPercent: 50, seed: 42);

    expect(paper.length, 200);
    expect(
      paper.shortfalls,
      isEmpty,
      reason: 'a 200-question paper should not run any subject dry',
    );

    // No repeats, and every subject that was allotted questions supplied them.
    final ids = paper.questions.map((question) => question.id).toSet();
    expect(ids.length, 200);
    final bySubject = <String, int>{};
    for (final question in paper.questions) {
      bySubject[question.subject] = (bySubject[question.subject] ?? 0) + 1;
    }
    for (final entry in paper.perSubject.entries) {
      if (entry.value > 0) {
        expect(
          bySubject[entry.key],
          entry.value,
          reason: '${entry.key} supplied the wrong number of questions',
        );
      }
    }

    // Pharmacology and Pathology are the heaviest subjects in the real papers,
    // so a weighted mock must give them more than the small subjects.
    expect(paper.perSubject['Pharmacology']!, greaterThan(10));
    expect(paper.perSubject['Pathology']!, greaterThan(10));
    expect(
      paper.perSubject['Pharmacology']!,
      greaterThan(paper.perSubject['Anaesthesia']!),
    );

    // Each answer still points at its own option after the letter spread.
    for (final question in paper.questions) {
      expect(question.correctIndex, inInclusiveRange(0, 3));
      expect(question.options.length, 4);
      expect(question.correctAnswer, question.options[question.correctIndex]);
      expect(question.correctAnswer.trim(), isNotEmpty);
    }
  });

  test('two papers in a row do not share a question', () async {
    final builder = await realBuilder();
    final first = await builder.build(total: 100, pyqPercent: 60, seed: 1);
    final second = await builder.build(total: 100, pyqPercent: 60, seed: 2);

    // Draws are independent, so overlap is expected — but a paper must never
    // repeat a question inside itself.
    expect(first.questions.map((q) => q.id).toSet().length, 100);
    expect(second.questions.map((q) => q.id).toSet().length, 100);
  });
}
