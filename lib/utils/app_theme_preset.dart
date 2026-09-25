import 'package:flutter/material.dart';
import 'package:personal_finance/utils/theme.dart';

class AppThemePreset {
  final String id;
  final String name;
  final Color primary;
  final bool isDark;
  final bool isPremium;
  final Color? background;
  final Color? surface;

  const AppThemePreset({
    required this.id,
    required this.name,
    required this.primary,
    required this.isDark,
    required this.isPremium,
    this.background,
    this.surface,
  });

  ThemeData get themeData => isDark
      ? AppTheme.dark(primaryColor: primary, background: background, surface: surface)
      : AppTheme.light(primaryColor: primary, background: background, surface: surface);

  Color get previewBackground =>
      background ?? (isDark ? const Color(0xFF07090F) : const Color(0xFFF6F7FB));

  Color get previewSurface =>
      surface ?? (isDark ? const Color(0xFF131620) : Colors.white);

  // ── Theme catalog ──────────────────────────────────────────────────────────

  static const List<AppThemePreset> all = [
    // ── Free themes (4) ────────────────────────────────────────────────────
    AppThemePreset(
      id: 'violeta',
      name: 'Violeta',
      primary: Color(0xFF6C63FF),
      isDark: false,
      isPremium: false,
    ),
    AppThemePreset(
      id: 'esmeralda',
      name: 'Esmeralda',
      primary: Color(0xFF0E8F5B),
      isDark: false,
      isPremium: false,
    ),
    AppThemePreset(
      id: 'cielo',
      name: 'Cielo',
      primary: Color(0xFF0284C7),
      isDark: false,
      isPremium: false,
    ),
    AppThemePreset(
      id: 'noche',
      name: 'Noche',
      primary: Color(0xFF8B80F9),
      isDark: true,
      isPremium: false,
    ),

    // Electric green on near-black — clean, productivity
    AppThemePreset(
      id: 'carbon',
      name: 'Carbón',
      primary: Color(0xFF00C853),
      isDark: true,
      isPremium: false,
      background: Color(0xFF1A1A1A),
      surface: Color(0xFF242424),
    ),

    // Indigo-blue on deep dark — cool, focused
    AppThemePreset(
      id: 'indigo_dark',
      name: 'Índigo',
      primary: Color(0xFF536DFE),
      isDark: true,
      isPremium: false,
      background: Color(0xFF1C1B2E),
      surface: Color(0xFF252438),
    ),

    // ── Premium themes (6) ─────────────────────────────────────────────────

    // Deep navy with indigo accent — AMOLED-friendly
    AppThemePreset(
      id: 'medianoche',
      name: 'Medianoche',
      primary: Color(0xFF6366F1),
      isDark: true,
      isPremium: true,
      background: Color(0xFF030712),
      surface: Color(0xFF0F172A),
    ),

    // Warm amber light — sunrise feel
    AppThemePreset(
      id: 'atardecer',
      name: 'Atardecer',
      primary: Color(0xFFF59E0B),
      isDark: false,
      isPremium: true,
      background: Color(0xFFFFFBF0),
      surface: Color(0xFFFFFDF7),
    ),

    // Deep purple dark — galaxy/space feel
    AppThemePreset(
      id: 'galaxia',
      name: 'Galaxia',
      primary: Color(0xFFA855F7),
      isDark: true,
      isPremium: true,
      background: Color(0xFF0D0618),
      surface: Color(0xFF1A0F2E),
    ),

    // Rose light — elegant pink tones
    AppThemePreset(
      id: 'rosa',
      name: 'Rosa',
      primary: Color(0xFFE11D48),
      isDark: false,
      isPremium: true,
      background: Color(0xFFFFF5F7),
      surface: Color(0xFFFFFFFF),
    ),

    // Cyan-on-deep-dark — high-tech fintech look
    AppThemePreset(
      id: 'cosmos',
      name: 'Cosmos',
      primary: Color(0xFF0891B2),
      isDark: true,
      isPremium: true,
      background: Color(0xFF020B12),
      surface: Color(0xFF0B1E2A),
    ),

    // Ruby red on very dark — bold, premium
    AppThemePreset(
      id: 'ruby',
      name: 'Rubí',
      primary: Color(0xFFEF5350),
      isDark: true,
      isPremium: true,
      background: Color(0xFF1A0A0A),
      surface: Color(0xFF2A1010),
    ),

    // Amber/gold on dark warm — luxurious
    AppThemePreset(
      id: 'amber_dark',
      name: 'Ámbar',
      primary: Color(0xFFFFB300),
      isDark: true,
      isPremium: true,
      background: Color(0xFF1C1400),
      surface: Color(0xFF2A1E00),
    ),

    // Forest green on deep dark — earthy, calm
    AppThemePreset(
      id: 'bosque',
      name: 'Bosque',
      primary: Color(0xFF43A047),
      isDark: true,
      isPremium: true,
      background: Color(0xFF0A1A0A),
      surface: Color(0xFF122012),
    ),

    // Warm earth tones — sandy natural palette
    AppThemePreset(
      id: 'arena',
      name: 'Arena',
      primary: Color(0xFFD97706),
      isDark: false,
      isPremium: true,
      background: Color(0xFFFAF6EF),
      surface: Color(0xFFF5EFE4),
    ),
  ];

  static AppThemePreset getById(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);
}
