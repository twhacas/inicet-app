import 'package:flutter/material.dart';

import '../../data/mock_test_builder.dart';
import '../../data/question_repository.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_card.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../domain/models/mock_blueprint.dart';
import '../../domain/models/test_config.dart';
import '../test/mcq_session_screen.dart';

/// Full-length mock papers, drawn fresh each time from the bundled questions.
///
/// Subject-wise practice trains recall. Only a full paper trains pacing across
/// 200 questions and the cost of switching subjects, so this section always
/// assembles a complete paper rather than a subject slice.
class MockTestsTab extends StatefulWidget {
  const MockTestsTab({required this.repository, super.key});

  final QuestionRepository repository;

  @override
  State<MockTestsTab> createState() => _MockTestsTabState();
}

class _MockTestsTabState extends State<MockTestsTab> {
  static const _lengthPresets = [50, 100, 150, 200];
  static const _durationPresets = [45, 90, 120, 150, 180];

  late final MockTestBuilder _builder = MockTestBuilder(
    repository: widget.repository,
  );

  /// Resolved once, not per build: a future created inside build() restarts on
  /// every rebuild and the tab never settles.
  late final Future<MockBlueprint> _blueprint = _builder.loadBlueprint();

  int _total = 200;
  int _pyqPercent = 50;
  int? _minutes = 180;
  TestMode _mode = TestMode.exam;
  bool _building = false;
  bool _showBlueprint = false;

  int get _effectiveMinutes => _minutes ?? ((_total * 54) / 60).ceil();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MockBlueprint>(
      future: _blueprint,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _MockMessage(
            icon: Icons.error_outline_rounded,
            title: 'Blueprint unavailable',
            detail:
                'Could not read ${MockTestBuilder.blueprintAsset}. Regenerate it '
                'with "python scripts/build_mock_tests.py --blueprint-only".',
          );
        }
        if (!snapshot.hasData) {
          // Deliberately static. An IndexedStack builds every tab, so a
          // spinner here would animate while another tab is on screen.
          return const Center(child: Text('Preparing the blueprint…'));
        }
        return _buildForm(context, snapshot.data!);
      },
    );
  }

  Widget _buildForm(BuildContext context, MockBlueprint plan) {
    final theme = Theme.of(context);
    final allocation = plan.allocate(_total);
    final pyqShort = plan.subjects
        .where((subject) => subject.pyqAvailable == 0)
        .map((subject) => subject.name)
        .toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.contentMaxWidth,
        ),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppCard(
              variant: AppCardVariant.filled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timer_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Full-length mock paper',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Every subject appears in the proportion the real papers '
                    'asked it, measured over INI-CET '
                    '${plan.years.join(', ')} (${plan.recordedTotal} recorded '
                    'questions). Questions are drawn at random, so no two '
                    'papers are the same.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _Section(
              title: 'Paper length',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final preset in _lengthPresets)
                        ChoiceChip(
                          label: Text('$preset Qs'),
                          selected: _total == preset,
                          onSelected: (_) => setState(() => _total = preset),
                        ),
                    ],
                  ),
                  Slider(
                    value: _total.toDouble(),
                    min: 20,
                    max: 200,
                    divisions: 36,
                    label: '$_total questions',
                    onChanged: (value) =>
                        setState(() => _total = value.round()),
                  ),
                ],
              ),
            ),

            _Section(
              title: 'Where the questions come from',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_pyqPercent% previous-year  ·  '
                    '${100 - _pyqPercent}% practice-set',
                    style: theme.textTheme.titleMedium,
                  ),
                  Slider(
                    value: _pyqPercent.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '$_pyqPercent% previous-year',
                    onChanged: (value) =>
                        setState(() => _pyqPercent = value.round()),
                  ),
                  Text(
                    'Previous-year questions are the real past papers. '
                    'Practice-set questions are the authored ones, which '
                    'reword a tested fact or sit next to a hot cluster.',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (_pyqPercent > 0 && pyqShort.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _Note(
                      'No previous-year questions are bundled for '
                      '${pyqShort.join(', ')} — their share is filled from the '
                      'practice sets instead.',
                    ),
                  ],
                ],
              ),
            ),

            _Section(
              title: 'Time limit',
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ChoiceChip(
                    label: Text('Exam pace ($_effectiveMinutes min)'),
                    selected: _minutes == null,
                    onSelected: (_) => setState(() => _minutes = null),
                  ),
                  for (final preset in _durationPresets)
                    ChoiceChip(
                      label: Text('$preset min'),
                      selected: _minutes == preset,
                      onSelected: (_) => setState(() => _minutes = preset),
                    ),
                ],
              ),
            ),

            _Section(
              title: 'Mode',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Text(_mode.description, style: theme.textTheme.bodySmall),
                ],
              ),
            ),

            AppCard(
              variant: AppCardVariant.outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () =>
                        setState(() => _showBlueprint = !_showBlueprint),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Subject split for $_total questions',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Icon(
                            _showBlueprint
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showBlueprint)
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                      },
                      children: [
                        for (final subject in plan.subjects)
                          if ((allocation[subject.name] ?? 0) > 0)
                            TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xs,
                                  ),
                                  child: Text(subject.name),
                                ),
                                Text('${allocation[subject.name]}'),
                                Text(
                                  '${(100 * subject.weight / plan.weightTotal).toStringAsFixed(1)}%',
                                  textAlign: TextAlign.end,
                                ),
                              ],
                            ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppButton(
              label: _building
                  ? 'Assembling paper…'
                  : 'Start mock paper · $_total Qs · $_effectiveMinutes min',
              icon: Icons.play_arrow_rounded,
              expand: true,
              loading: _building,
              onPressed: _building ? null : () => _start(plan),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sit it in one block. Note the time at every fiftieth question — '
              'pace is what a full paper teaches and a subject set cannot.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _start(MockBlueprint plan) async {
    setState(() => _building = true);
    final MockPaper paper;
    try {
      paper = await _builder.build(total: _total, pyqPercent: _pyqPercent);
    } catch (error) {
      if (!mounted) return;
      setState(() => _building = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not build the paper: $error')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _building = false);

    if (paper.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions available for a paper.')),
      );
      return;
    }
    if (paper.shortfalls.isNotEmpty) {
      final short = paper.shortfalls.entries
          .map((entry) => '${entry.key} (${entry.value})')
          .join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Paper is ${paper.length} questions — short in $short.',
          ),
        ),
      );
    }

    final config = TestConfig(
      title: 'Mock Paper — ${paper.length} Qs '
          '(${paper.pyqCount} PYQ / ${paper.practiceCount} practice)',
      selectedSubjects: paper.perSubject.keys.toSet(),
      selectedSubTopics: const {},
      questionCount: paper.length,
      mode: _mode,
      timerEnabled: true,
      timerType: TimerType.totalExam,
      totalDurationMinutes: _effectiveMinutes,
      shuffleQuestions: false,
      shuffleOptions: false,
    );

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => McqSessionScreen(
          questions: paper.questions,
          config: config,
          repository: widget.repository,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: AppDimensions.iconSmall,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockMessage extends StatelessWidget {
  const _MockMessage({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSpacing.xxl, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              detail,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
