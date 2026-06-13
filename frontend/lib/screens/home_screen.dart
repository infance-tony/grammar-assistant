import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/backend_service.dart';
import '../services/history_service.dart';
import '../models/action_result.dart';
import '../models/history_entry.dart';
import '../widgets/text_input_panel.dart';
import '../widgets/text_output_panel.dart';
import '../widgets/action_button_row.dart';
import '../widgets/loading_overlay.dart';
import '../theme/app_colors.dart';

/// Maps action IDs to display labels shown in the UI.
const Map<String, String> kActionLabels = {
  'grammar':          'Fix Grammar',
  'rewrite_casual':   'Rewrite — Casual',
  'rewrite_clear':    'Rewrite — Clear',
  'rewrite_concise':  'Rewrite — Concise',
  'professional':     'Professional Tone',
  'expand':           'Expand',
  'shorten':          'Shorten',
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
  bool _modelReady = true;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
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
      });

      // Save to history
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
    final surface = widget.isDark ? AppColors.darkSurface : AppColors.lightSurface;
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
              // Logo
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
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: 0.8),
                ),
              ),
            ],
          ),
          actions: [
            // Settings button
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

  Widget _buildBody(Color border, Color textSec) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Input panel
              TextInputPanel(
                controller: _inputController,
                isDark: widget.isDark,
              ),
              const SizedBox(height: 20),

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
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: textSec.withOpacity(0.4), size: 20),
                  ),
                  Expanded(child: Divider(color: border)),
                ],
              ),
              const SizedBox(height: 20),

              // Output panel
              TextOutputPanel(
                text: _outputText,
                actionLabel: _currentAction != null ? kActionLabels[_currentAction] : null,
                elapsedMs: _elapsedMs,
                isDark: widget.isDark,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
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
          ).animate(onPlay: (c) => _isLoading ? c.repeat() : c.reset())
           .then()
           .fadeOut(duration: 600.ms)
           .fadeIn(duration: 600.ms),
          const SizedBox(width: 8),
          Text(
            _statusMsg,
            style: GoogleFonts.inter(fontSize: 11, color: textSec),
          ),
          const Spacer(),
          Text(
            'Qwen2.5-0.5B · CPU',
            style: GoogleFonts.inter(fontSize: 11, color: textSec.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}
