import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'services/settings_service.dart';

class GrammarAssistantApp extends StatefulWidget {
  const GrammarAssistantApp({super.key});

  @override
  State<GrammarAssistantApp> createState() => _GrammarAssistantAppState();
}

class _GrammarAssistantAppState extends State<GrammarAssistantApp> {
  bool _isDark = true;

  Future<void> _toggleTheme() async {
    final settings = await SettingsService.getInstance();
    setState(() => _isDark = !_isDark);
    await settings.setThemeMode(_isDark ? 'dark' : 'light');
  }

  @override
  Widget build(BuildContext context) {
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
