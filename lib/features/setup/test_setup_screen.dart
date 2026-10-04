import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/question_repository.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_card.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../domain/models/test_config.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../history/test_history_screen.dart';
import '../import/import_questions_dialog.dart';
import '../test/mcq_session_screen.dart';

class TestSetupScreen extends StatefulWidget {
  const TestSetupScreen({
    required this.repository,
    required this.onToggleTheme,
    required this.isDark,
    this.embedded = false,
    super.key,
  });

  final QuestionRepository repository;
  final VoidCallback onToggleTheme;
  final bool isDark;
  final bool embedded;

  @override
  State<TestSetupScreen> createState() => _TestSetupScreenState();
}

class _TestSetupScreenState extends State<TestSetupScreen> {
  final Set<String> _selectedSubjects = {};
  final Map<String, Set<String>> _selectedSubTopics = {};
  final TextEditingController _titleController = TextEditingController();

  int _questionCount = 25;
  TestMode _mode = TestMode.practice;
  String _selectedExamFilter = 'all';
  bool _repeatsOnly = false;
  bool _shuffleQuestions = true;
  bool _shuffleOptions = true;
  bool _repeatsPriority = false;

  // Timer configuration
  bool _timerEnabled = true;
  TimerType _timerType = TimerType.perQuestion;
  int _timePerQuestionSeconds = 50; // Standard INI-CET pace
  int _totalDurationMinutes = 25;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _initRepository() async {
    if (!widget.repository.isInitialized) {
      await widget.repository.init();
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
        _selectAllSubjects();
      });
    }
  }

  void _selectAllSubjects() {
    final allSubs = widget.repository.getAvailableSubjects();
    _selectedSubjects.clear();
    _selectedSubjects.addAll(allSubs);
    _selectedSubTopics.clear();
  }

  void _clearSubjects() {
    setState(() {
      _selectedSubjects.clear();
      _selectedSubTopics.clear();
    });
  }

  void _toggleSubject(String subject) {
    setState(() {
      if (_selectedSubjects.contains(subject)) {
        _selectedSubjects.remove(subject);
        _selectedSubTopics.remove(subject);
      } else {
        _selectedSubjects.add(subject);
      }
    });
  }

  void _openSubTopicPicker(String subject) {
    final subTopics = widget.repository.getSubTopicsForSubject(subject);
    final currentSelected =
        _selectedSubTopics[subject] ?? subTopics.toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isAllSelected = currentSelected.length == subTopics.length;
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$subject Sub-topics',
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    TextButton(
                      child: Text(isAllSelected ? 'Deselect All' : 'Select All'),
                      onPressed: () {
                        setModalState(() {
                          if (isAllSelected) {
                            currentSelected.clear();
                          } else {
                            currentSelected.addAll(subTopics);
                          }
                        });
                      },
                    ),
                    const Spacer(),
                    Text(
                      '${currentSelected.length} of ${subTopics.length} selected',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const Divider(),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: subTopics.length,
                    itemBuilder: (context, idx) {
                      final topic = subTopics[idx];
                      final checked = currentSelected.contains(topic);
                      return CheckboxListTile(
                        dense: true,
                        title: Text(topic),
                        value: checked,
                        onChanged: (val) {
                          setModalState(() {
                            if (val == true) {
                              currentSelected.add(topic);
                            } else {
                              currentSelected.remove(topic);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Done',
                  onPressed: () {
                    setState(() {
                      _selectedSubTopics[subject] = Set.from(currentSelected);
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _startSession() {
    final poolCount = widget.repository.getFilteredCount(
      selectedSubjects: _selectedSubjects,
      selectedSubTopics: _selectedSubTopics,
      examFilter: _selectedExamFilter,
      repeatsOnly: _repeatsOnly,
    );

    if (poolCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No questions match the current filters. Adjust your subjects or exam filters.'),
        ),
      );
      return;
    }

    final effectiveCount = min(_questionCount, poolCount);

    final config = TestConfig(
      title: _titleController.text.trim(),
      examFilter: _selectedExamFilter,
      repeatsOnly: _repeatsOnly,
      selectedSubjects: _selectedSubjects,
      selectedSubTopics: _selectedSubTopics,
      questionCount: effectiveCount,
      shuffleQuestions: _shuffleQuestions,
      shuffleOptions: _shuffleOptions,
      repeatsPriority: _repeatsPriority,
      mode: _mode,
      timerEnabled: _timerEnabled,
      timerType: _timerType,
      timePerQuestionSeconds: _timePerQuestionSeconds,
      totalDurationMinutes: _totalDurationMinutes,
    );

    final questions = widget.repository.generateTest(config);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => McqSessionScreen(
          questions: questions,
          config: config,
          repository: widget.repository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final availableMatches = widget.repository.getFilteredCount(
      selectedSubjects: _selectedSubjects,
      selectedSubTopics: _selectedSubTopics,
      examFilter: _selectedExamFilter,
      repeatsOnly: _repeatsOnly,
    );
    final allSubjects = widget.repository.getAvailableSubjects();
    final isAllSubjects = _selectedSubjects.length == allSubjects.length;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.contentMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom Test Title Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custom Test Name (Optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Cranial Nerves & Head-Neck Mock',
                        prefixIcon: const Icon(Icons.title_rounded, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Test Mode Segmented Control
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Study Mode',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
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
                      selected: {_mode},
                      onSelectionChanged: (set) {
                        setState(() => _mode = set.first);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _mode.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Exam Source & Repeat Filters Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exam Source & Focus',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        ChoiceChip(
                          label: const Text('All Exams'),
                          selected: _selectedExamFilter == 'all',
                          onSelected: (_) =>
                              setState(() => _selectedExamFilter = 'all'),
                        ),
                        ChoiceChip(
                          label: const Text('INI-CET Only'),
                          selected: _selectedExamFilter == 'INI-CET',
                          onSelected: (_) =>
                              setState(() => _selectedExamFilter = 'INI-CET'),
                        ),
                        ChoiceChip(
                          label: const Text('NEET-PG Only'),
                          selected: _selectedExamFilter == 'NEET-PG',
                          onSelected: (_) =>
                              setState(() => _selectedExamFilter = 'NEET-PG'),
                        ),
                        ChoiceChip(
                          label: const Text('AIIMS Only'),
                          selected: _selectedExamFilter == 'AIIMS',
                          onSelected: (_) =>
                              setState(() => _selectedExamFilter = 'AIIMS'),
                        ),
                      ],
                    ),
                    const Divider(height: AppSpacing.lg),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('High-Yield Repeats Only (2X+ Tested)'),
                      subtitle: const Text(
                        'Include only questions tested multiple times in previous years',
                      ),
                      value: _repeatsOnly,
                      onChanged: (val) => setState(() => _repeatsOnly = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Subject and Sub-Topic Selection Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Subjects (${_selectedSubjects.length} of ${allSubjects.length})',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            if (isAllSubjects) {
                              _clearSubjects();
                            } else {
                              setState(() => _selectAllSubjects());
                            }
                          },
                          child:
                              Text(isAllSubjects ? 'Clear All' : 'Select All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tap subject to toggle. Tap subtitle/topic icon to filter sub-topics.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Subject chips
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final sub in allSubjects) ...[
                          _SubjectSelectChip(
                            subject: sub,
                            isSelected: _selectedSubjects.contains(sub),
                            subTopicsCount: widget.repository
                                .getSubTopicsForSubject(sub)
                                .length,
                            selectedTopicsCount:
                                _selectedSubTopics[sub]?.length,
                            onToggle: () => _toggleSubject(sub),
                            onOpenTopics: () => _openSubTopicPicker(sub),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Number of Questions Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Question Count',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            '$_questionCount MCQs',
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
                      '$availableMatches questions match current filters.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Presets
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        for (final count in [10, 25, 50, 100]) ...[
                          ChoiceChip(
                            label: Text('$count'),
                            selected: _questionCount == count,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _questionCount = count);
                              }
                            },
                          ),
                        ],
                        ChoiceChip(
                          label: const Text('All Available'),
                          selected: _questionCount == availableMatches &&
                              availableMatches > 0,
                          onSelected: (selected) {
                            if (selected && availableMatches > 0) {
                              setState(
                                  () => _questionCount = availableMatches);
                            }
                          },
                        ),
                      ],
                    ),

                    if (availableMatches > 10) ...[
                      Slider(
                        value: min(_questionCount, availableMatches).toDouble(),
                        min: 5,
                        max: min(200, availableMatches).toDouble(),
                        divisions: min(availableMatches ~/ 5, 39),
                        label: '$_questionCount',
                        onChanged: (val) {
                          setState(() => _questionCount = val.toInt());
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Timer Configuration Card
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
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _timerEnabled,
                          onChanged: (val) {
                            setState(() => _timerEnabled = val);
                          },
                        ),
                      ],
                    ),
                    if (_timerEnabled) ...[
                      const Divider(),
                      SegmentedButton<TimerType>(
                        segments: const [
                          ButtonSegment(
                            value: TimerType.perQuestion,
                            label: Text('Per-Question Pace'),
                          ),
                          ButtonSegment(
                            value: TimerType.totalExam,
                            label: Text('Total Exam Time'),
                          ),
                        ],
                        selected: {_timerType},
                        onSelectionChanged: (set) {
                          setState(() => _timerType = set.first);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_timerType == TimerType.perQuestion) ...[
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            Text('Time per question: $_timePerQuestionSeconds seconds'),
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
                                  child: Text('50s (INI-CET standard)'),
                                ),
                                DropdownMenuItem(
                                  value: 60,
                                  child: Text('60s (NEET-PG standard)'),
                                ),
                                DropdownMenuItem(
                                  value: 90,
                                  child: Text('90s (Relaxed pace)'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(
                                      () => _timePerQuestionSeconds = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ] else ...[
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            Text('Total duration: $_totalDurationMinutes minutes'),
                            DropdownButton<int>(
                              value: _totalDurationMinutes,
                              items: const [
                                DropdownMenuItem(value: 10, child: Text('10 mins')),
                                DropdownMenuItem(value: 15, child: Text('15 mins')),
                                DropdownMenuItem(value: 20, child: Text('20 mins')),
                                DropdownMenuItem(value: 30, child: Text('30 mins')),
                                DropdownMenuItem(value: 45, child: Text('45 mins')),
                                DropdownMenuItem(value: 60, child: Text('60 mins')),
                                DropdownMenuItem(value: 90, child: Text('90 mins')),
                                DropdownMenuItem(value: 120, child: Text('120 mins')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(
                                      () => _totalDurationMinutes = val);
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

              const SizedBox(height: AppSpacing.lg),

              // Shuffle & Randomization Options Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question Options',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Shuffle Options (A, B, C, D)'),
                      subtitle: const Text('Randomize choice order to prevent position bias'),
                      value: _shuffleOptions,
                      onChanged: (val) => setState(() => _shuffleOptions = val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Randomize Question Order'),
                      value: _shuffleQuestions,
                      onChanged: (val) =>
                          setState(() => _shuffleQuestions = val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('High-Repeat Questions First'),
                      subtitle: const Text('Prioritize high-yield repeat questions in test'),
                      value: _repeatsPriority,
                      onChanged: (val) =>
                          setState(() => _repeatsPriority = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Launch Button
              AppButton(
                label: 'Start Test (${min(_questionCount, availableMatches)} MCQs)',
                icon: Icons.play_arrow_rounded,
                variant: AppButtonVariant.primary,
                onPressed: availableMatches > 0 ? _startSession : null,
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_rounded),
            SizedBox(width: AppSpacing.sm),
            Text('INICET MCQ Hub'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Past Test History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      TestHistoryScreen(repository: widget.repository),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Import / Export JSON Questions',
            icon: const Icon(Icons.file_upload_rounded),
            onPressed: () async {
              final changed = await ImportQuestionsDialog.show(
                context,
                widget.repository,
              );
              if (changed == true) {
                setState(() => _selectAllSubjects());
              }
            },
          ),
          IconButton(
            tooltip: 'Bookmarks',
            icon: const Icon(Icons.bookmark_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      BookmarksScreen(repository: widget.repository),
                ),
              );
            },
          ),
          IconButton(
            tooltip: widget.isDark ? 'Light theme' : 'Dark theme',
            icon: Icon(
              widget.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(child: content),
    );
  }
}

class _SubjectSelectChip extends StatelessWidget {
  const _SubjectSelectChip({
    required this.subject,
    required this.isSelected,
    required this.subTopicsCount,
    required this.selectedTopicsCount,
    required this.onToggle,
    required this.onOpenTopics,
  });

  final String subject;
  final bool isSelected;
  final int subTopicsCount;
  final int? selectedTopicsCount;
  final VoidCallback onToggle;
  final VoidCallback onOpenTopics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCustomTopics =
        selectedTopicsCount != null && selectedTopicsCount! < subTopicsCount;

    return FilterChip(
      selected: isSelected,
      avatar: isSelected
          ? const Icon(Icons.check_rounded, size: 16)
          : const Icon(Icons.radio_button_unchecked, size: 16),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(subject),
          if (subTopicsCount > 1) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onOpenTopics,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isCustomTopics
                      ? AppColors.warning.withValues(alpha: 0.2)
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isCustomTopics
                          ? '$selectedTopicsCount/$subTopicsCount'
                          : '$subTopicsCount',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isCustomTopics
                            ? AppColors.warning
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      onSelected: (_) => onToggle(),
    );
  }
}
