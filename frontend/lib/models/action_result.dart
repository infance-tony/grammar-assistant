/// Data model for an AI action result.
class ActionResult {
  final String result;
  final int elapsedMs;
  final String action;

  const ActionResult({
    required this.result,
    required this.elapsedMs,
    required this.action,
  });

  factory ActionResult.fromJson(Map<String, dynamic> json) {
    return ActionResult(
      result: json['result'] as String,
      elapsedMs: json['elapsed_ms'] as int,
      action: json['action'] as String,
    );
  }

  @override
  String toString() => 'ActionResult(action: $action, elapsed: ${elapsedMs}ms)';
}
