import 'package:flutter/material.dart';

import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../domain/models/test_config.dart';

class SessionClockBar extends StatelessWidget {
  const SessionClockBar({
    required this.config,
    required this.remaining,
    required this.elapsed,
    required this.paused,
    required this.onPause,
    super.key,
  });
  final TestConfig config;
  final int remaining;
  final int elapsed;
  final bool paused;
  final VoidCallback? onPause;
  @override
  Widget build(BuildContext context) {
    final seconds = config.timerEnabled ? remaining : elapsed;
    final clock =
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    final color = config.timerEnabled && remaining < 60
        ? AppColors.error
        : Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_rounded,
                color: color,
                size: AppDimensions.iconSmall,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                clock,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontFamily: 'monospace', color: color),
              ),
            ],
          ),
          Text(
            !config.timerEnabled
                ? '(Elapsed time)'
                : config.timerType == TimerType.perQuestion
                ? '(${config.timePerQuestionSeconds}s/Q pace)'
                : '(Total Exam)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          TextButton.icon(
            onPressed: onPause,
            icon: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
            label: Text(paused ? 'Resume' : 'Pause'),
          ),
        ],
      ),
    );
  }
}

class QuestionTrackerRibbon extends StatelessWidget {
  const QuestionTrackerRibbon({
    required this.solved,
    required this.total,
    required this.skipped,
    required this.onNext,
    super.key,
  });
  final int solved;
  final int total;
  final int skipped;
  final VoidCallback? onNext;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.xs,
    ),
    child: Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppBadge(label: 'Solved: $solved', color: AppColors.success),
        AppBadge(label: 'Unsolved: ${total - solved}'),
        if (skipped > 0)
          AppBadge(label: 'Skipped: $skipped', color: AppColors.warning),
        TextButton.icon(
          onPressed: onNext,
          icon: const Icon(Icons.fast_forward_rounded),
          label: const Text('Next Unsolved'),
        ),
      ],
    ),
  );
}

class SessionPauseOverlay extends StatelessWidget {
  const SessionPauseOverlay({required this.onResume, super.key});
  final VoidCallback onResume;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.pause_circle_filled_rounded,
            size: AppDimensions.minTouchTarget,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Session Paused',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Question stem and options are hidden while the timer is paused.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Resume Test',
            icon: Icons.play_arrow_rounded,
            onPressed: onResume,
          ),
        ],
      ),
    ),
  );
}
