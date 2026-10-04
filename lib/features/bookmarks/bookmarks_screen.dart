import 'package:flutter/material.dart';

import '../../data/question_repository.dart';
import '../../design_system/components/app_card.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../domain/models/mcq_question.dart';
import '../../domain/models/test_config.dart';
import '../test/mcq_session_screen.dart';
import '../shared/operation_feedback.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({required this.repository, super.key});

  final QuestionRepository repository;

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late List<McqQuestion> _bookmarks;

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
    setState(() {
      _bookmarks = widget.repository.getBookmarkedQuestions();
    });
  }

  void _startBookmarkQuiz() {
    if (_bookmarks.isEmpty) return;
    final config = TestConfig(
      selectedSubjects: _bookmarks.map((q) => q.subject).toSet(),
      selectedSubTopics: {},
      questionCount: _bookmarks.length,
      mode: TestMode.practice,
      timerEnabled: false,
    );

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => McqSessionScreen(
              questions: List.from(_bookmarks),
              config: config,
              repository: widget.repository,
            ),
          ),
        )
        .then((_) => _loadBookmarks());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarked Questions (${_bookmarks.length})'),
        actions: [
          if (_bookmarks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: TextButton.icon(
                onPressed: _startBookmarkQuiz,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Practice All'),
              ),
            ),
        ],
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
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _bookmarks.length,
              itemBuilder: (context, index) {
                final q = _bookmarks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppBadge(label: q.subject, color: scheme.primary),
                            const SizedBox(width: AppSpacing.xs),
                            AppBadge(
                              label: q.subTopic,
                              color: scheme.secondary,
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Remove bookmark',
                              icon: const Icon(
                                Icons.bookmark_rounded,
                                color: AppColors.warning,
                              ),
                              onPressed: () async {
                                try {
                                  await widget.repository.toggleBookmark(q.id);
                                } catch (error) {
                                  if (context.mounted) {
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
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.md),
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
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
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
                          Text(
                            q.explanation,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
