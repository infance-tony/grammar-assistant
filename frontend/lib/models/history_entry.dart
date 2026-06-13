/// Data model for a history entry stored in SQLite.
class HistoryEntry {
  final int? id;
  final String action;
  final String inputText;
  final String outputText;
  final int elapsedMs;
  final DateTime createdAt;

  const HistoryEntry({
    this.id,
    required this.action,
    required this.inputText,
    required this.outputText,
    required this.elapsedMs,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'action': action,
      'input_text': inputText,
      'output_text': outputText,
      'elapsed_ms': elapsedMs,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    return HistoryEntry(
      id: map['id'] as int?,
      action: map['action'] as String,
      inputText: map['input_text'] as String,
      outputText: map['output_text'] as String,
      elapsedMs: map['elapsed_ms'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
