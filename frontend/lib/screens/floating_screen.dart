import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import '../services/backend_service.dart';
import '../services/clipboard_service.dart';
import '../services/floating_controller.dart';
import '../theme/app_colors.dart';

/// Compact always-on-top floating window for system-wide grammar correction.
/// Triggered by Ctrl+Shift+G from any application.
class FloatingScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onExpand;

  const FloatingScreen({
    super.key,
    required this.isDark,
    required this.onExpand,
  });

  @override
  State<FloatingScreen> createState() => _FloatingScreenState();
}

class _FloatingScreenState extends State<FloatingScreen> {
  String _corrected = '';
  bool _loading = false;
  bool _done = false;
  String _status = 'Press Ctrl+Shift+G to check selected text';

  StreamSubscription<void>? _grabSub;

  @override
  void initState() {
    super.initState();
    _grabSub = FloatingController.onGrabTrigger.listen((_) => grabAndCorrect());
  }

  @override
  void dispose() {
    _grabSub?.cancel();
    super.dispose();
  }

  /// Called externally when the hotkey fires — grabs text and corrects it.
  Future<void> grabAndCorrect() async {
    setState(() {
      _loading = true;
      _done = false;
      _status = 'Grabbing text…';
      _corrected = '';
    });

    // Brief delay so the hotkey release doesn't interfere with Ctrl+C
    await Future.delayed(const Duration(milliseconds: 150));

    final grabbed = await ClipboardService.grabSelectedText();
    if (grabbed.isEmpty) {
      setState(() {
        _loading = false;
        _status = 'No text selected — select text first, then press Ctrl+Shift+G';
      });
      return;
    }

    setState(() => _status = 'Correcting…');

    try {
      final result = await BackendService.instance.processText(
        action: 'grammar',
        text: grabbed,
      );
      setState(() {
        _corrected = result.result;
        _loading = false;
        _done = true;
        _status = 'Done in ${(result.elapsedMs / 1000).toStringAsFixed(1)}s';
      });
    } on BackendException catch (e) {
      setState(() {
        _loading = false;
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _replace() async {
    if (_corrected.isEmpty) return;
    // Hide our window so the original app can receive the paste
    await windowManager.hide();
    await Future.delayed(const Duration(milliseconds: 200));
    await ClipboardService.pasteText(_corrected);
    await Future.delayed(const Duration(milliseconds: 300));
    await windowManager.show();
    setState(() {
      _done = false;
      _corrected = '';
      _status = 'Replaced! Press Ctrl+Shift+G to check again';
    });
  }

  Future<void> _copyOnly() async {
    await Clipboard.setData(ClipboardData(text: _corrected));
    setState(() => _status = 'Copied — paste it yourself (Ctrl+V)');
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
      body: GestureDetector(
        // Allow dragging the floating window by its background
        onPanStart: (_) => windowManager.startDragging(),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // ── Title bar ────────────────────────────────────────────────
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  border: Border(bottom: BorderSide(color: border)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.accentLight],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.auto_awesome, size: 11, color: Colors.white),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Grammar Assistant',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'FLOAT',
                        style: GoogleFonts.inter(
                            fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.accent),
                      ),
                    ),
                    const Spacer(),
                    // Expand to full app
                    Tooltip(
                      message: 'Open full app',
                      child: InkWell(
                        onTap: widget.onExpand,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.open_in_full, size: 13, color: textSec),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Hide to tray
                    Tooltip(
                      message: 'Hide (still active via Ctrl+Shift+G)',
                      child: InkWell(
                        onTap: () => windowManager.hide(),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.minimize, size: 13, color: textSec),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content ──────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: _loading
                      ? _buildLoading(textSec)
                      : _done
                          ? _buildResult(textPrimary, textSec, border)
                          : _buildIdle(textSec),
                ),
              ),

              // ── Status bar ────────────────────────────────────────────────
              Container(
                height: 22,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                  border: Border(top: BorderSide(color: border)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text(
                      _status,
                      style: GoogleFonts.inter(fontSize: 10, color: textSec),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      'Ctrl+Shift+G',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: AppColors.accent.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdle(Color textSec) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.select_all, size: 22, color: textSec.withOpacity(0.4)),
        const SizedBox(height: 6),
        Text(
          'Select any text in any app\nthen press  Ctrl+Shift+G',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 11, color: textSec, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildLoading(Color textSec) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
        ),
        const SizedBox(height: 8),
        Text(_status, style: GoogleFonts.inter(fontSize: 11, color: textSec)),
      ],
    );
  }

  Widget _buildResult(Color textPrimary, Color textSec, Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Corrected text
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.07),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: AppColors.success.withOpacity(0.25)),
            ),
            child: SelectableText(
              _corrected,
              style: GoogleFonts.inter(fontSize: 12, color: textPrimary, height: 1.45),
            ),
          ),
        ),
        const SizedBox(height: 7),
        // Action buttons
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _btn(
                icon: Icons.swap_horiz_rounded,
                label: 'Replace',
                color: AppColors.accent,
                onTap: _replace,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: _btn(
                icon: Icons.copy_outlined,
                label: 'Copy',
                color: AppColors.darkTextSecondary,
                onTap: _copyOnly,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: _btn(
                icon: Icons.refresh,
                label: 'Clear',
                color: AppColors.darkTextSecondary,
                onTap: () => setState(() {
                  _done = false;
                  _corrected = '';
                  _status = 'Press Ctrl+Shift+G to check selected text';
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _btn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
