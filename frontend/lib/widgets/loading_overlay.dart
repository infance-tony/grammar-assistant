import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

/// Full-screen translucent overlay shown during AI inference.
class LoadingOverlay extends StatelessWidget {
  final String actionLabel;
  final bool isDark;

  const LoadingOverlay({
    super.key,
    required this.actionLabel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? AppColors.darkBackground.withOpacity(0.85)
        : AppColors.lightBackground.withOpacity(0.85);
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return AnimatedOpacity(
      opacity: 1,
      duration: 200.ms,
      child: Container(
        color: bg,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated spinner ring
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                    backgroundColor: AppColors.accent.withOpacity(0.15),
                  ),
                ).animate(onPlay: (c) => c.repeat()).rotate(duration: 1200.ms),
                const SizedBox(height: 24),
                Text(
                  'Processing…',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  actionLabel,
                  style: GoogleFonts.inter(fontSize: 13, color: textSec),
                ),
                const SizedBox(height: 4),
                Text(
                  'Running local AI model…',
                  style: GoogleFonts.inter(fontSize: 12, color: textSec.withOpacity(0.6)),
                ),
              ],
            ),
          ).animate().scale(begin: const Offset(0.9, 0.9), duration: 300.ms, curve: Curves.easeOut),
        ),
      ),
    );
  }
}
