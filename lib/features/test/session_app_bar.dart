import 'package:flutter/material.dart';

import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';

enum _SessionAction { smaller, larger, note, palette }

class SessionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SessionAppBar({
    required this.index,
    required this.total,
    required this.hasNote,
    required this.bookmarked,
    required this.onExit,
    required this.onSmaller,
    required this.onLarger,
    required this.onNote,
    required this.onBookmark,
    required this.onPalette,
    required this.onSubmit,
    super.key,
  });
  final int index;
  final int total;
  final bool hasNote;
  final bool bookmarked;
  final VoidCallback? onExit;
  final VoidCallback? onSmaller;
  final VoidCallback? onLarger;
  final VoidCallback? onNote;
  final VoidCallback? onBookmark;
  final VoidCallback? onPalette;
  final VoidCallback? onSubmit;

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + AppSpacing.xs);

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).width < AppDimensions.compactBreakpoint;
    return AppBar(
      leading: IconButton(
        tooltip: 'Exit test',
        icon: const Icon(Icons.close_rounded),
        onPressed: onExit,
      ),
      title: Text(
        'Q${index + 1} of $total',
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      actions: [
        if (!compact) ...[
          IconButton(
            tooltip: 'Smaller text',
            icon: const Text('A-'),
            onPressed: onSmaller,
          ),
          IconButton(
            tooltip: 'Larger text',
            icon: const Text('A+'),
            onPressed: onLarger,
          ),
          IconButton(
            tooltip: hasNote ? 'Edit personal note' : 'Add personal note',
            icon: Icon(
              hasNote ? Icons.edit_note_rounded : Icons.note_add_outlined,
            ),
            onPressed: onNote,
          ),
        ],
        IconButton(
          tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark question',
          icon: Icon(
            bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: bookmarked ? AppColors.warning : null,
          ),
          onPressed: onBookmark,
        ),
        if (!compact)
          IconButton(
            tooltip: 'Question palette',
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: onPalette,
          ),
        if (compact)
          PopupMenuButton<_SessionAction>(
            tooltip: 'Session options',
            onSelected: (action) {
              switch (action) {
                case _SessionAction.smaller:
                  onSmaller?.call();
                case _SessionAction.larger:
                  onLarger?.call();
                case _SessionAction.note:
                  onNote?.call();
                case _SessionAction.palette:
                  onPalette?.call();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _SessionAction.smaller,
                enabled: onSmaller != null,
                child: const Text('Smaller text'),
              ),
              PopupMenuItem(
                value: _SessionAction.larger,
                enabled: onLarger != null,
                child: const Text('Larger text'),
              ),
              PopupMenuItem(
                value: _SessionAction.note,
                enabled: onNote != null,
                child: Text(
                  hasNote ? 'Edit personal note' : 'Add personal note',
                ),
              ),
              PopupMenuItem(
                value: _SessionAction.palette,
                enabled: onPalette != null,
                child: const Text('Question palette'),
              ),
            ],
          ),
        TextButton(onPressed: onSubmit, child: const Text('Submit')),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(AppSpacing.xs),
        child: LinearProgressIndicator(
          value: (index + 1) / total,
          minHeight: AppSpacing.xs,
        ),
      ),
    );
  }
}
