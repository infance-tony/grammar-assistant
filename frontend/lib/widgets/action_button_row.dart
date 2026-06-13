import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

/// Definition for a single AI action button.
class ActionDef {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const ActionDef({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const List<ActionDef> kActions = [
  ActionDef(id: 'grammar',      label: 'Fix Grammar',   icon: Icons.spellcheck_rounded,         color: AppColors.btnGrammar),
  ActionDef(id: 'rewrite',      label: 'Rewrite',        icon: Icons.auto_fix_high_rounded,      color: AppColors.btnRewrite),
  ActionDef(id: 'professional', label: 'Professional',   icon: Icons.business_center_rounded,    color: AppColors.btnProfessional),
  ActionDef(id: 'expand',       label: 'Expand',         icon: Icons.unfold_more_rounded,        color: AppColors.btnExpand),
  ActionDef(id: 'shorten',      label: 'Shorten',        icon: Icons.compress_rounded,           color: AppColors.btnShorten),
];

/// Row of action buttons. Calls [onAction] with the action id.
/// 'rewrite' opens a sub-picker bottom sheet for mode selection.
class ActionButtonRow extends StatelessWidget {
  final bool isLoading;
  final bool isDark;
  final void Function(String actionId) onAction;

  const ActionButtonRow({
    super.key,
    required this.isLoading,
    required this.isDark,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kActions
          .asMap()
          .entries
          .map(
            (e) => _ActionChip(
              def: e.value,
              isLoading: isLoading,
              isDark: isDark,
              onTap: () => _handleTap(context, e.value.id),
            ).animate(delay: (e.key * 60).ms).fadeIn(duration: 300.ms).slideX(begin: -0.05, end: 0),
          )
          .toList(),
    );
  }

  void _handleTap(BuildContext context, String id) {
    if (id == 'rewrite') {
      _showRewritePicker(context);
    } else {
      onAction(id);
    }
  }

  void _showRewritePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => RewriteModePicker(
        isDark: isDark,
        onSelect: (mode) {
          Navigator.pop(context);
          onAction(mode);
        },
      ),
    );
  }
}

class _ActionChip extends StatefulWidget {
  final ActionDef def;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionChip({
    required this.def,
    required this.isLoading,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.def.color;
    final bg = widget.isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: 200.ms,
        decoration: BoxDecoration(
          color: _hovered ? color.withOpacity(0.12) : bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hovered ? color.withOpacity(0.6) : border,
            width: _hovered ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: widget.isLoading ? null : widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.def.icon,
                    size: 16,
                    color: _hovered ? color : (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    widget.def.label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _hovered ? color : (widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                  ),
                  if (widget.def.id == 'rewrite') ...[
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: _hovered ? color : AppColors.darkTextHint),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for choosing rewrite mode.
class RewriteModePicker extends StatelessWidget {
  final bool isDark;
  final void Function(String mode) onSelect;

  const RewriteModePicker({
    super.key,
    required this.isDark,
    required this.onSelect,
  });

  static const _modes = [
    ('rewrite_casual',   'Casual',   Icons.emoji_emotions_outlined, 'Friendly, conversational'),
    ('rewrite_clear',    'Clear',    Icons.visibility_outlined,     'Simple, easy to read'),
    ('rewrite_concise',  'Concise',  Icons.compress_rounded,        'Shorter, to the point'),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: bg,
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Choose Rewrite Style', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
              const SizedBox(height: 16),
              ..._modes.map((m) => _ModeItem(
                id: m.$1, label: m.$2, icon: m.$3, description: m.$4,
                isDark: isDark, onTap: () => onSelect(m.$1),
              )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}

class _ModeItem extends StatefulWidget {
  final String id, label, description;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _ModeItem({required this.id, required this.label, required this.icon, required this.description, required this.isDark, required this.onTap});

  @override
  State<_ModeItem> createState() => _ModeItemState();
}

class _ModeItemState extends State<_ModeItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppColors.darkInputFill : AppColors.lightBackground;
    final textPrimary = widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Material(
          color: _hovered ? AppColors.accent.withOpacity(0.1) : bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: 150.ms,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hovered ? AppColors.accent.withOpacity(0.4) : Colors.transparent,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(widget.icon, color: AppColors.accent),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textPrimary)),
                      Text(widget.description, style: GoogleFonts.inter(fontSize: 12, color: textSec)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

  }
}
