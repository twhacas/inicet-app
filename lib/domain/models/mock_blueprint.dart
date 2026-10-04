/// Subject weights recovered from the recorded INI-CET papers, used to shape a
/// mock paper so each subject appears in the proportion the exam asked it.
///
/// Regenerate `assets/fixtures/mock_tests/blueprint.json` with
/// `python scripts/build_mock_tests.py --blueprint-only`.
final class MockSubjectWeight {
  const MockSubjectWeight({
    required this.name,
    required this.weight,
    required this.bankSubject,
    required this.practiceFile,
    required this.pyqAvailable,
    required this.practiceAvailable,
  });

  factory MockSubjectWeight.fromJson(Map<String, Object?> json) {
    final name = json['name']?.toString().trim() ?? '';
    if (name.isEmpty) {
      throw const FormatException('Every blueprint subject needs a name.');
    }
    return MockSubjectWeight(
      name: name,
      weight: _asInt(json['weight']),
      bankSubject: json['bankSubject']?.toString().trim() ?? name,
      practiceFile: json['practiceFile']?.toString().trim() ?? '',
      pyqAvailable: _asInt(json['pyqAvailable']),
      practiceAvailable: _asInt(json['practiceAvailable']),
    );
  }

  final String name;

  /// Questions this subject contributed to the blueprint years.
  final int weight;

  /// How the bundled question bank spells this subject.
  final String bankSubject;

  /// Practice-set asset holding this subject's authored questions.
  final String practiceFile;

  final int pyqAvailable;
  final int practiceAvailable;
}

final class MockBlueprint {
  const MockBlueprint({
    required this.years,
    required this.recordedTotal,
    required this.subjects,
    required this.pyqIds,
  });

  factory MockBlueprint.fromJson(Map<String, Object?> json) {
    final rawSubjects = json['subjects'];
    if (rawSubjects is! List || rawSubjects.isEmpty) {
      throw const FormatException('Blueprint has no subjects.');
    }
    final subjects = rawSubjects
        .whereType<Map<String, Object?>>()
        .map(MockSubjectWeight.fromJson)
        .toList();
    if (subjects.every((subject) => subject.weight <= 0)) {
      throw const FormatException('Blueprint weights are all zero.');
    }
    final rawYears = json['blueprintYears'];
    final rawIds = json['pyqIds'];
    return MockBlueprint(
      years: rawYears is List
          ? rawYears.map((year) => year.toString()).toList()
          : const [],
      recordedTotal: _asInt(json['recordedTotal']),
      subjects: subjects,
      pyqIds: rawIds is List
          ? rawIds.map((id) => id.toString()).toSet()
          : const <String>{},
    );
  }

  /// INI-CET years the weights were measured over.
  final List<String> years;

  /// Questions recorded across those years, the denominator for every share.
  final int recordedTotal;

  final List<MockSubjectWeight> subjects;

  /// Bank questions that are genuine previous-year questions.
  ///
  /// The bundled bank holds authored practice questions for six subjects, so
  /// membership here is what separates a real past paper from a practice item.
  final Set<String> pyqIds;

  int get weightTotal =>
      subjects.fold(0, (sum, subject) => sum + subject.weight);

  /// Questions per subject for a paper of [total], summing exactly to [total].
  Map<String, int> allocate(int total) {
    final pool = weightTotal;
    if (pool <= 0 || total <= 0) {
      return {for (final subject in subjects) subject.name: 0};
    }
    final exact = <String, double>{};
    final counts = <String, int>{};
    for (final subject in subjects) {
      final share = total * subject.weight / pool;
      exact[subject.name] = share;
      counts[subject.name] = share.floor();
    }
    var shortfall = total - counts.values.fold(0, (sum, value) => sum + value);
    final ranked = subjects.map((subject) => subject.name).toList()
      ..sort((a, b) {
        final remainderA = exact[a]! - exact[a]!.floor();
        final remainderB = exact[b]! - exact[b]!.floor();
        return remainderB.compareTo(remainderA);
      });
    for (final name in ranked) {
      if (shortfall <= 0) break;
      counts[name] = counts[name]! + 1;
      shortfall--;
    }
    return counts;
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
