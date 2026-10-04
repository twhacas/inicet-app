import 'dart:math';

import 'package:flutter/material.dart';

import '../../design_system/components/app_card.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../domain/models/test_config.dart';
import '../../domain/models/test_result.dart';

class ResultScoreSummary extends StatelessWidget {
  const ResultScoreSummary({
    required this.result,
    required this.duration,
    super.key,
  });
  final TestSessionResult result;
  final String duration;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accuracyColor = result.accuracyPercent >= 70
        ? AppColors.success
        : result.accuracyPercent >= 50
        ? AppColors.warning
        : AppColors.error;
    final metrics = [
      (
        'Accuracy',
        '${result.accuracyPercent.toStringAsFixed(1)}%',
        accuracyColor,
      ),
      ('Correct', '${result.correctCount}', AppColors.success),
      ('Incorrect', '${result.incorrectCount}', AppColors.error),
      ('Skipped', '${result.unattemptedCount}', scheme.onSurfaceVariant),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppBadge(
                label: result.config.mode == TestMode.exam
                    ? 'EXAM RESULT'
                    : 'PRACTICE RESULT',
                color: scheme.primary,
                icon: Icons.emoji_events_rounded,
              ),
              Text(
                'Time: $duration',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final preferredColumns =
                  constraints.maxWidth < AppDimensions.compactBreakpoint
                  ? 2
                  : 4;
              var minimumWidth = 0.0;
              for (final metric in metrics) {
                final label = TextPainter(
                  text: TextSpan(
                    text: metric.$1,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout();
                minimumWidth = max(
                  minimumWidth,
                  label.width + AppSpacing.md * 2,
                );
                label.dispose();
              }
              final columns = min(
                preferredColumns,
                max(
                  1,
                  ((constraints.maxWidth + AppSpacing.sm) /
                          (minimumWidth + AppSpacing.sm))
                      .floor(),
                ),
              );
              final width =
                  (constraints.maxWidth - AppSpacing.sm * (columns - 1)) /
                  columns;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final metric in metrics)
                    SizedBox(
                      width: width,
                      child: _ScoreMetric(
                        label: metric.$1,
                        value: metric.$2,
                        color: metric.$3,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppProgressBar(
            value: result.totalQuestions > 0
                ? result.correctCount / result.totalQuestions
                : 0,
            label:
                'Overall Score (${result.correctCount} of ${result.totalQuestions})',
            color: result.accuracyPercent >= 70
                ? AppColors.success
                : AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _ScoreMetric extends StatelessWidget {
  const _ScoreMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
