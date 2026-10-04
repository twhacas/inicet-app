import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/question_repository.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../domain/models/mcq_question.dart';
import '../../domain/models/test_config.dart';
import '../../domain/models/test_result.dart';
import '../result/test_result_screen.dart';
import '../shared/operation_feedback.dart';
import 'question_palette_modal.dart';
import 'session_app_bar.dart';
import 'session_dialogs.dart';
import 'session_question_body.dart';
import 'session_status_widgets.dart';

class McqSessionScreen extends StatefulWidget {
  const McqSessionScreen({
    required this.questions,
    required this.config,
    required this.repository,
    this.clock,
    super.key,
  });
  final List<McqQuestion> questions;
  final TestConfig config;
  final QuestionRepository repository;
  final DateTime Function()? clock;
  @override
  State<McqSessionScreen> createState() => _McqSessionScreenState();
}

class _McqSessionScreenState extends State<McqSessionScreen> {
  int _currentIndex = 0;
  final Map<int, UserAnswer> _answers = {};
  final Set<int> _skipped = {};
  final Map<int, Set<int>> _eliminated = {};
  final Set<String> _savingBookmarks = {};
  late final List<McqQuestion> _questions;
  late final TestConfig _config;
  late final DateTime _startedAt;
  Timer? _timer;
  int _lastTick = 0;
  int _remaining = 0;
  int _elapsed = 0;
  bool _paused = false;
  bool _expired = false;
  bool _submitting = false;
  bool _confirming = false;
  double _fontScale = 1;
  TestSessionResult? _pendingResult;
  String? _saveError;

