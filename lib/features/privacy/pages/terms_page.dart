import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegalHeader(colorScheme, theme),
                  const SizedBox(height: 32),
                  _buildAgreementSummary(colorScheme, theme),
                  const SizedBox(height: 32),
                  Text(
                    'Detalles del Acuerdo',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTermsCard(colorScheme, theme),
                  const SizedBox(height: 40),
                  const Center(
                    child: Opacity(
                      opacity: 0.5,
                      child: Text(
                        'Última actualización: Marzo 2026',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalHeader(ColorScheme colorScheme, ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.gavel_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acuerdo de Uso',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Al usar la app, aceptas estos términos.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildAgreementSummary(ColorScheme colorScheme, ThemeData theme) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: const Column(
          children: [
            _SummaryItem(
              Icons.person_pin_rounded,
              'Registro de Usuario',
              'Eres responsable de mantener la confidencialidad de tu cuenta.',
            ),
            Divider(height: 24),
            _SummaryItem(
              Icons.auto_graph_rounded,
              'Uso de Datos',
              'Los datos financieros son procesados para tu análisis personal.',
            ),
            Divider(height: 24),
            _SummaryItem(
              Icons.copyright_rounded,
              'Propiedad Intelectual',
              'El diseño y código pertenecen a GrullonDev.',
            ),
          ],
        ),
      );

  Widget _buildTermsCard(ColorScheme colorScheme, ThemeData theme) {
    final List<Map<String, String>> termSections = [
      {
        'title': '1. Aceptación de Términos',
        'content':
            'Al acceder y utilizar la aplicación "Personal Finance", el usuario acepta quedar vinculado por estos Términos y Condiciones, todas las leyes y reglamentos aplicables.',
      },
      {
        'title': '2. Licencia de Uso',
        'content':
            'Se concede permiso para descargar temporalmente una copia de la aplicación para uso personal, no comercial y transitorio únicamente. Esta es la concesión de una licencia, no una transferencia de título.',
      },
      {
        'title': '3. Responsabilidad del Usuario',
        'content':
            'El usuario es el único responsable de la veracidad de los datos ingresados y de mantener la seguridad de su dispositivo y credenciales de acceso.',
      },
      {
        'title': '4. Limitaciones',
        'content':
            'En ningún caso "Personal Finance" o sus desarrolladores serán responsables de cualquier daño (incluyendo, sin limitación, daños por pérdida de datos o beneficios) que surjan del uso o la imposibilidad de usar la aplicación.',
      },
      {
        'title': '5. Modificaciones',
        'content':
            'Nos reservamos el derecho de revisar estos términos en cualquier momento sin previo aviso. Al usar esta aplicación, usted acepta estar obligado por la versión actual de estos términos.',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children:
              termSections.asMap().entries.map((entry) {
                final int index = entry.key;
                final Map<String, String> section = entry.value;
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom:
                          index < termSections.length - 1
                              ? BorderSide(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.3,
                                ),
                              )
                              : BorderSide.none,
                    ),
                  ),
                  child: Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text(
                        section['title']!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section['content']!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem(this.icon, this.title, this.desc);
  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
