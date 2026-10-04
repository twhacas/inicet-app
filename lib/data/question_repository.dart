import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/models/mcq_question.dart';
import '../domain/models/test_config.dart';
import '../domain/models/test_result.dart';
import 'practice_set_catalog.dart';
import 'question_decoder.dart';
import 'question_storage.dart';
import 'test_history_store.dart';

class QuestionRepository extends ChangeNotifier {
  QuestionRepository({
    AssetBundle? bundle,
    QuestionStorage? storage,
    Random? random,
  }) : _bundle = bundle ?? rootBundle,
       _storage = storage ?? FileQuestionStorage(),
       _random = random ?? Random();

  final AssetBundle _bundle;
  final QuestionStorage _storage;
  final Random _random;
  late final _history = TestHistoryStore(_storage);
  List<McqQuestion> _allQuestions = [];
  final Map<String, McqQuestion> _practiceQuestions = {};
  Set<String> _bookmarkedIds = {};
  Map<String, String> _userNotes = {};
  bool _isInitialized = false;
  Future<void>? _initialization;
  Future<void> _mutations = Future.value();

  static const _bundledAssetPath =
      'assets/fixtures/subject_data/questions_bank.json';
  bool get isInitialized => _isInitialized;
  List<McqQuestion> get allQuestions =>
      List.unmodifiable(_allQuestions.map(_withUserData));

  Future<void> init() {
    if (_isInitialized) return Future.value();
    return _initialization ??= _load().whenComplete(
      () => _initialization = null,
    );
  }

  void _notifyChanged() {
    if (hasListeners) notifyListeners();
  }

  Future<void> _load() async {
    final custom = await _storage.read('user_questions.json');
    final questions = decodeQuestions(
      custom ?? await _bundle.loadString(_bundledAssetPath),
    );
    final bookmarkContents = await _storage.read('user_bookmarks.json');
    final noteContents = await _storage.read('user_notes.json');
    try {
      final bookmarks = bookmarkContents == null
          ? <Object?>[]
          : jsonDecode(bookmarkContents);
      final notes = noteContents == null
          ? <String, Object?>{}
          : jsonDecode(noteContents);
      if (bookmarks is! List ||
          bookmarks.any((id) => id is! String) ||
          notes is! Map<String, Object?> ||
          notes.values.any((note) => note is! String)) {
        throw const FormatException('Invalid saved annotations.');
      }
      _bookmarkedIds = bookmarks.cast<String>().toSet();
      _userNotes = notes.cast<String, String>();
      if (noteContents == null) {
        for (final question in questions) {
          if (question.userNote != null) {
            _userNotes[question.id] = question.userNote!;
          }
        }
      }
    } catch (error) {
      throw QuestionStorageException(
        'Your notes or bookmarks could not be read. The original files have been kept. Please retry.',
        error,
      );
    }
    _allQuestions = questions;
    final unresolved = _bookmarkedIds.difference(
      questions.map((q) => q.id).toSet(),
    );
    for (final name in practiceSetFileMap.values.toSet()) {
      if (unresolved.isEmpty) break;
      await _loadPracticeFile(name);
      unresolved.removeAll(_practiceQuestions.keys);
    }
    _isInitialized = true;
    _notifyChanged();
  }

  McqQuestion _withUserData(McqQuestion question) => question.copyWith(
    isBookmarked: _bookmarkedIds.contains(question.id),
    userNote: _userNotes[question.id],
    clearUserNote: !_userNotes.containsKey(question.id),
  );

  List<String> getAvailableSubjects() =>
      _allQuestions.map((q) => q.subject).toSet().toList()..sort();

  List<String> getSubTopicsForSubject(String subject) =>
      _allQuestions
          .where((q) => q.subject == subject)
          .map((q) => q.subTopic)
          .toSet()
          .toList()
        ..sort();

  int getFilteredCount({
    Set<String>? selectedSubjects,
    Map<String, Set<String>>? selectedSubTopics,
    String examFilter = 'all',
    bool repeatsOnly = false,
  }) => _filterQuestions(
    selectedSubjects: selectedSubjects,
    selectedSubTopics: selectedSubTopics ?? const {},
    examFilter: examFilter,
    repeatsOnly: repeatsOnly,
  ).length;

  List<McqQuestion> _filterQuestions({
    Set<String>? selectedSubjects,
    required Map<String, Set<String>> selectedSubTopics,
    String examFilter = 'all',
    bool repeatsOnly = false,
  }) {
    return _allQuestions
        .where((question) {
          if (selectedSubjects != null &&
              !selectedSubjects.contains(question.subject)) {
            return false;
          }
          final topics = selectedSubTopics[question.subject];
          if (topics != null && !topics.contains(question.subTopic)) {
            return false;
          }
          return question.matchesExam(examFilter) &&
              (!repeatsOnly || question.repeats >= 2);
        })
        .map(_withUserData)
        .toList();
  }

