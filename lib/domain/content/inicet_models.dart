final class InicetSubjectStats {
  const InicetSubjectStats({
    required this.key,
    required this.title,
    required this.iniQuestions,
    required this.aiimsQuestions,
    required this.neetQuestions,
    required this.totalExtracted,
    required this.uniqueMappedPoints,
    required this.iniAndNeetOverlap,
    required this.repeatedPoints,
    required this.repeatPercent,
    required this.overlapPercent,
  });

  factory InicetSubjectStats.fromJson(Map<String, Object?> json) {
    return InicetSubjectStats(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      iniQuestions: (json['ini_questions'] as num?)?.toInt() ?? 0,
      aiimsQuestions: (json['aiims_questions'] as num?)?.toInt() ?? 0,
      neetQuestions: (json['neet_questions'] as num?)?.toInt() ?? 0,
      totalExtracted: (json['total_extracted'] as num?)?.toInt() ?? 0,
      uniqueMappedPoints: (json['unique_mapped_points'] as num?)?.toInt() ?? 0,
      iniAndNeetOverlap: (json['ini_and_neet_overlap'] as num?)?.toInt() ?? 0,
      repeatedPoints: (json['repeated_points'] as num?)?.toInt() ?? 0,
      repeatPercent: (json['repeat_percent'] as num?)?.toDouble() ?? 0.0,
      overlapPercent: (json['overlap_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String key;
  final String title;
  final int iniQuestions;
  final int aiimsQuestions;
  final int neetQuestions;
  final int totalExtracted;
  final int uniqueMappedPoints;
  final int iniAndNeetOverlap;
  final int repeatedPoints;
  final double repeatPercent;
  final double overlapPercent;
}

final class InicetQuestionPoint {
  const InicetQuestionPoint({
    required this.topic,
    required this.tag,
    required this.repeats,
    required this.stem,
    required this.answer,
    required this.examsList,
    required this.rawCount,
  });

  factory InicetQuestionPoint.fromJson(Map<String, Object?> json) {
    final rawExams = json['exams_list'];
    final examsList =
        rawExams is List
            ? rawExams.map((e) => e.toString()).toList()
            : <String>[];

    return InicetQuestionPoint(
      topic: json['topic'] as String? ?? 'General',
      tag: json['tag'] as String? ?? 'INI',
      repeats: (json['repeats'] as num?)?.toInt() ?? 1,
      stem: json['stem'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      examsList: examsList,
      rawCount: (json['raw_count'] as num?)?.toInt() ?? 1,
    );
  }

  final String topic;
  final String tag;
  final int repeats;
  final String stem;
  final String answer;
  final List<String> examsList;
  final int rawCount;
}

final class InicetSubjectDetail {
  const InicetSubjectDetail({
    required this.key,
    required this.topics,
    required this.samplePoints,
  });

  factory InicetSubjectDetail.fromJson(String key, Map<String, Object?> json) {
    final rawTopics = json['topics'];
    final topics =
        rawTopics is List
            ? rawTopics.map((e) => e.toString()).toList()
            : <String>[];

    final rawPoints = json['sample_points'];
    final samplePoints =
        rawPoints is List
            ? rawPoints
                .whereType<Map<String, Object?>>()
                .map(InicetQuestionPoint.fromJson)
                .toList()
            : <InicetQuestionPoint>[];

    return InicetSubjectDetail(
      key: key,
      topics: topics,
      samplePoints: samplePoints,
    );
  }

  final String key;
  final List<String> topics;
  final List<InicetQuestionPoint> samplePoints;
}
