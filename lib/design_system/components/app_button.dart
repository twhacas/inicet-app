import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outline, text, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeOnPressed = loading ? null : onPressed;
    final foreground = switch (variant) {
      AppButtonVariant.primary => scheme.onPrimary,
      AppButtonVariant.secondary => scheme.onSecondaryContainer,
      AppButtonVariant.outline || AppButtonVariant.text => scheme.primary,
      AppButtonVariant.destructive => scheme.onError,
    };
    final background = switch (variant) {
      AppButtonVariant.primary => scheme.primary,
      AppButtonVariant.secondary => scheme.secondaryContainer,
      AppButtonVariant.destructive => scheme.error,
      _ => Colors.transparent,
    };

    return Opacity(
      opacity: activeOnPressed == null && !loading ? 0.56 : 1,
      child: Semantics(
        button: true,
        enabled: activeOnPressed != null,
        label: loading ? '$label, loading' : label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: activeOnPressed,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppDimensions.minTouchTarget,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: background,
                  gradient:
                      variant == AppButtonVariant.primary &&
                              activeOnPressed != null
                          ? LinearGradient(
                            colors: [scheme.primary, scheme.tertiary],
                          )
                          : null,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border:
                      variant == AppButtonVariant.outline
                          ? Border.all(color: scheme.outline)
                          : null,
                ),
                child: Row(
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (loading) ...[
                      SizedBox.square(
                        dimension: AppDimensions.iconSmall,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ] else if (icon != null) ...[
                      Icon(
                        icon,
                        size: AppDimensions.iconSmall,
                        color: foreground,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color:
                              onPressed == null
                                  ? scheme.onSurface.withValues(alpha: 0.38)
                                  : foreground,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
