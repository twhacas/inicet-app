import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/content/inicet_models.dart';
import '../../domain/content/inicet_repository.dart';

final class AssetInicetRepository implements InicetRepository {
  AssetInicetRepository({
    AssetBundle? bundle,
    this.statsPath = _defaultStatsPath,
    this.samplesPath = _defaultSamplesPath,
  }) : _bundle = bundle ?? rootBundle;

  static const _defaultStatsPath =
      'assets/fixtures/subject_data/subject_stats.json';
  static const _defaultSamplesPath =
      'assets/fixtures/subject_data/high_yield_samples.json';

  final AssetBundle _bundle;
  final String statsPath;
  final String samplesPath;

  @override
  Future<List<InicetSubjectStats>> loadSubjectStats() async {
    try {
      final source = await _bundle.loadString(statsPath);
      final decoded = jsonDecode(source);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, Object?>>()
          .map(InicetSubjectStats.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<Map<String, InicetSubjectDetail>> loadSubjectDetails() async {
    try {
      final source = await _bundle.loadString(samplesPath);
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, Object?>) return const {};

      final result = <String, InicetSubjectDetail>{};
      for (final entry in decoded.entries) {
        if (entry.value is Map<String, Object?>) {
          result[entry.key] = InicetSubjectDetail.fromJson(
            entry.key,
            entry.value! as Map<String, Object?>,
          );
        }
      }
      return result;
    } catch (_) {
      return const {};
    }
  }
}
