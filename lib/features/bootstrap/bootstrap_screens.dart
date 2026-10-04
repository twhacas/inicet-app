import 'package:flutter/material.dart';

import '../../data/content/asset_inicet_repository.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_card.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../domain/content/bootstrap_manifest.dart';
import '../../domain/content/inicet_models.dart';
import '../../domain/content/inicet_repository.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    required this.manifest,
    required this.onToggleTheme,
    required this.onEnterLearning,
    required this.onOpenCatalog,
    super.key,
  });

  final BootstrapManifest manifest;
  final VoidCallback onToggleTheme;
  final VoidCallback onEnterLearning;
  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _InicetAppBar(
        productName: manifest.productName,
        isDark: Theme.of(context).brightness == Brightness.dark,
        onToggleTheme: onToggleTheme,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < AppDimensions.compactBreakpoint;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? AppSpacing.lg : AppSpacing.xxl,
                vertical: compact ? AppSpacing.xl : AppSpacing.xxxl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppDimensions.contentMaxWidth,
                  ),
                  child:
                      compact
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _WelcomeHero(manifest: manifest),
                              const SizedBox(height: AppSpacing.lg),
                              _WelcomeActions(
                                manifest: manifest,
                                onEnterLearning: onEnterLearning,
                                onOpenCatalog: onOpenCatalog,
                              ),
                            ],
                          )
                          : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _WelcomeHero(manifest: manifest),
                              ),
                              const SizedBox(width: AppSpacing.xl),
                              Expanded(
                                flex: 2,
                                child: _WelcomeActions(
                                  manifest: manifest,
                                  onEnterLearning: onEnterLearning,
                                  onOpenCatalog: onOpenCatalog,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LearningSpaceScreen extends StatefulWidget {
  const LearningSpaceScreen({
    required this.manifest,
    required this.onOpenCatalog,
    this.inicetRepository,
    super.key,
  });

  final BootstrapManifest manifest;
  final VoidCallback onOpenCatalog;
  final InicetRepository? inicetRepository;

  @override
  State<LearningSpaceScreen> createState() => _LearningSpaceScreenState();
}

class _LearningSpaceScreenState extends State<LearningSpaceScreen> {
  late final InicetRepository _repository;
  InicetSubject _selectedSubject = InicetSubject.anatomy;
  InicetCategory? _selectedCategory;
  Map<String, InicetSubjectDetail> _details = {};
  int _questionIndex = 0;
  bool _showAnswer = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.inicetRepository ?? AssetInicetRepository();
    _loadData();
  }

  Future<void> _loadData() async {
    final details = await _repository.loadSubjectDetails();
    if (mounted) {
      setState(() {
        _details = details;
        _loading = false;
      });
    }
  }

  void _nextQuestion(int total) {
    if (total == 0) return;
    setState(() {
      _questionIndex = (_questionIndex + 1) % total;
      _showAnswer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact =
        MediaQuery.sizeOf(context).width < AppDimensions.compactBreakpoint;

    final subjectDetail = _details[_selectedSubject.key];
    final samplePoints = subjectDetail?.samplePoints ?? const [];
    final currentPoint =
        samplePoints.isNotEmpty
            ? samplePoints[_questionIndex % samplePoints.length]
            : null;

    final filteredSubjects =
        _selectedCategory == null
            ? InicetSubject.values
            : InicetSubject.values
                .where((s) => s.category == _selectedCategory)
                .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.manifest.productName),
        actions: [
          IconButton(
            tooltip: 'View design system catalog',
            icon: const Icon(Icons.palette_outlined),
            onPressed: widget.onOpenCatalog,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.lg : AppSpacing.xxl,
            vertical: AppSpacing.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview banner
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const AppBadge(
                              label: 'INICET & NEET-PG PYT HUB',
                              icon: Icons.local_hospital_rounded,
                            ),
                            AppBadge(
                              label: '20 SUBJECTS',
                              color: scheme.secondary,
                            ),
                            AppBadge(
                              label: '7,000+ QUESTIONS',
                              color: scheme.tertiary,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'High-Yield Previous Year Topics',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Master repeating concepts across INICET, AIIMS, and NEET-PG. '
                          'Select any subject to inspect repeat trends and test yourself on high-yield recall points.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppStatusBanner(
                          title: 'Local and Offline',
                          message: widget.manifest.offlineMessage,
                          tone: AppBannerTone.success,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Category Filter Chips
                  Text(
                    'Subject Modules',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All (20)'),
                          selected: _selectedCategory == null,
                          onSelected: (_) {
                            setState(() => _selectedCategory = null);
                          },
                        ),
                        for (final cat in InicetCategory.values) ...[
                          const SizedBox(width: AppSpacing.sm),
                          FilterChip(
                            label: Text(cat.label),
                            selected: _selectedCategory == cat,
                            onSelected: (_) {
                              setState(() => _selectedCategory = cat);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Main Interactive Grid / Split layout
                  if (compact) ...[
                    // Mobile: Question Flashcard first, then Subject Grid
                    _InteractivePytCard(
                      subject: _selectedSubject,
                      point: currentPoint,
                      totalPoints: samplePoints.length,
                      currentIndex: _questionIndex,
                      showAnswer: _showAnswer,
                      onToggleAnswer: () {
                        setState(() => _showAnswer = !_showAnswer);
                      },
                      onNext: () => _nextQuestion(samplePoints.length),
                      loading: _loading,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _SubjectGrid(
                      subjects: filteredSubjects,
                      selected: _selectedSubject,
                      onSelect: (subject) {
                        setState(() {
                          _selectedSubject = subject;
                          _questionIndex = 0;
                          _showAnswer = false;
                        });
                      },
                    ),
                  ] else ...[
                    // Tablet & Desktop: Two Column Split View
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _SubjectGrid(
                            subjects: filteredSubjects,
                            selected: _selectedSubject,
                            onSelect: (subject) {
                              setState(() {
                                _selectedSubject = subject;
                                _questionIndex = 0;
                                _showAnswer = false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(
                          flex: 4,
                          child: _InteractivePytCard(
                            subject: _selectedSubject,
                            point: currentPoint,
                            totalPoints: samplePoints.length,
                            currentIndex: _questionIndex,
                            showAnswer: _showAnswer,
                            onToggleAnswer: () {
                              setState(() => _showAnswer = !_showAnswer);
                            },
                            onNext: () => _nextQuestion(samplePoints.length),
                            loading: _loading,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xxxl),

                  // Footer actions
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      AppButton(
                        label: 'Back to welcome',
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      AppButton(
                        label: 'View design system catalog',
                        icon: Icons.palette_outlined,
                        variant: AppButtonVariant.outline,
                        onPressed: widget.onOpenCatalog,
                      ),
                    ],
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

class _SubjectGrid extends StatelessWidget {
  const _SubjectGrid({
    required this.subjects,
    required this.selected,
    required this.onSelect,
  });

  final List<InicetSubject> subjects;
  final InicetSubject selected;
  final ValueChanged<InicetSubject> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 720
                ? 3
                : constraints.maxWidth >= 420
                ? 2
                : 1;
        final itemWidth =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final sub in subjects)
              SizedBox(
                width: itemWidth,
                child: _SubjectCard(
                  subject: sub,
                  isSelected: sub == selected,
                  onTap: () => onSelect(sub),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.isSelected,
    required this.onTap,
  });

  final InicetSubject subject;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      variant: isSelected ? AppCardVariant.elevated : AppCardVariant.outlined,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: subject.softColor,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(subject.icon, color: subject.color, size: 22),
              ),
              const Spacer(),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: subject.color,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            subject.label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${subject.questionCount} Questions • ${subject.repeatPercent}% Repeat',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: (subject.repeatPercent / 100.0).clamp(0.0, 1.0),
              minHeight: 5,
              color: subject.color,
              backgroundColor: subject.color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractivePytCard extends StatelessWidget {
  const _InteractivePytCard({
    required this.subject,
    required this.point,
    required this.totalPoints,
    required this.currentIndex,
    required this.showAnswer,
    required this.onToggleAnswer,
    required this.onNext,
    required this.loading,
  });

  final InicetSubject subject;
  final InicetQuestionPoint? point;
  final int totalPoints;
  final int currentIndex;
  final bool showAnswer;
  final VoidCallback onToggleAnswer;
  final VoidCallback onNext;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (loading) {
      return const AppCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (point == null) {
      return AppCard(
        child: Column(
          children: [
            Icon(subject.icon, size: 48, color: subject.color),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No sample points loaded for ${subject.label}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    final isRepeat = point!.repeats > 1;
    final tagColor = switch (point!.tag) {
      'REPEAT' => AppColors.repeatTag,
      'BOTH' => AppColors.bothTag,
      'NEET' => AppColors.neetTag,
      _ => AppColors.iniTag,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppBadge(
                label: 'HIGH-YIELD REVISION',
                color: subject.color,
                icon: subject.icon,
              ),
              const Spacer(),
              Text(
                '${currentIndex + 1} of $totalPoints',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Topic and badges
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppBadge(label: point!.topic, color: scheme.primary),
              AppBadge(
                label: point!.tag,
                color: tagColor,
                icon: Icons.tag_rounded,
              ),
              if (isRepeat)
                AppBadge(
                  label: '${point!.repeats}x REPEAT',
                  color: AppColors.repeatTag,
                  icon: Icons.repeat_rounded,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Question Stem
          Text(
            point!.stem,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Answer Reveal Section
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState:
                showAnswer
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            firstChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_clock_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Recall the key fact before tapping reveal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'HIGH-YIELD ANSWER / FACT',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    point!.answer,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (point!.examsList.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Exam Occurrences: ${point!.examsList.join(", ")}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: showAnswer ? 'Hide answer' : 'Reveal answer',
                  icon:
                      showAnswer
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                  variant:
                      showAnswer
                          ? AppButtonVariant.outline
                          : AppButtonVariant.secondary,
                  onPressed: onToggleAnswer,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: 'Next',
                icon: Icons.arrow_forward_rounded,
                variant: AppButtonVariant.primary,
                onPressed: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({required this.manifest});

  final BootstrapManifest manifest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBadge(
            label: 'LOCAL-FIRST MEDICAL REVISION',
            icon: Icons.local_hospital_rounded,
            color: scheme.onPrimary,
          ),
          const SizedBox(height: AppSpacing.xl),
          Semantics(
            header: true,
            child: Text(
              manifest.welcomeHeadline,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: scheme.onPrimary,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            manifest.welcomeMessage,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.90),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              _HeroStat(
                label: 'Subjects',
                value: '20',
                color: scheme.onPrimary,
              ),
              _HeroStat(
                label: 'Questions',
                value: '7,000+',
                color: scheme.onPrimary,
              ),
              _HeroStat(
                label: 'Storage',
                value: '100% Offline',
                color: scheme.onPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: color.withValues(alpha: 0.8)),
        ),
      ],
    );
  }
}

class _WelcomeActions extends StatelessWidget {
  const _WelcomeActions({
    required this.manifest,
    required this.onEnterLearning,
    required this.onOpenCatalog,
  });

  final BootstrapManifest manifest;
  final VoidCallback onEnterLearning;
  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Ready when you are',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppStatusBanner(
            title: 'Works offline',
            message: manifest.offlineMessage,
            tone: AppBannerTone.success,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: manifest.primaryActionLabel,
            icon: Icons.arrow_forward_rounded,
            expand: true,
            onPressed: onEnterLearning,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'View design system catalog',
            icon: Icons.palette_outlined,
            variant: AppButtonVariant.outline,
            expand: true,
            onPressed: onOpenCatalog,
          ),
        ],
      ),
    );
  }
}

class _InicetAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _InicetAppBar({
    required this.productName,
    required this.isDark,
    required this.onToggleTheme,
  });

  final String productName;
  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_hospital_rounded),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text(productName, overflow: TextOverflow.ellipsis)),
        ],
      ),
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
