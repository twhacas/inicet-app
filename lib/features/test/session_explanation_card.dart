import 'package:flutter/material.dart';

import '../../design_system/components/app_card.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../domain/models/mcq_question.dart';

class PracticeExplanationCard extends StatelessWidget {
  const PracticeExplanationCard({required this.question, super.key});

  final McqQuestion question;

  String _extractPearl(String text, String correctAnswer) {
    if (text.isEmpty) return correctAnswer;
    final lines = text.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty &&
          !trimmed.startsWith('>') &&
          !trimmed.startsWith('#')) {
        return trimmed;
      }
    }
    return correctAnswer;
  }

  @override
  Widget build(BuildContext context) {
    final pearl = _extractPearl(question.explanation, question.correctAnswer);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Explanation & Rationale',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            question.explanation,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.md),

          // High-Yield Key Takeaway Callout Box
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HIGH-YIELD PEARL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pearl,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (question.exam.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.history_edu_rounded,
                  size: 14,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Tested in: ${question.exam}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
