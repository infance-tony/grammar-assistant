import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/history_service.dart';
import '../services/backend_service.dart';
import '../models/history_entry.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const SettingsScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<HistoryEntry> _history = [];
  bool _loadingHistory = true;

  // Model selection state
  List<String> _availableModels = [];
  String _activeModel = '';
  bool _loadingModels = true;
  bool _switchingModel = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadModels();
  }

  Future<void> _loadHistory() async {
    final entries = await HistoryService.getRecent();
    if (mounted) {
      setState(() {
        _history = entries;
        _loadingHistory = false;
      });
    }
  }

  Future<void> _loadModels() async {
    try {
      final data = await BackendService.instance.getModels();
      if (mounted) {
        setState(() {
          _availableModels = (data['models'] as List).cast<String>();
          _activeModel = data['active'] as String? ?? '';
          _loadingModels = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  Future<void> _switchModel(String filename) async {
    if (filename == _activeModel) return;
    setState(() => _switchingModel = true);
    try {
      await BackendService.instance.switchModel(filename);
      if (mounted) {
        setState(() {
          _activeModel = filename;
          _switchingModel = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Switched to ${filename.replaceAll('.gguf', '')}')),
            ]),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on BackendException catch (e) {
      if (mounted) {
        setState(() => _switchingModel = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textSec),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Appearance ──────────────────────────────────────────────────
          _SectionHeader('Appearance', isDark: widget.isDark),
          _SettingsTile(
            icon: widget.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            label: widget.isDark ? 'Dark Mode' : 'Light Mode',
            trailing: Switch(
              value: widget.isDark,
              onChanged: (_) => widget.onToggleTheme(),
              activeColor: AppColors.accent,
            ),
            isDark: widget.isDark,
          ),

          const SizedBox(height: 24),

          // ── AI Model ─────────────────────────────────────────────────────
          _SectionHeader('AI Model', isDark: widget.isDark),
          _buildModelSection(textSec),

          const SizedBox(height: 24),

          // ── About ────────────────────────────────────────────────────────
          _SectionHeader('About', isDark: widget.isDark),
          _SettingsTile(
            icon: Icons.auto_awesome,
            label: 'Grammar Assistant',
            trailing: Text('v1.1.0', style: GoogleFonts.inter(color: textSec, fontSize: 13)),
            isDark: widget.isDark,
          ),
          _SettingsTile(
            icon: Icons.wifi_off_rounded,
            label: 'Mode',
            trailing: Text(
              '100% Offline',
              style: GoogleFonts.inter(
                color: AppColors.success,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            isDark: widget.isDark,
          ),

          const SizedBox(height: 24),

          // ── History ──────────────────────────────────────────────────────
          _SectionHeader('History', isDark: widget.isDark),
          if (_loadingHistory)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            )
          else if (_history.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No history yet.', style: GoogleFonts.inter(color: textSec)),
            )
          else ...[
            ..._history.take(10).map((e) => _HistoryTile(entry: e, isDark: widget.isDark)),
            if (_history.length > 1)
              TextButton(
                onPressed: () async {
                  await HistoryService.clearAll();
                  _loadHistory();
                },
                child: Text(
                  'Clear All History',
                  style: GoogleFonts.inter(color: AppColors.error, fontSize: 13),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildModelSection(Color textSec) {
    final isDark = widget.isDark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    if (_loadingModels) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Text('Loading models…', style: GoogleFonts.inter(color: textSec, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    if (_availableModels.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Text(
            'No models found in backend/models/.\nRun: python download_model.py phi4mini',
            style: GoogleFonts.inter(color: textSec, fontSize: 13),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            ..._availableModels.map((model) {
              final isActive = model == _activeModel;
              final displayName = model
                  .replaceAll('.gguf', '')
                  .replaceAll('-', ' ')
                  .replaceAll('_', ' ');
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(
                  Icons.memory_rounded,
                  color: isActive ? AppColors.accent : textSec,
                  size: 20,
                ),
                title: Text(
                  displayName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? textPrimary : textSec,
                  ),
                ),
                trailing: _switchingModel && !isActive
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.accent),
                      )
                    : isActive
                        ? const Icon(Icons.check_circle, color: AppColors.success, size: 18)
                        : null,
                onTap: _switchingModel ? null : () => _switchModel(model),
              );
            }),
            if (_switchingModel)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Switching model — this may take up to 30 seconds…',
                  style: GoogleFonts.inter(fontSize: 12, color: textSec),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader(this.title, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final bool isDark;
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(icon, color: AppColors.accent, size: 20),
            title: Text(label, style: GoogleFonts.inter(fontSize: 14, color: textPrimary)),
            trailing: trailing,
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;
  final bool isDark;
  const _HistoryTile({required this.entry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.action,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${entry.createdAt.hour}:${entry.createdAt.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.inter(fontSize: 11, color: textSec),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entry.inputText.length > 80
                ? '${entry.inputText.substring(0, 80)}…'
                : entry.inputText,
            style: GoogleFonts.inter(fontSize: 12, color: textSec),
          ),
        ],
      ),
    );
  }
}
