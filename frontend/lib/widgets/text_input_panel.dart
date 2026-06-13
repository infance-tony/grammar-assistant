import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

/// The input text editor panel with char counter and clear button.
class TextInputPanel extends StatefulWidget {
  final TextEditingController controller;
  final bool isDark;

  const TextInputPanel({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  State<TextInputPanel> createState() => _TextInputPanelState();
}

class _TextInputPanelState extends State<TextInputPanel> {
  static const int _maxChars = 4000;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppColors.darkInputFill : AppColors.lightInputFill;
    final border = widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final hint = widget.isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final label = widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final text = widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

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
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'INPUT',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: label,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (_, value, __) {
                final count = value.text.length;
                final isNear = count > _maxChars * 0.8;
                return Text(
                  '$count / $_maxChars',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isNear ? AppColors.warning : label,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            // Paste button
            _IconBtn(
              icon: Icons.content_paste_rounded,
              tooltip: 'Paste from clipboard',
              color: label,
              onTap: () async {
                final data = await Clipboard.getData('text/plain');
                if (data?.text != null) {
                  widget.controller.text = data!.text!;
                }
              },
            ),
            const SizedBox(width: 4),
            // Clear button
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (_, value, __) => AnimatedOpacity(
                opacity: value.text.isEmpty ? 0 : 1,
                duration: 200.ms,
                child: _IconBtn(
                  icon: Icons.clear_rounded,
                  tooltip: 'Clear',
                  color: label,
                  onTap: () => widget.controller.clear(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Text field
        Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: TextField(
            controller: widget.controller,
            maxLines: null,
            minLines: 8,
            maxLength: _maxChars,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            style: GoogleFonts.inter(fontSize: 15, color: text, height: 1.6),
            decoration: InputDecoration(
              hintText: 'Paste or type your text here…',
              hintStyle: GoogleFonts.inter(fontSize: 15, color: hint),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              counterText: '',
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0);
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
