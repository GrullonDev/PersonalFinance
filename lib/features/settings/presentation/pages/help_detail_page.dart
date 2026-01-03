import 'package:flutter/material.dart';

class HelpDetailPage extends StatefulWidget {
  const HelpDetailPage({super.key});

  @override
  State<HelpDetailPage> createState() => _HelpDetailPageState();
}

class _HelpDetailPageState extends State<HelpDetailPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todos';

  final List<String> _categories = [
    'Todos',
    'General',
    'Cuenta',
    'Seguridad',
    'Pagos',
  ];

  final List<Map<String, String>> _faqs = [
    {
      'category': 'General',
      'question': '¿Cómo agrego una nueva transacción?',
      'answer':
          'Toca el botón "+" en la parte inferior de la pantalla principal, selecciona el monto, la categoría y guarda los cambios.',
    },
    {
      'category': 'Cuenta',
      'question': '¿Cómo cambio mi nombre de usuario?',
      'answer':
          'Ve a Perfil > Editar Perfil y actualiza el campo de nombre de usuario.',
    },
    {
      'category': 'Seguridad',
      'question': '¿Es seguro guardar mis datos aquí?',
      'answer':
          'Sí, utilizamos encriptación local y sincronización segura con Firebase para proteger toda tu información financiera.',
    },
    {
      'category': 'General',
      'question': '¿Cómo puedo ver mis reportes mensuales?',
      'answer':
          'En la pestaña de Reportes podrás ver gráficos detallados de tus gastos e ingresos por mes.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Centro de Ayuda'), centerTitle: true),
      body: Column(
        children: [
          _buildSearchHeader(colorScheme),
          _buildCategoryFilter(colorScheme),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Preguntas Frecuentes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._buildFaqList(theme),
                const SizedBox(height: 32),
                _buildContactCard(colorScheme, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '¿En qué podemos ayudarte?',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(ColorScheme colorScheme) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return FilterChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (val) => setState(() => _selectedCategory = category),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  List<Widget> _buildFaqList(ThemeData theme) {
    return _faqs
        .where(
          (faq) =>
              _selectedCategory == 'Todos' ||
              faq['category'] == _selectedCategory,
        )
        .map(
          (faq) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(faq['question']!),
              leading: const Icon(Icons.help_outline, size: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    faq['answer']!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _buildContactCard(ColorScheme colorScheme, ThemeData theme) {
    return Card(
      elevation: 0,
      color: colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.support_agent, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            const Text(
              '¿Aún necesitas ayuda?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nuestros expertos están listos para asistirte 24/7.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Contactar Soporte Pro',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
