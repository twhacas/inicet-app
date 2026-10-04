import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/question_repository.dart';
import '../../data/question_file_picker.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_card.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../shared/operation_feedback.dart';

class ImportQuestionsDialog extends StatefulWidget {
  const ImportQuestionsDialog({required this.repository, super.key});

  final QuestionRepository repository;

  static Future<bool?> show(
    BuildContext context,
    QuestionRepository repository,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ImportQuestionsDialog(repository: repository),
    );
  }

  @override
  State<ImportQuestionsDialog> createState() => _ImportQuestionsDialogState();
}

class _ImportQuestionsDialogState extends State<ImportQuestionsDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _pasteController = TextEditingController();
  bool _replace = false;
  String? _pickedFileName;
  String? _pickedFileContent;
  String? _statusMessage;
  bool _isSuccess = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _handlePasteImport() async {
    final text = _pasteController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _statusMessage = 'Please paste JSON content first.';
        _isSuccess = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final count = await widget.repository.importQuestionsFromJsonString(
        text,
        replace: _replace,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _statusMessage = 'Successfully imported $count question(s)!';
      });
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = operationErrorMessage(e);
      });
    }
  }

  Future<void> _handleFilePicker() async {
    try {
      final result = await pickQuestionJsonFile();
      if (!mounted) return;
      if (result != null) {
        setState(() {
          _pickedFileName = result.name;
          _pickedFileContent = result.contents;
          _statusMessage = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = operationErrorMessage(e);
        _isSuccess = false;
      });
    }
  }

  Future<void> _handleFileImport() async {
    if (_pickedFileContent == null) return;
    setState(() => _isLoading = true);
    try {
      final count = await widget.repository.importQuestionsFromJsonString(
        _pickedFileContent!,
        replace: _replace,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _statusMessage = 'Successfully imported $count question(s)!';
      });
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = operationErrorMessage(e);
      });
    }
  }

  Future<void> _copyTemplate() async {
    const template = '''[
  {
    "id": "sample_1",
    "subject": "Anatomy",
    "subTopic": "Head & Neck",
    "stem": "Which cranial nerve provides sensory innervation to the face?",
    "options": [
      "Facial nerve (CN VII)",
      "Trigeminal nerve (CN V)",
      "Glossopharyngeal nerve (CN IX)",
      "Vagus nerve (CN X)"
    ],
    "correctIndex": 1,
    "explanation": "The trigeminal nerve (CN V) provides somatic sensory innervation to the skin of the face.",
    "tag": "INI-CET",
    "exam": "2024 INI-CET"
  }
]''';
    await Clipboard.setData(const ClipboardData(text: template));
    if (!mounted) return;
    setState(() {
      _statusMessage = 'Sample JSON template copied to clipboard!';
      _isSuccess = true;
    });
  }

  Future<void> _exportQuestions() async {
    final jsonStr = await widget.repository.exportQuestionsToJsonString();
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (!mounted) return;
    setState(() {
      _statusMessage = 'All questions exported & copied to clipboard!';
      _isSuccess = true;
    });
  }

  Future<void> _resetQuestions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset question bank?'),
        content: const Text(
          'Imported questions will be removed from the active bank. Your notes, bookmarks and history will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Reset Bank',
            variant: AppButtonVariant.destructive,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await widget.repository.resetToDefault();
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _statusMessage = operationErrorMessage(error);
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _statusMessage = 'Reset to bundled default question bank.';
      _isSuccess = true;
    });
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.compactBreakpoint,
          maxHeight: AppDimensions.compactBreakpoint,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.file_upload_rounded, color: scheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'JSON Question Manager',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close question manager',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Paste JSON'),
                  Tab(text: 'Pick File'),
                  Tab(text: 'Template / Export'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Checkbox(
                    value: _replace,
                    onChanged: (v) => setState(() => _replace = v ?? false),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Replace current question bank (unchecked = merge)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_statusMessage != null) ...[
                AppStatusBanner(
                  title: _isSuccess ? 'Success' : 'Notice',
                  message: _statusMessage!,
                  tone: _isSuccess
                      ? AppBannerTone.success
                      : AppBannerTone.error,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Paste JSON
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pasteController,
                            maxLines: null,
                            expands: true,
                            decoration: const InputDecoration(
                              hintText: 'Paste valid JSON array containing questions with options and correctIndex...',
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          label: 'Import from Pasted JSON',
                          icon: Icons.check_circle_rounded,
                          loading: _isLoading,
                          onPressed: _handlePasteImport,
                        ),
                      ],
                    ),

                    // Tab 2: Pick File
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppCard(
                          variant: AppCardVariant.outlined,
                          child: Column(
                            children: [
                              Icon(
                                Icons.file_present_rounded,
                                size: 48,
                                color: scheme.primary,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                _pickedFileName ?? 'Select a .json questions file from storage',
                                style: Theme.of(context).textTheme.titleSmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AppButton(
                                label: 'Browse Files…',
                                icon: Icons.folder_open_rounded,
                                variant: AppButtonVariant.outline,
                                onPressed: _handleFilePicker,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          label: 'Import Selected File',
                          icon: Icons.upload_file_rounded,
                          loading: _isLoading,
                          onPressed: _pickedFileContent != null
                              ? _handleFileImport
                              : null,
                        ),
                      ],
                    ),

                    // Tab 3: Template & Export
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppCard(
                            variant: AppCardVariant.filled,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'JSON Format Guidelines',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Every question requires: "subject", "subTopic", "stem", "options" (array of strings), and "correctIndex" (0..3).',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppButton(
                                  label: 'Copy Sample Template',
                                  icon: Icons.copy_rounded,
                                  variant: AppButtonVariant.outline,
                                  onPressed: _copyTemplate,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            label: 'Export All Questions to JSON',
                            icon: Icons.download_rounded,
                            variant: AppButtonVariant.secondary,
                            onPressed: _exportQuestions,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            label: 'Reset to Default Question Bank',
                            icon: Icons.restore_rounded,
                            variant: AppButtonVariant.destructive,
                            onPressed: _resetQuestions,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
