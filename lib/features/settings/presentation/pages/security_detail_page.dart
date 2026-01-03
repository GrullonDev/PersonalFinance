import 'package:flutter/material.dart';
import 'package:personal_finance/core/services/biometric_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityDetailPage extends StatefulWidget {
  const SecurityDetailPage({super.key});

  @override
  State<SecurityDetailPage> createState() => _SecurityDetailPageState();
}

class _SecurityDetailPageState extends State<SecurityDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final _biometricService = BiometricService();
  bool _biometricEnabled = false;
  bool _appLockEnabled = false;
  bool _isHardwareSupported = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isSupported = await _biometricService.isBiometricAvailable();
    setState(() {
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _appLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
      _isHardwareSupported = isSupported;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final authenticated = await _biometricService.authenticate(
        localizedReason:
            'Confirma tu identidad para habilitar el desbloqueo biométrico',
      );
      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometric_enabled', true);
        setState(() => _biometricEnabled = true);
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', false);
      setState(() => _biometricEnabled = false);
    }
  }

  Future<void> _toggleAppLock(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_lock_enabled', value);
    setState(() => _appLockEnabled = value);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Centro de Seguridad'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildAnimatedShield(colorScheme),
                  const SizedBox(height: 32),
                  _buildSecurityScore(theme),
                  const SizedBox(height: 40),
                  _buildSectionHeader(theme, 'PROTECCIÓN DE ACCESO'),
                  const SizedBox(height: 12),
                  if (_isHardwareSupported) ...[
                    _buildProtectionToggle(
                      colorScheme: colorScheme,
                      title: 'Desbloqueo Biométrico',
                      subtitle: 'Fingerprint o FaceID',
                      icon: Icons.fingerprint,
                      value: _biometricEnabled,
                      onChanged: _toggleBiometrics,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildProtectionToggle(
                    colorScheme: colorScheme,
                    title: 'Bloqueo de Aplicación',
                    subtitle: 'Solicitar PIN al abrir',
                    icon: Icons.lock_person_outlined,
                    value: _appLockEnabled,
                    onChanged: _toggleAppLock,
                  ),
                  const SizedBox(height: 40),
                  _buildSectionHeader(theme, 'GESTIÓN DE CUENTA'),
                  const SizedBox(height: 12),
                  _buildActionTile(
                    theme: theme,
                    title: 'Actualizar Contraseña',
                    icon: Icons.password_rounded,
                    onTap: _showUpdatePasswordDialog,
                  ),
                  const SizedBox(height: 12),
                  _buildActionTile(
                    theme: theme,
                    title: 'Dispositivos Vinculados',
                    icon: Icons.devices_other_rounded,
                    onTap: () {},
                  ),
                  const SizedBox(height: 48),
                  _buildEmergencyNote(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedShield(ColorScheme colorScheme) => AnimatedBuilder(
    animation: _pulseController,
    builder:
        (context, child) => Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primary.withOpacity(
              0.05 + (0.05 * _pulseController.value),
            ),
            border: Border.all(
              color: colorScheme.primary.withOpacity(
                0.1 + (0.2 * _pulseController.value),
              ),
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 15 * _pulseController.value,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
  );

  Widget _buildSecurityScore(ThemeData theme) => Column(
    children: [
      Text(
        'Tu Protección es Óptima',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Último análisis realizado hoy a las 09:45 AM',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _buildSectionHeader(ThemeData theme, String title) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    ),
  );

  Widget _buildProtectionToggle({
    required ColorScheme colorScheme,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Container(
    decoration: BoxDecoration(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: colorScheme.primary,
      ),
    ),
  );

  Widget _buildActionTile({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: theme.colorScheme.outline,
          ),
        ],
      ),
    ),
  );

  Widget _buildEmergencyNote(ThemeData theme) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.amber.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.amber.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'En caso de robo, puedes bloquear tu cuenta remotamente desde jorgegrullondev.com',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.amber[900],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  void _showUpdatePasswordDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UpdatePasswordSheet(),
    );
  }
}

class _UpdatePasswordSheet extends StatefulWidget {
  @override
  State<_UpdatePasswordSheet> createState() => _UpdatePasswordSheetState();
}

class _UpdatePasswordSheetState extends State<_UpdatePasswordSheet> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Actualizar Contraseña',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _currentController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña Actual',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nueva Contraseña',
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Confirmar Cambio'),
            ),
          ),
        ],
      ),
    );
  }
}
