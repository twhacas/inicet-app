import 'package:flutter/material.dart';

import '../../data/question_repository.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_card.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../domain/models/test_config.dart';
import '../../domain/models/test_result.dart';
import '../result/test_result_screen.dart';
import '../shared/operation_feedback.dart';
import 'history_stat_metric.dart';

class TestHistoryScreen extends StatefulWidget {
  const TestHistoryScreen({required this.repository, super.key});

  final QuestionRepository repository;

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  List<TestSessionResult> _sessions = [];
  bool _isLoading = true;
  String? _error;
  int _loadRequest = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    widget.repository.addListener(_loadHistory);
  }

  @override
  void dispose() {
    widget.repository.removeListener(_loadHistory);
    super.dispose();
  }

  @override
  void didUpdateWidget(TestHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      oldWidget.repository.removeListener(_loadHistory);
      widget.repository.addListener(_loadHistory);
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    final request = ++_loadRequest;
    try {
      final list = await widget.repository.getPastTestSessions();
      if (mounted && request == _loadRequest) {
        setState(() {
          _sessions = list;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted && request == _loadRequest) {
        setState(() {
          _isLoading = false;
          _error = operationErrorMessage(error);
        });
      }
    }
  }

  Future<void> _deleteSession(String id) async {
    try {
      await widget.repository.deleteTestSession(id);
    } catch (error) {
      if (mounted) showOperationError(context, error);
    }
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Test History?'),
        content: const Text(
          'This will permanently delete all your recorded test sessions and performance analytics.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear All'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.repository.clearTestHistory();
      } catch (error) {
        if (mounted) showOperationError(context, error);
      }
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hr = dt.hour.toString().padLeft(2, '0');
    final mn = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $hr:$mn';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Test History & Analytics')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                AppButton(label: 'Retry', onPressed: _loadHistory),
              ],
            ),
          ),
        ),
      );
    }

    // Cumulative calculations
    var totalQuestions = 0;
    var totalCorrect = 0;
    final subjectScores = <String, (int correct, int total)>{};

    for (final s in _sessions) {
      totalQuestions += s.totalQuestions;
      totalCorrect += s.correctCount;
      s.subjectBreakdown.forEach((subj, stats) {
        final curr = subjectScores[subj] ?? (0, 0);
        subjectScores[subj] = (curr.$1 + stats.$1, curr.$2 + stats.$2);
      });
    }

    final overallAccuracy = totalQuestions > 0
        ? (totalCorrect / totalQuestions) * 100
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test History & Analytics'),
        actions: [
          if (_sessions.isNotEmpty)
            IconButton(
              tooltip: 'Clear history',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _confirmClearHistory,
            ),
        ],
      ),
      body: SafeArea(
        child: _sessions.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 64,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No Test Attempts Yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Complete a practice or exam session to see your test logs and analytics here.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppDimensions.contentMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Cumulative Performance Dashboard
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overall Performance',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: HistoryStatMetric(
                                      label: 'Tests Taken',
                                      value: '${_sessions.length}',
                                      color: scheme.primary,
                                    ),
                                  ),
                                  Expanded(
                                    child: HistoryStatMetric(
                                      label: 'Questions',
                                      value: '$totalQuestions',
                                      color: scheme.secondary,
                                    ),
                                  ),
                                  Expanded(
                                    child: HistoryStatMetric(
                                      label: 'Overall Accuracy',
                                      value:
                                          '${overallAccuracy.toStringAsFixed(1)}%',
                                      color: overallAccuracy >= 70
                                          ? AppColors.success
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),

                              // Subject accuracy breakdown
                              if (subjectScores.isNotEmpty) ...[
                                const Divider(height: AppSpacing.xl),
                                Text(
                                  'Subject-Wise Accuracy Trends',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                for (final entry in subjectScores.entries) ...[
                                  Builder(
                                    builder: (context) {
                                      final acc = entry.value.$2 > 0
                                          ? (entry.value.$1 / entry.value.$2) *
                                                100
                                          : 0.0;
                                      final isWeak = acc < 60;
                                      final isStrong = acc >= 75;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: AppSpacing.xs,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                entry.key,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 4,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppRadii.pill,
                                                    ),
                                                child: LinearProgressIndicator(
                                                  value: acc / 100,
                                                  minHeight: 6,
                                                  color: isWeak
                                                      ? AppColors.error
                                                      : isStrong
                                                      ? AppColors.success
                                                      : AppColors.primary,
                                                  backgroundColor: scheme
                                                      .surfaceContainerHighest,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            Text(
                                              '${acc.toStringAsFixed(0)}%',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                                color: isWeak
                                                    ? AppColors.error
                                                    : isStrong
                                                    ? AppColors.success
                                                    : scheme.onSurface,
                                              ),
                                            ),
                                            if (isWeak) ...[
                                              const SizedBox(width: 4),
                                              const AppBadge(
                                                label: 'WEAK',
                                                color: AppColors.error,
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // 2. Chronological Test Log
                        Text(
                          'Test History (${_sessions.length} attempts)',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        for (final s in _sessions) ...[
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        s.config.title.isNotEmpty
                                            ? s.config.title
                                            : '${s.config.selectedSubjects.isEmpty ? "All Subjects" : s.config.selectedSubjects.first} • ${s.totalQuestions} MCQs',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    AppBadge(
                                      label: s.config.mode == TestMode.practice
                                          ? 'PRACTICE'
                                          : 'EXAM',
                                      color: s.config.mode == TestMode.practice
                                          ? scheme.secondary
                                          : AppColors.warning,
                                    ),
                                    IconButton(
                                      tooltip: 'Delete attempt',
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () => _deleteSession(
                                        s.id ??
                                            s.startedAt.millisecondsSinceEpoch
                                                .toString(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  _formatDate(s.completedAt),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                                const Divider(height: AppSpacing.lg),
                                Row(
                                  children: [
                                    Text(
                                      'Score: ${s.correctCount}/${s.totalQuestions} (${s.accuracyPercent.toStringAsFixed(1)}%)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: s.accuracyPercent >= 70
                                            ? AppColors.success
                                            : scheme.onSurface,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 14,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDuration(s.totalTimeSpentSeconds),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppButton(
                                  label: 'Review Full Test',
                                  icon: Icons.checklist_rounded,
                                  variant: AppButtonVariant.outline,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => TestResultScreen(
                                          result: s,
                                          repository: widget.repository,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
