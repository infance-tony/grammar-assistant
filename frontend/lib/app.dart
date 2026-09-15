import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/floating_screen.dart';
import 'theme/app_theme.dart';
import 'services/settings_service.dart';
import 'services/floating_controller.dart';

class GrammarAssistantApp extends StatefulWidget {
  const GrammarAssistantApp({super.key});

  @override
  State<GrammarAssistantApp> createState() => _GrammarAssistantAppState();
}

class _GrammarAssistantAppState extends State<GrammarAssistantApp>
    with WindowListener {
  bool _isDark = true;
  bool _isFloating = false;

  StreamSubscription<bool>? _modeSub;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _loadTheme();
    _modeSub = FloatingController.onModeChange.listen((floating) async {
      if (floating) {
        await _enterFloatMode();
      } else {
        await _exitFloatMode();
      }
    });
  }

  @override
  void dispose() {
    _modeSub?.cancel();
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _loadTheme() async {
    final settings = await SettingsService.getInstance();
    final mode = settings.getThemeMode();
    if (mounted) setState(() => _isDark = mode != 'light');
  }

  Future<void> _toggleTheme() async {
    final settings = await SettingsService.getInstance();
    setState(() => _isDark = !_isDark);
    await settings.setThemeMode(_isDark ? 'dark' : 'light');
  }

  Future<void> _enterFloatMode() async {
    // Resize to compact floating window
    await windowManager.setSize(const Size(440, 190));
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setResizable(false);
    if (mounted) setState(() => _isFloating = true);
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _exitFloatMode() async {
    // Restore full window
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setResizable(true);
    await windowManager.setSize(const Size(1100, 760));
    await windowManager.center();
    if (mounted) setState(() => _isFloating = false);
    await windowManager.show();
    await windowManager.focus();
  }

  // Minimize to tray instead of quitting when the user closes the window
  @override
  void onWindowClose() async {
    await windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFloating) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
        home: FloatingScreen(
          isDark: _isDark,
          onExpand: () => FloatingController.exitFloat(),
        ),
      );
    }

    return MaterialApp(
      title: 'Grammar Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (_) => HomeScreen(
              isDark: _isDark,
              onToggleTheme: _toggleTheme,
              onOpenSettings: () {},
            ),
        '/settings': (_) => SettingsScreen(
              isDark: _isDark,
              onToggleTheme: _toggleTheme,
            ),
      },
    );
  }
}
