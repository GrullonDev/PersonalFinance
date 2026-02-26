import 'package:flutter/material.dart';
import 'package:personal_finance/features/notifications/domain/entities/notification_preferences.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance/features/notifications/presentation/providers/notification_prefs_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationsDetailPage extends StatefulWidget {
  const NotificationsDetailPage({super.key});

  @override
  State<NotificationsDetailPage> createState() =>
      _NotificationsDetailPageState();
}

class _NotificationsDetailPageState extends State<NotificationsDetailPage>
    with WidgetsBindingObserver {
  PermissionStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final PermissionStatus s = await Permission.notification.status;
    if (mounted) setState(() => _status = s);
  }

  Future<void> _requestPermission() async {
    final PermissionStatus s = await Permission.notification.request();
    if (mounted) setState(() => _status = s);
    if (!mounted) return;
    final bool granted = s.isGranted || s.isLimited;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(granted ? 'Permiso concedido' : 'Permiso denegado'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Consumer<NotificationPrefsProvider>(
        builder: (BuildContext context, NotificationPrefsProvider provider, _) {
          if (provider.loading && provider.prefs == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.prefs == null) {
            return Center(child: Text(provider.error!));
          }
          final NotificationPreferences prefs = provider.prefs!;

          final bool hasPermission =
              _status?.isGranted == true || _status?.isLimited == true;

          // Si no tiene permiso en OS, apagamos forzosamente en UI para que sea coherente
          final bool isPushEnabled = hasPermission && prefs.pushEnabled;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader(context, 'PERMISOS Y CANALES'),
                    const SizedBox(height: 8),
                    _buildDeviceNotificationsCard(
                      context,
                      isPushEnabled,
                      hasPermission,
                      provider,
                    ),
                    const SizedBox(height: 16),
                    _buildEmailNotificationsCard(context, prefs, provider),
                    const SizedBox(height: 32),

                    // Finanzas e Insights (Animated Size si no hay permisos)
                    AnimatedCrossFade(
                      key: const ValueKey('notifications_sections_fade'),
                      firstChild: Column(
                        key: const ValueKey('finance_alerts_section'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            context,
                            'ALERTAS IMPORTANTES (FINANZAS)',
                          ),
                          const SizedBox(height: 8),
                          _buildFinanceAlerts(context, prefs, provider),
                          const SizedBox(height: 32),
                        ],
                      ),
                      secondChild: Container(
                        key: const ValueKey('notifications_disabled_warning'),
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Activa las notificaciones del dispositivo para gestionar las alertas financieras.',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      crossFadeState:
                          isPushEnabled
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 300),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeader(context, 'OTRAS NOTIFICACIONES'),
                    const SizedBox(height: 8),
                    _buildMarketingCard(context, prefs, provider),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 4),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _buildDeviceNotificationsCard(
    BuildContext context,
    bool isPushEnabled,
    bool hasPermission,
    NotificationPrefsProvider provider,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool permanentlyDenied = _status?.isPermanentlyDenied == true;

    return Container(
      decoration: _cardDecoration(colorScheme),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              'Notificaciones del dispositivo',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              hasPermission ? 'Permitidas' : 'Bloqueadas',
              style: TextStyle(
                color: hasPermission ? Colors.green : colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            value: isPushEnabled,
            activeThumbColor: colorScheme.primary,
            onChanged: (bool value) async {
              if (value && !hasPermission) {
                if (permanentlyDenied) {
                  await openAppSettings();
                } else {
                  await _requestPermission();
                }
              } else if (hasPermission) {
                final bool ok = await provider.save(push: value);
                _feedback(context, ok, provider.error);
              }
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child:
                (!hasPermission)
                    ? Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => openAppSettings(),
                          icon: const Icon(Icons.settings),
                          label: const Text('Abrir ajustes del sistema'),
                        ),
                      ),
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailNotificationsCard(
    BuildContext context,
    NotificationPreferences prefs,
    NotificationPrefsProvider provider,
  ) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: _cardDecoration(colorScheme),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              'Notificaciones por correo',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Resúmenes y alertas a tu bandeja'),
            value: prefs.emailEnabled,
            activeThumbColor: colorScheme.primary,
            onChanged: (bool value) async {
              final bool ok = await provider.save(email: value);
              _feedback(context, ok, provider.error);
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child:
                prefs.emailEnabled
                    ? Column(
                      key: const ValueKey('email_frequency_expanded'),
                      children: [
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Frecuencia',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: prefs.emailFrequency,
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  items:
                                      <String>['Diario', 'Semanal', 'Mensual']
                                          .map(
                                            (String value) =>
                                                DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                ),
                                          )
                                          .toList(),
                                  onChanged: (String? newValue) async {
                                    if (newValue != null) {
                                      final bool ok = await provider.save(
                                        emailFrequency: newValue,
                                      );
                                      _feedback(context, ok, provider.error);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                    : const SizedBox.shrink(
                      key: ValueKey('email_frequency_collapsed'),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceAlerts(
    BuildContext context,
    NotificationPreferences prefs,
    NotificationPrefsProvider provider,
  ) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: _cardDecoration(colorScheme),
      child: Column(
        children: [
          // Vencimiento de servicios
          _buildPremiumToggleItem(
            context: context,
            title: 'Vencimientos de servicios',
            subtitle: 'Que no se te pase ninguna fecha de pago',
            icon: Icons.receipt_long_outlined,
            value: prefs.servicesDueEnabled,
            onChanged: (bool val) => provider.save(servicesDueEnabled: val),
            expandedChild: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Avisar:',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: prefs.servicesDueTiming,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      items:
                          <String>['Mismo día', '1 día antes', '3 días antes']
                              .map(
                                (String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          provider.save(servicesDueTiming: newValue);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, indent: 56),

          // Presupuesto por agotarse
          _buildPremiumToggleItem(
            context: context,
            title: 'Presupuesto por agotarse',
            subtitle: 'Excediste el límite establecido',
            icon: Icons.pie_chart_outline,
            value: prefs.budgetAlertsEnabled,
            onChanged: (bool val) => provider.save(budgetAlertsEnabled: val),
            expandedChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Avisar al llegar al:',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        '${prefs.budgetThreshold.toInt()}%',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: prefs.budgetThreshold,
                    min: 50,
                    max: 100,
                    divisions: 5,
                    activeColor: colorScheme.primary,
                    onChanged: (double value) {
                      provider.save(budgetThreshold: value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, indent: 56),

          // Meta de ahorro
          _buildPremiumToggleItem(
            context: context,
            title: 'Metas de ahorro',
            subtitle: 'Actualizaciones de progreso en tus metas',
            icon: Icons.savings_outlined,
            value: prefs.savingsGoalsEnabled,
            onChanged: (bool val) => provider.save(savingsGoalsEnabled: val),
          ),
          const Divider(height: 1, indent: 56),

          // Resumen Semanal
          _buildPremiumToggleItem(
            context: context,
            title: 'Resumen semanal inteligente',
            subtitle: 'Tu actividad financiera cada fin de semana',
            icon: Icons.insights_outlined,
            value: prefs.weeklySummaryEnabled,
            onChanged: (bool val) => provider.save(weeklySummaryEnabled: val),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumToggleItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? expandedChild,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SwitchListTile(
          value: value,
          onChanged: onChanged,
          activeThumbColor: colorScheme.primary,
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child:
              (value && expandedChild != null)
                  ? expandedChild
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildMarketingCard(
    BuildContext context,
    NotificationPreferences prefs,
    NotificationPrefsProvider provider,
  ) => Container(
    decoration: _cardDecoration(Theme.of(context).colorScheme),
    child: SwitchListTile(
      title: const Text(
        'Promos y Novedades',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: const Text('Ofertas especiales y nuevas funciones'),
      secondary: const Padding(
        padding: EdgeInsets.only(left: 8),
        child: Icon(Icons.campaign_outlined, color: Colors.grey),
      ),
      value: prefs.marketingEnabled,
      activeThumbColor: Theme.of(context).colorScheme.primary,
      onChanged: (bool value) async {
        final bool ok = await provider.save(marketing: value);
        _feedback(context, ok, provider.error);
      },
    ),
  );

  BoxDecoration _cardDecoration(ColorScheme colorScheme) => BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  void _feedback(BuildContext context, bool ok, String? error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Preferencias guardadas' : (error ?? 'Error al guardar'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
