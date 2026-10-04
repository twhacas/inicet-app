import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inicet_app/data/question_repository.dart';
import 'package:inicet_app/data/question_storage.dart';
import 'package:inicet_app/domain/models/test_config.dart';
import 'package:inicet_app/domain/models/test_result.dart';

import 'support/question_fixtures.dart';

TestSessionResult savedResult(String id) => TestSessionResult(
  id: id,
  config: const TestConfig(
    selectedSubjects: {'Anatomy'},
    selectedSubTopics: {},
    questionCount: 1,
  ),
  questions: [fixtureQuestions.first],
  userAnswers: const {0: UserAnswer(questionIndex: 0, selectedOptionIndex: 0)},
  startedAt: DateTime(2026, 10, 2),
  completedAt: DateTime(2026, 10, 2, 0, 1),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late FileQuestionStorage storage;
  setUp(() {
    directory = Directory('${Directory.current.path}/.dart_tool')
        .createTempSync('inicet-storage-regression-');
    storage = FileQuestionStorage(directory: () async => directory);
  });
  tearDown(() {
    for (final entry in directory.listSync()) {
      if (entry is Directory) entry.deleteSync();
      if (entry is File) entry.deleteSync();
    }
    directory.deleteSync();
  });

  test(
    'real local files restore notes, bookmarks and history in a new repository',
    () async {
      final repo = QuestionRepository(
        storage: storage,
        bundle: FixtureQuestionBundle(),
      );
      await repo.init();
      await repo.saveQuestionNote('test-a', 'Durable note');
      await repo.toggleBookmark('test-a');
      await repo.saveTestSession(savedResult('durable'));
      final restored = QuestionRepository(
        storage: FileQuestionStorage(directory: () async => directory),
        bundle: FixtureQuestionBundle(),
      );
      await restored.init();
      expect(restored.getQuestionNote('test-a'), 'Durable note');
      expect(restored.getBookmarkedQuestions().single.id, 'test-a');
      expect((await restored.getPastTestSessions()).single.correctCount, 1);
    },
  );

  test(
    'an interrupted replacement keeps the previous committed file readable',
    () async {
      await storage.write('user_notes.json', '{"test-a":"Previous note"}');
      final original = File('${directory.path}/user_notes.json');
      await original.rename('${original.path}.previous');
      await File('${original.path}.pending').writeAsString('{incomplete');
      expect(
        await storage.read('user_notes.json'),
        '{"test-a":"Previous note"}',
      );
      await storage.write('user_notes.json', '{"test-a":"New note"}');
      expect(await storage.read('user_notes.json'), '{"test-a":"New note"}');
    },
  );

  test(
    'a failed file write raises an error without replacing committed data',
    () async {
      await storage.write('user_notes.json', '{"test-a":"Original"}');
      await Directory('${directory.path}/user_notes.json.pending').create();
      await expectLater(
        storage.write('user_notes.json', '{"test-a":"Changed"}'),
        throwsA(isA<QuestionStorageException>()),
      );
      expect(await storage.read('user_notes.json'), '{"test-a":"Original"}');
    },
  );

  test(
    'corrupt history is preserved and prevents a misleading successful save',
    () async {
      await storage.write('user_history.json', '{broken history');
      final repo = QuestionRepository(
        storage: storage,
        bundle: FixtureQuestionBundle(),
      );
      await repo.init();
      await expectLater(
        repo.getPastTestSessions(),
        throwsA(isA<QuestionStorageException>()),
      );
      await expectLater(
        repo.saveTestSession(savedResult('new')),
        throwsA(isA<QuestionStorageException>()),
      );
      expect(await storage.read('user_history.json'), '{broken history');
    },
  );

  test(
    'overlapping submissions retain both sessions and retries are idempotent',
    () async {
      final repo = QuestionRepository(
        storage: storage,
        bundle: FixtureQuestionBundle(),
      );
      await repo.init();
      await Future.wait([
        repo.saveTestSession(savedResult('first')),
        repo.saveTestSession(savedResult('second')),
        repo.saveTestSession(savedResult('first')),
      ]);
      final history = await repo.getPastTestSessions();
      expect(history.length, 2);
      expect(
        history.map((session) => session.id),
        containsAll(['first', 'second']),
      );
    },
  );
}
