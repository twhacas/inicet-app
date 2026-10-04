import 'package:flutter/services.dart';

import '../../domain/content/bootstrap_manifest.dart';
import '../../domain/content/bootstrap_manifest_repository.dart';

final class AssetBootstrapManifestRepository
    implements BootstrapManifestRepository {
  AssetBootstrapManifestRepository({
    AssetBundle? bundle,
    this.assetPath = _defaultAssetPath,
  }) : _bundle = bundle ?? rootBundle;

  static const _defaultAssetPath =
      'assets/fixtures/subject_data/bootstrap_manifest.json';

  final AssetBundle _bundle;
  final String assetPath;

  @override
  Future<BootstrapManifest> load() async {
    try {
      final source = await _bundle.loadString(assetPath);
      return BootstrapManifest.fromJsonString(source);
    } on BootstrapManifestException {
      rethrow;
    } on Object {
      throw const BootstrapManifestException(
        'The local bootstrap learning file could not be opened.',
      );
    }
  }
}
