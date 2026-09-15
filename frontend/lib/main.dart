import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app.dart';
import 'services/backend_launcher.dart';
import 'services/tray_service.dart';
import 'services/floating_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable runtime font fetching so the app works fully offline.
  // Falls back to the system sans-serif (Segoe UI on Windows).
  GoogleFonts.config.allowRuntimeFetching = false;

  // ── Window setup ─────────────────────────────────────────────────────────
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      size: Size(1100, 760),
      minimumSize: Size(800, 600),
      center: true,
      title: 'Grammar Assistant',
      titleBarStyle: TitleBarStyle.normal,
      backgroundColor: Color(0xFF0F0F13),
    ),
    () async {
      // Intercept close → minimize to tray instead of quitting
      await windowManager.setPreventClose(true);
      await windowManager.show();
      await windowManager.focus();
    },
  );

  // ── System tray ───────────────────────────────────────────────────────────
  await TrayService.initialize();

  // ── Global hotkey: Ctrl+Shift+G → show/focus window ──────────────────────
  await hotKeyManager.unregisterAll();
  if (Platform.isWindows) {
    await hotKeyManager.register(
      HotKey(
        key: PhysicalKeyboardKey.keyG,
        modifiers: [HotKeyModifier.control, HotKeyModifier.shift],
        scope: HotKeyScope.system,
      ),
      keyDownHandler: (_) async {
        if (FloatingController.isFloating) {
          // Already in float mode — trigger another grab
          FloatingController.triggerGrab();
        } else {
          // Enter float mode; FloatingScreen will auto-grab on trigger
          FloatingController.enterFloat();
          // Small delay to let the window appear and the previous app lose focus
          await Future.delayed(const Duration(milliseconds: 400));
          FloatingController.triggerGrab();
        }
      },
    );
  }

  // ── Set up flutter_animate defaults ──────────────────────────────────────
  Animate.restartOnHotReload = true;

  // ── Launch backend (dev: python; release: .exe) ───────────────────────────
  try {
    await BackendLauncher.launch();
  } catch (e) {
    debugPrint('Backend launch error: $e');
  }

  runApp(const GrammarAssistantApp());
}
