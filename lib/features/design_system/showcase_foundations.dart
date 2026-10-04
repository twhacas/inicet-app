import 'package:flutter/material.dart';

import '../../design_system/components/app_card.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';

class FoundationShowcaseSection extends StatelessWidget {
  const FoundationShowcaseSection({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const spaces = [4.0, 8.0, 12.0, 16.0, 24.0, 32.0, 48.0, 64.0];
    final typeSamples = [
      ('Headline', Theme.of(context).textTheme.headlineLarge),
      ('Title', Theme.of(context).textTheme.titleLarge),
      ('Body', Theme.of(context).textTheme.bodyLarge),
      ('Label', Theme.of(context).textTheme.labelLarge),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          eyebrow: 'Foundations',
          title: 'Design Tokens & Clinical Precision',
          description:
              'The same semantic color roles, typography, spacing rhythm, radii, and elevation are shared across all 20 subject modules.',
        ),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final colors = AppCard(
              variant: AppCardVariant.outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Semantic colors',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _Swatch('Primary', scheme.primary),
                      _Swatch('Secondary', scheme.secondary),
                      _Swatch('Tertiary', scheme.tertiary),
                      _Swatch('Surface', scheme.surfaceContainer),
                      const _Swatch('Success', AppColors.success),
                      _Swatch('Error', scheme.error),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Spacing', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final s in spaces)
                        Container(
                          width: s,
                          height: 24,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(AppRadii.xs),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );

            final typography = AppCard(
              variant: AppCardVariant.outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Type scale',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final item in typeSamples) ...[
                    Text(item.$1, style: item.$2),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            );

            if (!wide) {
              return Column(
                children: [
                  colors,
                  const SizedBox(height: AppSpacing.md),
                  typography,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: colors),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: typography),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color);

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
