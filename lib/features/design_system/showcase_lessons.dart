import 'package:flutter/material.dart';

import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_card.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';

class LessonShowcaseSection extends StatelessWidget {
  const LessonShowcaseSection({
    required this.subject,
    required this.progress,
    required this.onProgressChanged,
    required this.onAction,
    super.key,
  });

  final InicetSubject subject;
  final double progress;
  final ValueChanged<double> onProgressChanged;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          eyebrow: 'Study components',
          title: 'High-Yield PYT Cards & Repeat Metrics',
          description:
              'Cards combine exam tags, repeat frequency, quick-recall answers, and syllabus progress without cluttering study sessions.',
        ),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final lesson = _LessonCard(
              subject: subject,
              progress: progress,
              onAction: onAction,
            );
            final side = Column(
              children: [
                _QuickPracticeCard(subject: subject, onAction: onAction),
                const SizedBox(height: AppSpacing.md),
                const AppStatusBanner(
                  title: 'Ready for offline revision',
                  message:
                      'All extracted points, summaries, and compendiums are stored locally on device.',
                  tone: AppBannerTone.success,
                ),
              ],
            );
            if (!wide) {
              return Column(
                children: [
                  lesson,
                  const SizedBox(height: AppSpacing.md),
                  side,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: lesson),
                const SizedBox(width: AppSpacing.md),
                Expanded(flex: 2, child: side),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          variant: AppCardVariant.outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adjust simulated subject mastery',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Slider(
                value: progress,
                onChanged: onProgressChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.subject,
    required this.progress,
    required this.onAction,
  });

  final InicetSubject subject;
  final double progress;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppBadge(
                label: subject.category.label,
                color: subject.color,
                icon: subject.icon,
              ),
              const Spacer(),
              AppBadge(
                label: '${subject.repeatPercent}% REPEAT RATE',
                color: AppColors.repeatTag,
                icon: Icons.trending_up_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'High-Yield PYT Compendium',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Master the core ${subject.questionCount} extracted points for ${subject.label}. '
            'Covers AIIMS (2014-2018), INICET (2020-2024), and NEET-PG cross-exam repeats.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppProgressBar(
            value: progress,
            label: 'Revision completion',
            color: subject.color,
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              AppButton(
                label: 'Start recall session',
                icon: Icons.play_arrow_rounded,
                onPressed: () => onAction('Starting ${subject.label} recall session'),
              ),
              AppButton(
                label: 'Browse questions',
                icon: Icons.list_alt_rounded,
                variant: AppButtonVariant.outline,
                onPressed: () => onAction('Browsing questions for ${subject.label}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickPracticeCard extends StatelessWidget {
  const _QuickPracticeCard({required this.subject, required this.onAction});

  final InicetSubject subject;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.filled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: subject.color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Rapid Fire Drill',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '5 high-repeat points from ${subject.label} to test your active memory.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Quick test (5 Qs)',
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () => onAction('Launching quick test for ${subject.label}'),
          ),
        ],
      ),
    );
  }
}
