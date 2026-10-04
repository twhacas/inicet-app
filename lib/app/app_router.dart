import 'package:flutter/material.dart';

import '../domain/content/bootstrap_manifest.dart';
import '../domain/content/bootstrap_manifest_repository.dart';
import '../features/bootstrap/bootstrap_gate.dart';
import '../features/bootstrap/bootstrap_screens.dart';
import '../features/bootstrap/startup_screens.dart';
import '../features/design_system/design_system_showcase_screen.dart';

import '../domain/content/inicet_repository.dart';

abstract final class AppRoutes {
  static const welcome = '/';
  static const learningSpace = '/learning-space';
  static const designSystemCatalog = '/design-system';
}

final class AppRouter {
  const AppRouter({
    required this.bootstrapRepository,
    required this.onToggleTheme,
    this.inicetRepository,
  });

  final BootstrapManifestRepository bootstrapRepository;
  final VoidCallback onToggleTheme;
  final InicetRepository? inicetRepository;

  Route<void> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) {
        return switch (settings.name) {
          AppRoutes.welcome => BootstrapGate(
            repository: bootstrapRepository,
            builder:
                (context, manifest) => WelcomeScreen(
                  manifest: manifest,
                  onToggleTheme: onToggleTheme,
                  onEnterLearning: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.learningSpace,
                      arguments: manifest,
                    );
                  },
                  onOpenCatalog: () {
                    Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.designSystemCatalog);
                  },
                ),
          ),
          AppRoutes.learningSpace
              when settings.arguments is BootstrapManifest =>
            LearningSpaceScreen(
              manifest: settings.arguments! as BootstrapManifest,
              inicetRepository: inicetRepository,
              onOpenCatalog: () {
                Navigator.of(context).pushNamed(AppRoutes.designSystemCatalog);
              },
            ),
          AppRoutes.designSystemCatalog => DesignSystemShowcaseScreen(
            onToggleTheme: onToggleTheme,
          ),
          _ => RouteNotFoundScreen(
            onReturnHome: () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
            },
          ),
        };
      },
    );
  }
}
