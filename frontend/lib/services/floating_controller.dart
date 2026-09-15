import 'dart:async';

/// Coordinates the floating overlay mode across main.dart (hotkey) and
/// FloatingScreen (grab-and-correct trigger).
class FloatingController {
  FloatingController._();

  // ── Float mode toggle ──────────────────────────────────────────────────────
  static final _modeController = StreamController<bool>.broadcast();

  /// Stream that emits `true` to enter float mode, `false` to exit.
  static Stream<bool> get onModeChange => _modeController.stream;

  static bool _isFloating = false;
  static bool get isFloating => _isFloating;

  static void enterFloat() {
    _isFloating = true;
    _modeController.add(true);
  }

  static void exitFloat() {
    _isFloating = false;
    _modeController.add(false);
  }

  // ── Grab-and-correct trigger ───────────────────────────────────────────────
  static final _grabController = StreamController<void>.broadcast();

  /// Stream that fires each time the hotkey wants a new grab-and-correct cycle.
  static Stream<void> get onGrabTrigger => _grabController.stream;

  static void triggerGrab() => _grabController.add(null);
}
