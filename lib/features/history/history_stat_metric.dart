import 'package:flutter/material.dart';

class HistoryStatMetric extends StatelessWidget {
  const HistoryStatMetric({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800, color: color),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
