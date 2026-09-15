import 'dart:io';
import 'package:flutter/services.dart';

/// Grabs selected text from any focused app and pastes corrected text back.
class ClipboardService {
  /// Saves the clipboard content before we overwrite it.
  static String _savedClipboard = '';

  /// Simulates Ctrl+C in the currently focused window, then reads the clipboard.
  /// Returns the selected text, or empty string if nothing was selected.
  static Future<String> grabSelectedText() async {
    // Save current clipboard so we can restore it later
    final existing = await Clipboard.getData('text/plain');
    _savedClipboard = existing?.text ?? '';

    // Clear clipboard first so we can detect if Ctrl+C actually copied something
    await Clipboard.setData(const ClipboardData(text: ''));
    await Future.delayed(const Duration(milliseconds: 80));

    // Simulate Ctrl+C in the previously focused app
    await _sendKeys('^c');
    await Future.delayed(const Duration(milliseconds: 350));

    final data = await Clipboard.getData('text/plain');
    return data?.text?.trim() ?? '';
  }

  /// Sets clipboard to [text] and simulates Ctrl+V to paste into the focused app.
  static Future<void> pasteText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    await Future.delayed(const Duration(milliseconds: 80));
    await _sendKeys('^v');
    await Future.delayed(const Duration(milliseconds: 200));

    // Restore original clipboard after paste
    if (_savedClipboard.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      await Clipboard.setData(ClipboardData(text: _savedClipboard));
    }
  }

  /// Sends keyboard shortcut via PowerShell WScript.Shell (Windows only).
  static Future<void> _sendKeys(String keys) async {
    if (!Platform.isWindows) return;
    await Process.run('powershell', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      '(New-Object -ComObject WScript.Shell).SendKeys("$keys")',
    ]);
  }
}
