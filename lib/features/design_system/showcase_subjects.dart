import 'package:flutter/material.dart';

import '../../design_system/components/app_card.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';

class ShowcaseHero extends StatelessWidget {
  const ShowcaseHero({required this.compact, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? AppSpacing.xl : AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -56,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBadge(
                label: 'INICET DESIGN SYSTEM',
                icon: Icons.palette_outlined,
                color: scheme.onPrimary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'High-yield medical revision,\nbuilt for all devices.',
                style:
                    (compact
                            ? Theme.of(context).textTheme.headlineLarge
                            : Theme.of(context).textTheme.displayLarge)
                        ?.copyWith(color: scheme.onPrimary, height: 1.15),
              ),
              const SizedBox(height: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 630),
                child: Text(
                  'A clean, accessible visual system designed for rapid recall, '
                  'PYT repeat analysis, and high-density study across Android, iOS, iPad, Windows, and macOS.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.90),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SubjectShowcaseSection extends StatelessWidget {
  const SubjectShowcaseSection({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final InicetSubject selected;
  final ValueChanged<InicetSubject> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          eyebrow: 'Subject identity',
          title: '20 Subject Modules with Distinct Clinical Cues',
          description:
              'Every subject features an authoritative color code and icon while accessibility, contrast, and navigation stay uniform.',
        ),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final count =
                constraints.maxWidth >= 900
                    ? 4
                    : constraints.maxWidth >= 540
                    ? 2
                    : 1;
            final width =
                (constraints.maxWidth - AppSpacing.md * (count - 1)) / count;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final subject in InicetSubject.values)
                  SizedBox(
                    width: width,
                    child: _SubjectCard(
                      subject: subject,
                      selected: subject == selected,
                      onTap: () => onSelected(subject),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.selected,
    required this.onTap,
  });

  final InicetSubject subject;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: selected ? AppCardVariant.elevated : AppCardVariant.outlined,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: subject.softColor,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(subject.icon, color: subject.color),
              ),
              const Spacer(),
              if (selected)
                Icon(Icons.check_circle_rounded, color: subject.color),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            subject.label,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${subject.questionCount} Questions • ${subject.repeatPercent}% Repeat',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
