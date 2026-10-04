import 'bootstrap_manifest.dart';

abstract interface class BootstrapManifestRepository {
  Future<BootstrapManifest> load();
}
