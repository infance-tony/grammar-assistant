import 'package:flutter/material.dart';

/// Brand color palette for Grammar Assistant.
abstract class AppColors {
  // ── Violet Accent ─────────────────────────────────────────────────────────
  static const Color accent = Color(0xFF7C5CF6);
  static const Color accentLight = Color(0xFF9C82F8);
  static const Color accentDark = Color(0xFF5B3ED4);

  // ── Dark Theme Surfaces ───────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F0F13);
  static const Color darkSurface = Color(0xFF1A1A23);
  static const Color darkSurfaceVariant = Color(0xFF242433);
  static const Color darkBorder = Color(0xFF2E2E40);
  static const Color darkInputFill = Color(0xFF16161F);

  // ── Light Theme Surfaces ──────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF7F7FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0EFFF);
  static const Color lightBorder = Color(0xFFE2E0FF);
  static const Color lightInputFill = Color(0xFFFAFAFF);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color darkTextPrimary = Color(0xFFF0EFFF);
  static const Color darkTextSecondary = Color(0xFF8B8BA7);
  static const Color darkTextHint = Color(0xFF55556A);

  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B6B8A);
  static const Color lightTextHint = Color(0xFFAAAAAC);

  // ── Status ────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);

  // ── Action Button Colors ──────────────────────────────────────────────────
  static const Color btnGrammar = Color(0xFF7C5CF6);
  static const Color btnRewrite = Color(0xFF3B82F6);
  static const Color btnProfessional = Color(0xFF10B981);
  static const Color btnExpand = Color(0xFFF59E0B);
  static const Color btnShorten = Color(0xFFEF4444);
}
