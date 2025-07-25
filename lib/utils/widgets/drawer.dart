import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

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
    final bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final Color primaryColor = headerColor ?? Theme.of(context).primaryColor;
    final NumberFormat currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Container(
        decoration: BoxDecoration(
          color:
              isIOS ? CupertinoColors.extraLightBackgroundGray : Colors.white,
        ),
        child: Column(
          children: <Widget>[
            _buildHeader(context, primaryColor, currencyFormat, isIOS),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                children: <Widget>[
                  _buildSectionTitle('Resumen Financiero'),
                  _buildTile(
                    context,
                    title: 'Dashboard',
                    icon: Icons.dashboard,
                    isSelected: true,
                    isIOS: isIOS,
                    onTap: () => _navigateTo(context, '/dashboard'),
                  ),
                  _buildTile(
                    context,
                    title: 'Balance Actual',
                    icon: Icons.account_balance_wallet,
                    isIOS: isIOS,
                    trailingText: currencyFormat.format(currentBalance),
                    onTap: () => _navigateTo(context, '/balance'),
                  ),

                  _buildSectionTitle('Transacciones'),
                  _buildTile(
                    context,
                    title: 'Ingresos',
                    icon: Icons.trending_up,
                    isIOS: isIOS,
                    color: Colors.green,
                    onTap: () => _navigateTo(context, '/incomes'),
                  ),
                  _buildTile(
                    context,
                    title: 'Gastos',
                    icon: Icons.trending_down,
                    isIOS: isIOS,
                    color: Colors.red,
                    onTap: () => _navigateTo(context, '/expenses'),
                  ),
                  _buildTile(
                    context,
                    title: 'Historial',
                    icon: Icons.history,
                    isIOS: isIOS,
                    onTap: () => _navigateTo(context, '/history'),
                  ),
                  _buildTile(
                    context,
                    title: 'Categorías',
                    icon: Icons.category,
                    isIOS: isIOS,
                    onTap: () => _navigateTo(context, '/categories'),
                  ),

                  _buildSectionTitle('Planificación'),
                  _buildTile(
                    context,
                    title: 'Presupuestos',
                    icon: Icons.pie_chart,
                    isIOS: isIOS,
                    onTap: () => _navigateTo(context, '/budgets'),
                  ),
                  _buildTile(
                    context,
                    title: 'Metas',
                    icon: Icons.flag,
                    isIOS: isIOS,
                    onTap: () => _navigateTo(context, '/goals'),
                  ),
                  _buildTile(
                    context,
                    title: 'Inversiones',
                    icon: Icons.timeline,
                    isIOS: isIOS,
                    onTap: () => _navigateTo(context, '/investments'),
                  ),

                  _buildSectionTitle('Configuración'),
                  _buildTile(
                    context,
                    title: 'Perfil',
                    icon: Icons.person,
                    isIOS: isIOS,
                    onTap:
                        onProfileTap ?? () => _navigateTo(context, '/profile'),
                  ),
                  _buildTile(
                    context,
                    title: 'Cuentas Bancarias',
                    icon: Icons.account_balance,
                    isIOS: isIOS,
                    onTap: () => _navigateTo(context, '/accounts'),
                  ),
                  _buildTile(
                    context,
                    title: 'Notificaciones',
                    icon: Icons.notifications,
                    badgeCount: 3,
                    isIOS: isIOS,
                    onTap: () => _navigateTo(context, '/notifications'),
                  ),
                  const Divider(height: 1),
                  _buildTile(
                    context,
                    title: 'Cerrar sesión',
                    icon: Icons.logout,
                    isIOS: isIOS,
                    color: Colors.red,
                    onTap: onLogoutTap,
                  ),
                ],
              ),
            ),
            _buildFooter(context, isIOS),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );

  Widget _buildHeader(
    BuildContext context,
    Color primaryColor,
    NumberFormat currencyFormat,
    bool isIOS,
  ) => Container(
      height: 220,
      decoration: BoxDecoration(
        color: isIOS ? primaryColor.withValues() : primaryColor,
      ),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ), // Espacio adicional entre nombre y email
                    Text(
                      userEmail,
                      style: TextStyle(
                        color: Colors.white.withValues(),
                        fontSize: 14,
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
              color: Colors.white.withValues(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Balance Total:',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
                Text(
                  currencyFormat.format(currentBalance),
                  style: const TextStyle(
                    color: Colors.black,
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

  // _buildTile y _buildFooter similares al ejemplo anterior, pero con soporte para trailingText
  Widget _buildTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    bool isSelected = false,
    int badgeCount = 0,
    String? trailingText,
    bool isIOS = false,
    Color? color,
    VoidCallback? onTap,
  }) {
    final ThemeData theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isSelected
                ? (isIOS
                    ? CupertinoColors.activeBlue.withOpacity(0.1)
                    : theme.primaryColor.withValues())
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color:
              color ??
              (isIOS ? CupertinoColors.activeBlue : theme.primaryColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            color:
                color ??
                (isSelected
                    ? (isIOS ? CupertinoColors.activeBlue : theme.primaryColor)
                    : theme.textTheme.bodyLarge?.color),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing:
            badgeCount > 0
                ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                )
                : trailingText != null
                ? Text(
                  trailingText,
                  style: TextStyle(
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

  Widget _buildFooter(BuildContext context, bool isIOS) => const Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        'Finanzas Personales v1.0',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );

  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pop(context);
    Navigator.pushNamed(context, routeName);
  }
}
