import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

class AppBadge extends StatelessWidget {
  const AppBadge({required this.label, this.color, this.icon, super.key});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badgeColor = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
      ),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: 15, color: badgeColor),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: badgeColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.value,
    this.label,
    this.color,
    super.key,
  });

  final double value;
  final String? label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progressColor = color ?? scheme.primary;
    final safeValue = value.clamp(0.0, 1.0);
    final percent = (safeValue * 100).round().toString();
    return Semantics(
      label: label ?? 'Progress',
      value: '$percent percent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label!,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: safeValue,
              color: progressColor,
              backgroundColor: progressColor.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

enum AppBannerTone { info, success, warning, error }

class AppStatusBanner extends StatelessWidget {
  const AppStatusBanner({
    required this.title,
    required this.message,
    this.tone = AppBannerTone.info,
    super.key,
  });

  final String title;
  final String message;
  final AppBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (color, icon) = switch (tone) {
      AppBannerTone.success => (
        isDark ? AppColors.successDark : AppColors.success,
        Icons.check_circle_rounded,
      ),
      AppBannerTone.warning => (
        isDark ? AppColors.warningDark : AppColors.warning,
        Icons.warning_amber_rounded,
      ),
      AppBannerTone.error => (scheme.error, Icons.error_rounded),
      AppBannerTone.info => (
        isDark ? AppColors.infoDark : AppColors.info,
        Icons.info_rounded,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color.withValues(alpha: 0.28)),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: color, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(message, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    required this.title,
    required this.description,
    this.eyebrow,
    super.key,
  });

  final String title;
  final String description;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
