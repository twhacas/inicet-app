import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:inicet_app/data/question_repository.dart';
import 'package:inicet_app/data/question_storage.dart';
import 'package:inicet_app/domain/models/mcq_question.dart';

const fixtureQuestions = [
  McqQuestion(
    id: 'test-a',
    subject: 'Anatomy',
    subTopic: 'Topic A',
    stem: 'Question A',
    options: ['Alpha', 'Beta', 'Gamma', 'Delta'],
    correctIndex: 0,
    explanation: 'Alpha is correct.',
  ),
  McqQuestion(
    id: 'test-b',
    subject: 'Anatomy',
    subTopic: 'Topic B',
    stem: 'Question B',
    options: ['One', 'Two', 'Three', 'Four'],
    correctIndex: 0,
    explanation: 'One is correct.',
  ),
  McqQuestion(
    id: 'test-c',
    subject: 'Physiology',
    subTopic: 'Topic C',
    stem: 'Question C',
    options: ['Red', 'Blue', 'Green', 'Gold'],
    correctIndex: 0,
    explanation: 'Red is correct.',
  ),
];

class MemoryQuestionStorage implements QuestionStorage {
  final files = <String, String>{};
  bool failReads = false;
  bool failWrites = false;
  @override
  Future<String?> read(String name) async {
    if (failReads) {
      throw const QuestionStorageException(
        'Storage is unavailable. Please retry.',
      );
    }
    return files[name];
  }

  @override
  Future<void> write(String name, String contents) async {
    if (failWrites) {
      throw const QuestionStorageException(
        'Changes were not saved. Please retry.',
      );
    }
    files[name] = contents;
  }

  @override
  Future<void> delete(String name) async {
    if (failWrites) {
      throw const QuestionStorageException(
        'Changes were not saved. Please retry.',
      );
    }
    files.remove(name);
  }
}

class FixtureQuestionBundle extends CachingAssetBundle {
  FixtureQuestionBundle({String? json})
    : source =
          json ?? jsonEncode(fixtureQuestions.map((q) => q.toJson()).toList());
  final String source;
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(source)));
}

class LocalAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(File(key).readAsBytesSync());
}

Future<QuestionRepository> fixtureRepository({
  MemoryQuestionStorage? storage,
  bool bundled = false,
}) async {
  final repository = QuestionRepository(
    storage: storage ?? MemoryQuestionStorage(),
    bundle: bundled ? LocalAssetBundle() : FixtureQuestionBundle(),
  );
  await repository.init();
  return repository;
}
