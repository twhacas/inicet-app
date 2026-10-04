import 'package:flutter/material.dart';

import '../../design_system/components/app_card.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../domain/models/mcq_question.dart';
import '../../domain/models/test_result.dart';

import '../../data/question_repository.dart';
import '../shared/operation_feedback.dart';

class ReviewQuestionCard extends StatefulWidget {
  const ReviewQuestionCard({
    required this.index,
    required this.question,
    required this.answer,
    required this.repository,
    super.key,
  });

  final int index;
  final McqQuestion question;
  final UserAnswer? answer;
  final QuestionRepository repository;

  @override
  State<ReviewQuestionCard> createState() => _ReviewQuestionCardState();
}

class _ReviewQuestionCardState extends State<ReviewQuestionCard> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.repository,
      builder: (context, _) => _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final q = widget.question;
    final ans = widget.answer;
    final bookmarked = widget.repository.isBookmarked(q.id);
    final isCorrect = ans != null && ans.selectedOptionIndex == q.correctIndex;
    final isSkipped = ans == null || !ans.isAttempted;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    AppBadge(
                      label: 'Q${widget.index + 1}',
                      color: isCorrect
                          ? AppColors.success
                          : isSkipped
                          ? scheme.onSurfaceVariant
                          : AppColors.error,
                    ),
                    AppBadge(label: q.subject, color: scheme.primary),
                    AppBadge(label: q.subTopic, color: scheme.secondary),
                    if (ans?.isFlagged ?? false)
                      const AppBadge(
                        label: 'FLAGGED',
                        color: AppColors.warning,
                        icon: Icons.flag_rounded,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                icon: Icon(
                  bookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: bookmarked
                      ? AppColors.warning
                      : scheme.onSurfaceVariant,
                ),
                tooltip: 'Bookmark',
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        try {
                          await widget.repository.toggleBookmark(q.id);
                        } catch (error) {
                          if (context.mounted) {
                            showOperationError(context, error);
                          }
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(q.stem, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),

          // Options
          for (var i = 0; i < q.options.length; i++) ...[
            _ReviewOptionTile(
              index: i,
              text: q.options[i],
              isCorrect: i == q.correctIndex,
              isSelected: i == ans?.selectedOptionIndex,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],

          if (q.explanation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'EXPLANATION',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    q.explanation,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewOptionTile extends StatelessWidget {
  const _ReviewOptionTile({
    required this.index,
    required this.text,
    required this.isCorrect,
    required this.isSelected,
  });

  final int index;
  final String text;
  final bool isCorrect;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final prefix = String.fromCharCode(65 + index); // A, B, C, D

    Color background = Colors.transparent;
    Color border = scheme.outlineVariant;
    Color textCol = scheme.onSurface;
    IconData? icon;
    Color iconColor = scheme.primary;

    if (isCorrect) {
      background = AppColors.success.withValues(alpha: 0.12);
      border = AppColors.success;
      textCol = AppColors.success;
      icon = Icons.check_circle_rounded;
      iconColor = AppColors.success;
    } else if (isSelected && !isCorrect) {
      background = AppColors.error.withValues(alpha: 0.12);
      border = AppColors.error;
      textCol = AppColors.error;
      icon = Icons.cancel_rounded;
      iconColor = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: border,
          width: isCorrect || isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCorrect
                  ? AppColors.success
                  : isSelected
                  ? AppColors.error
                  : scheme.surfaceContainerHighest,
            ),
            child: Text(
              prefix,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isCorrect || isSelected
                    ? Colors.white
                    : scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textCol,
                fontWeight: isCorrect || isSelected
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(icon, color: iconColor, size: 18),
          ],
        ],
      ),
    );
  }
}
