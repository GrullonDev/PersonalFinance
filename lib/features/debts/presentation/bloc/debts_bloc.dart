import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/core/services/notifications/notification_service.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';
import 'package:personal_finance/features/debts/domain/repositories/debt_repository.dart';
import 'package:personal_finance/features/debts/presentation/bloc/debts_event.dart';
import 'package:personal_finance/features/debts/presentation/bloc/debts_state.dart';
import 'package:personal_finance/utils/currency_helper.dart';

// ── Milestone helpers ────────────────────────────────────────────────────────

/// Returns the highest debt-paid milestone (80, 100) just crossed, or null.
int? _crossedDebtMilestone(double oldPaidPct, double newPaidPct) {
  int? highest;
  for (final int m in const <int>[80, 100]) {
    if (oldPaidPct < m && newPaidPct >= m) highest = m;
  }
  return highest;
}

String _debtMilestoneTitle(int pct) =>
    pct == 100 ? '🎉 ¡Deuda Liquidada!' : '💪 ¡80% de la deuda pagado!';

String _debtMilestoneBody(int pct, String nombre, double balance, double original) {
  const String sym = CurrencyHelper.symbol;
  if (pct == 100) {
    return '¡Felicidades! Liquidaste completamente la deuda "$nombre" ($sym${original.toStringAsFixed(0)}). ¡Eres libre! 🎊';
  }
  return '¡Increíble! Ya pagaste el 80% de "$nombre". Solo te quedan $sym${balance.toStringAsFixed(0)} de $sym${original.toStringAsFixed(0)}. ¡La recta final! 🔥';
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class DebtsBloc extends Bloc<DebtsEvent, DebtsState> {
  final DebtRepository _repo;

  DebtsBloc(this._repo) : super(const DebtsState()) {
    on<DebtsLoad>(_onLoad);
    on<DebtCreate>(_onCreate);
    on<DebtUpdate>(_onUpdate);
    on<DebtDelete>(_onDelete);
  }

  Future<void> _onLoad(DebtsLoad event, Emitter<DebtsState> emit) async {
    emit(state.copyWith(loading: true));
    final Either<Failure, List<Debt>> res = await _repo.getDebts();
    res.fold(
      (Failure l) => emit(state.copyWith(loading: false, error: l.message)),
      (List<Debt> r) {
        emit(state.copyWith(loading: false, items: r));
        _scheduleUpcomingPaymentReminders(r);
      },
    );
  }

  void _scheduleUpcomingPaymentReminders(List<Debt> debts) {
    try {
      final notif = GetIt.instance<NotificationService>();
      for (final Debt d in debts) {
        notif.scheduleDebtPaymentReminder(
          debtId: d.id,
          debtName: d.name,
          paymentDate: d.nextPaymentDate,
          minimumPayment: d.minimumPayment,
        );
      }
    } catch (_) {}
  }

  Future<void> _onCreate(DebtCreate event, Emitter<DebtsState> emit) async {
    emit(state.copyWith(loading: true));
    final Either<Failure, Debt> res = await _repo.createDebt(event.debt);
    res.fold(
      (Failure l) => emit(state.copyWith(loading: false, error: l.message)),
      (Debt r) {
        emit(
          state.copyWith(
            loading: false,
            items: List<Debt>.from(state.items)..add(r),
          ),
        );
        try {
          final notif = GetIt.instance<NotificationService>();
          notif.local.showNotification(
            id: r.id.hashCode,
            title: '📉 ¡Deuda Registrada!',
            body:
                'Has registrado la deuda "${r.name}" con un saldo de ${CurrencyHelper.symbol}${r.currentBalance.toStringAsFixed(0)}. Sigue tu plan de pagos.',
          );
          notif.scheduleDebtPaymentReminder(
            debtId: r.id,
            debtName: r.name,
            paymentDate: r.nextPaymentDate,
            minimumPayment: r.minimumPayment,
          );
        } catch (_) {}
      },
    );
  }

  Future<void> _onUpdate(DebtUpdate event, Emitter<DebtsState> emit) async {
    // Capture old value before any state change so we can detect milestone crossings.
    Debt? oldDebt;
    try {
      oldDebt = state.items.firstWhere((Debt b) => b.id == event.debt.id);
    } catch (_) {}

    emit(state.copyWith(loading: true));
    final Either<Failure, Debt> res = await _repo.updateDebt(event.debt);
    res.fold(
      (Failure l) => emit(state.copyWith(loading: false, error: l.message)),
      (Debt r) {
        emit(
          state.copyWith(
            loading: false,
            items: state.items.map((Debt b) => b.id == r.id ? r : b).toList(),
          ),
        );
        try {
          final notif = GetIt.instance<NotificationService>();

          final double oldPaidPct = (oldDebt != null && oldDebt.originalAmount > 0)
              ? (1 - oldDebt.currentBalance / oldDebt.originalAmount) * 100
              : 0;
          final double newPaidPct = r.originalAmount > 0
              ? (1 - r.currentBalance / r.originalAmount) * 100
              : 0;

          final int? milestone = _crossedDebtMilestone(oldPaidPct, newPaidPct);

          if (milestone != null) {
            notif.local.showNotification(
              id: r.id.hashCode,
              title: _debtMilestoneTitle(milestone),
              body: _debtMilestoneBody(
                  milestone, r.name, r.currentBalance, r.originalAmount),
            );
          } else {
            notif.local.showNotification(
              id: r.id.hashCode,
              title: '🔄 Deuda Actualizada',
              body:
                  'Tu deuda "${r.name}" ha sido actualizada. Saldo actual: ${CurrencyHelper.symbol}${r.currentBalance.toStringAsFixed(0)}.',
            );
          }
        } catch (_) {}
      },
    );
  }

  Future<void> _onDelete(DebtDelete event, Emitter<DebtsState> emit) async {
    emit(state.copyWith(loading: true));
    final Either<Failure, void> res = await _repo.deleteDebt(event.debtId);
    res.fold(
      (Failure l) => emit(state.copyWith(loading: false, error: l.message)),
      (_) => emit(
        state.copyWith(
          loading: false,
          items:
              state.items.where((Debt b) => b.id != event.debtId).toList(),
        ),
      ),
    );
  }
}
