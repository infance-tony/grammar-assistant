import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

/// Manages the system tray icon and context menu.
class TrayService {
  static final SystemTray _tray = SystemTray();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || !Platform.isWindows) return;

    try {
      await _tray.initSystemTray(
        title: 'Grammar Assistant',
        iconPath: 'assets/icons/app_icon.ico',
      );

      final menu = Menu();
      await menu.buildFrom([
        MenuItemLabel(
          label: 'Open Grammar Assistant',
          onClicked: (_) async {
            await windowManager.show();
            await windowManager.focus();
          },
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: 'Quit',
          onClicked: (_) => exit(0),
        ),
      ]);
      await _tray.setContextMenu(menu);

      _tray.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick ||
            eventName == kSystemTrayEventRightClick) {
          windowManager.show();
          windowManager.focus();
        }
      });

      _initialized = true;
    } catch (e) {
      debugPrint('[TrayService] Failed to initialize: $e');
    }
  }

  static Future<void> dispose() async {
    if (_initialized) {
      await _tray.destroy();
      _initialized = false;
    }
  }
}
