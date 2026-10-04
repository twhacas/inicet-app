import 'dart:convert';

import '../domain/models/test_result.dart';
import 'question_storage.dart';

class TestHistoryStore {
  const TestHistoryStore(this.storage);
  final QuestionStorage storage;
  static const fileName = 'user_history.json';

  Future<List<TestSessionResult>> read() async {
    final contents = await storage.read(fileName);
    if (contents == null) return [];
    try {
      final decoded = jsonDecode(contents);
      if (decoded is! List) throw const FormatException('Expected a list.');
      return decoded.map((item) {
        if (item is! Map<String, Object?>) {
          throw const FormatException('Invalid saved test.');
        }
        return TestSessionResult.fromJson(item);
      }).toList();
    } catch (error) {
      throw QuestionStorageException(
        'Your test history could not be read. The original file has been kept. Retry or restore a backup.',
        error,
      );
    }
  }

  Future<void> save(TestSessionResult result) async {
    final id = result.toJson()['id'];
    final history = await read();
    history.removeWhere((session) => session.toJson()['id'] == id);
    history.insert(0, result);
    await _write(history.take(100).toList());
  }

  Future<void> delete(String id) async {
    final history = await read();
    history.removeWhere((session) => session.toJson()['id'] == id);
    await _write(history);
  }

  Future<void> clear() => storage.delete(fileName);

  Future<void> _write(List<TestSessionResult> history) => storage.write(
    fileName,
    jsonEncode(history.map((session) => session.toJson()).toList()),
  );
}
