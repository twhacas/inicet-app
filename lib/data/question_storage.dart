import 'dart:io';

import 'package:path_provider/path_provider.dart';

class QuestionStorageException implements Exception {
  const QuestionStorageException(this.message, [this.cause]);
  final String message;
  final Object? cause;
  @override
  String toString() => message;
}

abstract interface class QuestionStorage {
  Future<String?> read(String name);
  Future<void> write(String name, String contents);
  Future<void> delete(String name);
}

class FileQuestionStorage implements QuestionStorage {
  FileQuestionStorage({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directory;

  Future<File> _file(String name) async {
    try {
      final directory = await _directory();
      await directory.create(recursive: true);
      return File('${directory.path}/$name');
    } catch (error) {
      throw QuestionStorageException(
        'Local storage is unavailable. Please retry. Your saved data has not been reset.',
        error,
      );
    }
  }

  @override
  Future<String?> read(String name) async {
    final file = await _file(name);
    try {
      if (await file.exists()) return await file.readAsString();
      final previous = File('${file.path}.previous');
      // A interrupted replacement can leave the last committed file here.
      if (await previous.exists()) return await previous.readAsString();
      return null;
    } catch (error) {
      throw QuestionStorageException(
        'Could not read your saved data. Please retry; the original files have been kept.',
        error,
      );
    }
  }

  @override
  Future<void> write(String name, String contents) async {
    final file = await _file(name);
    final pending = File('${file.path}.pending');
    final previous = File('${file.path}.previous');
    try {
      await pending.writeAsString(contents, flush: true);
      if (!await file.exists() && await previous.exists()) {
        await previous.rename(file.path);
      }
      if (await file.exists()) {
        if (await previous.exists()) await previous.delete();
        await file.rename(previous.path);
      }
      await pending.rename(file.path);
    } catch (error) {
      // Keep the previous committed file readable if replacement fails.
      throw QuestionStorageException(
        'Could not save your changes. Your previous saved data is still available. Please retry.',
        error,
      );
    }
  }

  @override
  Future<void> delete(String name) async {
    final file = await _file(name);
    try {
      for (final suffix in ['.pending', '.previous', '']) {
        final candidate = File('${file.path}$suffix');
        if (await candidate.exists()) await candidate.delete();
      }
    } catch (error) {
      throw QuestionStorageException(
        'Could not reset the saved data. Please retry.',
        error,
      );
    }
  }
}
