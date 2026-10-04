import 'package:flutter/material.dart';

import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';

class SessionOptionTile extends StatelessWidget {
  const SessionOptionTile({
    required this.index,
    required this.text,
    required this.isSelected,
    required this.isPractice,
    required this.isCorrect,
    required this.hasAnswered,
    required this.isEliminated,
    required this.fontSizeScale,
    required this.onTap,
    required this.onToggleEliminate,
    super.key,
  });

  final int index;
  final String text;
  final bool isSelected;
  final bool isPractice;
  final bool isCorrect;
  final bool hasAnswered;
  final bool isEliminated;
  final double fontSizeScale;
  final VoidCallback onTap;
  final VoidCallback onToggleEliminate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final prefix = String.fromCharCode(65 + index); // A, B, C, D

    Color background = scheme.surfaceContainerLowest;
    Color border = scheme.outlineVariant;
    Color textCol = scheme.onSurface;
    IconData? icon;

    if (isPractice && hasAnswered) {
      if (isCorrect) {
        background = AppColors.success.withValues(alpha: 0.12);
        border = AppColors.success;
        textCol = AppColors.success;
        icon = Icons.check_circle_rounded;
      } else if (isSelected && !isCorrect) {
        background = AppColors.error.withValues(alpha: 0.12);
        border = AppColors.error;
        textCol = AppColors.error;
        icon = Icons.cancel_rounded;
      }
    } else if (isSelected) {
      background = scheme.primaryContainer.withValues(alpha: 0.35);
      border = scheme.primary;
      textCol = scheme.primary;
      icon = Icons.check_circle_rounded;
    }

    return Semantics(
      button: true,
      selected: isSelected,
      child: Opacity(
        opacity: isEliminated ? 0.45 : 1.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(
                  color: border,
                  width: isSelected || (isPractice && isCorrect && hasAnswered)
                      ? 2.0
                      : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPractice && hasAnswered && isCorrect
                          ? AppColors.success
                          : isPractice &&
                                hasAnswered &&
                                isSelected &&
                                !isCorrect
                          ? AppColors.error
                          : isSelected
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                    ),
                    child: Text(
                      prefix,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color:
                            isSelected ||
                                (isPractice &&
                                    hasAnswered &&
                                    (isCorrect || isSelected))
                            ? Colors.white
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textCol,
                        decoration: isEliminated
                            ? TextDecoration.lineThrough
                            : null,
                        fontSize:
                            (Theme.of(context).textTheme.bodyLarge?.fontSize ??
                                16) *
                            fontSizeScale,
                        fontWeight:
                            isSelected ||
                                (isPractice && isCorrect && hasAnswered)
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      icon,
                      color: isPractice && hasAnswered && isCorrect
                          ? AppColors.success
                          : isPractice && hasAnswered && isSelected
                          ? AppColors.error
                          : scheme.primary,
                    ),
                  ],
                  const SizedBox(width: AppSpacing.xs),

                  // Option Strike-Through Button
                  IconButton(
                    tooltip: isEliminated
                        ? 'Restore option'
                        : 'Eliminate option (✕)',
                    icon: Icon(
                      isEliminated ? Icons.undo_rounded : Icons.close_rounded,
                      size: 18,
                      color: isEliminated
                          ? scheme.primary
                          : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    onPressed: onToggleEliminate,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
