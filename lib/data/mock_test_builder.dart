import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../domain/models/mcq_question.dart';
import '../domain/models/mock_blueprint.dart';
import 'question_repository.dart';

/// Result of assembling one mock paper.
final class MockPaper {
  const MockPaper({
    required this.questions,
    required this.perSubject,
    required this.pyqCount,
    required this.practiceCount,
    required this.shortfalls,
  });

  final List<McqQuestion> questions;
  final Map<String, int> perSubject;
  final int pyqCount;
  final int practiceCount;

  /// Subjects that could not supply their full share, and by how many.
  final Map<String, int> shortfalls;

  int get length => questions.length;
}

/// Assembles a blueprint-weighted mock paper from the questions already
/// bundled with the app, drawing a fresh random selection on every call.
///
/// Two pools feed a paper. Previous-year questions come from the bundled bank,
/// restricted to the ids the blueprint vouches for. Practice questions come
/// from the authored per-subject sets. The learner chooses the mix.
class MockTestBuilder {
  MockTestBuilder({required this.repository, AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const blueprintAsset = 'assets/fixtures/mock_tests/blueprint.json';

  final QuestionRepository repository;
  final AssetBundle _bundle;

  MockBlueprint? _blueprint;
  final Map<String, List<McqQuestion>> _practiceCache = {};

  MockBlueprint? get blueprint => _blueprint;

  Future<MockBlueprint> loadBlueprint() async {
    final cached = _blueprint;
    if (cached != null) return cached;
    final decoded = jsonDecode(await _bundle.loadString(blueprintAsset));
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('blueprint.json must be a JSON object.');
    }
    return _blueprint = MockBlueprint.fromJson(decoded);
  }

  /// Build a paper of [total] questions, [pyqPercent] of them previous-year.
  ///
  /// Pass [seed] to reproduce a paper; omit it for a new draw each time.
  Future<MockPaper> build({
    required int total,
    required int pyqPercent,
    int? seed,
    bool interleaveSubjects = true,
  }) async {
    assert(total > 0, 'A paper needs at least one question.');
    assert(
      pyqPercent >= 0 && pyqPercent <= 100,
      'pyqPercent must be a percentage.',
    );
    final plan = await loadBlueprint();
    await repository.init();

    final random = Random(seed);
    final perSubject = plan.allocate(total);
    final bankBySubject = _groupBankQuestions(plan);

    final selected = <McqQuestion>[];
    final taken = <String>{};
    final shortfalls = <String, int>{};
    var pyqCount = 0;
    var practiceCount = 0;

    for (final subject in plan.subjects) {
      final wanted = perSubject[subject.name] ?? 0;
      if (wanted == 0) continue;

      final pyqPool = bankBySubject[subject.bankSubject] ?? const [];
      final practicePool = await _practiceQuestions(subject);

      var wantPyq = (wanted * pyqPercent / 100).round();
      if (wantPyq > wanted) wantPyq = wanted;
      final wantPractice = wanted - wantPyq;

      final fromPyq = _draw(pyqPool, taken, wantPyq, random, subject.name);
      final fromPractice = _draw(
        practicePool,
        taken,
        wantPractice,
        random,
        subject.name,
      );
      selected.addAll(fromPyq);
      selected.addAll(fromPractice);
      pyqCount += fromPyq.length;
      practiceCount += fromPractice.length;

      // A thin pool must not shrink the paper, so top up from the other one.
      var missing = wanted - fromPyq.length - fromPractice.length;
      if (missing > 0) {
        final topUpPyq = _draw(pyqPool, taken, missing, random, subject.name);
        selected.addAll(topUpPyq);
        pyqCount += topUpPyq.length;
        missing -= topUpPyq.length;
      }
      if (missing > 0) {
        final topUpPractice = _draw(
          practicePool,
          taken,
          missing,
          random,
          subject.name,
        );
        selected.addAll(topUpPractice);
        practiceCount += topUpPractice.length;
        missing -= topUpPractice.length;
      }
      if (missing > 0) shortfalls[subject.name] = missing;
    }

    final ordered = interleaveSubjects
        ? _interleave(selected, plan)
        : selected;
    return MockPaper(
      questions: _spreadAnswerLetters(ordered, random),
      perSubject: perSubject,
      pyqCount: pyqCount,
      practiceCount: practiceCount,
      shortfalls: shortfalls,
    );
  }

  Map<String, List<McqQuestion>> _groupBankQuestions(MockBlueprint plan) {
    final grouped = <String, List<McqQuestion>>{};
    for (final question in repository.allQuestions) {
      if (!plan.pyqIds.contains(question.id)) continue;
      grouped.putIfAbsent(question.subject, () => []).add(question);
    }
    return grouped;
  }

  Future<List<McqQuestion>> _practiceQuestions(
    MockSubjectWeight subject,
  ) async {
    final cached = _practiceCache[subject.name];
    if (cached != null) return cached;
    final questions = await repository.loadPracticeSet(subject.name);
    return _practiceCache[subject.name] = questions;
  }

  /// Draw [wanted] unused questions, relabelled to [canonicalSubject].
  ///
  /// The two pools spell six subjects differently — the bank says
  /// "Forensic Medicine & Toxicology" where the practice set says
  /// "Forensic Medicine", and likewise for Anaesthesia, ENT, PSM,
  /// Orthopaedics and Paediatrics. Left alone, one paper would report that
  /// subject's accuracy under two separate headings, so every drawn question
  /// takes the blueprint's name for its subject.
  List<McqQuestion> _draw(
    List<McqQuestion> pool,
    Set<String> taken,
    int wanted,
    Random random,
    String canonicalSubject,
  ) {
    if (wanted <= 0 || pool.isEmpty) return const [];
    final available = pool
        .where((question) => !taken.contains(question.id))
        .toList()
      ..shuffle(random);
    final chosen = available.take(wanted).toList();
    taken.addAll(chosen.map((question) => question.id));
    return [
      for (final question in chosen)
        question.subject == canonicalSubject
            ? question
            : question.copyWith(subject: canonicalSubject),
    ];
  }

  /// Spread each subject through the paper, so it switches subjects the way a
  /// real paper does instead of running twenty blocks back to back.
  List<McqQuestion> _interleave(
    List<McqQuestion> questions,
    MockBlueprint plan,
  ) {
    if (questions.isEmpty) return questions;
    final order = {
      for (var index = 0; index < plan.subjects.length; index++)
        plan.subjects[index].name: index,
    };
    final grouped = <String, List<McqQuestion>>{};
    for (final question in questions) {
      grouped.putIfAbsent(question.subject, () => []).add(question);
    }
    final placed = <(double, int, McqQuestion)>[];
    for (final entry in grouped.entries) {
      final step = questions.length / entry.value.length;
      for (var position = 0; position < entry.value.length; position++) {
        placed.add((
          (position + 0.5) * step,
          order[entry.key] ?? order.length,
          entry.value[position],
        ));
      }
    }
    placed.sort((a, b) {
      final byPosition = a.$1.compareTo(b.$1);
      return byPosition != 0 ? byPosition : a.$2.compareTo(b.$2);
    });
    return placed.map((row) => row.$3).toList();
  }

  /// Even out which letter is correct, so the paper cannot be gamed by habit.
  ///
  /// The authored sets are already balanced per subject, but a 200-question
  /// draw across twenty subjects is not, and a learner who notices a skew gets
  /// marks the paper did not intend to give.
  List<McqQuestion> _spreadAnswerLetters(
    List<McqQuestion> questions,
    Random random,
  ) {
    if (questions.isEmpty) return questions;
    final targets = <int>[
      for (var index = 0; index < questions.length; index++) index % 4,
    ]..shuffle(random);
    final balanced = <McqQuestion>[];
    for (var index = 0; index < questions.length; index++) {
      final question = questions[index];
      final target = targets[index];
      if (question.correctIndex == target ||
          target >= question.options.length) {
        balanced.add(question);
        continue;
      }
      final options = [...question.options];
      final current = question.correctIndex;
      final swap = options[current];
      options[current] = options[target];
      options[target] = swap;
      balanced.add(question.copyWith(options: options, correctIndex: target));
    }
    return balanced;
  }
}
