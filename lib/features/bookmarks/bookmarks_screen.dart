import 'package:flutter/material.dart';

import '../../data/question_repository.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_card.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../domain/models/mcq_question.dart';
import '../shared/operation_feedback.dart';
import 'bookmark_group_helper.dart';
import 'bookmark_practice_modal.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({required this.repository, super.key});

  final QuestionRepository repository;

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late List<McqQuestion> _bookmarks;
  late Map<String, Map<String, List<McqQuestion>>> _grouped;
  final BookmarkSelectionState _selectionState = BookmarkSelectionState();

  final Set<String> _expandedSubjects = {};
  final Map<String, Set<String>> _expandedChapters = {};
  bool _hasInitializedSelection = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    widget.repository.addListener(_loadBookmarks);
  }

  @override
  void didUpdateWidget(BookmarksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      oldWidget.repository.removeListener(_loadBookmarks);
      widget.repository.addListener(_loadBookmarks);
      _loadBookmarks();
    }
  }

  @override
  void dispose() {
    widget.repository.removeListener(_loadBookmarks);
    super.dispose();
  }

  void _loadBookmarks() {
    if (!mounted) return;
    final bookmarks = widget.repository.getBookmarkedQuestions();
    final grouped = BookmarkGroupHelper.group(bookmarks);

    _selectionState.prune(grouped);
    if (!_hasInitializedSelection && bookmarks.isNotEmpty) {
      _selectionState.selectAll(grouped);
      _hasInitializedSelection = true;
    } else if (bookmarks.isEmpty) {
      _hasInitializedSelection = false;
    }

    // Prune expanded state
    _expandedSubjects.removeWhere((s) => !grouped.containsKey(s));
    _expandedChapters.removeWhere((s, chapters) {
      if (!grouped.containsKey(s)) return true;
      chapters.removeWhere((c) => !grouped[s]!.containsKey(c));
      return chapters.isEmpty;
    });

    setState(() {
      _bookmarks = bookmarks;
      _grouped = grouped;
    });
  }

  void _openPracticeModal() {
    final selectedQuestions = _selectionState.getSelectedQuestions(_grouped);
    if (selectedQuestions.isEmpty) return;

    BookmarkPracticeModal.show(
      context: context,
      selectedQuestions: selectedQuestions,
      repository: widget.repository,
    ).then((_) => _loadBookmarks());
  }

  IconData _getSubjectIcon(String subjectName) {
    for (final s in InicetSubject.values) {
      if (s.label.toLowerCase() == subjectName.toLowerCase() ||
          s.name.toLowerCase() == subjectName.toLowerCase()) {
        return s.icon;
      }
    }
    return Icons.menu_book_rounded;
  }

  Color _getSubjectColor(String subjectName, ColorScheme scheme) {
    for (final s in InicetSubject.values) {
      if (s.label.toLowerCase() == subjectName.toLowerCase() ||
          s.name.toLowerCase() == subjectName.toLowerCase()) {
        return s.color;
      }
    }
    return scheme.primary;
  }

  Widget _buildQuestionCard(McqQuestion q, ColorScheme scheme) {
    final optionLetters = const ['A', 'B', 'C', 'D'];
    return Padding(
      key: Key('question-card-${q.id}'),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        variant: AppCardVariant.elevated,
        padding: const EdgeInsets.all(AppSpacing.md),
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
                      AppBadge(label: q.subject, color: scheme.primary),
                      AppBadge(
                        label:
                            q.subTopic.trim().isEmpty ? 'General' : q.subTopic,
                        color: scheme.secondary,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('unbookmark-${q.id}'),
                  tooltip: 'Remove bookmark',
                  icon: const Icon(
                    Icons.bookmark_rounded,
                    color: AppColors.warning,
                  ),
                  onPressed: () async {
                    try {
                      await widget.repository.toggleBookmark(q.id);
                    } catch (error) {
                      if (mounted) {
                        showOperationError(context, error);
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              q.stem,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Options A-D with correct answer highlighted
            for (var i = 0; i < q.options.length; i++) ...[
              Builder(
                builder: (context) {
                  final isCorrect = i == q.correctIndex;
                  final letter = i < optionLetters.length
                      ? optionLetters[i]
                      : '${i + 1}';
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? AppColors.success.withValues(alpha: 0.1)
                          : scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: isCorrect
                            ? AppColors.success.withValues(alpha: 0.4)
                            : scheme.outlineVariant,
                        width: isCorrect ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? AppColors.success
                                : scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(AppRadii.xs),
                          ),
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isCorrect
                                  ? Colors.white
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            q.options[i],
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: isCorrect
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isCorrect
                                      ? AppColors.success
                                      : scheme.onSurface,
                                ),
                          ),
                        ),
                        if (isCorrect) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            // Correct answer pill
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Correct: ${q.correctAnswer}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            if (q.explanation.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explanation',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      q.explanation,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            if (q.userNote != null && q.userNote!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.sticky_note_2_rounded,
                      color: AppColors.warning,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Note',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            q.userNote!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChapterAccordion({
    required String subject,
    required String chapter,
    required List<McqQuestion> questions,
    required ColorScheme scheme,
  }) {
    final isExpanded = _expandedChapters[subject]?.contains(chapter) ?? false;
    final isSelected = _selectionState.isChapterSelected(subject, chapter);

    return Container(
      key: Key('chapter-section-$subject-$chapter'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Chapter Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Checkbox(
                  key: Key('chapter-checkbox-$subject-$chapter'),
                  value: isSelected,
                  onChanged: (_) {
                    setState(() {
                      _selectionState.toggleChapter(subject, chapter);
                    });
                  },
                ),
                Expanded(
                  child: InkWell(
                    key: Key('chapter-header-$subject-$chapter'),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    onTap: () {
                      setState(() {
                        final current = _expandedChapters.putIfAbsent(
                          subject,
                          () => <String>{},
                        );
                        if (current.contains(chapter)) {
                          current.remove(chapter);
                        } else {
                          current.add(chapter);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                        horizontal: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              chapter,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          AppBadge(
                            label: '${questions.length}',
                            color: scheme.secondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            isExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: scheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chapter Questions
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      children: [
                        for (final q in questions)
                          _buildQuestionCard(q, scheme),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard({
    required String subject,
    required Map<String, List<McqQuestion>> chapters,
    required ColorScheme scheme,
  }) {
    final isExpanded = _expandedSubjects.contains(subject);
    final allChapters = chapters.keys.toList();
    final subjectSelection = _selectionState.subjectSelectionState(
      subject,
      allChapters,
    );
    final subjectColor = _getSubjectColor(subject, scheme);
    final subjectIcon = _getSubjectIcon(subject);
    final totalSubjectQuestions = BookmarkGroupHelper.subjectCount(chapters);

    return Padding(
      key: Key('subject-card-$subject'),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        variant: AppCardVariant.elevated,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subject Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Checkbox(
                    key: Key('subject-checkbox-$subject'),
                    tristate: true,
                    value: subjectSelection,
                    onChanged: (_) {
                      setState(() {
                        _selectionState.toggleSubject(subject, allChapters);
                      });
                    },
                  ),
                  Expanded(
                    child: InkWell(
                      key: Key('subject-header-$subject'),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      onTap: () {
                        setState(() {
                          if (_expandedSubjects.contains(subject)) {
                            _expandedSubjects.remove(subject);
                          } else {
                            _expandedSubjects.add(subject);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                          horizontal: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: subjectColor.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadii.sm),
                              ),
                              child: Icon(
                                subjectIcon,
                                color: subjectColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                subject,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            AppBadge(
                              label: '$totalSubjectQuestions',
                              color: subjectColor,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              isExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Subject Chapters
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.xs,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      child: Column(
                        children: [
                          for (final chapterEntry in chapters.entries)
                            _buildChapterAccordion(
                              subject: subject,
                              chapter: chapterEntry.key,
                              questions: chapterEntry.value,
                              scheme: scheme,
                            ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedCount = _selectionState.getSelectedQuestionCount(_grouped);

    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarked Questions (${_bookmarks.length})'),
      ),
      body: _bookmarks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 64,
                    color: scheme.outline,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No bookmarked questions yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Bookmark challenging questions during test or practice sessions.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Top Selection Toolbar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    border: Border(
                      bottom: BorderSide(color: scheme.outlineVariant),
                    ),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Text(
                        '$selectedCount of ${_bookmarks.length} selected',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      Wrap(
                        spacing: AppSpacing.xs,
                        children: [
                          TextButton.icon(
                            key: const Key('select-all-button'),
                            icon: const Icon(
                              Icons.select_all_rounded,
                              size: 18,
                            ),
                            label: const Text('Select All'),
                            onPressed: () {
                              setState(() {
                                _selectionState.selectAll(_grouped);
                              });
                            },
                          ),
                          TextButton.icon(
                            key: const Key('deselect-all-button'),
                            icon: const Icon(
                              Icons.deselect_rounded,
                              size: 18,
                            ),
                            label: const Text('Deselect All'),
                            onPressed: selectedCount == 0
                                ? null
                                : () {
                                    setState(() {
                                      _selectionState.deselectAll();
                                    });
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Hierarchical Accordion List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _grouped.length,
                    itemBuilder: (context, index) {
                      final subject = _grouped.keys.elementAt(index);
                      final chapters = _grouped[subject]!;
                      return _buildSubjectCard(
                        subject: subject,
                        chapters: chapters,
                        scheme: scheme,
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _bookmarks.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                border: Border(
                  top: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: SafeArea(
                child: AppButton(
                  label: 'Practice Selected ($selectedCount)',
                  icon: Icons.play_arrow_rounded,
                  variant: AppButtonVariant.primary,
                  expand: true,
                  onPressed: selectedCount > 0 ? _openPracticeModal : null,
                ),
              ),
            )
          : null,
    );
  }
}
