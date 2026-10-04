import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:inicet_app/data/question_repository.dart';
import 'package:inicet_app/domain/models/test_config.dart';

import 'support/question_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleQuestionsJson = '''
[
  {
    "id": "anat-001",
    "subject": "Anatomy",
    "subTopic": "Head & Neck",
    "stem": "Which cranial nerve emerges from the dorsal aspect of the brainstem?",
    "options": ["Oculomotor (CN III)", "Trochlear (CN IV)", "Abducens (CN VI)", "Trigeminal (CN V)"],
    "correctIndex": 1,
    "explanation": "Trochlear nerve (CN IV) is the only cranial nerve that exits from the dorsal aspect of the midbrain.",
    "tag": "INI-CET 2024",
    "exam": "INI-CET Nov 2024",
    "repeats": 3,
    "difficulty": "Medium"
  },
  {
    "id": "phys-001",
    "subject": "Physiology",
    "subTopic": "Cardiovascular",
    "stem": "What generates the pacemaker potential in the SA node?",
    "options": ["Funny sodium current (If)", "T-type calcium current", "Delayed rectifier potassium current", "L-type calcium current"],
    "correctIndex": 0,
    "explanation": "Hyperpolarization-activated cyclic nucleotide-gated (HCN) channels carry the funny current (If).",
    "tag": "NEET-PG 2023",
    "exam": "NEET-PG 2023",
    "repeats": 1,
    "difficulty": "Hard"
  },
  {
    "id": "anat-002",
    "subject": "Anatomy",
    "subTopic": "Neuroanatomy",
    "stem": "Broca area is located in which anatomical gyrus?",
    "options": ["Inferior frontal gyrus", "Superior temporal gyrus", "Precentral gyrus", "Postcentral gyrus"],
    "correctIndex": 0,
    "explanation": "Broca area comprises Brodmann areas 44 and 45 in the pars opercularis and triangularis of the inferior frontal gyrus.",
    "tag": "AIIMS 2022",
    "exam": "AIIMS Nov 2022",
    "repeats": 2,
    "difficulty": "Easy"
  }
]
''';

  group('QuestionRepository filtering and test generation', () {
    late QuestionRepository repo;

    setUp(() async {
      repo = QuestionRepository(
        storage: MemoryQuestionStorage(),
        bundle: FixtureQuestionBundle(json: sampleQuestionsJson),
      );
      await repo.importQuestionsFromJsonString(
        sampleQuestionsJson,
        replace: true,
      );
    });

    test('Loads imported questions and extracts subjects and subtopics', () {
      expect(repo.allQuestions.length, 3);
      final subjects = repo.getAvailableSubjects();
      expect(subjects, containsAll(['Anatomy', 'Physiology']));

      final anatTopics = repo.getSubTopicsForSubject('Anatomy');
      expect(anatTopics, containsAll(['Head & Neck', 'Neuroanatomy']));
    });

    test('Filters by subject and subtopics correctly', () {
      final anatCount = repo.getFilteredCount(selectedSubjects: {'Anatomy'});
      expect(anatCount, 2);

      final physCount = repo.getFilteredCount(selectedSubjects: {'Physiology'});
      expect(physCount, 1);

      final subTopicCount = repo.getFilteredCount(
        selectedSubjects: {'Anatomy'},
        selectedSubTopics: {
          'Anatomy': {'Neuroanatomy'},
        },
      );
      expect(subTopicCount, 1);
    });

    test('Filters by exam source (all, INI-CET, NEET-PG, AIIMS)', () {
      final iniCetCount = repo.getFilteredCount(examFilter: 'INI-CET');
      expect(iniCetCount, 1);

      final neetPgCount = repo.getFilteredCount(examFilter: 'NEET-PG');
      expect(neetPgCount, 1);

      final aiimsCount = repo.getFilteredCount(examFilter: 'AIIMS');
      expect(aiimsCount, 1);

      final allCount = repo.getFilteredCount(examFilter: 'all');
      expect(allCount, 3);
    });

    test('Filters by 2X+ repeat high-yield questions', () {
      final repeatCount = repo.getFilteredCount(repeatsOnly: true);
      // anat-001 (repeats: 3), anat-002 (repeats: 2)
      expect(repeatCount, 2);
    });

    test('Generates test with requested configuration and limits', () {
      const config = TestConfig(
        title: 'Custom Test',
        mode: TestMode.exam,
        selectedSubjects: {'Anatomy'},
        selectedSubTopics: {},
        questionCount: 1,
        shuffleQuestions: false,
        shuffleOptions: false,
      );

      final testQs = repo.generateTest(config);
      expect(testQs.length, 1);
      expect(testQs.first.subject, 'Anatomy');
    });

    test('Bookmarks toggle and retrieval', () async {
      expect(repo.isBookmarked('anat-001'), false);
      await repo.toggleBookmark('anat-001');
      expect(repo.isBookmarked('anat-001'), true);
      expect(repo.getBookmarkedQuestions().length, 1);
      expect(repo.getBookmarkedQuestions().first.id, 'anat-001');

      await repo.toggleBookmark('anat-001');
      expect(repo.isBookmarked('anat-001'), false);
      expect(repo.getBookmarkedQuestions(), isEmpty);
    });

    test('User notes save and retrieval', () async {
      expect(repo.getQuestionNote('anat-001'), isNull);
      await repo.saveQuestionNote('anat-001', 'CN IV is the only dorsal exit.');
      expect(
        repo.getQuestionNote('anat-001'),
        'CN IV is the only dorsal exit.',
      );

      // Clearing note with empty string
      await repo.saveQuestionNote('anat-001', '   ');
      expect(repo.getQuestionNote('anat-001'), isNull);
    });

    test('Exports questions as valid JSON', () async {
      final exportedJson = await repo.exportQuestionsToJsonString();
      final decoded = jsonDecode(exportedJson);
      expect(decoded, isA<List>());
      expect(decoded.length, 3);
    });

    test(
      'Practice set overview contains 20 subjects with 3,258 total MCQs',
      () {
        final overview = repo.getPracticeSetsOverview();
        expect(overview.length, 20);
        final subjects = overview.map((item) => item['subject']).toList();
        expect(
          subjects,
          containsAll([
            'Anatomy',
            'Physiology',
            'Biochemistry',
            'Pathology',
            'Microbiology',
            'Pharmacology',
            'Forensic Medicine',
            'ENT',
            'PSM',
            'Ophthalmology',
            'General Medicine',
            'General Surgery',
            'Obstetrics',
            'Gynaecology',
            'Pediatrics',
            'Anesthesia',
            'Dermatology',
            'Orthopedics',
            'Psychiatry',
            'Radiology',
          ]),
        );
        final totalCount = overview.fold<int>(
          0,
          (sum, item) => sum + (item['count'] as int),
        );
        expect(totalCount, 3258);
      },
    );
  });
}
