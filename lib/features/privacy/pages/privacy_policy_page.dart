import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Página que muestra la política de privacidad de la aplicación
class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  String _privacyPolicyContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacyPolicy();
  }

  /// Carga el contenido de la política de privacidad desde assets
  Future<void> _loadPrivacyPolicy() async {
    try {
      final String content = await rootBundle.loadString(
        'assets/privacy_policy.md',
      );
      setState(() {
        _privacyPolicyContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _privacyPolicyContent = 'Error al cargar la política de privacidad.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
        backgroundColor: isDarkMode ? colorScheme.surface : colorScheme.primary,
        foregroundColor:
            isDarkMode ? colorScheme.onSurface : colorScheme.onPrimary,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePrivacyPolicy(),
            tooltip: 'Compartir política',
          ),
        ],
      ),
      body: Container(
        color: isDarkMode ? colorScheme.surface : colorScheme.surface,
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Header con fecha de actualización
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? colorScheme.primary.withValues(alpha: 0.1)
                                  : colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.security,
                              color: colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Tu privacidad es importante',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDarkMode
                                              ? colorScheme.onSurface
                                              : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Última actualización: 28 de julio de 2025',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          isDarkMode
                                              ? colorScheme.onSurface
                                                  .withValues(alpha: 0.7)
                                              : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Contenido de la política de privacidad
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode ? colorScheme.surface : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: SelectableText(
                          _privacyPolicyContent,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color:
                                isDarkMode
                                    ? colorScheme.onSurface
                                    : Colors.black87,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Botones de acción
                      _buildActionButtons(context, colorScheme, isDarkMode),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
      ),
    );
  }

  /// Construye los botones de acción en la parte inferior
  Widget _buildActionButtons(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) => Column(
    children: <Widget>[
      // Botón de contacto
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _contactSupport(),
          icon: const Icon(Icons.email_outlined),
          label: const Text('Contactar Soporte'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      const SizedBox(height: 12),

      // Botón de eliminación de datos
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _requestDataDeletion(),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Solicitar Eliminación de Datos'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red[600],
            side: BorderSide(color: Colors.red[600]!),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    ],
  );

  /// Comparte la política de privacidad
  void _sharePrivacyPolicy() {
    // Implementar compartir (requiere package share_plus)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de compartir disponible próximamente'),
      ),
    );
  }

  /// Abre el contacto de soporte
  void _contactSupport() {
    showDialog<void>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Contactar Soporte'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Para consultas sobre privacidad:'),
                SizedBox(height: 8),
                SelectableText(
                  'privacy@grullondev.com',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Tiempo de respuesta: Máximo 72 horas'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Aquí puedes implementar abrir el cliente de email
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copiado: privacy@grullondev.com'),
                    ),
                  );
                },
                child: const Text('Copiar Email'),
              ),
            ],
          ),
    );
  }

  /// Solicita la eliminación de datos
  void _requestDataDeletion() {
    showDialog<void>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Eliminar Datos'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '¿Estás seguro de que quieres solicitar la eliminación de todos tus datos?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Esta acción:'),
                SizedBox(height: 8),
                Text('• Eliminará permanentemente tu cuenta'),
                Text('• Borrará todos tus datos financieros'),
                Text('• No se puede deshacer'),
                SizedBox(height: 16),
                Text(
                  'Para proceder, envía un email a privacy@grullondev.com con el asunto "Solicitud de eliminación de datos"',
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _contactSupport();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Contactar'),
              ),
            ],
          ),
    );
  }
}
