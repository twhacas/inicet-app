import 'package:flutter/material.dart';

import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import 'showcase_foundations.dart';
import 'showcase_interactions.dart';
import 'showcase_lessons.dart';
import 'showcase_subjects.dart';

class DesignSystemShowcaseScreen extends StatefulWidget {
  const DesignSystemShowcaseScreen({required this.onToggleTheme, super.key});

  final VoidCallback onToggleTheme;

  @override
  State<DesignSystemShowcaseScreen> createState() =>
      _DesignSystemShowcaseScreenState();
}

class _DesignSystemShowcaseScreenState
    extends State<DesignSystemShowcaseScreen> {
  InicetSubject _subject = InicetSubject.anatomy;
  bool _repeatsPriority = true;
  bool _instantPreview = true;
  double _progress = 0.65;
  int _navigationIndex = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).width < AppDimensions.compactBreakpoint;
    return Scaffold(
      appBar: _CatalogAppBar(
        isDark: Theme.of(context).brightness == Brightness.dark,
        onToggleTheme: widget.onToggleTheme,
      ),
      body: Row(
        children: [
          if (!compact)
            _InicetRail(
              selectedIndex: _navigationIndex,
              onSelect: (index) {
                setState(() => _navigationIndex = index);
              },
            ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? AppSpacing.lg : AppSpacing.xxl,
                    vertical: AppSpacing.xl,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppDimensions.contentMaxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShowcaseHero(compact: compact),
                            const SizedBox(height: AppSpacing.xxxl),
                            SubjectShowcaseSection(
                              selected: _subject,
                              onSelected: (subject) {
                                setState(() => _subject = subject);
                              },
                            ),
                            const SizedBox(height: AppSpacing.xxxl),
                            LessonShowcaseSection(
                              subject: _subject,
                              progress: _progress,
                              onProgressChanged: (value) {
                                setState(() => _progress = value);
                              },
                              onAction: _notify,
                            ),
                            const SizedBox(height: AppSpacing.xxxl),
                            InteractionShowcaseSection(
                              narration: _repeatsPriority,
                              captions: _instantPreview,
                              answerController: _searchController,
                              onNarrationChanged: (value) {
                                setState(() => _repeatsPriority = value);
                              },
                              onCaptionsChanged: (value) {
                                setState(() => _instantPreview = value);
                              },
                              onAction: _notify,
                            ),
                            const SizedBox(height: AppSpacing.xxxl),
                            const FoundationShowcaseSection(),
                            const SizedBox(height: AppSpacing.xxxxl),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InicetRail extends StatelessWidget {
  const _InicetRail({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: AppDimensions.navigationRailWidth,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Catalog Index',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          _RailItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'Overview',
            selected: selectedIndex == 0,
            onTap: () => onSelect(0),
          ),
          _RailItem(
            icon: Icons.category_outlined,
            activeIcon: Icons.category_rounded,
            label: 'Subjects (20)',
            selected: selectedIndex == 1,
            onTap: () => onSelect(1),
          ),
          _RailItem(
            icon: Icons.psychology_outlined,
            activeIcon: Icons.psychology_rounded,
            label: 'PYT Cards',
            selected: selectedIndex == 2,
            onTap: () => onSelect(2),
          ),
          _RailItem(
            icon: Icons.tune_outlined,
            activeIcon: Icons.tune_rounded,
            label: 'Interactions',
            selected: selectedIndex == 3,
            onTap: () => onSelect(3),
          ),
          _RailItem(
            icon: Icons.palette_outlined,
            activeIcon: Icons.palette_rounded,
            label: 'Foundations',
            selected: selectedIndex == 4,
            onTap: () => onSelect(4),
          ),
          const Spacer(),
          const AppStatusBanner(
            title: 'Adaptive Layout',
            message: 'Optimized for phones, tablets & desktops.',
            tone: AppBannerTone.info,
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color:
            selected
                ? scheme.primaryContainer.withValues(alpha: 0.6)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  size: 20,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? scheme.primary : scheme.onSurface,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CatalogAppBar({
    required this.isDark,
    required this.onToggleTheme,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('INICET Design System Catalog'),
      actions: [
        IconButton(
          tooltip: isDark ? 'Use light theme' : 'Use dark theme',
          onPressed: onToggleTheme,
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}
