import 'package:flutter/material.dart';
import 'package:personal_finance/features/settings/presentation/pages/themes_page.dart';
import 'package:personal_finance/features/settings/presentation/providers/settings_provider.dart';
import 'package:personal_finance/utils/app_theme_preset.dart';
import 'package:provider/provider.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Apariencia'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _sectionHeader(context, 'TEMA Y COLORES'),
          _buildThemeEntry(context, cs, settings),
          const SizedBox(height: 24),
          _sectionHeader(context, 'INTERFAZ'),
          _buildTextSizeSelector(cs, settings),
          _buildAnimationsToggle(cs, settings),
          const SizedBox(height: 24),
          _sectionHeader(context, 'DATOS Y REPORTES'),
          _buildChartStyleSelector(cs, settings),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Section header ──────────────────────────────────────────────────────────

  Widget _sectionHeader(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );

  // ── Theme entry ─────────────────────────────────────────────────────────────

  Widget _buildThemeEntry(
    BuildContext context,
    ColorScheme cs,
    SettingsProvider settings,
  ) {
    final preset = AppThemePreset.getById(settings.selectedThemeId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (_) => const ThemesPage()),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Color swatch
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: preset.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: preset.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          preset.isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          size: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          preset.isDark ? 'Oscuro' : 'Claro',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (preset.isPremium) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  // ── Text size ───────────────────────────────────────────────────────────────

  Widget _buildTextSizeSelector(
    ColorScheme cs,
    SettingsProvider settings,
  ) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.text_fields_rounded, color: cs.onSurfaceVariant),
    ),
    title: const Text(
      'Tamaño de texto',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      'Ajusta la lectura de la app',
      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
    ),
    trailing: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: settings.textSize,
        borderRadius: BorderRadius.circular(16),
        items: ['Pequeño', 'Mediano', 'Grande']
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(fontSize: 14)),
              ),
            )
            .toList(),
        onChanged: (val) {
          if (val != null) settings.setTextSize(val);
        },
      ),
    ),
  );

  // ── Animations toggle ───────────────────────────────────────────────────────

  Widget _buildAnimationsToggle(
    ColorScheme cs,
    SettingsProvider settings,
  ) => SwitchListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    value: settings.animationsEnabled,
    onChanged: (val) => settings.setAnimationsEnabled(enabled: val),
    activeThumbColor: cs.primary,
    secondary: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.animation_rounded, color: cs.onSurfaceVariant),
    ),
    title: const Text(
      'Animaciones',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      'Transiciones fluidas',
      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
    ),
  );

  // ── Chart style ─────────────────────────────────────────────────────────────

  Widget _buildChartStyleSelector(
    ColorScheme cs,
    SettingsProvider settings,
  ) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.pie_chart_outline_rounded, color: cs.onSurfaceVariant),
    ),
    title: const Text(
      'Estilo de gráfico',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      'Presentación en reportes',
      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
    ),
    trailing: Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chartIconOption(Icons.donut_large_rounded, 'Anillo', cs, settings),
          _chartIconOption(Icons.bar_chart_rounded, 'Barras', cs, settings),
        ],
      ),
    ),
  );

  Widget _chartIconOption(
    IconData icon,
    String value,
    ColorScheme cs,
    SettingsProvider settings,
  ) {
    final isSelected = settings.chartStyle == value;
    return GestureDetector(
      onTap: () => settings.setChartStyle(value),
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? cs.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected
              ? cs.primary
              : cs.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
