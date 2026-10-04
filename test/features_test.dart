import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inicet_app/data/question_repository.dart';
import 'package:inicet_app/domain/models/mcq_question.dart';
import 'package:inicet_app/domain/models/test_config.dart';
import 'package:inicet_app/domain/models/test_result.dart';
import 'package:inicet_app/features/history/test_history_screen.dart';
import 'package:inicet_app/features/practice_sets/practice_sets_tab.dart';
import 'package:inicet_app/features/test/mcq_session_screen.dart';

import 'support/question_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testQuestions = [
    McqQuestion(
      id: 'q1',
      subject: 'Pathology',
      subTopic: 'Cell Injury',
      stem: 'Which organelle is primarily responsible for intrinsic apoptosis?',
      options: [
        'Mitochondria',
        'Endoplasmic reticulum',
        'Golgi apparatus',
        'Peroxisome',
      ],
      correctIndex: 0,
      explanation: 'Intrinsic apoptosis is initiated by cytochrome c release from mitochondria.',
      tag: 'INI-CET',
      exam: '2024 INI-CET',
      repeats: 3,
      difficulty: 'Easy',
    ),
    McqQuestion(
      id: 'q2',
      subject: 'Microbiology',
      subTopic: 'Bacteriology',
      stem: 'Which toxin inhibits EF-2 by ADP-ribosylation?',
      options: [
        'Diphtheria toxin',
        'Cholera toxin',
        'Tetanus toxin',
        'Botulinum toxin',
      ],
      correctIndex: 0,
      explanation:
          'Diphtheria toxin and Pseudomonas Exotoxin A ADP-ribosylate EF-2.',
      tag: 'INI-CET',
      exam: '2023 INI-CET',
      repeats: 2,
      difficulty: 'Medium',
    ),
  ];

  group('McqSessionScreen features', () {
    late _MockRepo repo;

    setUp(() {
      repo = _MockRepo(List.from(testQuestions));
    });

    testWidgets(
      'Top persistent timer bar renders with pace and pause/resume blackout',
      (tester) async {
        const config = TestConfig(
          title: 'Test Session',
          mode: TestMode.practice,
          selectedSubjects: {'Pathology'},
          selectedSubTopics: {},
          questionCount: 2,
          timerEnabled: true,
          timerType: TimerType.perQuestion,
          timePerQuestionSeconds: 50,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: McqSessionScreen(
              questions: testQuestions,
              config: config,
              repository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Top timer bar exists and shows pace
        expect(find.textContaining('50s/Q pace'), findsOneWidget);
        expect(find.text('Pause'), findsOneWidget);

        // Question is visible
        expect(
          find.text(
            'Which organelle is primarily responsible for intrinsic apoptosis?',
          ),
          findsOneWidget,
        );
        expect(find.text('Mitochondria'), findsOneWidget);

        // Tap Pause to trigger blackout overlay
        await tester.tap(find.text('Pause'));
        await tester.pumpAndSettle();

        // Overlay should be displayed
        expect(find.text('Session Paused'), findsOneWidget);
        expect(
          find.text(
            'Question stem and options are hidden while the timer is paused.',
          ),
          findsOneWidget,
        );
        expect(find.text('Resume Test'), findsOneWidget);

        // Question stem and options should now be hidden
        expect(
          find.text(
            'Which organelle is primarily responsible for intrinsic apoptosis?',
          ),
          findsNothing,
        );
        expect(find.text('Mitochondria'), findsNothing);

        // Resume test
        await tester.tap(find.text('Resume Test'));
        await tester.pumpAndSettle();

        // Stem is restored
        expect(
          find.text(
            'Which organelle is primarily responsible for intrinsic apoptosis?',
          ),
          findsOneWidget,
        );
        expect(find.text('Mitochondria'), findsOneWidget);
      },
    );

    testWidgets(
      'Option elimination (strike-through) dims distractor without selecting',
      (tester) async {
        const config = TestConfig(
          title: 'Test Session',
          mode: TestMode.practice,
          selectedSubjects: {'Pathology'},
          selectedSubTopics: {},
          questionCount: 2,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: McqSessionScreen(
              questions: testQuestions,
              config: config,
              repository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find strike button for options
        final strikeButtons = find.byTooltip('Eliminate option (✕)');
        expect(strikeButtons, findsNWidgets(4));

        // Tap strike on first option
        final firstStrike = strikeButtons.first;
        await tester.ensureVisible(firstStrike);
        await tester.tap(firstStrike);
        await tester.pumpAndSettle();

        // The tooltip changes to 'Restore option'
        expect(find.byTooltip('Restore option'), findsOneWidget);

        // Option should not be answered
        expect(find.text('Explanation & Rationale'), findsNothing);

        // Tapping Restore restores it
        await tester.tap(find.byTooltip('Restore option'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Restore option'), findsNothing);
      },
    );

    testWidgets(
      'Live Question Status Tracker ribbon updates and supports Next Unsolved jump',
      (tester) async {
        const config = TestConfig(
          title: 'Test Session',
          mode: TestMode.practice,
          selectedSubjects: {'Pathology'},
          selectedSubTopics: {},
          questionCount: 2,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: McqSessionScreen(
              questions: testQuestions,
              config: config,
              repository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initial state: Solved: 0, Unsolved: 2
        expect(find.text('Solved: 0'), findsOneWidget);
        expect(find.text('Unsolved: 2'), findsOneWidget);

        // Tap Next to navigate past Q1 without answering
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Now on Q2 of 2, Q1 was skipped
        expect(find.text('Q2 of 2'), findsOneWidget);
        expect(find.text('Skipped: 1'), findsOneWidget);

        // Tap 'Next Unsolved' should cycle back to Q1
        await tester.tap(find.text('Next Unsolved'));
        await tester.pumpAndSettle();

        expect(find.text('Q1 of 2'), findsOneWidget);

        // Answer Q1
        await tester.tap(find.text('Mitochondria'));
        await tester.pumpAndSettle();

        // Solved updates to 1
        expect(find.text('Solved: 1'), findsOneWidget);
      },
    );

    testWidgets('Font size controls A- and A+ adjust text sizing scale', (
      tester,
    ) async {
      const config = TestConfig(
        title: 'Test Session',
        mode: TestMode.practice,
        selectedSubjects: {'Pathology'},
        selectedSubTopics: {},
        questionCount: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: McqSessionScreen(
            questions: testQuestions,
            config: config,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final aMinus = find.byTooltip('Smaller text');
      final aPlus = find.byTooltip('Larger text');

      expect(aMinus, findsOneWidget);
      expect(aPlus, findsOneWidget);

      await tester.tap(aPlus);
      await tester.pumpAndSettle();

      await tester.tap(aMinus);
      await tester.pumpAndSettle();
    });

    testWidgets('Personal question note can be added, saved, and rendered', (
      tester,
    ) async {
      const config = TestConfig(
        title: 'Test Session',
        mode: TestMode.practice,
        selectedSubjects: {'Pathology'},
        selectedSubTopics: {},
        questionCount: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: McqSessionScreen(
            questions: testQuestions,
            config: config,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap note button in app bar
      final noteButton = find.byTooltip('Add personal note');
      expect(noteButton, findsOneWidget);
      await tester.tap(noteButton);
      await tester.pumpAndSettle();

      // Note dialog appears
      expect(find.text('Personal Question Note'), findsOneWidget);

      // Enter text
      await tester.enterText(
        find.byType(TextField),
        'Important: Cytochrome c initiates caspase 9 activation.',
      );
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save Note'));
      await tester.pumpAndSettle();

      // Verify note is saved in repo
      expect(
        repo.getQuestionNote('q1'),
        'Important: Cytochrome c initiates caspase 9 activation.',
      );

      // Verify personal note callout appears on screen
      expect(find.text('MY HIGH-YIELD NOTE'), findsOneWidget);
      expect(
        find.text('Important: Cytochrome c initiates caspase 9 activation.'),
        findsOneWidget,
      );
    });
  });

  group('PracticeSetsTab and TestHistoryScreen', () {
    late _MockRepo repo;

    setUp(() {
      repo = _MockRepo(List.from(testQuestions));
    });

    testWidgets(
      'PracticeSetsTab renders 20 subject cards with high-yield badges',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: PracticeSetsTab(repository: repo)),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Curated Core Sets (3,258 Authored Questions across 20 Subjects)',
          ),
          findsOneWidget,
        );
        expect(find.text('Anatomy'), findsOneWidget);
        expect(find.text('Physiology'), findsOneWidget);
        expect(find.text('Biochemistry'), findsOneWidget);
        expect(find.text('Pathology'), findsOneWidget);
        expect(find.text('Microbiology'), findsOneWidget);
        expect(find.text('Pharmacology'), findsOneWidget);
        expect(find.text('Forensic Medicine'), findsOneWidget);
        expect(find.text('ENT'), findsOneWidget);
        expect(find.text('PSM'), findsOneWidget);
        expect(find.text('Ophthalmology'), findsOneWidget);
        expect(find.text('General Medicine'), findsOneWidget);
        expect(find.text('General Surgery'), findsOneWidget);
        expect(find.text('Obstetrics'), findsOneWidget);
        expect(find.text('Gynaecology'), findsOneWidget);
        expect(find.text('Pediatrics'), findsOneWidget);
        expect(find.text('Anesthesia'), findsOneWidget);
        expect(find.text('Dermatology'), findsOneWidget);
        expect(find.text('Orthopedics'), findsOneWidget);
        expect(find.text('Psychiatry'), findsOneWidget);
        expect(find.text('Radiology'), findsOneWidget);

        expect(find.text('150 QUESTIONS'), findsNWidgets(12));
        expect(find.text('167 QUESTIONS'), findsOneWidget);
        expect(find.text('160 QUESTIONS'), findsOneWidget);
        expect(find.text('206 QUESTIONS'), findsOneWidget);
        expect(find.text('148 QUESTIONS'), findsOneWidget);
        expect(find.text('172 QUESTIONS'), findsOneWidget);
        expect(find.text('171 QUESTIONS'), findsOneWidget);
        expect(find.text('209 QUESTIONS'), findsOneWidget);
        expect(find.text('225 QUESTIONS'), findsOneWidget);

        expect(find.text('Start All 150 Qs'), findsNWidgets(12));
        expect(find.text('Start All 167 Qs'), findsOneWidget);
        expect(find.text('Start All 160 Qs'), findsOneWidget);
        expect(find.text('Start All 206 Qs'), findsOneWidget);
        expect(find.text('Start All 148 Qs'), findsOneWidget);
        expect(find.text('Start All 172 Qs'), findsOneWidget);
        expect(find.text('Start All 171 Qs'), findsOneWidget);
        expect(find.text('Start All 209 Qs'), findsOneWidget);
        expect(find.text('Start All 225 Qs'), findsOneWidget);
        expect(find.text('Custom'), findsNWidgets(20));
      },
    );

    testWidgets(
      'PracticeSetsTab Custom button opens PracticeSetCustomModal with subtopics and exam filters',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: PracticeSetsTab(repository: repo)),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Custom on first card (Anatomy)
        final customBtns = find.text('Custom');
        expect(customBtns, findsWidgets);
        await tester.ensureVisible(customBtns.first);
        await tester.tap(customBtns.first);
        await tester.pumpAndSettle();

        // Modal appears
        expect(find.textContaining('Custom Filters'), findsOneWidget);
        expect(find.text('Study Mode'), findsOneWidget);
        expect(find.textContaining('Sub-Topics'), findsOneWidget);
        expect(find.text('Exam Source Filters'), findsOneWidget);
        expect(
          find.text('High-Yield Repeats Only (2X+ Tested)'),
          findsOneWidget,
        );
        expect(find.text('Timer'), findsOneWidget);
        expect(find.text('Randomization Options'), findsOneWidget);

        // Tap Start Custom Test
        final startBtn = find.textContaining('Start Custom Test');
        expect(startBtn, findsOneWidget);
        await tester.tap(startBtn);
        await tester.pumpAndSettle();

        // Session starts
        expect(find.textContaining('Q1 of'), findsOneWidget);
      },
    );

    testWidgets('TestHistoryScreen renders empty state when no sessions', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TestHistoryScreen(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Test Attempts Yet'), findsOneWidget);
    });

    testWidgets(
      'TestHistoryScreen renders session cards and Review Full Test button',
      (tester) async {
        // Add a simulated past session
        final session = TestSessionResult(
          id: 'hist-1',
          startedAt: DateTime.now().subtract(const Duration(hours: 1)),
          completedAt: DateTime.now(),
          config: const TestConfig(
            title: 'INI-CET Pathology High-Yield Drill',
            mode: TestMode.exam,
            selectedSubjects: {'Pathology'},
            selectedSubTopics: {},
            questionCount: 2,
          ),
          questions: testQuestions,
          userAnswers: {
            0: const UserAnswer(
              questionIndex: 0,
              selectedOptionIndex: 0,
              isFlagged: false,
              timeSpentSeconds: 30,
            ),
            1: const UserAnswer(
              questionIndex: 1,
              selectedOptionIndex: 1,
              isFlagged: false,
              timeSpentSeconds: 45,
            ),
          },
        );

        repo.simulatedHistory = [session];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: TestHistoryScreen(repository: repo)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Overall Performance'), findsOneWidget);
        expect(find.text('INI-CET Pathology High-Yield Drill'), findsOneWidget);
        expect(find.text('Review Full Test'), findsOneWidget);
      },
    );
  });
}

class _MockRepo extends QuestionRepository {
  _MockRepo(this._questions) : super(storage: MemoryQuestionStorage());

  final List<McqQuestion> _questions;
  final Map<String, String> _notes = {};
  List<TestSessionResult> simulatedHistory = [];

  @override
  bool get isInitialized => true;

  @override
  List<McqQuestion> get allQuestions => _questions;

  @override
  String? getQuestionNote(String questionId) => _notes[questionId];

  @override
  Future<void> saveQuestionNote(String questionId, String noteText) async {
    if (noteText.trim().isEmpty) {
      _notes.remove(questionId);
    } else {
      _notes[questionId] = noteText.trim();
    }
  }

  @override
  Future<List<TestSessionResult>> getPastTestSessions() async {
    return simulatedHistory;
  }

  @override
  Future<List<McqQuestion>> loadPracticeSet(String subject) async {
    return _questions;
  }
}
