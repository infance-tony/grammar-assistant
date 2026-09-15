import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum _DiffType { equal, delete, insert }

class _DiffSpan {
  final _DiffType type;
  final String text;
  const _DiffSpan(this.type, this.text);
}

/// Word-level diff widget — shows deletions in red strikethrough, insertions in green.
class DiffViewPanel extends StatelessWidget {
  final String originalText;
  final String revisedText;
  final bool isDark;

  const DiffViewPanel({
    super.key,
    required this.originalText,
    required this.revisedText,
    required this.isDark,
  });

  // ── LCS-based word diff ────────────────────────────────────────────────────

  static List<_DiffSpan> _diff(String original, String revised) {
    final a = _tokenize(original);
    final b = _tokenize(revised);

    final m = a.length;
    final n = b.length;

    // Build LCS table
    final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
        }
      }
    }

    // Backtrack to build diff spans
    final spans = <_DiffSpan>[];
    int i = m, j = n;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && a[i - 1] == b[j - 1]) {
        spans.add(_DiffSpan(_DiffType.equal, a[i - 1]));
        i--;
        j--;
      } else if (j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j])) {
        spans.add(_DiffSpan(_DiffType.insert, b[j - 1]));
        j--;
      } else {
        spans.add(_DiffSpan(_DiffType.delete, a[i - 1]));
        i--;
      }
    }
    return spans.reversed.toList();
  }

  static List<String> _tokenize(String text) {
    // Split on whitespace, keeping the trailing space with each token for display
    final tokens = <String>[];
    final parts = text.split(RegExp(r'(?<=\s)|(?=\s)'));
    for (final p in parts) {
      if (p.isNotEmpty) tokens.add(p);
    }
    return tokens;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final spans = _diff(originalText, revisedText);
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final textSpans = spans.map((s) {
      switch (s.type) {
        case _DiffType.equal:
          return TextSpan(
            text: s.text,
            style: TextStyle(color: textColor, fontSize: 15),
          );
        case _DiffType.delete:
          return TextSpan(
            text: s.text,
            style: TextStyle(
              color: AppColors.error,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.error,
              fontSize: 15,
            ),
          );
        case _DiffType.insert:
          return TextSpan(
            text: s.text,
            style: TextStyle(
              color: AppColors.success,
              backgroundColor: AppColors.success.withOpacity(0.15),
              fontSize: 15,
            ),
          );
      }
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputFill : AppColors.lightInputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows,
                  size: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              const SizedBox(width: 6),
              Text(
                'Changes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(width: 12),
              _legend(AppColors.error, 'Removed', isDark),
              const SizedBox(width: 10),
              _legend(AppColors.success, 'Added', isDark),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText.rich(TextSpan(children: textSpans)),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
