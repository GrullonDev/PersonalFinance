import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';
import 'package:personal_finance/utils/currency_helper.dart';

class TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback onDelete;
  final bool hideAmounts;

  const TransactionTile({
    required this.transaction,
    required this.onDelete,
    this.hideAmounts = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Dismissible(
    key: ValueKey(transaction.id),
    direction: DismissDirection.endToStart,
    onDismissed: (_) {
      HapticFeedback.mediumImpact();
      onDelete();
    },
    background: const _DeleteBackground(),
    child: _TileBody(transaction: transaction, hideAmounts: hideAmounts),
  );
}

// ── Swipe background ──────────────────────────────────────────────────────────

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.red.shade600,
      borderRadius: BorderRadius.circular(16),
    ),
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
        SizedBox(height: 2),
        Text(
          'Eliminar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

// ── Tile body ─────────────────────────────────────────────────────────────────

class _TileBody extends StatelessWidget {
  final TransactionEntity transaction;
  final bool hideAmounts;

  static final _dateFmt = DateFormat('d MMM  HH:mm', 'es');

  const _TileBody({required this.transaction, required this.hideAmounts});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final amountColor =
        isIncome ? const Color(0xFF34C759) : const Color(0xFFFF3B30);
    final cat = _categorize(transaction);
    final displayCategory = transaction.categoryId ?? cat.inferredCategory;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cat.iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(cat.icon, color: cat.iconColor, size: 18),
          ),
          const SizedBox(width: 12),

          // Note + date + category badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.note,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _dateFmt.format(transaction.createdAt),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                    if (displayCategory != null) ...[
                      const SizedBox(width: 6),
                      Flexible(child: _CategoryChip(label: displayCategory)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Amount + sync badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hideAmounts
                    ? '${isIncome ? '+' : '-'}••••'
                    : '${isIncome ? '+' : '-'}${CurrencyHelper.format(transaction.amount)}',
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              _SyncBadge(status: transaction.syncStatus),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sync badge ────────────────────────────────────────────────────────────────

class _SyncBadge extends StatelessWidget {
  final SyncStatus status;
  const _SyncBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case SyncStatus.pending:
        return _badge(
          icon: Icons.cloud_upload_outlined,
          label: 'Pendiente',
          color: const Color(0xFFFF9500),
        );
      case SyncStatus.failed:
        return _badge(
          icon: Icons.error_outline_rounded,
          label: 'Error',
          color: const Color(0xFFFF3B30),
        );
      case SyncStatus.synced:
        return _badge(
          icon: Icons.cloud_done_outlined,
          label: 'Sync',
          color: const Color(0xFF34C759),
        );
    }
  }

  Widget _badge({
    required IconData icon,
    required String label,
    required Color color,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

// ── Category chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      '#$label',
      style: TextStyle(
        fontSize: 10,
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.w500,
      ),
      overflow: TextOverflow.ellipsis,
    ),
  );
}

// ── Category inference ────────────────────────────────────────────────────────

class _CatInfo {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String? inferredCategory;

  const _CatInfo({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.inferredCategory,
  });
}

bool _has(String text, List<String> kw) => kw.any(text.contains);

_CatInfo _categorize(TransactionEntity t) {
  final text = '${t.note} ${t.categoryId ?? ''}'.toLowerCase();

  if (_has(text, [
    'comida',
    'almuerzo',
    'cena',
    'desayuno',
    'café',
    'cafe',
    'restaurante',
    'pizza',
    'burger',
    'lunch',
    'food',
    'mercado',
    'super',
    'sushi',
    'taco',
    'kebab',
  ])) {
    return const _CatInfo(
      icon: Icons.restaurant_rounded,
      iconBg: Color(0xFFFFF3E0),
      iconColor: Color(0xFFFF9500),
      inferredCategory: 'comida',
    );
  }

  if (_has(text, [
    'transporte',
    'taxi',
    'uber',
    'bus',
    'metro',
    'tren',
    'gasolina',
    'coche',
    'auto',
    'bici',
    'moto',
    'lyft',
  ])) {
    return const _CatInfo(
      icon: Icons.directions_car_rounded,
      iconBg: Color(0xFFE3F2FD),
      iconColor: Color(0xFF007AFF),
      inferredCategory: 'transporte',
    );
  }

  if (_has(text, ['venta', 'ventas', 'negocio', 'comercio', 'producto'])) {
    return const _CatInfo(
      icon: Icons.storefront_rounded,
      iconBg: Color(0xFFE8F5E9),
      iconColor: Color(0xFF2E7D32),
      inferredCategory: 'negocio',
    );
  }

  if (_has(text, [
    'salario',
    'sueldo',
    'trabajo',
    'nomina',
    'pago',
    'salary',
    'transferencia',
    'freelance',
    'cliente',
    'ingreso',
  ])) {
    return const _CatInfo(
      icon: Icons.account_balance_wallet_rounded,
      iconBg: Color(0xFFE8F9EE),
      iconColor: Color(0xFF34C759),
      inferredCategory: 'salario',
    );
  }

  if (_has(text, [
    'servicio',
    'luz',
    'agua',
    'gas',
    'internet',
    'telefono',
    'electricidad',
    'renta',
    'alquiler',
    'rent',
  ])) {
    return const _CatInfo(
      icon: Icons.home_rounded,
      iconBg: Color(0xFFF0EFFF),
      iconColor: Color(0xFF5856D6),
      inferredCategory: 'servicios',
    );
  }

  if (_has(text, [
    'compra',
    'tienda',
    'ropa',
    'amazon',
    'shopping',
    'zapatos',
    'mall',
  ])) {
    return const _CatInfo(
      icon: Icons.shopping_bag_rounded,
      iconBg: Color(0xFFFFEEF0),
      iconColor: Color(0xFFFF2D55),
      inferredCategory: 'compras',
    );
  }

  if (_has(text, [
    'salud',
    'medico',
    'doctor',
    'farmacia',
    'gym',
    'deporte',
    'hospital',
  ])) {
    return const _CatInfo(
      icon: Icons.favorite_rounded,
      iconBg: Color(0xFFFFEEF0),
      iconColor: Color(0xFFFF2D55),
      inferredCategory: 'salud',
    );
  }

  if (_has(text, [
    'cine',
    'netflix',
    'spotify',
    'entretenimiento',
    'pelicula',
    'musica',
    'streaming',
    'disney',
  ])) {
    return const _CatInfo(
      icon: Icons.movie_rounded,
      iconBg: Color(0xFFFFF3E0),
      iconColor: Color(0xFFFF9500),
      inferredCategory: 'entretenimiento',
    );
  }

  return t.type == TransactionType.income
      ? const _CatInfo(
        icon: Icons.arrow_upward_rounded,
        iconBg: Color(0xFFE8F9EE),
        iconColor: Color(0xFF34C759),
      )
      : const _CatInfo(
        icon: Icons.arrow_downward_rounded,
        iconBg: Color(0xFFFFEEED),
        iconColor: Color(0xFFFF3B30),
      );
}
