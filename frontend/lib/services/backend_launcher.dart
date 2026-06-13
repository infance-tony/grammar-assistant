import 'dart:io';
import 'package:flutter/foundation.dart';
import 'backend_service.dart';

/// Launches the Python FastAPI backend as a child process and
/// manages its lifecycle with the Flutter app.
class BackendLauncher {
  static Process? _process;
  static bool _launched = false;

  /// Starts the backend process and waits until it is healthy.
  ///
  /// In debug mode, spawns: python backend/main.py
  /// In release mode, spawns: grammar_backend_python/python.exe main.py
  static Future<void> launch() async {
    if (_launched) return;

    // Check if backend is already running (e.g. user started it manually)
    final alreadyRunning = await BackendService.instance.isHealthy();
    if (alreadyRunning) {
      debugPrint('[BackendLauncher] Backend already running, skipping launch');
      _launched = true;
      return;
    }

    final exePath = _resolveBackendPath();
    final args = _resolveArgs(exePath);
    final workDir = _resolveWorkingDir(exePath);
    debugPrint('[BackendLauncher] Starting backend: $exePath ${args.join(" ")}');
    debugPrint('[BackendLauncher] Working dir: $workDir');

    try {
      _process = await Process.start(
        exePath,
        args,
        environment: {'GRAMMAR_PORT': '11434'},
        workingDirectory: workDir,
        runInShell: Platform.isWindows,
      );

      _launched = true;

      // Pipe backend logs to Flutter debug console
      _process!.stdout.listen(
        (data) => debugPrint('[Backend] ${String.fromCharCodes(data).trim()}'),
      );
      _process!.stderr.listen(
        (data) => debugPrint('[Backend ERR] ${String.fromCharCodes(data).trim()}'),
      );
    } catch (e) {
      debugPrint('[BackendLauncher] Failed to start backend: $e');
      rethrow;
    }
  }

  /// Waits until /health returns "ready", with a timeout.
  static Future<bool> waitForReady({int timeoutSeconds = 120}) async {
    final deadline = DateTime.now().add(Duration(seconds: timeoutSeconds));
    while (DateTime.now().isBefore(deadline)) {
      final healthy = await BackendService.instance.isHealthy();
      if (healthy) return true;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  /// Kills the backend process when the app exits.
  static Future<void> dispose() async {
    if (_process != null) {
      debugPrint('[BackendLauncher] Stopping backend…');
      _process!.kill();
      await _process!.exitCode;
      _process = null;
      _launched = false;
    }
  }

  /// Resolves the backend executable path based on release vs debug mode.
  static String _resolveBackendPath() {
    final appDir = File(Platform.resolvedExecutable).parent.path;

    // Release mode: look for embedded Python next to the Flutter exe
    final embeddedPython = '$appDir\\grammar_backend_python\\python.exe';
    if (File(embeddedPython).existsSync()) return embeddedPython;

    // Dev mode: run python directly
    return 'python';
  }

  /// Returns arguments for the backend process.
  static List<String> _resolveArgs(String exe) {
    if (exe.contains('grammar_backend_python')) {
      // Installed mode: run main.py from the embedded python directory
      return ['main.py'];
    }
    // Dev mode: pass the backend main.py path
    final repoRoot = Directory.current.path
        .replaceAll('\\frontend', '')
        .replaceAll('/frontend', '');
    return ['$repoRoot\\backend\\main.py'];
  }

  /// Returns the working directory for the backend process.
  static String? _resolveWorkingDir(String exe) {
    if (exe.contains('grammar_backend_python')) {
      // Installed mode: working dir is the embedded python directory
      return File(exe).parent.path;
    }
    // Dev mode: use current dir
    return null;
  }
}
