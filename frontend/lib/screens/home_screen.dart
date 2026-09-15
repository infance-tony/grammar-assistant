import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/backend_service.dart';
import '../services/history_service.dart';
import '../models/history_entry.dart';
import '../widgets/text_input_panel.dart';
import '../widgets/text_output_panel.dart';
import '../widgets/action_button_row.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/diff_view_panel.dart';
import '../widgets/stats_bar.dart';
import '../theme/app_colors.dart';

const Map<String, String> kActionLabels = {
  'grammar':          'Fix Grammar',
  'rewrite_casual':   'Rewrite — Casual',
  'rewrite_clear':    'Rewrite — Clear',
  'rewrite_concise':  'Rewrite — Concise',
  'professional':     'Professional Tone',
  'expand':           'Expand',
  'shorten':          'Shorten',
  'explain':          'Explain Issues',
  'tone':             'Detect Tone',
  'suggest_multi':    'Suggest Options',
  'email':            'Write Email',
};

class HomeScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onOpenSettings;

  const HomeScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.onOpenSettings,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _inputController = TextEditingController();
  String _outputText = '';
  String? _currentAction;
  bool _isLoading = false;
  int? _elapsedMs;
  String _statusMsg = 'Model ready';
  String _activeModelName = '';

  // Grammarly-like feature state
  bool _autoCheckEnabled = false;
  bool _showDiff = false;
  String? _detectedTone;
  List<String> _alternatives = [];
  int _selectedAlternative = 0;
  Timer? _debounceTimer;

  // Tab: 0 = Grammar Assistant, 1 = Email Writer
  int _selectedTab = 0;
  final _emailNotesController = TextEditingController();
  String _emailOutput = '';
  bool _emailLoading = false;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
    _loadModelName();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _inputController.removeListener(_onInputChanged);
    _inputController.dispose();
    _emailNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadModelName() async {
    try {
      final data = await BackendService.instance.getModels();
      final active = data['active'] as String? ?? '';
      if (mounted) setState(() => _activeModelName = active);
    } catch (_) {}
  }

  void _onInputChanged() {
    if (!_autoCheckEnabled) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_inputController.text.trim().isNotEmpty && mounted) {
        _runAction('grammar');
      }
    });
  }

  Future<void> _runAction(String actionId) async {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      _showSnackBar('Please enter some text first.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _currentAction = actionId;
      _statusMsg = 'Processing…';
      _showDiff = false;
      _alternatives = [];
      _selectedAlternative = 0;
    });

    try {
      final result = await BackendService.instance.processText(
        action: actionId,
        text: input,
      );

      setState(() {
        _outputText = result.result;
        _elapsedMs = result.elapsedMs;
        _statusMsg = 'Done in ${(result.elapsedMs / 1000).toStringAsFixed(1)}s';
        _alternatives = result.alternatives;
        if (result.tone != null) _detectedTone = result.tone;
      });

      // Background tone check after grammar/rewrite actions (if not already a tone check)
      if (actionId != 'tone' && actionId != 'explain' && input.split(' ').length > 8) {
        _runBackgroundToneCheck(input);
      }

      await HistoryService.insert(HistoryEntry(
        action: actionId,
        inputText: input,
        outputText: result.result,
        elapsedMs: result.elapsedMs,
        createdAt: DateTime.now(),
      ));
    } on BackendException catch (e) {
      _showSnackBar(e.message, isError: true);
      setState(() => _statusMsg = 'Error');
    } catch (e) {
      _showSnackBar('Unexpected error: $e', isError: true);
      setState(() => _statusMsg = 'Error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runEmailAction() async {
    final notes = _emailNotesController.text.trim();
    if (notes.isEmpty) {
      _showSnackBar('Enter your notes or topic first.', isError: true);
      return;
    }
    setState(() => _emailLoading = true);
    try {
      final result = await BackendService.instance.processText(
        action: 'email',
        text: notes,
      );
      setState(() => _emailOutput = result.result);
    } on BackendException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      _showSnackBar('Unexpected error: $e', isError: true);
    } finally {
      setState(() => _emailLoading = false);
    }
  }

  Future<void> _runBackgroundToneCheck(String text) async {
    try {
      final result = await BackendService.instance.processText(
        action: 'tone',
        text: text,
      );
      if (mounted && result.tone != null) {
        setState(() => _detectedTone = result.tone);
      }
    } catch (_) {}
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? AppColors.error : AppColors.success,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final border = widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: bg,
          appBar: _buildAppBar(textPrimary, textSec, border),
          body: _buildBody(border, textSec),
          bottomNavigationBar: _buildStatusBar(border, textSec),
        ),
        if (_isLoading)
          LoadingOverlay(
            actionLabel: kActionLabels[_currentAction] ?? _currentAction ?? '',
            isDark: widget.isDark,
          ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(Color textPrimary, Color textSec, Color border) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkBackground : AppColors.lightBackground,
          border: Border(bottom: BorderSide(color: border)),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.accentLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                'Grammar Assistant',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'LOCAL AI',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            // Auto-check toggle
            Tooltip(
              message: _autoCheckEnabled ? 'Auto-check: ON (tap to disable)' : 'Auto-check: OFF (tap to enable)',
              child: IconButton(
                icon: Icon(
                  _autoCheckEnabled ? Icons.flash_on : Icons.flash_off,
                  color: _autoCheckEnabled ? AppColors.accent : textSec,
                ),
                onPressed: () => setState(() => _autoCheckEnabled = !_autoCheckEnabled),
              ),
            ),
            // Settings
            Tooltip(
              message: 'Settings & History',
              child: IconButton(
                icon: Icon(Icons.settings_outlined, color: textSec),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            ),
            // Theme toggle
            Tooltip(
              message: widget.isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              child: IconButton(
                icon: Icon(
                  widget.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: textSec,
                ),
                onPressed: widget.onToggleTheme,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  Widget _buildTabBar(Color border, Color textPrimary, Color textSec) {
    final tabs = [
      (Icons.spellcheck_rounded, 'Grammar Assistant'),
      (Icons.mail_outline_rounded, 'Email Writer'),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 44,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tabs[i].$1, size: 16,
                        color: selected ? Colors.white : textSec),
                    const SizedBox(width: 6),
                    Text(tabs[i].$2,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : textSec,
                        )),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody(Color border, Color textSec) {
    final textPrimary = widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTabBar(border, textPrimary, textSec),

              if (_selectedTab == 1) ...[
                _buildEmailTab(border, textPrimary, textSec),
              ] else ...[

              // Input panel
              TextInputPanel(
                controller: _inputController,
                isDark: widget.isDark,
              ),

              // Stats bar — live word/char count and tone badge
              StatsBar(
                controller: _inputController,
                tone: _detectedTone,
                isDark: widget.isDark,
              ),

              const SizedBox(height: 12),

              // Action buttons
              ActionButtonRow(
                isLoading: _isLoading,
                isDark: widget.isDark,
                onAction: _runAction,
              ),
              const SizedBox(height: 20),

              // Divider with arrow
              Row(
                children: [
                  Expanded(child: Divider(color: border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: textSec.withOpacity(0.4),
                      size: 20,
                    ),
                  ),
                  Expanded(child: Divider(color: border)),
                ],
              ),
              const SizedBox(height: 16),

              // Output / Diff area
              if (_outputText.isNotEmpty) ...[
                _buildOutputHeader(textSec, border),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _showDiff
                      ? DiffViewPanel(
                          key: const ValueKey('diff'),
                          originalText: _inputController.text,
                          revisedText: _outputText,
                          isDark: widget.isDark,
                        )
                      : TextOutputPanel(
                          key: const ValueKey('output'),
                          text: _outputText,
                          actionLabel: _currentAction != null
                              ? kActionLabels[_currentAction]
                              : null,
                          elapsedMs: _elapsedMs,
                          isDark: widget.isDark,
                        ),
                ),

                // Multiple suggestions
                if (_alternatives.isNotEmpty && _alternatives.length > 1) ...[
                  const SizedBox(height: 16),
                  _buildAlternativesCard(border, textSec),
                ],
              ] else ...[
                TextOutputPanel(
                  text: '',
                  actionLabel: null,
                  elapsedMs: null,
                  isDark: widget.isDark,
                ),
              ],
              const SizedBox(height: 40),
              ], // end grammar else
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailTab(Color border, Color textPrimary, Color textSec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Notes input
        Container(
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_note_rounded, size: 16,
                      color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text('Your notes / topic',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: textSec)),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailNotesController,
                maxLines: 5,
                style: GoogleFonts.inter(fontSize: 13, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g.  job application, python developer, 3 years exp, interested in AI products\n'
                      'e.g.  apology for delay, supplier issue, offer 10% discount\n'
                      'e.g.  meeting tomorrow 3pm, discuss budget',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: textSec.withOpacity(0.5)),
                  border: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Write Email button
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _emailLoading ? null : _runEmailAction,
            icon: _emailLoading
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome, size: 16),
            label: Text(_emailLoading ? 'Writing email…' : 'Write Email',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Email output
        if (_emailOutput.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.mail_rounded, size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Text('Generated Email',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _emailOutput));
                  _showSnackBar('Email copied to clipboard!');
                },
                icon: const Icon(Icons.copy_outlined, size: 14),
                label: Text('Copy', style: GoogleFonts.inter(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _emailOutput = ''),
                icon: const Icon(Icons.clear, size: 14),
                label: Text('Clear', style: GoogleFonts.inter(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: textSec),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: SelectableText(
              _emailOutput,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: textPrimary,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ],
    );
  }

  Widget _buildOutputHeader(Color textSec, Color border) {
    return Row(
      children: [
        Text(
          _currentAction != null
              ? (kActionLabels[_currentAction] ?? _currentAction!)
              : 'Result',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textSec,
          ),
        ),
        const Spacer(),
        // Copy output button
        if (_outputText.isNotEmpty)
          Tooltip(
            message: 'Copy to clipboard',
            child: IconButton(
              iconSize: 18,
              icon: Icon(Icons.copy_outlined, color: textSec),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _outputText));
                _showSnackBar('Copied to clipboard');
              },
            ),
          ),
        // Diff toggle (only for grammar/rewrite actions)
        if (_outputText.isNotEmpty &&
            (_currentAction == 'grammar' ||
                _currentAction?.startsWith('rewrite') == true ||
                _currentAction == 'professional' ||
                _currentAction == 'shorten' ||
                _currentAction == 'expand'))
          Tooltip(
            message: _showDiff ? 'Show result' : 'Show changes',
            child: IconButton(
              iconSize: 18,
              icon: Icon(
                _showDiff ? Icons.text_fields : Icons.compare_arrows,
                color: _showDiff ? AppColors.accent : textSec,
              ),
              onPressed: () => setState(() => _showDiff = !_showDiff),
            ),
          ),
      ],
    );
  }

  Widget _buildAlternativesCard(Color border, Color textSec) {
    final isDark = widget.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 14, color: AppColors.warning),
                const SizedBox(width: 6),
                Text(
                  'Alternative suggestions',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSec,
                  ),
                ),
              ],
            ),
          ),
          // Tab row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(_alternatives.length, (i) {
                final selected = i == _selectedAlternative;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedAlternative = i;
                      _outputText = _alternatives[i];
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accent.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.accent : border,
                        ),
                      ),
                      child: Text(
                        'Option ${i + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? AppColors.accent : textSec,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _alternatives[_selectedAlternative],
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                IconButton(
                  iconSize: 16,
                  icon: Icon(Icons.copy_outlined, color: textSec),
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: _alternatives[_selectedAlternative]));
                    _showSnackBar('Copied to clipboard');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(Color border, Color textSec) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(top: BorderSide(color: border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _isLoading ? AppColors.warning : AppColors.success,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => _isLoading ? c.repeat() : c.reset())
              .then()
              .fadeOut(duration: 600.ms)
              .fadeIn(duration: 600.ms),
          const SizedBox(width: 8),
          Text(_statusMsg, style: GoogleFonts.inter(fontSize: 11, color: textSec)),
          if (_autoCheckEnabled) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'AUTO',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(
            _activeModelName.isNotEmpty
                ? _activeModelName.replaceAll('.gguf', '').replaceAll('-', ' ')
                : 'Local AI · CPU',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: textSec.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
