import 'package:flutter/material.dart';

import '../data/question_repository.dart';
import '../design_system/theme/app_theme.dart';
import '../features/navigation/main_navigation_shell.dart';
import '../features/shared/operation_feedback.dart';
import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_spacing.dart';

class InicetPrepApp extends StatefulWidget {
  const InicetPrepApp({this.questionRepository, super.key});

  final QuestionRepository? questionRepository;

  @override
  State<InicetPrepApp> createState() => _InicetPrepAppState();
}

class _InicetPrepAppState extends State<InicetPrepApp> {
  ThemeMode _themeMode = ThemeMode.light;
  late final QuestionRepository _questionRepository;

  @override
  void initState() {
    super.initState();
    _questionRepository = widget.questionRepository ?? QuestionRepository();
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  void dispose() {
    if (widget.questionRepository == null) _questionRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'INICET MCQ Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: _QuestionStartup(
        repository: _questionRepository,
        onToggleTheme: _toggleTheme,
        isDark: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class _QuestionStartup extends StatefulWidget {
  const _QuestionStartup({
    required this.repository,
    required this.onToggleTheme,
    required this.isDark,
  });
  final QuestionRepository repository;
  final VoidCallback onToggleTheme;
  final bool isDark;
  @override
  State<_QuestionStartup> createState() => _QuestionStartupState();
}

class _QuestionStartupState extends State<_QuestionStartup> {
  late Future<void> _load;
  @override
  void initState() {
    super.initState();
    _load = widget.repository.isInitialized
        ? Future.value()
        : widget.repository.init();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _load,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not open your question bank',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      operationErrorMessage(snapshot.error!),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Retry',
                      onPressed: () => setState(() {
                        _load = widget.repository.init();
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      return MainNavigationShell(
        repository: widget.repository,
        onToggleTheme: widget.onToggleTheme,
        isDark: widget.isDark,
      );
    },
  );
}
