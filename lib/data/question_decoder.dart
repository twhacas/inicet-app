import 'dart:convert';

import '../domain/models/mcq_question.dart';

List<McqQuestion> decodeQuestions(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! List || decoded.isEmpty) {
    throw const FormatException('Provide a non-empty JSON array of questions.');
  }
  final ids = <String>{};
  final questions = <McqQuestion>[];
  for (var index = 0; index < decoded.length; index++) {
    final item = decoded[index];
    if (item is! Map<String, Object?>) {
      throw FormatException('Question ${index + 1} must be a JSON object.');
    }
    try {
      final question = McqQuestion.fromJson(item);
      if (!ids.add(question.id)) {
        throw FormatException('Duplicate question id: ${question.id}.');
      }
      questions.add(question);
    } on FormatException catch (error) {
      throw FormatException('Question ${index + 1}: ${error.message}');
    }
  }
  return questions;
}
