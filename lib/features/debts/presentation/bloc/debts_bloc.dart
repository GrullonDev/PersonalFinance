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
import 'package:personal_finance/utils/routes/route_path.dart';

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
  final String sym = CurrencyHelper.symbol;
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
      },
    );
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

          if (oldPaidPct < 100 && newPaidPct >= 100) {
            notif.local.showNotification(
              id: r.id.hashCode,
              title: '🎉 ¡Deuda Liquidada!',
              body: '¡Felicidades! Liquidaste completamente la deuda "${r.name}" (${CurrencyHelper.symbol}${r.originalAmount.toStringAsFixed(0)}). ¡Eres libre! 🎊',
              payload: RoutePath.debts,
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
