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
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Busca preguntas o temas…',
            prefixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _searchController.text.isEmpty
                    ? Icons.search_rounded
                    : Icons.manage_search_rounded,
                key: ValueKey(_searchController.text.isEmpty),
                color: colorScheme.primary,
              ),
            ),
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: (val) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(ColorScheme colorScheme) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedCategory = category);
              },
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              selectedColor: colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color:
                    isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color:
                      isSelected
                          ? colorScheme.primary.withValues(alpha: 0.2)
                          : Colors.transparent,
                ),
              ),
              showCheckmark: false,
              elevation: isSelected ? 2 : 0,
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFaqList(ThemeData theme) {
    return _faqs
        .where((faq) {
          final matchesCategory =
              _selectedCategory == 'Todos' ||
              faq['category'] == _selectedCategory;
          final matchesSearch =
              _searchController.text.isEmpty ||
              faq['question']!.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ) ||
              faq['answer']!.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              );
          return matchesCategory && matchesSearch;
        })
        .map(
          (faq) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.2,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    faq['question']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  iconColor: theme.colorScheme.primary,
                  collapsedIconColor: theme.colorScheme.onSurfaceVariant,
                  children: [
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.2,
                      ),
                      indent: 16,
                      endIndent: 16,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Text(
                        faq['answer']!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _buildContactCard(ColorScheme colorScheme, ThemeData theme) {
    return Card(
      elevation: 4,
      shadowColor: colorScheme.primary.withValues(alpha: 0.3),
      color: colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              '¿No encuentras lo que buscas?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nuestro equipo está disponible 24/7.',
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Enviar mensaje directo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
