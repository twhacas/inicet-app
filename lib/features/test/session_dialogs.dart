import 'package:flutter/material.dart';

import '../../design_system/components/app_button.dart';
import '../../design_system/tokens/app_spacing.dart';

Future<bool> confirmSessionExit(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Test Session?'),
        content: const Text(
          'Your current test responses will be discarded. Are you sure you want to exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue Test'),
          ),
          AppButton(
            label: 'Exit',
            variant: AppButtonVariant.destructive,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ??
    false;

Future<bool> confirmSessionSubmit(
  BuildContext context, {
  required int attempted,
  required int total,
  required int flagged,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Test?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attempted: $attempted of $total'),
            Text('Unattempted: ${total - attempted}'),
            if (flagged > 0) Text('Marked for Review: $flagged'),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Are you sure you want to finish and view your scorecard?',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Working'),
          ),
          AppButton(
            label: 'Submit Now',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ??
    false;

Future<String?> editSessionNote(
  BuildContext context, {
  required String text,
  required int questionNumber,
}) => showDialog<String>(
  context: context,
  builder: (_) =>
      _SessionNoteDialog(text: text, questionNumber: questionNumber),
);

class _SessionNoteDialog extends StatefulWidget {
  const _SessionNoteDialog({required this.text, required this.questionNumber});
  final String text;
  final int questionNumber;
  @override
  State<_SessionNoteDialog> createState() => _SessionNoteDialogState();
}

class _SessionNoteDialogState extends State<_SessionNoteDialog> {
  late final controller = TextEditingController(text: widget.text);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Personal Question Note'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Save your high-yield pearl or mnemonics for Q${widget.questionNumber}:',
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Your notes...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    ),
    actions: [
      if (widget.text.isNotEmpty)
        TextButton(
          onPressed: () => Navigator.pop(context, ''),
          child: const Text('Delete'),
        ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      AppButton(
        label: 'Save Note',
        onPressed: () => Navigator.pop(context, controller.text),
      ),
    ],
  );
}
