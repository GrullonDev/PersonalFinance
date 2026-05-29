import 'package:flutter/material.dart';
import 'package:personal_finance/utils/widgets/empty_state.dart';
import 'package:url_launcher/url_launcher.dart';

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
    'Presupuesto',
    'IA',
  ];

  final List<Map<String, String>> _faqs = [
    {
      'category': 'General',
      'question': '¿Cómo agrego una nueva transacción?',
      'answer':
          'Toca el botón "+" en la pantalla principal, ingresa el monto, selecciona si es un ingreso o gasto, elige la categoría y guarda. La transacción aparece de inmediato en tu historial y afecta tus reportes del mes.',
    },
    {
      'category': 'General',
      'question': '¿Puedo usar la app sin conexión a internet?',
      'answer':
          'Sí. Personal Finance funciona completamente sin conexión. Tus datos se guardan localmente con cifrado Hive y se sincronizan con Firebase de forma automática cuando recuperas la conexión.',
    },
    {
      'category': 'General',
      'question': '¿Cómo veo mis reportes mensuales?',
      'answer':
          'Accede a la pestaña "Reportes" desde el menú principal. Encontrarás gráficos con el desglose de ingresos, gastos y balance neto por mes. Puedes filtrar por fecha y por categoría.',
    },
    {
      'category': 'General',
      'question': '¿Cómo configuro alertas de presupuesto?',
      'answer':
          'Ve a Configuración > Alertas. Puedes recibir notificaciones push cuando estés cerca de tu límite mensual de gastos o cuando tu saldo baje de un umbral definido por ti.',
    },
    {
      'category': 'Cuenta',
      'question': '¿Cómo actualizo mi nombre o foto de perfil?',
      'answer':
          'Toca tu avatar en la esquina superior y selecciona "Editar Perfil". Ahí puedes cambiar tu nombre, foto y correo de contacto. Los cambios se sincronizan automáticamente con tu cuenta Firebase.',
    },
    {
      'category': 'Cuenta',
      'question': '¿Qué hago si olvido mi contraseña?',
      'answer':
          'En la pantalla de inicio de sesión toca "¿Olvidaste tu contraseña?". Se enviará un enlace de recuperación a tu correo registrado. Si no lo ves, revisa la carpeta de spam.',
    },
    {
      'category': 'Cuenta',
      'question': '¿Cómo elimino mi cuenta permanentemente?',
      'answer':
          'Ve a Configuración > Cuenta > Eliminar cuenta. Esta acción es irreversible: se borrarán todos tus datos financieros, metas, deudas y configuración, tanto en el dispositivo como en la nube.',
    },
    {
      'category': 'Cuenta',
      'question': '¿Puedo acceder a mi cuenta desde otro dispositivo?',
      'answer':
          'Sí. Inicia sesión con tu correo y contraseña en cualquier dispositivo. Tu información se sincroniza desde Firebase Firestore, así que verás exactamente los mismos datos en todos los dispositivos.',
    },
    {
      'category': 'Seguridad',
      'question': '¿Es seguro guardar mis datos financieros en la app?',
      'answer':
          'Sí. Los datos sensibles se almacenan localmente con cifrado AES-256 usando Hive. La sincronización con Firebase usa conexiones TLS cifradas. No almacenamos contraseñas en texto plano ni compartimos tu información con terceros.',
    },
    {
      'category': 'Seguridad',
      'question': '¿Mis datos están solo en mi teléfono o también en la nube?',
      'answer':
          'En ambos lugares. Primero se guardan en tu dispositivo (Hive cifrado) para que funcionen sin internet, y luego se sincronizan con Firebase Firestore para respaldo y acceso desde múltiples dispositivos.',
    },
    {
      'category': 'Seguridad',
      'question': '¿Qué pasa con mis datos si desinstalo la app?',
      'answer':
          'Los datos locales se eliminan del dispositivo, pero tu respaldo en la nube (Firebase) permanece intacto. Al reinstalar la app e iniciar sesión, tu historial y configuración se restauran automáticamente.',
    },
    {
      'category': 'Presupuesto',
      'question': '¿Cómo creo una meta de ahorro?',
      'answer':
          'Ve a "Finanzas Rápidas" y selecciona "Nueva Meta". Define el nombre, el monto objetivo y la fecha límite. La app calculará cuánto debes ahorrar por mes y mostrará tu progreso conforme registres ingresos.',
    },
    {
      'category': 'Presupuesto',
      'question': '¿Cómo registro y doy seguimiento a una deuda?',
      'answer':
          'En "Finanzas Rápidas" > "Deudas" puedes registrar deudas con el nombre del acreedor, monto total e interés. La app calcula el progreso de pago y te muestra cuánto falta por liquidar.',
    },
    {
      'category': 'Presupuesto',
      'question': '¿Cómo establezco límites de gasto por categoría?',
      'answer':
          'Ve a Configuración > Presupuesto Mensual y asigna un límite a cada categoría (Alimentación, Transporte, etc.). Cuando superes el 80% del límite recibirás una alerta automática.',
    },
    {
      'category': 'Presupuesto',
      'question': '¿Las metas y deudas se sincronizan con mis transacciones?',
      'answer':
          'Sí. Al registrar una transacción puedes asociarla a una meta de ahorro activa. Los gastos marcados como "pago de deuda" reducen automáticamente el saldo pendiente de la deuda correspondiente.',
    },
    {
      'category': 'IA',
      'question': '¿Qué puede hacer el asistente financiero con IA?',
      'answer':
          'El asistente (basado en Gemini AI) analiza tus patrones de gasto, te sugiere cómo reducir gastos innecesarios, proyecta cuándo alcanzarás tus metas de ahorro y responde preguntas sobre tus finanzas en lenguaje natural.',
    },
    {
      'category': 'IA',
      'question': '¿El asistente de IA tiene acceso a mis datos reales?',
      'answer':
          'Solo si tú lo permites. El asistente puede leer tus categorías y totales de forma anonimizada para darte consejos contextuales. Nunca envía datos identificables a servidores externos sin tu consentimiento.',
    },
    {
      'category': 'IA',
      'question': '¿Cómo activo el asistente de inteligencia artificial?',
      'answer':
          'El asistente está disponible desde el ícono de IA en la pantalla principal. Si es la primera vez, se te pedirá aceptar los términos del servicio Gemini. Una vez activado, puedes hacerle preguntas directamente en español.',
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
    final filteredFaqs = _filteredFaqs;

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
                if (filteredFaqs.isEmpty)
                  SizedBox(
                    height: 280,
                    child: EmptyState(
                      title: 'No encontramos resultados',
                      message:
                          'Prueba con otra palabra clave o limpia la búsqueda para ver todas las respuestas.',
                      icon: Icons.search_off_rounded,
                      action: FilledButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: const Text('Limpiar búsqueda'),
                      ),
                    ),
                  )
                else
                  ..._buildFaqList(theme, filteredFaqs),
                const SizedBox(height: 32),
                _buildContactCard(colorScheme, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(ColorScheme colorScheme) => Container(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    decoration: BoxDecoration(
      color: colorScheme.surface,
      border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
    ),
    child: TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: '¿En qué podemos ayudarte?',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(),
      ),
    ),
  );

  Widget _buildCategoryFilter(ColorScheme colorScheme) => SizedBox(
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

  List<Map<String, String>> get _filteredFaqs {
    final query = _searchController.text.trim().toLowerCase();
    return _faqs.where((faq) {
      final matchesCategory =
          _selectedCategory == 'Todos' || faq['category'] == _selectedCategory;
      if (!matchesCategory) return false;
      if (query.isEmpty) return true;
      final haystack = <String>[
        faq['question'] ?? '',
        faq['answer'] ?? '',
        faq['category'] ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  List<Widget> _buildFaqList(ThemeData theme, List<Map<String, String>> faqs) =>
      faqs
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

  Widget _buildContactCard(ColorScheme colorScheme, ThemeData theme) => Card(
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
            'Contáctanos directamente y te respondemos a la brevedad.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _launchEmail,
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: const Text('Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _launchWhatsApp,
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
    ),
  );

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'prosystem155@gmail.com',
      queryParameters: {'subject': 'Soporte Personal Finance App'},
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
      'https://wa.me/50242909548?text=Hola%2C%20necesito%20ayuda%20con%20Personal%20Finance%20App',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir WhatsApp'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
