import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

/// The output text display panel with copy and action badge.
class TextOutputPanel extends StatefulWidget {
  final String text;
  final String? actionLabel;
  final int? elapsedMs;
  final bool isDark;

  const TextOutputPanel({
    super.key,
    required this.text,
    this.actionLabel,
    this.elapsedMs,
    required this.isDark,
  });

  @override
  State<TextOutputPanel> createState() => _TextOutputPanelState();
}

class _TextOutputPanelState extends State<TextOutputPanel> {
  bool _copied = false;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final label = widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final text = widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final hasContent = widget.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'OUTPUT',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: label,
                letterSpacing: 1.2,
              ),
            ),
            if (widget.actionLabel != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Text(
                  widget.actionLabel!,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (widget.elapsedMs != null)
              Text(
                '${(widget.elapsedMs! / 1000).toStringAsFixed(1)}s',
                style: GoogleFonts.inter(fontSize: 11, color: label),
              ),
            if (hasContent) ...[
              const SizedBox(width: 12),
              // Copy button
              AnimatedSwitcher(
                duration: 300.ms,
                child: _copied
                    ? _CopyBadge(isDark: widget.isDark, key: const ValueKey('copied'))
                    : _CopyButton(onTap: _copyToClipboard, key: const ValueKey('copy')),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Output area
        AnimatedContainer(
          duration: 300.ms,
          constraints: const BoxConstraints(minHeight: 140),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasContent ? AppColors.success.withOpacity(0.3) : border,
            ),
          ),
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: hasContent
              ? SelectableText(
                  widget.text,
                  style: GoogleFonts.inter(fontSize: 15, color: text, height: 1.6),
                ).animate().fadeIn(duration: 300.ms)
              : Text(
                  'Your result will appear here…',
                  style: GoogleFonts.inter(fontSize: 15, color: label.withOpacity(0.5)),
                ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.04, end: 0);
  }
}

class _CopyButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CopyButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.copy_rounded, size: 14),
      label: const Text('Copy'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.accent, width: 1),
        ),
      ),
    );
  }
}

class _CopyBadge extends StatelessWidget {
  final bool isDark;
  const _CopyBadge({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 14, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            'Copied!',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    ).animate().scale(begin: const Offset(0.8, 0.8), duration: 200.ms, curve: Curves.easeOut);
  }
}
