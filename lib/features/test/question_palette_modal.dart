import 'package:flutter/material.dart';

import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../domain/models/test_result.dart';

class QuestionPaletteModal extends StatelessWidget {
  const QuestionPaletteModal({
    required this.totalQuestions,
    required this.currentIndex,
    required this.answers,
    required this.skippedIndices,
    required this.onSelect,
    super.key,
  });

  final int totalQuestions;
  final int currentIndex;
  final Map<int, UserAnswer> answers;
  final Set<int> skippedIndices;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Question Palette',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Status Legend
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _LegendItem(color: AppColors.success, label: 'Answered'),
              _LegendItem(
                color: scheme.surfaceContainerHighest,
                label: 'Unanswered',
              ),
              _LegendItem(color: AppColors.warning, label: 'Skipped'),
              _LegendItem(color: AppColors.info, label: 'Flagged'),
            ],
          ),
          const Divider(height: AppSpacing.xl),

          // Palette Grid (1..N)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 52,
                crossAxisSpacing: AppSpacing.xs,
                mainAxisSpacing: AppSpacing.xs,
              ),
              itemCount: totalQuestions,
              itemBuilder: (context, index) {
                final isCurrent = index == currentIndex;
                final ans = answers[index];
                final isAttempted = ans?.isAttempted ?? false;
                final isFlagged = ans?.isFlagged ?? false;
                final isSkipped = skippedIndices.contains(index);

                Color bg = scheme.surfaceContainerHighest;
                Color textCol = scheme.onSurfaceVariant;

                if (isAttempted) {
                  bg = AppColors.success;
                  textCol = Colors.white;
                } else if (isSkipped) {
                  bg = AppColors.warning.withValues(alpha: 0.25);
                  textCol = AppColors.warning;
                }

                return InkWell(
                  onTap: () => onSelect(index),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: isCurrent
                            ? scheme.primary
                            : isFlagged
                            ? AppColors.info
                            : Colors.transparent,
                        width: isCurrent || isFlagged ? 2.5 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: textCol,
                              fontWeight: isCurrent
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (isFlagged)
                          const Positioned(
                            top: 2,
                            right: 2,
                            child: Icon(
                              Icons.flag_rounded,
                              size: 10,
                              color: AppColors.info,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
