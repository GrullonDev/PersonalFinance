import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {

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
              padding: const EdgeInsets.all(24),
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
                        'Versión Legal: 2026.1.0 · Última actualización: Mayo 2026',
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

  Widget _buildTrustHeader(ColorScheme colorScheme, ThemeData theme) => Column(
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
                  'Tus Datos están Seguros',
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

  Widget _buildSafetySummary(ColorScheme colorScheme, ThemeData theme) =>
      Container(
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

  Widget _buildSummaryItem(IconData icon, String title, String desc) => Row(
    children: [
      Icon(icon, size: 20, color: Colors.blueGrey),
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
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildPolicyCard(ColorScheme colorScheme, ThemeData theme) {
    final List<Map<String, String>> policySections = [
      {
        'title': 'Resumen Ejecutivo',
        'content':
            'Priorizamos tu privacidad en cada decisión de diseño. Personal Finance recopila únicamente los datos que tú ingresas, los protege con cifrado de extremo a extremo y nunca los usa con fines distintos a brindarte el mejor servicio de gestión financiera personal.',
      },
      {
        'title': 'Información que recopilamos',
        'content':
            'Recopilamos los datos que eliges ingresar: transacciones, categorías, metas de ahorro, deudas y límites de presupuesto. También almacenamos tu correo electrónico y nombre de perfil para la autenticación con Firebase. No recopilamos datos de ubicación, contactos ni actividad fuera de la app.',
      },
      {
        'title': 'Tecnología y almacenamiento',
        'content':
            'Tus datos se guardan localmente en tu dispositivo usando Hive con cifrado AES-256. La sincronización con la nube usa Firebase Firestore con conexiones TLS. El asistente de inteligencia artificial (Gemini AI) procesa únicamente resúmenes anonimizados cuando solicitas análisis o sugerencias; nunca envía datos identificables sin tu consentimiento.',
      },
      {
        'title': 'Cómo usamos tus datos',
        'content':
            'Usamos tu información exclusivamente para: mostrar tus reportes y gráficos financieros, generar alertas de presupuesto, sincronizar entre dispositivos y mejorar la experiencia de la app. Nunca vendemos ni compartimos tus datos con terceros con fines publicitarios.',
      },
      {
        'title': 'Derechos del usuario',
        'content':
            'Tienes control total sobre tu información. En cualquier momento puedes solicitar acceder, corregir, exportar o eliminar permanentemente todos los datos asociados a tu cuenta, tanto locales como en la nube. Para ejercer estos derechos, contáctanos directamente.',
      },
      {
        'title': 'Contacto directo',
        'content':
            'Para cualquier duda sobre privacidad o solicitud de datos, contáctanos en prosystem155@gmail.com o vía WhatsApp al +502 4290-9548. Respondemos en un máximo de 48 horas hábiles.',
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
                  child: Material(
                    color: Colors.transparent,
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(
                          section['title']!,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section['content']!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildContactSupportCard(
    ColorScheme colorScheme,
    ThemeData theme,
  ) => Container(
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
          'Contáctanos directamente y te respondemos en menos de 48 horas.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _launchEmail,
                icon: const Icon(Icons.email_outlined, size: 16),
                label: const Text('Email'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _launchWhatsApp,
                icon: const Icon(Icons.chat_outlined, size: 16),
                label: const Text('WhatsApp'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'prosystem155@gmail.com',
      queryParameters: {'subject': 'Consulta sobre Privacidad - Personal Finance'},
    );
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el cliente de correo'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/50242909548?text=Hola%2C%20tengo%20una%20consulta%20sobre%20privacidad%20de%20Personal%20Finance%20App',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir WhatsApp'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
