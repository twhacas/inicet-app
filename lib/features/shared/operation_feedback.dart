import 'package:flutter/material.dart';

import '../../data/question_storage.dart';

String operationErrorMessage(Object error) => switch (error) {
  QuestionStorageException() => error.message,
  FormatException() => error.message.toString(),
  _ => 'The operation could not be completed. Please retry.',
};

void showOperationError(
  BuildContext context,
  Object error, {
  VoidCallback? retry,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(operationErrorMessage(error)),
      action: retry == null
          ? null
          : SnackBarAction(label: 'Retry', onPressed: retry),
    ),
  );
}
