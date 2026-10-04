import 'package:flutter/material.dart';

import '../../data/question_repository.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_card.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../domain/models/test_config.dart';
import '../../domain/models/test_result.dart';
import '../test/mcq_session_screen.dart';
import 'review_question_card.dart';
import 'result_score_summary.dart';

enum ReviewFilter { all, incorrect, flagged, correct }

class TestResultScreen extends StatefulWidget {
  const TestResultScreen({
    required this.result,
    required this.repository,
    super.key,
  });

  final TestSessionResult result;
  final QuestionRepository repository;

  @override
  State<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen> {
  ReviewFilter _filter = ReviewFilter.all;

  void _reattemptIncorrect() {
    final incorrect = widget.result.incorrectQuestions;
    if (incorrect.isEmpty) return;

    final config = widget.result.config.copyWith(
      questionCount: incorrect.length,
      mode: TestMode.practice,
      timerEnabled: false,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => McqSessionScreen(
          questions: List.from(incorrect),
          config: config,
          repository: widget.repository,
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final res = widget.result;

    // Filter questions
    final filteredIndices = <int>[];
    for (var i = 0; i < res.questions.length; i++) {
      final ans = res.userAnswers[i];
      final isCorrect =
          ans != null &&
          ans.selectedOptionIndex == res.questions[i].correctIndex;
      final isIncorrect =
          ans != null &&
          ans.isAttempted &&
          ans.selectedOptionIndex != res.questions[i].correctIndex;
      final isFlagged = ans?.isFlagged ?? false;

      switch (_filter) {
        case ReviewFilter.all:
          filteredIndices.add(i);
          break;
        case ReviewFilter.incorrect:
          if (isIncorrect) filteredIndices.add(i);
          break;
        case ReviewFilter.flagged:
          if (isFlagged) filteredIndices.add(i);
          break;
        case ReviewFilter.correct:
          if (isCorrect) filteredIndices.add(i);
          break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance & Review'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (res.timedOut) ...[
                    const AppStatusBanner(
                      title: 'Time limit reached',
                      message: 'Your test was automatically submitted when the timer ended.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  ResultScoreSummary(
                    result: res,
                    duration: _formatDuration(res.totalTimeSpentSeconds),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Action Buttons
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      if (res.incorrectCount > 0)
                        AppButton(
                          label: 'Re-attempt Incorrect (${res.incorrectCount})',
                          icon: Icons.refresh_rounded,
                          variant: AppButtonVariant.primary,
                          onPressed: _reattemptIncorrect,
                        ),
                      AppButton(
                        label: 'Start New Test',
                        icon: Icons.add_rounded,
                        variant: AppButtonVariant.outline,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Subject Breakdown
                  if (res.subjectBreakdown.isNotEmpty) ...[
                    Text(
                      'Subject Breakdown',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      variant: AppCardVariant.outlined,
                      child: Column(
                        children: [
                          for (final entry in res.subjectBreakdown.entries) ...[
                            Padding(
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
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.pill,
                                      ),
                                      child: LinearProgressIndicator(
                                        value: entry.value.$2 > 0
                                            ? entry.value.$1 / entry.value.$2
                                            : 0,
                                        minHeight: 6,
                                        color: AppColors.success,
                                        backgroundColor:
                                            scheme.surfaceContainerHighest,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Text(
                                    '${entry.value.$1}/${entry.value.$2}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Question Review Filter Header
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    children: [
                      Text(
                        'Review Questions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SegmentedButton<ReviewFilter>(
                        segments: [
                          ButtonSegment(
                            value: ReviewFilter.all,
                            label: Text('All (${res.totalQuestions})'),
                          ),
                          ButtonSegment(
                            value: ReviewFilter.incorrect,
                            label: Text('Missed (${res.incorrectCount})'),
                          ),
                          ButtonSegment(
                            value: ReviewFilter.flagged,
                            label: Text(
                              'Flagged (${res.flaggedQuestions.length})',
                            ),
                          ),
                        ],
                        selected: {_filter},
                        onSelectionChanged: (set) {
                          setState(() => _filter = set.first);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Review Questions List
                  if (filteredIndices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Center(
                        child: Text(
                          'No questions match the current filter.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    for (final idx in filteredIndices) ...[
                      ReviewQuestionCard(
                        key: ValueKey(res.questions[idx].id),
                        index: idx,
                        question: res.questions[idx],
                        answer: res.userAnswers[idx],
                        repository: widget.repository,
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
