enum ExamSource {
  inicet('INI-CET'),
  neetPg('NEET-PG'),
  aiims('AIIMS');

  const ExamSource(this.label);
  final String label;
}

Set<ExamSource> parseExamSources(String text) {
  return {
    if (RegExp(r'\bini(?:[\s-]*cet)?\b', caseSensitive: false).hasMatch(text))
      ExamSource.inicet,
    if (RegExp(r'\bneet(?:[\s-]*pg)?\b', caseSensitive: false).hasMatch(text))
      ExamSource.neetPg,
    if (RegExp(r'\baiims\b', caseSensitive: false).hasMatch(text))
      ExamSource.aiims,
  };
}

int parseRepeatCount(Object? value, String tag, String exam) {
  var count = 1;
  if (value != null) {
    final explicit = value is int ? value : int.tryParse(value.toString());
    if (explicit == null || explicit < 1) {
      throw const FormatException('repeats must be a positive integer.');
    }
    count = explicit;
  }
  // Older exports stored a default of 1 even when their source tag said 2x+.
  for (final match in RegExp(
    r'\b(\d+)\s*x\b',
    caseSensitive: false,
  ).allMatches('$tag $exam')) {
    final repeated = int.parse(match.group(1)!);
    if (repeated > count) count = repeated;
  }
  return count;
}
