import 'package:flutter_test/flutter_test.dart';
import 'package:inicet_app/domain/content/bootstrap_manifest.dart';

void main() {
  const validSource = '''
  {
    "schemaVersion": 1,
    "productId": "inicet-prep-hub",
    "productName": "INICET Prep",
    "welcomeHeadline": "Master INICET & NEET-PG Previous Year Topics.",
    "welcomeMessage": "High-yield topic analysis, question repeat trends, and rapid revision.",
    "offlineMessage": "All 20 subjects remain offline.",
    "primaryActionLabel": "Enter learning space"
  }
  ''';

  test('parses a valid typed bootstrap manifest', () {
    final manifest = BootstrapManifest.fromJsonString(validSource);

    expect(manifest.schemaVersion, 1);
    expect(manifest.productId, 'inicet-prep-hub');
    expect(manifest.productName, 'INICET Prep');
    expect(manifest.primaryActionLabel, 'Enter learning space');
  });

  test('rejects blank and malformed bootstrap content', () {
    expect(
      () => BootstrapManifest.fromJsonString('  '),
      throwsA(isA<BootstrapManifestException>()),
    );
    expect(
      () => BootstrapManifest.fromJsonString('{not json}'),
      throwsA(isA<BootstrapManifestException>()),
    );
  });

  test('rejects unsupported schemas and blank required fields', () {
    expect(
      () => BootstrapManifest.fromJsonString(
        validSource.replaceFirst('"schemaVersion": 1', '"schemaVersion": 2'),
      ),
      throwsA(isA<BootstrapManifestException>()),
    );
    expect(
      () => BootstrapManifest.fromJsonString(
        validSource.replaceFirst(
          '"productName": "INICET Prep"',
          '"productName": ""',
        ),
      ),
      throwsA(isA<BootstrapManifestException>()),
    );
  });
}
