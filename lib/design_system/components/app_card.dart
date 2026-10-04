import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

enum AppCardVariant { elevated, filled, outlined }

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.variant = AppCardVariant.elevated,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    super.key,
  });

  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final decoration = BoxDecoration(
      color:
          variant == AppCardVariant.filled
              ? scheme.surfaceContainer
              : scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border:
          variant == AppCardVariant.outlined
              ? Border.all(color: scheme.outlineVariant)
              : null,
      boxShadow:
          variant == AppCardVariant.elevated
              ? [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ]
              : null,
    );

    return Semantics(
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: decoration,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
