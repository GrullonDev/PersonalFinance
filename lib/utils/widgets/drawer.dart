import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/utils/app_localization.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({
    required this.userName,
    required this.userEmail,
    super.key,
    this.currentBalance = 0.0,
    this.headerColor,
    this.onProfileTap,
    this.onLogoutTap,
  });

  final String userName;
  final String userEmail;
  final double currentBalance;
  final Color? headerColor;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogoutTap;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = headerColor ?? Theme.of(context).primaryColor;
    final NumberFormat currencyFormat =
        AppLocalizations.of(context)!.currencyFormatter;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Container(
        decoration: const BoxDecoration(
          color: CupertinoColors.extraLightBackgroundGray,
        ),
        child: Column(
          children: <Widget>[
            _buildHeader(context, primaryColor, currencyFormat),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                children: <Widget>[
                  _buildSectionTitle(context, 'Resumen Financiero'),
                  _buildTile(
                    context,
                    title: 'Dashboard',
                    icon: Icons.dashboard,
                    isSelected: true,
                    onTap: () => _navigateTo(context, '/dashboard'),
                  ),
                  _buildTile(
                    context,
                    title: 'Balance Actual',
                    icon: Icons.account_balance_wallet,
                    trailingText: currencyFormat.format(currentBalance),
                    onTap: () => _navigateTo(context, '/balance'),
                  ),

                  _buildSectionTitle(context, 'Transacciones'),
                  _buildTile(
                    context,
                    title: 'Ingresos',
                    icon: Icons.trending_up,
                    color: Colors.green,
                    onTap: () => _navigateTo(context, '/incomes'),
                  ),
                  _buildTile(
                    context,
                    title: 'Gastos',
                    icon: Icons.trending_down,
                    color: Colors.red,
                    onTap: () => _navigateTo(context, '/expenses'),
                  ),
                  _buildTile(
                    context,
                    title: 'Historial',
                    icon: Icons.history,
                    onTap: () => _navigateTo(context, '/transactions-crud'),
                  ),
                  _buildTile(
                    context,
                    title: 'Categorías',
                    icon: Icons.category,
                    onTap: () => _navigateTo(context, '/categories'),
                  ),

                  _buildSectionTitle(context, 'Planificación'),
                  _buildTile(
                    context,
                    title: 'Presupuestos',
                    icon: Icons.pie_chart,
                    onTap: () => _navigateTo(context, '/budgets-crud'),
                  ),
                  _buildTile(
                    context,
                    title: 'Metas',
                    icon: Icons.flag,
                    onTap: () => _navigateTo(context, '/goals-crud'),
                  ),
                  _buildTile(
                    context,
                    title: 'Inversiones',
                    icon: Icons.timeline,
                    onTap: () => _navigateTo(context, '/investments'),
                  ),

                  _buildSectionTitle(context, 'Configuración'),
                  _buildTile(
                    context,
                    title: 'Perfil',
                    icon: Icons.person,
                    onTap:
                        onProfileTap ?? () => _navigateTo(context, '/profile'),
                  ),
                  _buildTile(
                    context,
                    title: 'Cuentas Bancarias',
                    icon: Icons.account_balance,
                    onTap: () => _navigateTo(context, '/accounts'),
                  ),
                  _buildTile(
                    context,
                    title: 'Notificaciones',
                    icon: Icons.notifications,
                    badgeCount: 3,
                    onTap: () => _navigateTo(context, '/notifications'),
                  ),
                  const Divider(height: 1),
                  _buildTile(
                    context,
                    title: 'Cerrar sesión',
                    icon: Icons.logout,
                    color: Colors.red,
                    onTap: onLogoutTap,
                  ),
                ],
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
      ),
    ),
  );

  Widget _buildHeader(
    BuildContext context,
    Color primaryColor,
    NumberFormat currencyFormat,
  ) => Container(
    height: 220,
    decoration: BoxDecoration(color: primaryColor),
    padding: EdgeInsets.only(
      top:
          MediaQuery.of(context).padding.top +
          20, // Añade espacio para la barra de estado
      left: 16,
      right: 16,
      bottom: 16,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Avatar y información de usuario
        Row(
          children: <Widget>[
            GestureDetector(
              onTap: onProfileTap ?? () => _navigateTo(context, '/profile'),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 30, color: primaryColor),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ), // Espacio adicional entre nombre y email
                  Text(
                    userEmail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24), // Espacio antes del balance
        // Tarjeta de balance
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Balance Total:',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
              Text(
                currencyFormat.format(currentBalance),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    bool isSelected = false,
    Color? color,
    String? trailingText,
    int badgeCount = 0,
    VoidCallback? onTap,
  }) {
    final ThemeData theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isSelected
                ? CupertinoColors.activeBlue.withValues(alpha: 0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: color ?? CupertinoColors.activeBlue),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color:
                color ??
                (isSelected
                    ? CupertinoColors.activeBlue
                    : theme.textTheme.bodyLarge?.color),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing:
            badgeCount > 0
                ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                )
                : trailingText != null
                ? Text(
                  trailingText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color ?? theme.textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.bold,
                  ),
                )
                : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(
      '${AppLocalizations.of(context)!.appTitle} v1.0',
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    ),
  );

  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pop(context);
    Navigator.pushReplacementNamed(context, routeName);
  }
}
