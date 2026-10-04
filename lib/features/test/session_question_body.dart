import 'package:flutter/material.dart';

import '../../design_system/components/app_card.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../domain/models/mcq_question.dart';
import 'session_explanation_card.dart';
import 'session_option_tile.dart';

class SessionQuestionBody extends StatelessWidget {
  const SessionQuestionBody({
    required this.question,
    required this.selectedOption,
    required this.isPractice,
    required this.isFlagged,
    required this.eliminated,
    required this.fontScale,
    required this.onSelect,
    required this.onEliminate,
    super.key,
  });
  final McqQuestion question;
  final int? selectedOption;
  final bool isPractice;
  final bool isFlagged;
  final Set<int> eliminated;
  final double fontScale;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onEliminate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final note = question.userNote;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.contentMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  AppBadge(label: question.subject, color: scheme.primary),
                  AppBadge(label: question.subTopic, color: scheme.secondary),
                  if (question.repeats >= 2)
                    AppBadge(
                      label: '${question.repeats}X REPEAT',
                      color: AppColors.repeatTag,
                      icon: Icons.repeat_rounded,
                    ),
                  for (final source in question.examSources)
                    AppBadge(label: source.label, color: scheme.tertiary),
                  if (question.difficulty.isNotEmpty)
                    AppBadge(
                      label: question.difficulty,
                      color: question.difficulty.toLowerCase() == 'hard'
                          ? AppColors.error
                          : AppColors.info,
                    ),
                  if (isFlagged)
                    const AppBadge(
                      label: 'FLAGGED',
                      color: AppColors.warning,
                      icon: Icons.flag_rounded,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Text(
                  question.stem,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize:
                        Theme.of(context).textTheme.titleLarge!.fontSize! *
                        fontScale,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (var index = 0; index < question.options.length; index++) ...[
                SessionOptionTile(
                  index: index,
                  text: question.options[index],
                  isSelected: selectedOption == index,
                  isPractice: isPractice,
                  isCorrect: index == question.correctIndex,
                  hasAnswered: selectedOption != null,
                  isEliminated: eliminated.contains(index),
                  fontSizeScale: fontScale,
                  onTap: () => onSelect(index),
                  onToggleEliminate: () => onEliminate(index),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  variant: AppCardVariant.filled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MY HIGH-YIELD NOTE',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(note),
                    ],
                  ),
                ),
              ],
              if (isPractice && selectedOption != null) ...[
                const SizedBox(height: AppSpacing.lg),
                PracticeExplanationCard(question: question),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
