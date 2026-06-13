import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app.dart';
import 'services/backend_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      await windowManager.show();
      await windowManager.focus();
    },
  );

  // ── Set up flutter_animate defaults ──────────────────────────────────────
  Animate.restartOnHotReload = true;

  // ── Launch backend (dev: python; release: .exe) ───────────────────────
  try {
    await BackendLauncher.launch();
  } catch (e) {
    debugPrint('Backend launch error: $e');
  }

  runApp(const GrammarAssistantApp());
}
