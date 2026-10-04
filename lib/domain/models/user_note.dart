final class UserNote {
  const UserNote({
    required this.questionId,
    required this.noteText,
    required this.updatedAt,
  });

  final String questionId;
  final String noteText;
  final DateTime updatedAt;

  Map<String, Object?> toJson() {
    return {
      'questionId': questionId,
      'noteText': noteText,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserNote.fromJson(Map<String, Object?> json) {
    return UserNote(
      questionId: json['questionId']?.toString() ?? '',
      noteText: json['noteText']?.toString() ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
