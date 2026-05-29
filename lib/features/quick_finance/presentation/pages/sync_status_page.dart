import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_bloc.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_event.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_state.dart';

class SyncStatusPage extends StatelessWidget {
  const SyncStatusPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F7F9),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF6F7F9),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      title: const Text(
        'Estado de sincronización',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
      ),
    ),
    body: BlocBuilder<QuickFinanceBloc, QuickFinanceState>(
      builder: (context, state) {
        final pendingCount =
            state.transactions
                .where(
                  (t) =>
                      t.syncStatus == SyncStatus.pending && t.deletedAt == null,
                )
                .length;

        final failedCount =
            state.transactions
                .where(
                  (t) =>
                      t.syncStatus == SyncStatus.failed && t.deletedAt == null,
                )
                .length;

        final _Status status;
        if (state.isSyncing) {
          status = _Status.syncing;
        } else if (state.isOffline) {
          status = _Status.offline;
        } else if (state.syncError != null) {
          status = _Status.error;
        } else if (pendingCount > 0 || failedCount > 0) {
          status = _Status.pending;
        } else {
          status = _Status.synced;
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            _StatusCard(
              status: status,
              pendingCount: pendingCount,
              failedCount: failedCount,
              syncError: state.syncError,
            ),
            const SizedBox(height: 16),
            _LastSyncCard(lastSyncAt: state.lastSyncAt),
            const SizedBox(height: 16),
            _StatsCard(
              pendingCount: pendingCount,
              failedCount: failedCount,
              syncedCount:
                  state.transactions
                      .where(
                        (t) =>
                            t.syncStatus == SyncStatus.synced &&
                            t.deletedAt == null,
                      )
                      .length,
            ),
            const SizedBox(height: 32),
            _SyncNowButton(
              isSyncing: state.isSyncing,
              isOffline: state.isOffline,
            ),
          ],
        );
      },
    ),
  );
}

// ── Status indicator ──────────────────────────────────────────────────────────

enum _Status { syncing, synced, pending, offline, error }

class _StatusCard extends StatelessWidget {
  final _Status status;
  final int pendingCount;
  final int failedCount;
  final String? syncError;

  const _StatusCard({
    required this.status,
    required this.pendingCount,
    required this.failedCount,
    this.syncError,
  });

  @override
  Widget build(BuildContext context) {
    final (
      IconData icon,
      String title,
      String subtitle,
      Color color,
    ) = switch (status) {
      _Status.syncing => (
        Icons.sync_rounded,
        'Sincronizando…',
        'Subiendo y descargando cambios',
        const Color(0xFF007AFF),
      ),
      _Status.synced => (
        Icons.cloud_done_rounded,
        'Sincronizado',
        'Todos tus datos están al día',
        const Color(0xFF34C759),
      ),
      _Status.pending => (
        Icons.cloud_upload_rounded,
        'Pendiente de sincronizar',
        _pendingLabel(pendingCount, failedCount),
        const Color(0xFFFF9500),
      ),
      _Status.offline => (
        Icons.wifi_off_rounded,
        'Sin conexión',
        'Se sincronizará cuando recuperes internet',
        const Color(0xFF8E8E93),
      ),
      _Status.error => (
        Icons.cloud_off_rounded,
        'Error al sincronizar',
        'No se pudo completar la sincronización',
        const Color(0xFFFF3B30),
      ),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child:
                status == _Status.syncing
                    ? _SpinningIcon(icon: icon, color: color)
                    : Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (syncError != null && status == _Status.error) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                syncError!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFF3B30),
                  fontFamily: 'monospace',
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _pendingLabel(int pending, int failed) {
    final parts = <String>[];
    if (pending > 0) {
      parts.add(
        pending == 1
            ? '1 movimiento pendiente'
            : '$pending movimientos pendientes',
      );
    }
    if (failed > 0) {
      parts.add(failed == 1 ? '1 con error' : '$failed con error');
    }
    return parts.join(' • ');
  }
}

// ── Spinning icon ─────────────────────────────────────────────────────────────

class _SpinningIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _SpinningIcon({required this.icon, required this.color});

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _ctrl,
    child: Icon(widget.icon, color: widget.color, size: 36),
  );
}

// ── Last sync card ────────────────────────────────────────────────────────────

class _LastSyncCard extends StatelessWidget {
  final DateTime? lastSyncAt;

  const _LastSyncCard({this.lastSyncAt});

  @override
  Widget build(BuildContext context) {
    final label =
        lastSyncAt == null
            ? 'Nunca sincronizado'
            : _formatTimestamp(lastSyncAt!);

    return _InfoRow(
      icon: Icons.access_time_rounded,
      iconColor: const Color(0xFF007AFF),
      label: 'Última sincronización',
      value: label,
    );
  }

  static String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Hace unos segundos';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return 'Hace ${m == 1 ? '1 minuto' : '$m minutos'}';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return 'Hace ${h == 1 ? '1 hora' : '$h horas'}';
    }
    return DateFormat('d MMM, HH:mm', 'es').format(dt);
  }
}

// ── Stats card ────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final int pendingCount;
  final int failedCount;
  final int syncedCount;

  const _StatsCard({
    required this.pendingCount,
    required this.failedCount,
    required this.syncedCount,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        _StatRow(
          label: 'Sincronizados',
          count: syncedCount,
          color: const Color(0xFF34C759),
          icon: Icons.check_circle_outline_rounded,
        ),
        const Divider(height: 20),
        _StatRow(
          label: 'Pendientes',
          count: pendingCount,
          color: const Color(0xFFFF9500),
          icon: Icons.cloud_upload_outlined,
        ),
        if (failedCount > 0) ...[
          const Divider(height: 20),
          _StatRow(
            label: 'Con error',
            count: failedCount,
            color: const Color(0xFFFF3B30),
            icon: Icons.error_outline_rounded,
          ),
        ],
      ],
    ),
  );
}

class _StatRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatRow({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      Text(
        count.toString(),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: count > 0 ? color : Colors.grey.shade400,
        ),
      ),
    ],
  );
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    ),
  );
}

// ── Sync now button ───────────────────────────────────────────────────────────

class _SyncNowButton extends StatelessWidget {
  final bool isSyncing;
  final bool isOffline;

  const _SyncNowButton({required this.isSyncing, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    final disabled = isSyncing || isOffline;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed:
            disabled
                ? null
                : () => context.read<QuickFinanceBloc>().add(
                  const SyncTransactionsRequested(),
                ),
        icon:
            isSyncing
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.sync_rounded),
        label: Text(
          isSyncing
              ? 'Sincronizando…'
              : isOffline
              ? 'Sin conexión'
              : 'Sincronizar ahora',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
