import 'dart:collection';

import '../../domain/models/mcq_question.dart';

/// Pure functional grouping utilities for bookmarked questions.
abstract final class BookmarkGroupHelper {
  /// Groups bookmarked questions by Subject (outer key) then Chapter (inner key, from [subTopic]).
  ///
  /// Normalizes whitespace and empty subTopics to 'General'.
  /// Both outer keys (subjects) and inner keys (chapters) are sorted alphabetically.
  static Map<String, Map<String, List<McqQuestion>>> group(
    List<McqQuestion> questions,
  ) {
    final grouped = SplayTreeMap<String, Map<String, List<McqQuestion>>>();

    for (final q in questions) {
      final subject = q.subject.trim().isEmpty ? 'General' : q.subject.trim();
      final rawSubTopic = q.subTopic.trim();
      final chapter = rawSubTopic.isEmpty ? 'General' : rawSubTopic;

      final subjectMap = grouped.putIfAbsent(
        subject,
        () => SplayTreeMap<String, List<McqQuestion>>(),
      );

      final chapterList = subjectMap.putIfAbsent(
        chapter,
        () => <McqQuestion>[],
      );
      chapterList.add(q);
    }

    return grouped;
  }

  /// Calculates total number of bookmarked questions across all subjects and chapters.
  static int totalCount(Map<String, Map<String, List<McqQuestion>>> grouped) {
    var count = 0;
    for (final subjectMap in grouped.values) {
      for (final list in subjectMap.values) {
        count += list.length;
      }
    }
    return count;
  }

  /// Calculates total number of bookmarked questions for a specific subject's chapters.
  static int subjectCount(Map<String, List<McqQuestion>> chapters) {
    var count = 0;
    for (final list in chapters.values) {
      count += list.length;
    }
    return count;
  }
}

/// State container managing multi-selection of chapters per subject.
class BookmarkSelectionState {
  BookmarkSelectionState([Map<String, Set<String>>? initialSelection])
      : _selectedChapters = initialSelection != null
            ? {
                for (final entry in initialSelection.entries)
                  entry.key: Set<String>.from(entry.value),
              }
            : {};

  final Map<String, Set<String>> _selectedChapters;

  /// Returns unmodifiable map of selected chapters per subject.
  Map<String, Set<String>> get selectedChapters =>
      Map.unmodifiable(_selectedChapters.map((k, v) => MapEntry(k, Set.unmodifiable(v))));

  /// Checks if a specific chapter within a subject is selected.
  bool isChapterSelected(String subject, String chapter) {
    return _selectedChapters[subject]?.contains(chapter) ?? false;
  }

  /// Calculates tri-state selection status for a subject:
  /// - `true`: all chapters in subject are selected
  /// - `false`: no chapters in subject are selected (or subject has no chapters)
  /// - `null`: indeterminate / partial (some but not all chapters are selected)
  bool? subjectSelectionState(
    String subject,
    List<String> allChaptersInSubject,
  ) {
    if (allChaptersInSubject.isEmpty) return false;
    final selected = _selectedChapters[subject];
    if (selected == null || selected.isEmpty) return false;

    var selectedCount = 0;
    for (final ch in allChaptersInSubject) {
      if (selected.contains(ch)) {
        selectedCount++;
      }
    }

    if (selectedCount == 0) return false;
    if (selectedCount == allChaptersInSubject.length) return true;
    return null;
  }

  /// Toggles selection of a specific chapter.
  void toggleChapter(String subject, String chapter) {
    final current = _selectedChapters.putIfAbsent(subject, () => <String>{});
    if (current.contains(chapter)) {
      current.remove(chapter);
      if (current.isEmpty) {
        _selectedChapters.remove(subject);
      }
    } else {
      current.add(chapter);
    }
  }

  /// Toggles selection of an entire subject.
  /// If all chapters are currently selected, deselects all chapters.
  /// Otherwise, selects all chapters in the subject.
  void toggleSubject(String subject, List<String> allChaptersInSubject) {
    final state = subjectSelectionState(subject, allChaptersInSubject);
    if (state == true) {
      _selectedChapters.remove(subject);
    } else {
      _selectedChapters[subject] = Set<String>.from(allChaptersInSubject);
    }
  }

  /// Selects all chapters across all subjects in [grouped].
  void selectAll(Map<String, Map<String, List<McqQuestion>>> grouped) {
    _selectedChapters.clear();
    for (final entry in grouped.entries) {
      if (entry.value.isNotEmpty) {
        _selectedChapters[entry.key] = Set<String>.from(entry.value.keys);
      }
    }
  }

  /// Deselects all chapters across all subjects.
  void deselectAll() {
    _selectedChapters.clear();
  }

  /// Cleans up selections when bookmarks are removed.
  /// Removes any subjects or chapters that no longer exist in [grouped].
  void prune(Map<String, Map<String, List<McqQuestion>>> grouped) {
    final subjectsToRemove = <String>[];
    for (final entry in _selectedChapters.entries) {
      final subject = entry.key;
      final groupedChapters = grouped[subject];
      if (groupedChapters == null || groupedChapters.isEmpty) {
        subjectsToRemove.add(subject);
      } else {
        entry.value.removeWhere((chapter) => !groupedChapters.containsKey(chapter));
        if (entry.value.isEmpty) {
          subjectsToRemove.add(subject);
        }
      }
    }
    for (final sub in subjectsToRemove) {
      _selectedChapters.remove(sub);
    }
  }

  /// Calculates total number of questions selected across all checked chapters.
  int getSelectedQuestionCount(
    Map<String, Map<String, List<McqQuestion>>> grouped,
  ) {
    var total = 0;
    for (final entry in _selectedChapters.entries) {
      final subject = entry.key;
      final chapters = entry.value;
      final subjectGroup = grouped[subject];
      if (subjectGroup != null) {
        for (final chapter in chapters) {
          final list = subjectGroup[chapter];
          if (list != null) {
            total += list.length;
          }
        }
      }
    }
    return total;
  }

  /// Extracts the list of questions selected across all checked chapters,
  /// preserving subject and chapter ordering.
  List<McqQuestion> getSelectedQuestions(
    Map<String, Map<String, List<McqQuestion>>> grouped,
  ) {
    final selectedQuestions = <McqQuestion>[];
    for (final subjectEntry in grouped.entries) {
      final subject = subjectEntry.key;
      final chaptersMap = subjectEntry.value;
      final selectedForSubject = _selectedChapters[subject];
      if (selectedForSubject == null || selectedForSubject.isEmpty) continue;

      for (final chapterEntry in chaptersMap.entries) {
        final chapter = chapterEntry.key;
        if (selectedForSubject.contains(chapter)) {
          selectedQuestions.addAll(chapterEntry.value);
        }
      }
    }
    return selectedQuestions;
  }
}
