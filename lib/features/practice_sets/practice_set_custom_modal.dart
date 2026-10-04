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

class PracticeSetCustomModal extends StatefulWidget {
  const PracticeSetCustomModal({
    required this.subject,
    required this.subjectColor,
    required this.subjectIcon,
    required this.repository,
    required this.initialMode,
    super.key,
  });

  final String subject;
  final Color subjectColor;
  final IconData subjectIcon;
  final QuestionRepository repository;
  final TestMode initialMode;

  static Future<void> show(
    BuildContext context, {
    required String subject,
    required Color subjectColor,
    required IconData subjectIcon,
    required QuestionRepository repository,
    required TestMode initialMode,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PracticeSetCustomModal(
        subject: subject,
        subjectColor: subjectColor,
        subjectIcon: subjectIcon,
        repository: repository,
        initialMode: initialMode,
      ),
    );
  }

  @override
  State<PracticeSetCustomModal> createState() => _PracticeSetCustomModalState();
}

class _PracticeSetCustomModalState extends State<PracticeSetCustomModal> {
  List<McqQuestion> _allQuestions = [];
  bool _isLoading = true;

  // Filter state
  late TestMode _selectedMode;
  Set<String> _selectedSubTopics = {};
  List<String> _availableSubTopics = [];
  Map<String, int> _subTopicCounts = {};

  String _selectedExamFilter = 'all'; // 'all', 'INI-CET', 'NEET-PG', 'AIIMS'
  bool _repeatsOnly = false;

  // Question count & Shuffle
  int _questionCount = 150;
  bool _shuffleQuestions = false;
  bool _shuffleOptions = false;

  // Timer configuration
  bool _timerEnabled = true;
  TimerType _timerType = TimerType.perQuestion;
  int _timePerQuestionSeconds = 50;
  int _totalDurationMinutes = 20;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final qs = await widget.repository.loadPracticeSet(widget.subject);
    final Map<String, int> counts = {};

    for (final q in qs) {
      final topic = q.subTopic.trim().isEmpty ? 'General' : q.subTopic.trim();
      counts[topic] = (counts[topic] ?? 0) + 1;
    }

    final topics = counts.keys.toList()..sort();

