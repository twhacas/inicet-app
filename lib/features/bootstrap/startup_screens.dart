import 'package:flutter/material.dart';

import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_card.dart';
import '../../design_system/components/app_components.dart';
import '../../design_system/tokens/app_spacing.dart';

class StartupLoadingScreen extends StatelessWidget {
  const StartupLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Semantics(
              liveRegion: true,
              label: 'Opening local learning content',
              child: AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Opening your local learning space…',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StartupFailureScreen extends StatelessWidget {
  const StartupFailureScreen({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppStatusBanner(
                      title: 'INICET Prep could not start',
                      message:
                          'A required local learning file could not be opened. '
                          'Your offline revision data has not been changed.',
                      tone: AppBannerTone.error,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: 'Retry startup',
                      icon: Icons.refresh_rounded,
                      onPressed: onRetry,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen({required this.onReturnHome, super.key});

  final VoidCallback onReturnHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppStatusBanner(
                      title: 'Route unavailable',
                      message:
                          'The requested screen is not registered in this application.',
                      tone: AppBannerTone.warning,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: 'Back to welcome',
                      icon: Icons.home_rounded,
                      onPressed: onReturnHome,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
