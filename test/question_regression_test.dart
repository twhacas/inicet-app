import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:inicet_app/data/question_storage.dart';
import 'package:inicet_app/domain/models/test_config.dart';

import 'support/question_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'practice-set bookmarks survive repository restart and enter the hub',
    () async {
      final storage = MemoryQuestionStorage();
      final repo = await fixtureRepository(storage: storage, bundled: true);
      final practice = await repo.loadPracticeSet('Anatomy');
      expect(practice.length, 150);
      await repo.toggleBookmark(practice.first.id);
      final reloaded = await fixtureRepository(storage: storage, bundled: true);
      expect(
        reloaded.getBookmarkedQuestions().map((q) => q.id),
        contains(practice.first.id),
      );
      expect(reloaded.allQuestions.length, 4303);
    },
  );

  test(
    'deleting a note clears its model, export and restarted state',
    () async {
      final storage = MemoryQuestionStorage();
      final repo = await fixtureRepository(storage: storage);
      await repo.saveQuestionNote('test-a', 'Remove this note');
      await repo.saveQuestionNote('test-a', '');
      expect(repo.allQuestions.first.userNote, isNull);
      expect(
        await repo.exportQuestionsToJsonString(),
        isNot(contains('Remove this note')),
      );
      final reloaded = await fixtureRepository(storage: storage);
      expect(reloaded.getQuestionNote('test-a'), isNull);
    },
  );

  test(
    'empty selected subjects and subtopics mean no matching questions',
    () async {
      final repo = await fixtureRepository();
      expect(repo.getFilteredCount(selectedSubjects: {}), 0);
      expect(
        repo.getFilteredCount(
          selectedSubjects: {'Anatomy'},
          selectedSubTopics: {'Anatomy': {}},
        ),
        0,
      );
      expect(repo.getFilteredCount(), 3);
      expect(
        repo.generateTest(
          const TestConfig(
            selectedSubjects: {},
            selectedSubTopics: {},
            questionCount: 3,
          ),
        ),
        isEmpty,
      );
      expect(
        repo.generateTest(
          const TestConfig(
            selectedSubjects: {'Missing'},
            selectedSubTopics: {},
            questionCount: 3,
          ),
        ),
        isEmpty,
      );
    },
  );

  test(
    'failed imports do not report success or replace the current bank',
    () async {
      final storage = MemoryQuestionStorage();
      final repo = await fixtureRepository(storage: storage);
      storage.failWrites = true;
      final imported = fixtureQuestions.first.copyWith(id: 'new-id');
      await expectLater(
        repo.importQuestionsFromJsonString(
          jsonEncode([imported.toJson()]),
          replace: true,
        ),
        throwsA(isA<QuestionStorageException>()),
      );
      expect(repo.allQuestions.length, 3);
      expect(repo.allQuestions.map((q) => q.id), isNot(contains('new-id')));
      storage.failWrites = false;
      expect(
        await repo.importQuestionsFromJsonString(
          jsonEncode([imported.toJson()]),
        ),
        1,
      );
      final reloaded = await fixtureRepository(storage: storage);
      expect(reloaded.allQuestions.map((q) => q.id), contains('new-id'));
    },
  );

  test(
    'failed annotation writes preserve the previous committed values',
    () async {
      final storage = MemoryQuestionStorage();
      final repo = await fixtureRepository(storage: storage);
      await repo.saveQuestionNote('test-a', 'Original');
      await repo.toggleBookmark('test-a');
      storage.failWrites = true;
      await expectLater(
        repo.saveQuestionNote('test-a', 'Changed'),
        throwsA(isA<QuestionStorageException>()),
      );
      await expectLater(
        repo.toggleBookmark('test-a'),
        throwsA(isA<QuestionStorageException>()),
      );
      expect(repo.getQuestionNote('test-a'), 'Original');
      expect(repo.isBookmarked('test-a'), isTrue);
    },
  );

  test(
    'malformed or duplicate answer data is rejected before any bank change',
    () async {
      final repo = await fixtureRepository();
      for (final answer in [99, -1, null, 'bad']) {
        final invalid = fixtureQuestions.first.toJson()
          ..['correctIndex'] = answer;
        await expectLater(
          repo.importQuestionsFromJsonString(
            jsonEncode([invalid]),
            replace: true,
          ),
          throwsFormatException,
        );
        expect(repo.allQuestions.length, 3);
      }
      await expectLater(
        repo.importQuestionsFromJsonString(
          jsonEncode([
            fixtureQuestions.first.toJson(),
            fixtureQuestions.first.toJson(),
          ]),
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'exam aliases include INI and NEET while explicit exam sources win',
    () async {
      final repo = await fixtureRepository(bundled: true);
      final questions = repo.generateTest(
        TestConfig(
          selectedSubjects: repo.getAvailableSubjects().toSet(),
          selectedSubTopics: {},
          questionCount: 10000,
          examFilter: 'INI-CET',
          shuffleQuestions: false,
          shuffleOptions: false,
        ),
      );
      expect(questions.map((q) => q.id), contains('q_901'));
      expect(questions.map((q) => q.id), isNot(contains('q_10')));
      expect(repo.getFilteredCount(examFilter: 'NEET-PG'), greaterThan(1003));
    },
  );

  test(
    '2X+ excludes 1x tags and repeat priority uses the parsed counts',
    () async {
      final repo = await fixtureRepository(bundled: true);
      final subjects = repo.getAvailableSubjects().toSet();
      final repeated = repo.generateTest(
        TestConfig(
          selectedSubjects: subjects,
          selectedSubTopics: {},
          questionCount: 10000,
          repeatsOnly: true,
          shuffleQuestions: false,
          shuffleOptions: false,
        ),
      );
      expect(repeated, isNotEmpty);
      expect(repeated.every((q) => q.repeats >= 2), isTrue);
      expect(repeated.map((q) => q.id), isNot(contains('q_901')));
      final prioritized = repo.generateTest(
        TestConfig(
          selectedSubjects: subjects,
          selectedSubTopics: {},
          questionCount: 20,
          repeatsPriority: true,
          shuffleOptions: false,
        ),
      );
      for (var index = 1; index < prioritized.length; index++) {
        expect(
          prioritized[index - 1].repeats,
          greaterThanOrEqualTo(prioritized[index].repeats),
        );
      }
    },
  );

  test(
    'overlapping imports retain both batches and count only new questions',
    () async {
      final storage = MemoryQuestionStorage();
      final repo = await fixtureRepository(storage: storage);
      final first = fixtureQuestions.first.copyWith(id: 'batch-1');
      final second = fixtureQuestions.first.copyWith(id: 'batch-2');
      await Future.wait([
        repo.importQuestionsFromJsonString(jsonEncode([first.toJson()])),
        repo.importQuestionsFromJsonString(jsonEncode([second.toJson()])),
      ]);
      final reloaded = await fixtureRepository(storage: storage);
      expect(
        reloaded.allQuestions.map((q) => q.id),
        containsAll(['batch-1', 'batch-2']),
      );
      expect(
        await repo.importQuestionsFromJsonString(jsonEncode([first.toJson()])),
        0,
      );
    },
  );
}
