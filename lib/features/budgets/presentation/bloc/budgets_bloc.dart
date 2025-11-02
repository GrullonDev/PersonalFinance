import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:personal_finance/features/budgets/domain/repositories/budget_repository.dart';
import 'package:personal_finance/features/budgets/domain/entities/budget.dart';

abstract class BudgetsEvent extends Equatable {
  @override
  List<Object?> get props => <Object?>[];
}

class BudgetsLoad extends BudgetsEvent {}

class BudgetCreate extends BudgetsEvent {
  BudgetCreate(this.payload);
  final Budget payload;
}

class BudgetUpdate extends BudgetsEvent {
  BudgetUpdate(this.payload);
  final Budget payload;
}

class BudgetDelete extends BudgetsEvent {
  BudgetDelete(this.id);
  final int id;
}

class BudgetsState extends Equatable {
  const BudgetsState({
    this.loading = false,
    this.error,
    this.items = const <Budget>[],
  });
  final bool loading;
  final String? error;
  final List<Budget> items;

  BudgetsState copyWith({bool? loading, String? error, List<Budget>? items}) =>
      BudgetsState(
        loading: loading ?? this.loading,
        error: error,
        items: items ?? this.items,
      );

  @override
  List<Object?> get props => <Object?>[loading, error, items];
}

class BudgetsBloc extends Bloc<BudgetsEvent, BudgetsState> {
  BudgetsBloc(this._repo) : super(const BudgetsState()) {
    on<BudgetsLoad>(_onLoad);
    on<BudgetCreate>(_onCreate);
    on<BudgetUpdate>(_onUpdate);
    on<BudgetDelete>(_onDelete);
  }

  final BudgetRepository _repo;

  Future<void> _onLoad(BudgetsLoad event, Emitter<BudgetsState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    final res = await _repo.getBudgets();
    res.fold(
      (l) => emit(state.copyWith(loading: false, error: l.message)),
      (r) => emit(state.copyWith(loading: false, items: r)),
    );
  }

  Future<void> _onCreate(BudgetCreate event, Emitter<BudgetsState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    final res = await _repo.createBudget(event.payload);
    res.fold(
      (l) => emit(state.copyWith(loading: false, error: l.message)),
      (r) => emit(
        state.copyWith(
          loading: false,
          items: List<Budget>.from(state.items)..add(r),
        ),
      ),
    );
  }

  Future<void> _onUpdate(BudgetUpdate event, Emitter<BudgetsState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    final res = await _repo.updateBudget(event.payload);
    res.fold(
      (l) => emit(state.copyWith(loading: false, error: l.message)),
      (r) => emit(
        state.copyWith(
          loading: false,
          items: state.items.map((b) => b.id == r.id ? r : b).toList(),
        ),
      ),
    );
  }

  Future<void> _onDelete(BudgetDelete event, Emitter<BudgetsState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    final res = await _repo.deleteBudget(event.id);
    res.fold(
      (l) => emit(state.copyWith(loading: false, error: l.message)),
      (_) => emit(
        state.copyWith(
          loading: false,
          items: state.items.where((b) => b.id != event.id).toList(),
        ),
      ),
    );
  }
}
