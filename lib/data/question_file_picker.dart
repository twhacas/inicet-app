import 'dart:io';

import 'package:file_picker/file_picker.dart';

class PickedQuestionFile {
  const PickedQuestionFile(this.name, this.contents);
  final String name;
  final String contents;
}

Future<PickedQuestionFile?> pickQuestionJsonFile() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (files.isEmpty) return null;
  final path = files.first.path;
  if (path == null) {
    throw const FormatException(
      'The selected file could not be read. Try pasting its JSON instead.',
    );
  }
  return PickedQuestionFile(files.first.name, await File(path).readAsString());
}
