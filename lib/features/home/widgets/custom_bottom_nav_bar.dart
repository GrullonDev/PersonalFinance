import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final VoidCallback onAddPressed;

  const CustomBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onAddPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final double width = MediaQuery.sizeOf(context).width;
    // Responsive sizing
    final bool isSmall = width < 360;
    final bool isMedium = width >= 360 && width < 420;
    final double barHeight = isSmall ? 64 : (isMedium ? 68 : 72);
    // final double iconSize = isSmall ? 22 : (isMedium ? 24 : 26);
    // final double fontSize = isSmall ? 11 : (isMedium ? 12 : 13);
    // final double spacing = isSmall ? 3 : 4;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      // Evitamos SafeArea aquí para no reducir el alto efectivo.
      // Añadimos padding inferior según el inset del sistema (gestures/home bar).
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: barHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(
              context,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Inicio',
              index: 0,
              scheme: scheme,
            ),
            _buildNavItem(
              context,
              icon: Icons.bolt_outlined,
              activeIcon: Icons.bolt,
              label: 'Servicios',
              index: 1,
              scheme: scheme,
            ),
            const SizedBox(width: 56),
            _buildNavItem(
              context,
              icon: Icons.pie_chart_outline,
              activeIcon: Icons.pie_chart,
              label: 'Presupuestos',
              index: 2,
              scheme: scheme,
            ),
            _buildNavItem(
              context,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Perfil',
              index: 3,
              scheme: scheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required ColorScheme scheme,
  }) {
    final bool isSelected = currentIndex == index;
    final Color color = isSelected ? scheme.primary : Colors.grey.shade600;
    final double width = MediaQuery.sizeOf(context).width;
    final double iconSize = width < 360 ? 22 : (width < 420 ? 24 : 26);
    final double fontSize = width < 360 ? 11 : (width < 420 ? 12 : 13);
    final double spacing = width < 360 ? 3 : 4;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? (scheme.primaryContainer.withOpacity(0.6))
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                isSelected ? activeIcon : icon,
                color: color,
                size: iconSize,
              ),
              SizedBox(height: spacing),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