    if (mounted) {
      setState(() {
        _allQuestions = qs;
        _availableSubTopics = topics;
        _subTopicCounts = counts;
        _selectedSubTopics = Set<String>.from(topics);
        _questionCount = qs.length;
        _isLoading = false;
      });
    }
  }

  List<McqQuestion> get _filteredQuestions {
    var pool = _allQuestions;

    // 1. Sub-topic filter
    if (_selectedSubTopics.length < _availableSubTopics.length) {
      pool = pool.where((q) {
        final topic = q.subTopic.trim().isEmpty ? 'General' : q.subTopic.trim();
        return _selectedSubTopics.contains(topic);
      }).toList();
    }

    // 2. Exam source filter
    if (_selectedExamFilter != 'all') {
      final ef = _selectedExamFilter.toLowerCase();
      pool = pool.where((q) {
        final tagLower = q.tag.toLowerCase();
        final examLower = q.exam.toLowerCase();
        return tagLower.contains(ef) ||
            examLower.contains(ef) ||
            (ef == 'ini-cet' && (tagLower.contains('inicet') || examLower.contains('inicet')));
      }).toList();
    }

    // 3. Repeats-only filter
    if (_repeatsOnly) {
      pool = pool.where((q) {
        return q.repeats >= 2 ||
            q.tag.contains('x') ||
            q.exam.contains('X') ||
            q.exam.contains('x');
      }).toList();
    }

    return pool;
  }

  void _selectAllSubTopics() {
    setState(() {
      _selectedSubTopics = Set<String>.from(_availableSubTopics);
    });
  }

  void _clearAllSubTopics() {
    setState(() {
      _selectedSubTopics.clear();
    });
  }

  void _toggleSubTopic(String topic) {
    setState(() {
      if (_selectedSubTopics.contains(topic)) {
        _selectedSubTopics.remove(topic);
      } else {
        _selectedSubTopics.add(topic);
      }
    });
  }

  void _startSession() {
    final matches = _filteredQuestions;
    if (matches.isEmpty) return;

    var pool = List<McqQuestion>.from(matches);

    if (_shuffleQuestions) {
      pool.shuffle();
    }

    final targetCount = min(_questionCount, pool.length);
    var selected = pool.take(targetCount).toList();

    if (_shuffleOptions) {
      selected = selected.map((q) => q.shuffleOptions()).toList();
    }

    final config = TestConfig(
      title: '${widget.subject} — Custom Practice (${selected.length} MCQs)',
      selectedSubjects: {widget.subject},
      selectedSubTopics: {widget.subject: _selectedSubTopics},
      questionCount: selected.length,
      mode: _selectedMode,
      timerEnabled: _timerEnabled,
      timerType: _timerType,
      timePerQuestionSeconds: _timePerQuestionSeconds,
      totalDurationMinutes: _totalDurationMinutes,
      shuffleQuestions: _shuffleQuestions,
      shuffleOptions: _shuffleOptions,
      repeatsOnly: _repeatsOnly,
      examFilter: _selectedExamFilter,
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
    final matches = _filteredQuestions;
    final matchesCount = matches.length;

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
                        color: widget.subjectColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Icon(
                        widget.subjectIcon,
                        color: widget.subjectColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.subject} — Custom Filters',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${_allQuestions.length} Total Curated Questions in Set',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
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

              // Scrollable Filter Settings
              if (_isLoading)
                const SizedBox(
                  height: 280,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Study Mode Selector
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Study Mode',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SegmentedButton<TestMode>(
                                segments: const [
                                  ButtonSegment(
                                    value: TestMode.practice,
                                    icon: Icon(Icons.school_rounded),
                                    label: Text('Practice Mode'),
                                  ),
                                  ButtonSegment(
                                    value: TestMode.exam,
                                    icon: Icon(Icons.timer_rounded),
                                    label: Text('Exam Mode'),
                                  ),
                                ],
                                selected: {_selectedMode},
                                onSelectionChanged: (set) =>
                                    setState(() => _selectedMode = set.first),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                _selectedMode == TestMode.practice
                                    ? 'Instant visual feedback, full rationales, and high-yield pearls after each option.'
                                    : 'Exam simulation: answers are recorded quietly without instant explanations.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // 2. Sub-Topics Selection Card
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Sub-Topics (${_selectedSubTopics.length} of ${_availableSubTopics.length})',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: _selectedSubTopics.length ==
                                            _availableSubTopics.length
                                        ? _clearAllSubTopics
                                        : _selectAllSubTopics,
                                    child: Text(
                                      _selectedSubTopics.length ==
                                              _availableSubTopics.length
                                          ? 'Clear All'
                                          : 'Select All',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Select specific topics to focus your practice drill:',
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
                                  for (final topic in _availableSubTopics) ...[
                                    FilterChip(
                                      label: Text(
                                        '$topic (${_subTopicCounts[topic] ?? 0})',
                                      ),
                                      selected:
                                          _selectedSubTopics.contains(topic),
                                      onSelected: (_) => _toggleSubTopic(topic),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // 3. Exam Source & High-Yield Repeats Filter Card
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Exam Source Filters',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.xs,
                                children: [
                                  ChoiceChip(
                                    label: const Text('All Exams'),
                                    selected: _selectedExamFilter == 'all',
                                    onSelected: (_) => setState(
                                      () => _selectedExamFilter = 'all',
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text('INI-CET Only'),
                                    selected: _selectedExamFilter == 'INI-CET',
                                    onSelected: (_) => setState(
                                      () => _selectedExamFilter = 'INI-CET',
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text('NEET-PG Only'),
                                    selected: _selectedExamFilter == 'NEET-PG',
                                    onSelected: (_) => setState(
                                      () => _selectedExamFilter = 'NEET-PG',
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text('AIIMS Only'),
                                    selected: _selectedExamFilter == 'AIIMS',
                                    onSelected: (_) => setState(
                                      () => _selectedExamFilter = 'AIIMS',
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: AppSpacing.lg),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'High-Yield Repeats Only (2X+ Tested)',
                                ),
                                subtitle: const Text(
                                  'Focus only on questions repeated multiple times in previous years',
                                ),
                                value: _repeatsOnly,
                                onChanged: (val) =>
                                    setState(() => _repeatsOnly = val),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // 4. Question Count Card
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Question Count',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const Spacer(),
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
                                      '${min(_questionCount, matchesCount)} MCQs',
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
                                '$matchesCount of ${_allQuestions.length} questions match current filters.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: matchesCount == 0
                                          ? AppColors.error
                                          : scheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.xs,
                                children: [
                                  for (final count in [10, 25, 50, 100]) ...[
                                    if (matchesCount >= count)
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
                                    label: Text('All Matching ($matchesCount)'),
                                    selected: _questionCount >= matchesCount &&
                                        matchesCount > 0,
                                    onSelected: (selected) {
                                      if (selected && matchesCount > 0) {
                                        setState(
                                          () => _questionCount = matchesCount,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              if (matchesCount > 10) ...[
                                Slider(
                                  value: min(_questionCount, matchesCount)
                                      .toDouble()
                                      .clamp(5, matchesCount.toDouble()),
                                  min: 5,
                                  max: matchesCount.toDouble(),
                                  divisions: max(1, matchesCount ~/ 5),
                                  label: '${min(_questionCount, matchesCount)}',
                                  onChanged: (val) {
                                    setState(
                                      () => _questionCount = val.toInt(),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // 5. Timer Configuration Card
                        AppCard(
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
                                SegmentedButton<TimerType>(
                                  segments: const [
                                    ButtonSegment(
                                      value: TimerType.perQuestion,
                                      label: Text('50s/Q Pace'),
                                    ),
                                    ButtonSegment(
                                      value: TimerType.totalExam,
                                      label: Text('Total Duration'),
                                    ),
                                  ],
                                  selected: {_timerType},
                                  onSelectionChanged: (set) =>
                                      setState(() => _timerType = set.first),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                if (_timerType == TimerType.perQuestion) ...[
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: AppSpacing.sm,
                                    children: [
                                      Text(
                                        'Time per question: $_timePerQuestionSeconds seconds',
                                      ),
                                      DropdownButton<int>(
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
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(
                                              () => _timePerQuestionSeconds =
                                                  val,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: AppSpacing.sm,
                                    children: [
                                      Text(
                                        'Total duration: $_totalDurationMinutes minutes',
                                      ),
                                      DropdownButton<int>(
                                        value: _totalDurationMinutes,
                                        items: const [
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
                                              () =>
                                                  _totalDurationMinutes = val,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // 6. Question Randomization Options
                        AppCard(
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
                                title:
                                    const Text('Shuffle Options (A, B, C, D)'),
                                subtitle: const Text(
                                  'Randomize choice order to prevent position bias',
                                ),
                                value: _shuffleOptions,
                                onChanged: (val) =>
                                    setState(() => _shuffleOptions = val),
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Randomize Question Order'),
                                value: _shuffleQuestions,
                                onChanged: (val) =>
                                    setState(() => _shuffleQuestions = val),
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
                  label: matchesCount > 0
                      ? 'Start Custom Test (${min(_questionCount, matchesCount)} MCQs)'
                      : 'No Matching Questions',
                  icon: Icons.play_arrow_rounded,
                  variant: AppButtonVariant.primary,
                  onPressed: matchesCount > 0 ? _startSession : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
