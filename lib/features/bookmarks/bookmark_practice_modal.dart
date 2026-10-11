import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/question_repository.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_card.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../domain/models/mcq_question.dart';
import '../../domain/models/test_config.dart';
import '../test/mcq_session_screen.dart';

class BookmarkPracticeModal extends StatefulWidget {
  const BookmarkPracticeModal({
    required this.selectedQuestions,
    required this.repository,
    super.key,
  });

  final List<McqQuestion> selectedQuestions;
  final QuestionRepository repository;

  static Future<void> show({
    required BuildContext context,
    required List<McqQuestion> selectedQuestions,
    required QuestionRepository repository,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookmarkPracticeModal(
        selectedQuestions: selectedQuestions,
        repository: repository,
      ),
    );
  }

  @override
  State<BookmarkPracticeModal> createState() => _BookmarkPracticeModalState();
}

class _BookmarkPracticeModalState extends State<BookmarkPracticeModal> {
  // Mode selection
  TestMode _selectedMode = TestMode.practice;

  // Question count & Randomization
  late int _questionCount;
  bool _shuffleQuestions = true;
  bool _shuffleOptions = false;

  // Timer configuration
  bool _timerEnabled = true;
  TimerType _timerType = TimerType.perQuestion;
  int _timePerQuestionSeconds = 50;
  int _totalDurationMinutes = 20;

  @override
  void initState() {
    super.initState();
    _questionCount = max(1, widget.selectedQuestions.length);
  }

