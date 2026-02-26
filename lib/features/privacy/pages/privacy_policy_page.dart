import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Privacidad y Confianza'),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTrustHeader(colorScheme, theme),
                  const SizedBox(height: 32),
                  _buildSafetySummary(colorScheme, theme),
                  const SizedBox(height: 32),
                  Text(
                    'Detalles de la Política',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPolicyCard(colorScheme, theme),
                  const SizedBox(height: 32),
                  _buildContactSupportCard(colorScheme, theme),
                  const SizedBox(height: 40),
                  Center(
                    child: Opacity(
                      opacity: 0.5,
                      child: Text(
                        'Versión Legal: 2026.1.0',
                        style: theme.textTheme.labelSmall,
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

  Widget _buildTrustHeader(ColorScheme colorScheme, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.security_rounded,
                color: Colors.blue,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu Datos están Seguros',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Protegemos tu información con estándares bancarios.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Cumple con GDPR / Protección de Datos',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSafetySummary(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildSummaryItem(
            Icons.enhanced_encryption_rounded,
            'Encriptación AES-256',
            'Tus datos financieros viajan y se guardan cifrados.',
          ),
          const Divider(height: 24, indent: 40),
          _buildSummaryItem(
            Icons.cloud_done_rounded,
            'Respaldo Seguro en la Nube',
            'Nunca pierdes tu información con nuestra infraestructura cloud.',
          ),
          const Divider(height: 24, indent: 40),
          _buildSummaryItem(
            Icons.privacy_tip_rounded,
            'Nunca Vendemos Datos',
            'Tu información es tuya. No la compartimos con terceros.',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String title, String desc) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyCard(ColorScheme colorScheme, ThemeData theme) {
    final List<Map<String, String>> policySections = [
      {
        'title': 'Resumen Ejecutivo',
        'content':
            'Nuestra política de privacidad es simple: priorizamos tu privacidad. Recopilamos y mantenemos tu información de forma segura para brindarte el mejor servicio posible de gestión financiera personal.',
      },
      {
        'title': 'Información que recopilamos',
        'content':
            'Únicamente recopilamos los datos esenciales que decides proporcionarnos al utilizar la app, como los balances de transacciones de tus categorías de ahorro, límites de gasto y credenciales encriptadas para autenticarte.',
      },
      {
        'title': 'Cómo usamos tus datos',
        'content':
            'Usamos tus datos para ofrecer y mejorar el funcionamiento de la aplicación, mostrarte análisis visuales de tus presupuestos y metas. Nunca utilizamos la información para fines publicitarios intrusivos ni las vendemos a corredores de datos.',
      },
      {
        'title': 'Derechos del usuario',
        'content':
            'Tienes pleno control de tus datos. En cualquier momento puedes solicitar acceder, modificar, exportar o borrar toda la información asociada a tu cuenta en base a normativas GDPR.',
      },
      {
        'title': 'Contacto',
        'content':
            'Si tienes cualquier duda sobre cómo gestionamos tu privacidad, puedes contactar con nuestro equipo de soporte directamente dentro de la app o a través de nuestros canales oficiales señalados en el portal.',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children:
              policySections.asMap().entries.map((entry) {
                final int index = entry.key;
                final Map<String, String> section = entry.value;
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom:
                          index < policySections.length - 1
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

  Widget _buildContactSupportCard(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withBlue(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '¿Preguntas sobre Privacidad?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nuestro delegado de protección de datos está disponible para ti.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Enviar mensaje directo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
