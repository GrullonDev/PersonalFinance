import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';
import 'package:personal_finance/features/debts/domain/repositories/debt_repository.dart';
import 'package:personal_finance/features/debts/presentation/bloc/debts_event.dart';
import 'package:personal_finance/features/debts/presentation/bloc/debts_state.dart';

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
      (List<Debt> r) => emit(state.copyWith(loading: false, items: r)),
    );
  }

  Future<void> _onCreate(DebtCreate event, Emitter<DebtsState> emit) async {
    emit(state.copyWith(loading: true));
    final Either<Failure, Debt> res = await _repo.createDebt(event.debt);
    res.fold(
      (Failure l) => emit(state.copyWith(loading: false, error: l.message)),
      (Debt r) => emit(
        state.copyWith(
          loading: false,
          items: List<Debt>.from(state.items)..add(r),
        ),
      ),
    );
  }

  Future<void> _onUpdate(DebtUpdate event, Emitter<DebtsState> emit) async {
    emit(state.copyWith(loading: true));
    final Either<Failure, Debt> res = await _repo.updateDebt(event.debt);
    res.fold(
      (Failure l) => emit(state.copyWith(loading: false, error: l.message)),
      (Debt r) => emit(
        state.copyWith(
          loading: false,
          items: state.items.map((Debt b) => b.id == r.id ? r : b).toList(),
        ),
      ),
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
          items: state.items.where((Debt b) => b.id != event.debtId).toList(),
        ),
      ),
    );
  }
}