  void _startSession() {
    if (widget.selectedQuestions.isEmpty) return;

    var pool = List<McqQuestion>.from(widget.selectedQuestions);

    if (_shuffleQuestions) {
      pool.shuffle();
    }

    final targetCount = min(_questionCount, pool.length);
    var selected = pool.take(targetCount).toList();

    if (_shuffleOptions) {
      selected = selected.map((q) => q.shuffleOptions()).toList();
    }

    final selectedSubjects = selected.map((q) => q.subject).toSet();
    final selectedSubTopics = <String, Set<String>>{};
    for (final q in selected) {
      final topic = q.subTopic.trim().isEmpty ? 'General' : q.subTopic.trim();
      selectedSubTopics.putIfAbsent(q.subject, () => <String>{}).add(topic);
    }

    final config = TestConfig(
      title: 'Bookmarked Practice ($targetCount MCQs)',
      selectedSubjects: selectedSubjects,
      selectedSubTopics: selectedSubTopics,
      questionCount: targetCount,
      mode: _selectedMode,
      timerEnabled: _timerEnabled,
      timerType: _timerType,
      timePerQuestionSeconds: _timePerQuestionSeconds,
      totalDurationMinutes: _totalDurationMinutes,
      shuffleQuestions: _shuffleQuestions,
      shuffleOptions: _shuffleOptions,
    );

    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => McqSessionScreen(
          questions: selected,
          config: config,
          repository: widget.repository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalAvailable = widget.selectedQuestions.length;
    final targetCount = min(_questionCount, totalAvailable);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.xl),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.contentMaxWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: AppSpacing.sm),
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),

              // Modal Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs + 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: const Icon(
                        Icons.bookmark_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Practice Configuration',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '$totalAvailable Selected Bookmarked Question${totalAvailable == 1 ? '' : 's'}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Scrollable Options
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Study Mode Selector
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Test Mode',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<TestMode>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment(
                                    value: TestMode.practice,
                                    label: Text('Practice Mode'),
                                  ),
                                  ButtonSegment(
                                    value: TestMode.exam,
                                    label: Text('Exam Mode'),
                                  ),
                                ],
                                selected: {_selectedMode},
                                onSelectionChanged: (set) =>
                                    setState(() => _selectedMode = set.first),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _selectedMode == TestMode.practice
                                  ? 'Instant feedback: see rationales and pearls immediately upon answering.'
                                  : 'Exam simulation: timed questions recorded quietly with scorecard at the end.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // 2. Question Count Subset Card
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: [
                                Text(
                                  'Question Count',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.primaryContainer,
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.pill),
                                  ),
                                  child: Text(
                                    '$targetCount of $totalAvailable MCQs',
                                    style: TextStyle(
                                      color: scheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Choose how many questions to include in this practice drill:',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: [
                                for (final count in [5, 10, 25, 50]) ...[
                                  if (totalAvailable >= count)
                                    ChoiceChip(
                                      label: Text('$count'),
                                      selected: _questionCount == count,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(
                                            () => _questionCount = count,
                                          );
                                        }
                                      },
                                    ),
                                ],
                                ChoiceChip(
                                  label: Text('All ($totalAvailable)'),
                                  selected: _questionCount >= totalAvailable,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(
                                        () => _questionCount = totalAvailable,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            if (totalAvailable > 5) ...[
                              Slider(
                                value: targetCount
                                    .toDouble()
                                    .clamp(1.0, totalAvailable.toDouble()),
                                min: 1.0,
                                max: totalAvailable.toDouble(),
                                divisions: max(1, totalAvailable - 1),
                                label: '$targetCount',
                                onChanged: (val) {
                                  setState(
                                    () => _questionCount = val.round(),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // 3. Timer Configuration Card
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 20),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Timer',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                Switch(
                                  value: _timerEnabled,
                                  onChanged: (val) =>
                                      setState(() => _timerEnabled = val),
                                ),
                              ],
                            ),
                            if (_timerEnabled) ...[
                              const Divider(),
                              SizedBox(
                                width: double.infinity,
                                child: SegmentedButton<TimerType>(
                                  showSelectedIcon: false,
                                  segments: const [
                                    ButtonSegment(
                                      value: TimerType.perQuestion,
                                      label: Text('Per-Question'),
                                    ),
                                    ButtonSegment(
                                      value: TimerType.totalExam,
                                      label: Text('Total Exam'),
                                    ),
                                  ],
                                  selected: {_timerType},
                                  onSelectionChanged: (set) =>
                                      setState(() => _timerType = set.first),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              if (_timerType == TimerType.perQuestion) ...[
                                Text(
                                  'Pace per question: $_timePerQuestionSeconds seconds',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                SizedBox(
                                  width: double.infinity,
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    value: _timePerQuestionSeconds,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 30,
                                        child: Text('30s (Rapid fire)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 45,
                                        child: Text('45s (Fast pace)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 50,
                                        child: Text('50s (INI-CET pace)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 60,
                                        child: Text('60s (NEET pace)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 90,
                                        child: Text('90s (Standard)'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(
                                          () => _timePerQuestionSeconds = val,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  'Total duration: $_totalDurationMinutes minutes',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                SizedBox(
                                  width: double.infinity,
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    value: _totalDurationMinutes,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 5,
                                        child: Text('5 mins'),
                                      ),
                                      DropdownMenuItem(
                                        value: 10,
                                        child: Text('10 mins'),
                                      ),
                                      DropdownMenuItem(
                                        value: 15,
                                        child: Text('15 mins'),
                                      ),
                                      DropdownMenuItem(
                                        value: 20,
                                        child: Text('20 mins'),
                                      ),
                                      DropdownMenuItem(
                                        value: 30,
                                        child: Text('30 mins'),
                                      ),
                                      DropdownMenuItem(
                                        value: 45,
                                        child: Text('45 mins'),
                                      ),
                                      DropdownMenuItem(
                                        value: 60,
                                        child: Text('60 mins'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(
                                          () => _totalDurationMinutes = val,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // 4. Shuffling Options Card
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Randomization Options',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Randomize Question Order'),
                              subtitle: const Text(
                                'Shuffle questions to avoid sequence predictability',
                              ),
                              value: _shuffleQuestions,
                              onChanged: (val) =>
                                  setState(() => _shuffleQuestions = val),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Shuffle Options (A, B, C, D)'),
                              subtitle: const Text(
                                'Randomize answer choice order to avoid position bias',
                              ),
                              value: _shuffleOptions,
                              onChanged: (val) =>
                                  setState(() => _shuffleOptions = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Sticky Bottom Launch Bar
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  border: Border(
                    top: BorderSide(color: scheme.outlineVariant),
                  ),
                ),
                child: AppButton(
                  label: totalAvailable > 0
                      ? 'Start Session ($targetCount MCQs)'
                      : 'No Questions Selected',
                  icon: Icons.play_arrow_rounded,
                  variant: AppButtonVariant.primary,
                  expand: true,
                  onPressed: totalAvailable > 0 ? _startSession : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
