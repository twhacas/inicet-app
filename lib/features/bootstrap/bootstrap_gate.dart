import 'package:flutter/material.dart';

import '../../domain/content/bootstrap_manifest.dart';
import '../../domain/content/bootstrap_manifest_repository.dart';
import 'startup_screens.dart';

class BootstrapGate extends StatefulWidget {
  const BootstrapGate({
    required this.repository,
    required this.builder,
    super.key,
  });

  final BootstrapManifestRepository repository;
  final Widget Function(BuildContext context, BootstrapManifest manifest)
  builder;

  @override
  State<BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<BootstrapGate> {
  late Future<BootstrapManifest> _manifest;

  @override
  void initState() {
    super.initState();
    _manifest = widget.repository.load();
  }

  @override
  void didUpdateWidget(BootstrapGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _manifest = widget.repository.load();
    }
  }

  void _retry() {
    setState(() {
      _manifest = widget.repository.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BootstrapManifest>(
      future: _manifest,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const StartupLoadingScreen();
        }

        final manifest = snapshot.data;
        if (manifest != null) {
          return widget.builder(context, manifest);
        }

        final error = snapshot.error;
        final message =
            error is BootstrapManifestException
                ? error.message
                : 'The local startup content returned an unexpected error.';
        return StartupFailureScreen(message: message, onRetry: _retry);
      },
    );
  }
}
