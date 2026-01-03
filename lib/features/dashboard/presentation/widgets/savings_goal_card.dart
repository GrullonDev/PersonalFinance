import 'package:flutter/material.dart';

class SavingsGoalCard extends StatelessWidget {
  final String title;
  final double targetAmount;
  final double currentAmount;
  final String emoji;
  final DateTime? deadline;
  final VoidCallback? onTap;

  const SavingsGoalCard({
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.emoji = '🎯',
    this.deadline,
    this.onTap,
    super.key,
  });

  double get percentage =>
      targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;

  // Convertir string de icono a IconData
  IconData _iconFromString(String? iconName) {
    const Map<String, IconData> iconMap = {
      'flag': Icons.flag,
      'star': Icons.star,
      'savings': Icons.savings,
      'home': Icons.home,
      'car': Icons.directions_car,
      'school': Icons.school,
      'favorite': Icons.favorite,
      'flight': Icons.flight_takeoff,
      'shopping': Icons.shopping_cart,
      'health': Icons.health_and_safety,
      'fitness': Icons.fitness_center,
      'restaurant': Icons.restaurant,
      'trophy': Icons.emoji_events,
      'gift': Icons.card_giftcard,
      'beach': Icons.beach_access,
    };
    return iconMap[iconName?.toLowerCase()] ?? Icons.flag;
  }

  // Determinar si es emoji o nombre de icono
  bool _isEmoji(String text) {
    if (text.isEmpty) return false;
    final int firstCodeUnit = text.codeUnitAt(0);
    // Emojis generalmente están en rangos Unicode específicos
    return firstCodeUnit > 0x1F000;
  }

  String _getDaysRemaining() {
    if (deadline == null) return '';
    final int days = deadline!.difference(DateTime.now()).inDays;
    if (days < 0) return 'Vencida';
    if (days == 0) return 'Hoy';
    if (days == 1) return '1 día';
    return '$days días';
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = currentAmount >= targetAmount;
    final String daysText = _getDaysRemaining();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: <Color>[
              isCompleted
                  ? Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.2)
                  : Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.15),
              isCompleted
                  ? Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.1)
                  : Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            // Contenido principal
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Icono o Emoji
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).shadowColor.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child:
                          _isEmoji(emoji)
                              ? Text(
                                emoji,
                                style: const TextStyle(fontSize: 32),
                              )
                              : Icon(
                                _iconFromString(emoji),
                                size: 32,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                    ),
                  ),
                  const Spacer(),

                  // Badge de progreso o completado
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isCompleted
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (isCompleted)
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green,
                              ),
                            if (isCompleted) const SizedBox(width: 4),
                            Text(
                              isCompleted
                                  ? 'Completada'
                                  : '${percentage.toInt()}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color:
                                    isCompleted
                                        ? Colors.green.shade700
                                        : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Título
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Días restantes
                  if (daysText.isNotEmpty)
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          daysText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),

                  // Progreso con moneda
                  Text(
                    '${currentAmount.toStringAsFixed(0)} / ${targetAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Barra de progreso animada
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0, end: percentage / 100),
                    builder:
                        (BuildContext context, double value, Widget? child) =>
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: value,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isCompleted
                                      ? Colors.green
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
