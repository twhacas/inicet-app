import 'package:flutter/material.dart';

import '../../data/question_repository.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../history/test_history_screen.dart';
import '../import/import_questions_dialog.dart';
import '../mock_tests/mock_tests_tab.dart';
import '../practice_sets/practice_sets_tab.dart';
import '../setup/test_setup_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({
    required this.repository,
    required this.onToggleTheme,
    required this.isDark,
    super.key,
  });

  final QuestionRepository repository;
  final VoidCallback onToggleTheme;
  final bool isDark;

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  static const _titles = [
    'INICET MCQ Hub',
    'Subject Practice Sets',
    'Full-Length Mock Papers',
    'Test History & Analytics',
    'Bookmarked Questions',
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.of(context).size.width >= AppDimensions.compactBreakpoint;

    final tabs = [
      TestSetupScreen(
        repository: widget.repository,
        onToggleTheme: widget.onToggleTheme,
        isDark: widget.isDark,
        embedded: true,
      ),
      PracticeSetsTab(repository: widget.repository),
      MockTestsTab(repository: widget.repository),
      TestHistoryScreen(repository: widget.repository),
      BookmarksScreen(repository: widget.repository),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.quiz_rounded),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _titles[_currentIndex],
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // JSON Manager dialog
          IconButton(
            tooltip: 'Import / Export JSON Questions',
            icon: const Icon(Icons.file_upload_rounded),
            onPressed: () async {
              await ImportQuestionsDialog.show(context, widget.repository);
              if (mounted) setState(() {});
            },
          ),

          // Theme toggle
          IconButton(
            tooltip: widget.isDark ? 'Light theme' : 'Dark theme',
            icon: Icon(
              widget.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Row(
        children: [
          if (isWide) ...[
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) =>
                  setState(() => _currentIndex = idx),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.tune_rounded),
                  selectedIcon: Icon(Icons.tune),
                  label: Text('Custom Test'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.auto_stories_outlined),
                  selectedIcon: Icon(Icons.auto_stories_rounded),
                  label: Text('Practice Sets'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.timer_outlined),
                  selectedIcon: Icon(Icons.timer_rounded),
                  label: Text('Mock Tests'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history_rounded),
                  selectedIcon: Icon(Icons.history_toggle_off_rounded),
                  label: Text('History'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bookmark_border_rounded),
                  selectedIcon: Icon(Icons.bookmark_rounded),
                  label: Text('Bookmarks'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
          ],
          Expanded(
            child: IndexedStack(index: _currentIndex, children: tabs),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) =>
                  setState(() => _currentIndex = idx),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.tune_rounded),
                  selectedIcon: Icon(Icons.tune),
                  label: 'Custom Test',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_stories_outlined),
                  selectedIcon: Icon(Icons.auto_stories_rounded),
                  label: 'Practice Sets',
                ),
                NavigationDestination(
                  icon: Icon(Icons.timer_outlined),
                  selectedIcon: Icon(Icons.timer_rounded),
                  label: 'Mock Tests',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_rounded),
                  selectedIcon: Icon(Icons.history_toggle_off_rounded),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bookmark_border_rounded),
                  selectedIcon: Icon(Icons.bookmark_rounded),
                  label: 'Bookmarks',
                ),
              ],
            ),
    );
  }
}
