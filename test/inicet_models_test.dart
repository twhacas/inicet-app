import 'package:flutter_test/flutter_test.dart';
import 'package:inicet_app/domain/content/inicet_models.dart';

void main() {
  test('InicetSubjectStats deserializes correctly', () {
    final json = {
      'key': '1. Anatomy',
      'title': 'ANATOMY',
      'ini_questions': 151,
      'aiims_questions': 119,
      'neet_questions': 92,
      'total_extracted': 362,
      'unique_mapped_points': 287,
      'ini_and_neet_overlap': 36,
      'repeated_points': 62,
      'repeat_percent': 21.6,
      'overlap_percent': 12.5,
    };

    final stats = InicetSubjectStats.fromJson(json);

    expect(stats.key, '1. Anatomy');
    expect(stats.title, 'ANATOMY');
    expect(stats.iniQuestions, 151);
    expect(stats.aiimsQuestions, 119);
    expect(stats.neetQuestions, 92);
    expect(stats.totalExtracted, 362);
    expect(stats.uniqueMappedPoints, 287);
    expect(stats.repeatedPoints, 62);
    expect(stats.repeatPercent, 21.6);
    expect(stats.overlapPercent, 12.5);
  });

  test('InicetQuestionPoint deserializes correctly', () {
    final json = {
      'topic': 'UPPER LIMB',
      'tag': 'INI',
      'repeats': 3,
      'stem': "Which structures passes through Guyon's canal",
      'answer': 'Ulnar nerve and artery.',
      'exams_list': ['INI', 'AIIMS', 'NEET'],
      'raw_count': 3,
    };

    final point = InicetQuestionPoint.fromJson(json);

    expect(point.topic, 'UPPER LIMB');
    expect(point.tag, 'INI');
    expect(point.repeats, 3);
    expect(point.stem, contains('Guyon'));
    expect(point.answer, contains('Ulnar nerve'));
    expect(point.examsList, ['INI', 'AIIMS', 'NEET']);
    expect(point.rawCount, 3);
  });

  test('InicetSubjectDetail deserializes correctly', () {
    final json = {
      'topics': ['UPPER LIMB', 'THORAX'],
      'sample_points': [
        {
          'topic': 'UPPER LIMB',
          'tag': 'INI',
          'repeats': 1,
          'stem': 'Question stem',
          'answer': 'Answer text',
          'exams_list': ['INI'],
          'raw_count': 1,
        },
      ],
    };

    final detail = InicetSubjectDetail.fromJson('1. Anatomy', json);

    expect(detail.key, '1. Anatomy');
    expect(detail.topics.length, 2);
    expect(detail.samplePoints.length, 1);
    expect(detail.samplePoints.first.stem, 'Question stem');
  });
}
