import 'package:flutter/material.dart';
import 'package:personal_finance/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  String _selectedTheme = 'Sistema'; // Claro, Oscuro, Sistema
  String _textSize = 'Mediano';
  bool _animationsEnabled = true;
  String _chartStyle = 'Anillo';

  final List<Color> _primaryColors = [
    Colors.blue,
    Colors.purple,
    Colors.teal,
    Colors.orange,
    Colors.pink,
  ];
  Color _selectedColor = Colors.blue; // Simulación

  @override
  void initState() {
    super.initState();
    // In here we would map _selectedTheme based on settingsProvider.darkMode
    _selectedColor = _primaryColors[0];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();

    if (settingsProvider.darkMode) {
      _selectedTheme = 'Oscuro';
    } else {
      _selectedTheme = 'Claro';
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('Apariencia'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSectionHeader(context, 'TEMA Y COLORES'),
          _buildThemeSelector(colorScheme, settingsProvider),
          const SizedBox(height: 24),
          _buildColorPicker(colorScheme),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'INTERFAZ'),
          _buildTextSizeSelector(colorScheme),
          _buildAnimationsToggle(colorScheme),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'DATOS Y REPORTES'),
          _buildChartStyleSelector(colorScheme),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) => Padding(
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

  Widget _buildThemeSelector(
    ColorScheme colorScheme,
    SettingsProvider settings,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          _buildThemeOption(
            'Claro',
            Icons.light_mode_rounded,
            _selectedTheme == 'Claro',
            () async {
              if (settings.darkMode) {
                await settings.toggleDarkMode();
              }
            },
            colorScheme,
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          _buildThemeOption(
            'Oscuro',
            Icons.dark_mode_rounded,
            _selectedTheme == 'Oscuro',
            () async {
              if (!settings.darkMode) {
                await settings.toggleDarkMode();
              }
            },
            colorScheme,
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          _buildThemeOption(
            'Sistema',
            Icons.brightness_auto_rounded,
            _selectedTheme == 'Sistema',
            () {
              // Simulación de tema sistema, ya que actualmente solo es un boolean toggle en el provider temporal
            },
            colorScheme,
          ),
        ],
      ),
    ),
  );

  Widget _buildThemeOption(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    ColorScheme colorScheme,
  ) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color:
                  isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color:
                    isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildColorPicker(ColorScheme colorScheme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Color Principal',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 50,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: _primaryColors.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final color = _primaryColors[index];
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected ? colorScheme.onSurface : Colors.transparent,
                    width: isSelected ? 3 : 0,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child:
                    isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
              ),
            );
          },
        ),
      ),
    ],
  );

  Widget _buildTextSizeSelector(ColorScheme colorScheme) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.text_fields_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      title: const Text(
        'Tamaño de texto',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'Ajusta la lectura de la app',
        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
      ),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _textSize,
          borderRadius: BorderRadius.circular(16),
          items:
              ['Pequeño', 'Mediano', 'Grande']
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, style: const TextStyle(fontSize: 14)),
                    ),
                  )
                  .toList(),
          onChanged: (val) => setState(() => _textSize = val!),
        ),
      ),
    );

  Widget _buildAnimationsToggle(ColorScheme colorScheme) => SwitchListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    value: _animationsEnabled,
    onChanged: (val) => setState(() => _animationsEnabled = val),
    activeThumbColor: colorScheme.primary,
    secondary: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.animation_rounded, color: colorScheme.onSurfaceVariant),
    ),
    title: const Text(
      'Animaciones',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      'Transiciones fluidas',
      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
    ),
  );

  Widget _buildChartStyleSelector(ColorScheme colorScheme) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.pie_chart_outline_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    title: const Text(
      'Estilo de gráfico',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      'Presentación en reportes',
      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
    ),
    trailing: Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChartIconOption(
            Icons.donut_large_rounded,
            'Anillo',
            colorScheme,
          ),
          _buildChartIconOption(Icons.bar_chart_rounded, 'Barras', colorScheme),
        ],
      ),
    ),
  );

  Widget _buildChartIconOption(
    IconData icon,
    String value,
    ColorScheme colorScheme,
  ) {
    final isSelected = _chartStyle == value;
    return GestureDetector(
      onTap: () => setState(() => _chartStyle = value),
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow:
              isSelected
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
          color:
              isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
