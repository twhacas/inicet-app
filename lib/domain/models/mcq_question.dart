import 'dart:math';

import 'question_metadata.dart';

final class McqQuestion {
  const McqQuestion({
    required this.id,
    required this.subject,
    required this.subTopic,
    required this.stem,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.tag = 'INI-CET',
    this.exam = '',
    this.repeats = 1,
    this.difficulty = 'Moderate',
    this.userNote,
    this.isBookmarked = false,
  });

  factory McqQuestion.fromJson(Map<String, Object?> json) {
    final rawOptions = json['options'];
    if (rawOptions is! List ||
        rawOptions.length != 4 ||
        rawOptions.any(
          (option) => option is! String || option.trim().isEmpty,
        )) {
      throw const FormatException(
        'options must contain four non-empty strings.',
      );
    }
    final options = rawOptions
        .cast<String>()
        .map((option) => option.trim())
        .toList();

    final rawCorrectIndex = json['correctIndex'] ?? json['correct_index'];
    final correctIndex = rawCorrectIndex is int
        ? rawCorrectIndex
        : int.tryParse(rawCorrectIndex?.toString() ?? '');
    if (correctIndex == null ||
        correctIndex < 0 ||
        correctIndex >= options.length) {
      throw const FormatException(
        'correctIndex must be an integer from 0 to 3.',
      );
    }
    final id = json['id']?.toString().trim() ?? '';
    final subject = json['subject']?.toString().trim() ?? '';
    final stem = json['stem']?.toString().trim() ?? '';
    if (id.isEmpty || subject.isEmpty || stem.isEmpty) {
      throw const FormatException('id, subject and stem are required.');
    }
    final tag = json['tag']?.toString().trim() ?? 'INI-CET';
    final exam = json['exam']?.toString().trim() ?? '';

    final rawMeta = json['metadata'];
    var difficulty = json['difficulty']?.toString().trim() ?? 'Moderate';
    if (rawMeta is Map<String, Object?> && rawMeta['difficulty'] != null) {
      difficulty = rawMeta['difficulty'].toString().trim();
    }

    return McqQuestion(
      id: id,
      subject: subject,
      subTopic:
          (json['subTopic'] ?? json['sub_topic'])?.toString().trim() ??
          'General',
      stem: stem,
      options: options,
      correctIndex: correctIndex,
      explanation: json['explanation']?.toString().trim() ?? '',
      tag: tag,
      exam: exam,
      repeats: parseRepeatCount(json['repeats'], tag, exam),
      difficulty: difficulty,
      userNote: json['userNote']?.toString().trim(),
      isBookmarked: json['isBookmarked'] == true,
    );
  }

  final String id;
  final String subject;
  final String subTopic;
  final String stem;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String tag;
  final String exam;
  final int repeats;
  final String difficulty;
  final String? userNote;
  final bool isBookmarked;

  Set<ExamSource> get examSources {
    final sources = parseExamSources(exam);
    // Explicit exam provenance takes precedence over a generic bank tag.
    return sources.isNotEmpty ? sources : parseExamSources(tag);
  }

  bool matchesExam(String filter) {
    if (filter == 'all') return true;
    return parseExamSources(filter).any(examSources.contains);
  }

  String get correctAnswer => correctIndex >= 0 && correctIndex < options.length
      ? options[correctIndex]
      : '';

  McqQuestion copyWith({
    String? id,
    String? subject,
    String? subTopic,
    String? stem,
    List<String>? options,
    int? correctIndex,
    String? explanation,
    String? tag,
    String? exam,
    int? repeats,
    String? difficulty,
    String? userNote,
    bool clearUserNote = false,
    bool? isBookmarked,
  }) {
    return McqQuestion(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      subTopic: subTopic ?? this.subTopic,
      stem: stem ?? this.stem,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      explanation: explanation ?? this.explanation,
      tag: tag ?? this.tag,
      exam: exam ?? this.exam,
      repeats: repeats ?? this.repeats,
      difficulty: difficulty ?? this.difficulty,
      userNote: clearUserNote ? null : userNote ?? this.userNote,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  McqQuestion shuffleOptions({Random? random}) {
    if (options.length <= 1) return this;
    final r = random ?? Random();
    final order = List<int>.generate(options.length, (index) => index)
      ..shuffle(r);
    final shuffled = order.map((index) => options[index]).toList();
    final newCorrectIndex = order.indexOf(correctIndex);
    return copyWith(options: shuffled, correctIndex: newCorrectIndex);
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'subject': subject,
      'subTopic': subTopic,
      'stem': stem,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'tag': tag,
      'exam': exam,
      'repeats': repeats,
      'difficulty': difficulty,
      if (userNote != null && userNote!.isNotEmpty) 'userNote': userNote,
      'isBookmarked': isBookmarked,
    };
  }
}
