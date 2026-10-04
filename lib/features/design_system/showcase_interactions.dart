import 'package:flutter/material.dart';

import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_card.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_spacing.dart';

class InteractionShowcaseSection extends StatelessWidget {
  const InteractionShowcaseSection({
    required this.narration,
    required this.captions,
    required this.answerController,
    required this.onNarrationChanged,
    required this.onCaptionsChanged,
    required this.onAction,
    super.key,
  });

  final bool narration;
  final bool captions;
  final TextEditingController answerController;
  final ValueChanged<bool> onNarrationChanged;
  final ValueChanged<bool> onCaptionsChanged;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          eyebrow: 'Interaction & states',
          title: 'Accessible Controls & Rapid Revision Tools',
          description:
              'Touch targets are at least 48dp, controls feature explicit accessibility semantics, and states never rely solely on color.',
        ),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final controls = AppCard(
              variant: AppCardVariant.outlined,
              child: Column(
                children: [
                  _SettingRow(
                    icon: Icons.repeat_rounded,
                    title: 'Prioritize Repeats',
                    subtitle: 'Show 2x and 3x repeating topics first',
                    control: Switch(
                      value: narration,
                      onChanged: onNarrationChanged,
                    ),
                  ),
                  const Divider(height: AppSpacing.xl),
                  _SettingRow(
                    icon: Icons.visibility_rounded,
                    title: 'Instant Answer Preview',
                    subtitle: 'Reveal answers automatically after selection',
                    control: Checkbox(
                      value: captions,
                      onChanged: (v) => onCaptionsChanged(v ?? false),
                    ),
                  ),
                ],
              ),
            );

            final inputCard = AppCard(
              variant: AppCardVariant.outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Topics & Disease Entities',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Search across anatomy, Guyon canal, brachial plexus, etc.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: answerController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Brachial plexus, Guyon canal...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      AppButton(
                        label: 'Search',
                        icon: Icons.search_rounded,
                        onPressed: () {
                          if (answerController.text.trim().isNotEmpty) {
                            onAction('Searching for "${answerController.text}"');
                          } else {
                            onAction('Enter search keywords');
                          }
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppButton(
                        label: 'Clear',
                        variant: AppButtonVariant.text,
                        onPressed: () {
                          answerController.clear();
                          onAction('Search cleared');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );

            if (!wide) {
              return Column(
                children: [
                  controls,
                  const SizedBox(height: AppSpacing.md),
                  inputCard,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: controls),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: inputCard),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.control,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        control,
      ],
    );
  }
}