  bool get _canInteract =>
      !_paused && !_expired && !_submitting && _pendingResult == null;
  DateTime _now() => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _questions = widget.questions.map((question) {
      final note = widget.repository.getQuestionNote(question.id);
      return question.copyWith(
        userNote: note,
        clearUserNote: note == null,
        isBookmarked: widget.repository.isBookmarked(question.id),
      );
    }).toList();
    _startedAt = _now();
    _config = widget.config.copyWith(
      selectedSubjects: Set.unmodifiable(widget.config.selectedSubjects),
      selectedSubTopics: Map.unmodifiable({
        for (final entry in widget.config.selectedSubTopics.entries)
          entry.key: Set<String>.unmodifiable(entry.value),
      }),
    );
    for (var index = 0; index < _questions.length; index++) {
      _answers[index] = UserAnswer(questionIndex: index);
    }
    _remaining = _config.calculateTotalSeconds(_questions.length);
    if (_questions.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    }
  }

  void _tick(Timer timer) {
    final ticks = timer.tick - _lastTick;
    _lastTick = timer.tick;
    if (!mounted ||
        _paused ||
        _submitting ||
        _pendingResult != null ||
        _expired) {
      return;
    }
    final delta = _config.timerEnabled ? ticks.clamp(0, _remaining) : ticks;
    setState(() {
      _elapsed += delta;
      final answer = _answers[_currentIndex]!;
      _answers[_currentIndex] = answer.copyWith(
        timeSpentSeconds: answer.timeSpentSeconds + delta,
      );
      if (_config.timerEnabled) {
        _remaining = (_remaining - delta).clamp(0, _remaining);
      }
    });
    if (_config.timerEnabled && _remaining == 0) {
      _expired = true;
      _submitTest();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectOption(int index) {
    if (!_canInteract) return;
    setState(() {
      _eliminated[_currentIndex]?.remove(index);
      _skipped.remove(_currentIndex);
      _answers[_currentIndex] = _answers[_currentIndex]!.copyWith(
        selectedOptionIndex: index,
      );
    });
  }

  void _toggleElimination(int index) {
    if (!_canInteract) return;
    setState(() {
      final options = _eliminated.putIfAbsent(_currentIndex, () => <int>{});
      if (!options.remove(index)) options.add(index);
    });
  }

  void _toggleFlag() {
    if (!_canInteract) return;
    setState(() {
      final answer = _answers[_currentIndex]!;
      _answers[_currentIndex] = answer.copyWith(isFlagged: !answer.isFlagged);
    });
  }

  Future<void> _toggleBookmark([int? atIndex]) async {
    if (!mounted || !_canInteract) return;
    final index = atIndex ?? _currentIndex;
    final question = _questions[index];
    if (_savingBookmarks.contains(question.id)) return;
    setState(() => _savingBookmarks.add(question.id));
    try {
      await widget.repository.toggleBookmark(question.id);
      if (!mounted) return;
      setState(() {
        if (_questions[index].id == question.id) {
          _questions[index] = _questions[index].copyWith(
            isBookmarked: widget.repository.isBookmarked(question.id),
          );
        }
      });
    } catch (error) {
      if (mounted) {
        showOperationError(context, error, retry: () => _toggleBookmark(index));
      }
    } finally {
      if (mounted) setState(() => _savingBookmarks.remove(question.id));
    }
  }

  void _navigateToIndex(int index) {
    if (!_canInteract ||
        index == _currentIndex ||
        index < 0 ||
        index >= _questions.length) {
      return;
    }
    setState(() {
      if (!_answers[_currentIndex]!.isAttempted) _skipped.add(_currentIndex);
      _currentIndex = index;
    });
  }

  void _nextUnsolved() {
    if (!_canInteract) return;
    for (var step = 1; step <= _questions.length; step++) {
      final index = (_currentIndex + step) % _questions.length;
      if (!_answers[index]!.isAttempted) {
        _navigateToIndex(index);
        return;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All questions have been attempted!')),
    );
  }

  Future<void> _openNote() async {
    if (!_canInteract) return;
    final index = _currentIndex;
    final question = _questions[index];
    final note = await editSessionNote(
      context,
      text:
          widget.repository.getQuestionNote(question.id) ??
          question.userNote ??
          '',
      questionNumber: index + 1,
    );
    if (note != null && mounted && !_expired && !_submitting) {
      await _saveNote(index, note);
    }
  }

  Future<void> _saveNote(int index, String text) async {
    if (!mounted || _expired || _submitting) return;
    final question = _questions[index];
    try {
      await widget.repository.saveQuestionNote(question.id, text);
      if (!mounted) return;
      final note = widget.repository.getQuestionNote(question.id);
      setState(() {
        if (_questions[index].id == question.id) {
          _questions[index] = _questions[index].copyWith(
            userNote: note,
            clearUserNote: note == null,
          );
        }
      });
    } catch (error) {
      if (mounted) {
        showOperationError(context, error, retry: () => _saveNote(index, text));
      }
    }
  }

  Future<void> _submitTest() async {
    if (_submitting || !mounted) return;
    final route = ModalRoute.of(context);
    _timer?.cancel();
    _pendingResult ??= TestSessionResult(
      config: _config,
      questions: List.unmodifiable(_questions),
      userAnswers: Map.unmodifiable(_answers),
      startedAt: _startedAt,
      completedAt: _now(),
      activeTimeSpentSeconds: _elapsed,
      timedOut: _expired,
    );
    setState(() {
      _submitting = true;
      _saveError = null;
    });
    try {
      await widget.repository.saveTestSession(_pendingResult!);
      if (!mounted) return;
      final navigator = Navigator.of(context);
      // Close only overlays above this session before replacing the session itself.
      navigator.popUntil((candidate) => candidate == route);
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => TestResultScreen(
            result: _pendingResult!,
            repository: widget.repository,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _saveError = operationErrorMessage(error);
        });
      }
    }
  }

  Future<void> _confirmSubmit() async {
    if (_submitting || _expired || _pendingResult != null || _confirming) {
      return;
    }
    _confirming = true;
    try {
      final confirmed = await confirmSessionSubmit(
        context,
        attempted: _answers.values.where((a) => a.isAttempted).length,
        total: _questions.length,
        flagged: _answers.values.where((a) => a.isFlagged).length,
      );
      if (confirmed && mounted && !_expired && !_submitting) {
        await _submitTest();
      }
    } finally {
      _confirming = false;
    }
  }

  Future<void> _confirmExit() async {
    if (_submitting || _confirming) return;
    _confirming = true;
    try {
      if (await confirmSessionExit(context) && mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      _confirming = false;
    }
  }

  void _palette() {
    if (!_canInteract) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => QuestionPaletteModal(
        totalQuestions: _questions.length,
        currentIndex: _currentIndex,
        answers: _answers,
        skippedIndices: _skipped,
        onSelect: (index) {
          _navigateToIndex(index);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text(
            'No questions available. Adjust your filters and start a new test.',
          ),
        ),
      );
    }
    final question = _questions[_currentIndex];
    final answer = _answers[_currentIndex]!;
    final solved = _answers.values.where((a) => a.isAttempted).length;
    final hasNote = question.userNote?.isNotEmpty ?? false;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: SessionAppBar(
          index: _currentIndex,
          total: _questions.length,
          hasNote: hasNote,
          bookmarked: widget.repository.isBookmarked(question.id),
          onExit: _submitting ? null : _confirmExit,
          onSmaller: _canInteract
              ? () => setState(
                  () => _fontScale = (_fontScale - 0.15).clamp(0.85, 1.45),
                )
              : null,
          onLarger: _canInteract
              ? () => setState(
                  () => _fontScale = (_fontScale + 0.15).clamp(0.85, 1.45),
                )
              : null,
          onNote: _canInteract ? _openNote : null,
          onBookmark: _canInteract && !_savingBookmarks.contains(question.id)
              ? _toggleBookmark
              : null,
          onPalette: _canInteract ? _palette : null,
          onSubmit: _pendingResult == null && !_submitting
              ? _confirmSubmit
              : null,
        ),
        body: SafeArea(
          child: Column(
            children: [
              SessionClockBar(
                config: _config,
                remaining: _remaining,
                elapsed: _elapsed,
                paused: _paused,
                onPause: _pendingResult != null || _submitting
                    ? null
                    : () => setState(() => _paused = !_paused),
              ),
              QuestionTrackerRibbon(
                solved: solved,
                total: _questions.length,
                skipped: _skipped.length,
                onNext: _canInteract ? _nextUnsolved : null,
              ),
              if (_submitting) const LinearProgressIndicator(),
              if (_saveError != null) ...[
                AppStatusBanner(
                  title: 'Test not saved',
                  message:
                      '$_saveError Your responses are kept on this screen.',
                  tone: AppBannerTone.error,
                ),
                AppButton(label: 'Retry Save', onPressed: _submitTest),
              ],
              Expanded(
                child: _paused
                    ? SessionPauseOverlay(
                        onResume: () => setState(() => _paused = false),
                      )
                    : AbsorbPointer(
                        absorbing: !_canInteract,
                        child: SessionQuestionBody(
                          question: question,
                          selectedOption: answer.selectedOptionIndex,
                          isPractice: _config.mode == TestMode.practice,
                          isFlagged: answer.isFlagged,
                          eliminated: _eliminated[_currentIndex] ?? const {},
                          fontScale: _fontScale,
                          onSelect: _selectOption,
                          onEliminate: _toggleElimination,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    TextButton(
                      onPressed: _canInteract && _currentIndex > 0
                          ? () => _navigateToIndex(_currentIndex - 1)
                          : null,
                      child: const Text('Previous'),
                    ),
                    TextButton(
                      onPressed: _canInteract ? _toggleFlag : null,
                      child: Text(
                        answer.isFlagged ? 'Unflag' : 'Flag for Review',
                      ),
                    ),
                    AppButton(
                      label: _currentIndex == _questions.length - 1
                          ? 'Submit Test'
                          : 'Next',
                      onPressed: !_canInteract
                          ? null
                          : _currentIndex == _questions.length - 1
                          ? _confirmSubmit
                          : () => _navigateToIndex(_currentIndex + 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
