/// Writing statistics returned with every API response.
class TextStats {
  final int wordCount;
  final int charCount;
  final int sentenceCount;
  final int readingTimeSec;

  const TextStats({
    required this.wordCount,
    required this.charCount,
    required this.sentenceCount,
    required this.readingTimeSec,
  });

  factory TextStats.fromJson(Map<String, dynamic> json) => TextStats(
        wordCount: json['word_count'] as int,
        charCount: json['char_count'] as int,
        sentenceCount: json['sentence_count'] as int,
        readingTimeSec: json['reading_time_sec'] as int,
      );

  static TextStats compute(String text) {
    final words = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    final chars = text.length;
    final sentences = RegExp(r'[.!?]+').allMatches(text).length;
    final readingTimeSec = words == 0 ? 0 : (words * 60 / 200).ceil();
    return TextStats(
      wordCount: words,
      charCount: chars,
      sentenceCount: sentences == 0 ? 1 : sentences,
      readingTimeSec: readingTimeSec < 1 ? 1 : readingTimeSec,
    );
  }
}

/// Data model for an AI action result.
class ActionResult {
  final String result;
  final int elapsedMs;
  final String action;
  final List<String> alternatives;
  final String? tone;
  final TextStats? stats;

  const ActionResult({
    required this.result,
    required this.elapsedMs,
    required this.action,
    this.alternatives = const [],
    this.tone,
    this.stats,
  });

  factory ActionResult.fromJson(Map<String, dynamic> json) => ActionResult(
        result: json['result'] as String,
        elapsedMs: json['elapsed_ms'] as int,
        action: json['action'] as String,
        alternatives: (json['alternatives'] as List?)?.cast<String>() ?? [],
        tone: json['tone'] as String?,
        stats: json['stats'] != null
            ? TextStats.fromJson(json['stats'] as Map<String, dynamic>)
            : null,
      );

  @override
  String toString() => 'ActionResult(action: $action, elapsed: ${elapsedMs}ms)';
}
