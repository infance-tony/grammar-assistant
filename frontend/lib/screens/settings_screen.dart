import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/history_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final entries = await HistoryService.getRecent();
    if (mounted) setState(() { _history = entries; _loadingHistory = false; });
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = widget.isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w600)),
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
          _SectionHeader('About', isDark: widget.isDark),
          _SettingsTile(icon: Icons.auto_awesome, label: 'Grammar Assistant', trailing: Text('v1.0.0', style: GoogleFonts.inter(color: textSec, fontSize: 13)), isDark: widget.isDark),
          _SettingsTile(icon: Icons.memory_rounded, label: 'AI Model', trailing: Text('Qwen2.5-0.5B Q4_K_M', style: GoogleFonts.inter(color: textSec, fontSize: 13)), isDark: widget.isDark),
          _SettingsTile(icon: Icons.wifi_off_rounded, label: 'Mode', trailing: Text('100% Offline', style: GoogleFonts.inter(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600)), isDark: widget.isDark),
          const SizedBox(height: 24),
          _SectionHeader('History', isDark: widget.isDark),
          if (_loadingHistory)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.accent)))
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
                child: Text('Clear All History', style: GoogleFonts.inter(color: AppColors.error, fontSize: 13)),
              ),
          ],
        ],
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
  const _SettingsTile({required this.icon, required this.label, required this.trailing, required this.isDark});

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
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                child: Text(entry.action, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accent)),
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
            entry.inputText.length > 80 ? '${entry.inputText.substring(0, 80)}…' : entry.inputText,
            style: GoogleFonts.inter(fontSize: 12, color: textSec),
          ),
        ],
      ),
    );
  }
}
