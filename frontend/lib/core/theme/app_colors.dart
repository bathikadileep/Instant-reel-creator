import 'package:flutter/material.dart';

class AppColors {
  // ===========================================================================
  // Brand Colors (Aligned with uploaded Camera Studio reference)
  // ===========================================================================

  // Primary Accent: Electric Royal Blue (matches "Create Logos" button in reference)
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8);

  // Secondary Accent: Camera Gold / Amber (matches camera badge cards in reference)
  static const Color secondary = Color(0xFFF59E0B); // Amber / Camera Gold
  static const Color secondaryLight = Color(0xFFFBBF24);
  static const Color accent = Color(0xFFD4AF37); // Classic Metallic Gold

  // Background: Deep Obsidian Charcoal (matches dark wavy texture in reference)
  static const Color backgroundDark = Color(0xFF0A0B0E); // Deep Obsidian
  static const Color surfaceDark = Color(0xFF141620); // Dark Surface
  static const Color cardDark = Color(0xFF1C1E2B); // Elevated Card Surface
  static const Color borderDark = Color(0xFF2A2D3D); // Subtle Card Border

  // Light Theme Surfaces (Fallback)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Typography Colors
  static const Color textPrimaryDark = Color(0xFFFFFFFF); // Pure White
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Muted Slate
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Status & Feedback Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Crimson
  static const Color info = Color(0xFF3B82F6); // Blue
}
