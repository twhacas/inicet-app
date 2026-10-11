import 'package:flutter_test/flutter_test.dart';
import 'package:inicet_app/domain/models/mcq_question.dart';
import 'package:inicet_app/features/bookmarks/bookmark_group_helper.dart';

McqQuestion _createQuestion({
  required String id,
  required String subject,
  required String subTopic,
  String stem = 'Stem text',
}) {
  return McqQuestion(
    id: id,
    subject: subject,
    subTopic: subTopic,
    stem: stem,
    options: const ['Option A', 'Option B', 'Option C', 'Option D'],
    correctIndex: 0,
    explanation: 'Explanation text',
  );
}

void main() {
  group('BookmarkGroupHelper', () {
    test('groups empty questions list to empty map', () {
      final grouped = BookmarkGroupHelper.group([]);
      expect(grouped.isEmpty, isTrue);
      expect(BookmarkGroupHelper.totalCount(grouped), 0);
    });

    test('groups questions by subject then chapter with alphabetical ordering', () {
      final questions = [
        _createQuestion(id: 'q1', subject: 'Physiology', subTopic: 'Cardiovascular'),
        _createQuestion(id: 'q2', subject: 'Anatomy', subTopic: 'Upper Limb'),
        _createQuestion(id: 'q3', subject: 'Anatomy', subTopic: 'Neuroanatomy'),
        _createQuestion(id: 'q4', subject: 'Biochemistry', subTopic: 'Metabolism'),
        _createQuestion(id: 'q5', subject: 'Anatomy', subTopic: 'Upper Limb'),
      ];

      final grouped = BookmarkGroupHelper.group(questions);

      // Verify outer keys are sorted alphabetically
      expect(grouped.keys.toList(), ['Anatomy', 'Biochemistry', 'Physiology']);

      // Verify inner keys for Anatomy are sorted alphabetically
      expect(grouped['Anatomy']!.keys.toList(), ['Neuroanatomy', 'Upper Limb']);
      expect(grouped['Anatomy']!['Upper Limb']!.length, 2);
      expect(grouped['Anatomy']!['Upper Limb']!.map((q) => q.id), ['q2', 'q5']);
      expect(grouped['Anatomy']!['Neuroanatomy']!.length, 1);

      // Verify total count and subject count
      expect(BookmarkGroupHelper.totalCount(grouped), 5);
      expect(BookmarkGroupHelper.subjectCount(grouped['Anatomy']!), 3);
      expect(BookmarkGroupHelper.subjectCount(grouped['Biochemistry']!), 1);
      expect(BookmarkGroupHelper.subjectCount(grouped['Physiology']!), 1);
    });

    test('normalizes empty and whitespace-only subTopics to General', () {
      final questions = [
        _createQuestion(id: 'q1', subject: 'Pathology', subTopic: ''),
        _createQuestion(id: 'q2', subject: 'Pathology', subTopic: '   '),
        _createQuestion(id: 'q3', subject: 'Pathology', subTopic: 'Neoplasia'),
      ];

      final grouped = BookmarkGroupHelper.group(questions);
      expect(grouped.keys.toList(), ['Pathology']);
      expect(grouped['Pathology']!.keys.toList(), ['General', 'Neoplasia']);
      expect(grouped['Pathology']!['General']!.length, 2);
      expect(grouped['Pathology']!['Neoplasia']!.length, 1);
    });

    test('trims whitespace on subjects and handles empty subject', () {
      final questions = [
        _createQuestion(id: 'q1', subject: '  Pharmacology  ', subTopic: 'Autonomic'),
        _createQuestion(id: 'q2', subject: '', subTopic: 'General'),
      ];

      final grouped = BookmarkGroupHelper.group(questions);
      expect(grouped.containsKey('Pharmacology'), isTrue);
      expect(grouped.containsKey('General'), isTrue);
    });

    test('handles special characters and maintains insertion order of questions', () {
      final questions = [
        _createQuestion(
          id: 'q1',
          subject: 'Anatomy & Embryology',
          subTopic: 'Chapter 1.1: Upper Limb (Bones & Joints)',
        ),
        _createQuestion(
          id: 'q2',
          subject: 'Anatomy & Embryology',
          subTopic: 'Chapter 1.1: Upper Limb (Bones & Joints)',
        ),
        _createQuestion(
          id: 'q3',
          subject: 'Anatomy & Embryology',
          subTopic: 'Chapter 1.1: Upper Limb (Bones & Joints)',
        ),
      ];

      final grouped = BookmarkGroupHelper.group(questions);
      expect(grouped.keys.toList(), ['Anatomy & Embryology']);
      expect(grouped['Anatomy & Embryology']!.keys.toList(), [
        'Chapter 1.1: Upper Limb (Bones & Joints)',
      ]);
      expect(
        grouped['Anatomy & Embryology']!['Chapter 1.1: Upper Limb (Bones & Joints)']!
            .map((q) => q.id)
            .toList(),
        ['q1', 'q2', 'q3'],
      );
      expect(BookmarkGroupHelper.totalCount(grouped), 3);
      expect(BookmarkGroupHelper.subjectCount(grouped['Anatomy & Embryology']!), 3);
    });
  });

  group('BookmarkSelectionState', () {
    late Map<String, Map<String, List<McqQuestion>>> sampleGrouped;

    setUp(() {
      final questions = [
        _createQuestion(id: 'q1', subject: 'Anatomy', subTopic: 'Abdomen'),
        _createQuestion(id: 'q2', subject: 'Anatomy', subTopic: 'Thorax'),
        _createQuestion(id: 'q3', subject: 'Anatomy', subTopic: 'Thorax'),
        _createQuestion(id: 'q4', subject: 'Physiology', subTopic: 'Endocrine'),
        _createQuestion(id: 'q5', subject: 'Physiology', subTopic: 'Renal'),
      ];
      sampleGrouped = BookmarkGroupHelper.group(questions);
    });

    test('starts with empty selection by default', () {
      final state = BookmarkSelectionState();
      expect(state.selectedChapters.isEmpty, isTrue);
      expect(state.isChapterSelected('Anatomy', 'Abdomen'), isFalse);
      expect(state.subjectSelectionState('Anatomy', ['Abdomen', 'Thorax']), isFalse);
      expect(state.getSelectedQuestionCount(sampleGrouped), 0);
      expect(state.getSelectedQuestions(sampleGrouped), isEmpty);
    });

    test('toggles individual chapters and subject status dynamically', () {
      final state = BookmarkSelectionState();

      // Toggle Abdomen in Anatomy
      state.toggleChapter('Anatomy', 'Abdomen');
      expect(state.isChapterSelected('Anatomy', 'Abdomen'), isTrue);
      expect(state.isChapterSelected('Anatomy', 'Thorax'), isFalse);

      // Tri-state for Anatomy should be null (indeterminate)
      expect(state.subjectSelectionState('Anatomy', ['Abdomen', 'Thorax']), isNull);

      // Question count should reflect 1 question (Abdomen has 1)
      expect(state.getSelectedQuestionCount(sampleGrouped), 1);
      expect(state.getSelectedQuestions(sampleGrouped).map((q) => q.id), ['q1']);

      // Toggle Thorax as well
      state.toggleChapter('Anatomy', 'Thorax');
      expect(state.isChapterSelected('Anatomy', 'Thorax'), isTrue);
      // Now all chapters in Anatomy are selected -> tri-state should be true
      expect(state.subjectSelectionState('Anatomy', ['Abdomen', 'Thorax']), isTrue);
      // Abdomen (1) + Thorax (2) = 3
      expect(state.getSelectedQuestionCount(sampleGrouped), 3);

      // Toggle Abdomen back off
      state.toggleChapter('Anatomy', 'Abdomen');
      expect(state.isChapterSelected('Anatomy', 'Abdomen'), isFalse);
      expect(state.subjectSelectionState('Anatomy', ['Abdomen', 'Thorax']), isNull);
      expect(state.getSelectedQuestionCount(sampleGrouped), 2);

      // Toggle Thorax off -> subject becomes completely deselected
      state.toggleChapter('Anatomy', 'Thorax');
      expect(state.subjectSelectionState('Anatomy', ['Abdomen', 'Thorax']), isFalse);
      expect(state.selectedChapters.containsKey('Anatomy'), isFalse);
      expect(state.getSelectedQuestionCount(sampleGrouped), 0);
    });

    test('toggleSubject selects all if partially or none selected, and deselects all if all selected', () {
      final state = BookmarkSelectionState();
      final anatomyChapters = ['Abdomen', 'Thorax'];

      // Initially none selected -> toggleSubject selects all
      state.toggleSubject('Anatomy', anatomyChapters);
      expect(state.isChapterSelected('Anatomy', 'Abdomen'), isTrue);
      expect(state.isChapterSelected('Anatomy', 'Thorax'), isTrue);
      expect(state.subjectSelectionState('Anatomy', anatomyChapters), isTrue);

      // When all selected -> toggleSubject deselects all
      state.toggleSubject('Anatomy', anatomyChapters);
      expect(state.isChapterSelected('Anatomy', 'Abdomen'), isFalse);
      expect(state.isChapterSelected('Anatomy', 'Thorax'), isFalse);
      expect(state.subjectSelectionState('Anatomy', anatomyChapters), isFalse);

      // When partially selected -> toggleSubject selects all
      state.toggleChapter('Anatomy', 'Abdomen');
      expect(state.subjectSelectionState('Anatomy', anatomyChapters), isNull);
      state.toggleSubject('Anatomy', anatomyChapters);
      expect(state.subjectSelectionState('Anatomy', anatomyChapters), isTrue);
      expect(state.isChapterSelected('Anatomy', 'Abdomen'), isTrue);
      expect(state.isChapterSelected('Anatomy', 'Thorax'), isTrue);
    });

    test('selectAll and deselectAll affect all subjects and chapters', () {
      final state = BookmarkSelectionState();

      state.selectAll(sampleGrouped);
      expect(state.isChapterSelected('Anatomy', 'Abdomen'), isTrue);
      expect(state.isChapterSelected('Anatomy', 'Thorax'), isTrue);
      expect(state.isChapterSelected('Physiology', 'Endocrine'), isTrue);
      expect(state.isChapterSelected('Physiology', 'Renal'), isTrue);
      expect(state.getSelectedQuestionCount(sampleGrouped), 5);
      expect(state.getSelectedQuestions(sampleGrouped).length, 5);

      state.deselectAll();
      expect(state.selectedChapters.isEmpty, isTrue);
      expect(state.getSelectedQuestionCount(sampleGrouped), 0);
      expect(state.getSelectedQuestions(sampleGrouped), isEmpty);
    });

    test('prune removes deleted chapters and subjects from selection', () {
      final state = BookmarkSelectionState();
      state.selectAll(sampleGrouped);
      expect(state.getSelectedQuestionCount(sampleGrouped), 5);

      // Simulate unbookmarking questions: Thorax in Anatomy is removed, and all of Physiology is removed
      final remainingQuestions = [
        _createQuestion(id: 'q1', subject: 'Anatomy', subTopic: 'Abdomen'),
      ];
      final newGrouped = BookmarkGroupHelper.group(remainingQuestions);

      state.prune(newGrouped);

      // Physiology should be completely pruned
      expect(state.selectedChapters.containsKey('Physiology'), isFalse);
      // Thorax should be pruned from Anatomy
      expect(state.isChapterSelected('Anatomy', 'Thorax'), isFalse);
      // Abdomen should still be selected
      expect(state.isChapterSelected('Anatomy', 'Abdomen'), isTrue);
      expect(state.getSelectedQuestionCount(newGrouped), 1);
      expect(state.getSelectedQuestions(newGrouped).map((q) => q.id), ['q1']);
    });

    test('getSelectedQuestions preserves alphabetical subject and chapter order', () {
      final state = BookmarkSelectionState();
      state.selectAll(sampleGrouped);

      final selected = state.getSelectedQuestions(sampleGrouped);
      expect(selected.map((q) => q.id).toList(), ['q1', 'q2', 'q3', 'q4', 'q5']);
    });

    test('subjectSelectionState with empty chapter list returns false', () {
      final state = BookmarkSelectionState();
      expect(state.subjectSelectionState('Anatomy', []), isFalse);
    });

    test('initializes with initialSelection map if provided', () {
      final state = BookmarkSelectionState({
        'Anatomy': {'Abdomen'},
      });
      expect(state.isChapterSelected('Anatomy', 'Abdomen'), isTrue);
      expect(state.isChapterSelected('Anatomy', 'Thorax'), isFalse);
    });

    test('prune with completely empty map clears all selections', () {
      final state = BookmarkSelectionState();
      state.selectAll(sampleGrouped);
      expect(state.selectedChapters.isNotEmpty, isTrue);

      state.prune({});
      expect(state.selectedChapters.isEmpty, isTrue);
      expect(state.getSelectedQuestionCount(sampleGrouped), 0);
    });

    test('getSelectedQuestionCount ignores selections for subjects not in grouped map', () {
      final state = BookmarkSelectionState({
        'NonExistentSubject': {'GhostChapter'},
      });
      expect(state.getSelectedQuestionCount(sampleGrouped), 0);
    });

    test('isChapterSelected returns false for nonexistent subject or chapter', () {
      final state = BookmarkSelectionState();
      expect(state.isChapterSelected('UnknownSubject', 'UnknownChapter'), isFalse);
    });
  });
}
