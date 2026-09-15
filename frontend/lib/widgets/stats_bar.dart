import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Compact horizontal bar showing live writing statistics and optional tone badge.
class StatsBar extends StatefulWidget {
  final TextEditingController controller;
  final String? tone;
  final bool isDark;

  const StatsBar({
    super.key,
    required this.controller,
    required this.isDark,
    this.tone,
  });

  @override
  State<StatsBar> createState() => _StatsBarState();
}

class _StatsBarState extends State<StatsBar> {
  int _words = 0;
  int _chars = 0;

  @override
  void initState() {
    super.initState();
    _update();
    widget.controller.addListener(_update);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  void _update() {
    final text = widget.controller.text;
    final words = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    setState(() {
      _words = words;
      _chars = text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final secColor = widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final readSec = _words == 0 ? 0 : (_words * 60 / 200).ceil();
    final readLabel = readSec < 60
        ? '${readSec}s read'
        : '${(readSec / 60).ceil()}m read';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        children: [
          _stat('$_words', 'words', secColor),
          _dot(secColor),
          _stat('$_chars', 'chars', secColor),
          _dot(secColor),
          _stat(readLabel, '', secColor),
          if (widget.tone != null) ...[
            _dot(secColor),
            _toneBadge(widget.tone!, widget.isDark),
          ],
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ],
    );
  }

  Widget _dot(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text('·', style: TextStyle(fontSize: 14, color: color)),
    );
  }

  Widget _toneBadge(String tone, bool isDark) {
    final (bg, fg) = _toneColors(tone, isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tone,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  (Color, Color) _toneColors(String tone, bool isDark) {
    switch (tone) {
      case 'positive':
        return (AppColors.success.withOpacity(0.18), AppColors.success);
      case 'negative':
        return (AppColors.error.withOpacity(0.18), AppColors.error);
      case 'formal':
      case 'professional':
        return (AppColors.accent.withOpacity(0.18), AppColors.accentLight);
      case 'casual':
      case 'informal':
        return (AppColors.warning.withOpacity(0.18), AppColors.warning);
      default:
        return (
          isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.lightSurfaceVariant,
          isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        );
    }
  }
}