  List<McqQuestion> generateTest(TestConfig config) {
    final pool = _filterQuestions(
      selectedSubjects: config.selectedSubjects,
      selectedSubTopics: config.selectedSubTopics,
      examFilter: config.examFilter,
      repeatsOnly: config.repeatsOnly,
    );
    if (config.shuffleQuestions) {
      pool.shuffle(_random);
    }
    if (config.repeatsPriority) {
      pool.sort((a, b) => b.repeats.compareTo(a.repeats));
    }
    final selected = pool
        .take(max(0, min(config.questionCount, pool.length)))
        .toList();
    if (!config.shuffleOptions) return selected;
    return selected.map((q) => q.shuffleOptions(random: _random)).toList();
  }

  Future<T> _mutate<T>(Future<T> Function() action) {
    final result = Completer<T>();
    _mutations = _mutations.then((_) async {
      try {
        result.complete(await action());
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }

  Future<int> importQuestionsFromJsonString(
    String jsonString, {
    bool replace = false,
  }) async {
    final parsed = decodeQuestions(jsonString);
    await init();
    return _mutate(() async {
      final existingIds = _allQuestions.map((q) => q.id).toSet();
      final added = replace
          ? parsed
          : parsed.where((q) => !existingIds.contains(q.id)).toList();
      final next = replace ? added : [..._allQuestions, ...added];
      await _storage.write(
        'user_questions.json',
        jsonEncode(next.map((q) => q.toJson()).toList()),
      );
      _allQuestions = List.of(next);
      _notifyChanged();
      return added.length;
    });
  }

  Future<String> exportQuestionsToJsonString() async =>
      const JsonEncoder.withIndent('  ')
          .convert(allQuestions.map((q) => q.toJson()).toList());

  Future<void> resetToDefault() => _mutate(() async {
    final questions = decodeQuestions(
      await _bundle.loadString(_bundledAssetPath),
    );
    await _storage.delete('user_questions.json');
    _allQuestions = questions;
    _isInitialized = true;
    _notifyChanged();
  });

  Future<void> toggleBookmark(String questionId) => _mutate(() async {
    final next = Set<String>.of(_bookmarkedIds);
    if (!next.remove(questionId)) next.add(questionId);
    await _storage.write('user_bookmarks.json', jsonEncode(next.toList()));
    _bookmarkedIds = next;
    _notifyChanged();
  });

  bool isBookmarked(String questionId) => _bookmarkedIds.contains(questionId);

  List<McqQuestion> getBookmarkedQuestions() {
    final available = {
      for (final question in _practiceQuestions.values) question.id: question,
      for (final question in _allQuestions) question.id: question,
    };
    return _bookmarkedIds
        .where(available.containsKey)
        .map((id) => _withUserData(available[id]!))
        .toList();
  }

  Future<void> saveQuestionNote(String questionId, String noteText) =>
      _mutate(() async {
        final next = Map<String, String>.of(_userNotes);
        final trimmed = noteText.trim();
        if (trimmed.isEmpty) {
          next.remove(questionId);
        } else {
          next[questionId] = trimmed;
        }
        await _storage.write('user_notes.json', jsonEncode(next));
        _userNotes = next;
        _notifyChanged();
      });

  String? getQuestionNote(String questionId) => _userNotes[questionId];

  Future<void> saveTestSession(TestSessionResult result) => _mutate(() async {
    await _history.save(result);
    _notifyChanged();
  });

  Future<List<TestSessionResult>> getPastTestSessions() async {
    await _mutations;
    return _history.read();
  }

  Future<void> deleteTestSession(String id) => _mutate(() async {
    await _history.delete(id);
    _notifyChanged();
  });

  Future<void> clearTestHistory() => _mutate(() async {
    await _history.clear();
    _notifyChanged();
  });

  Future<List<McqQuestion>> _loadPracticeFile(String name) async {
    final questions = decodeQuestions(
      await _bundle.loadString('assets/fixtures/practice_sets/$name'),
    );
    for (final question in questions) {
      _practiceQuestions[question.id] = question;
    }
    return questions.map(_withUserData).toList();
  }

  Future<List<McqQuestion>> loadPracticeSet(String subject) async {
    final normalized = subject.toLowerCase().trim();
    final name = practiceSetFileMap[normalized];
    if (name == null) {
      return allQuestions
          .where((q) => q.subject.toLowerCase() == normalized)
          .toList();
    }
    return _loadPracticeFile(name);
  }

  List<Map<String, dynamic>> getPracticeSetsOverview() => practiceSetsOverview;
}
