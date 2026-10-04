import 'dart:convert';

final class BootstrapManifest {
  const BootstrapManifest({
    required this.schemaVersion,
    required this.productId,
    required this.productName,
    required this.welcomeHeadline,
    required this.welcomeMessage,
    required this.offlineMessage,
    required this.primaryActionLabel,
  });

  factory BootstrapManifest.fromJsonString(String source) {
    if (source.trim().isEmpty) {
      throw const BootstrapManifestException(
        'The bootstrap manifest is blank.',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const BootstrapManifestException(
        'The bootstrap manifest is not valid JSON.',
      );
    }

    if (decoded is! Map<String, Object?>) {
      throw const BootstrapManifestException(
        'The bootstrap manifest must be a JSON object.',
      );
    }

    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion != 1) {
      throw const BootstrapManifestException(
        'The bootstrap manifest schema version is not supported.',
      );
    }

    return BootstrapManifest(
      schemaVersion: schemaVersion as int,
      productId: _requiredText(decoded, 'productId'),
      productName: _requiredText(decoded, 'productName'),
      welcomeHeadline: _requiredText(decoded, 'welcomeHeadline'),
      welcomeMessage: _requiredText(decoded, 'welcomeMessage'),
      offlineMessage: _requiredText(decoded, 'offlineMessage'),
      primaryActionLabel: _requiredText(decoded, 'primaryActionLabel'),
    );
  }

  final int schemaVersion;
  final String productId;
  final String productName;
  final String welcomeHeadline;
  final String welcomeMessage;
  final String offlineMessage;
  final String primaryActionLabel;

  static String _requiredText(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw BootstrapManifestException(
        'The bootstrap manifest field "$key" must contain text.',
      );
    }
    return value.trim();
  }
}

final class BootstrapManifestException implements Exception {
  const BootstrapManifestException(this.message);

  final String message;

  @override
  String toString() => message;
}
