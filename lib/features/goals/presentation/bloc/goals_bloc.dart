import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/core/error/failures.dart';

import 'package:personal_finance/features/goals/domain/entities/goal.dart';
import 'package:personal_finance/features/goals/domain/repositories/goal_repository.dart';

abstract class GoalsEvent extends Equatable {
  @override
  List<Object?> get props => <Object?>[];
}

class GoalsLoad extends GoalsEvent {}

class GoalCreate extends GoalsEvent {
  GoalCreate(this.payload);
  final Goal payload;
}

class GoalUpdate extends GoalsEvent {
  GoalUpdate(this.payload);
  final Goal payload;
}

class GoalDelete extends GoalsEvent {
  GoalDelete(this.id);
  final int id;
}

class GoalsState extends Equatable {
  const GoalsState({
    this.loading = false,
    this.error,
    this.items = const <Goal>[],
  });
  final bool loading;
  final String? error;
  final List<Goal> items;

  GoalsState copyWith({bool? loading, String? error, List<Goal>? items}) =>
      GoalsState(
        loading: loading ?? this.loading,
        error: error,
        items: items ?? this.items,
      );

  @override
  List<Object?> get props => <Object?>[loading, error, items];
}

class GoalsBloc extends Bloc<GoalsEvent, GoalsState> {
  GoalsBloc(this._repo) : super(const GoalsState()) {
    on<GoalsLoad>(_onLoad);
    on<GoalCreate>(_onCreate);
    on<GoalUpdate>(_onUpdate);
    on<GoalDelete>(_onDelete);
  }

  final GoalRepository _repo;

  Future<void> _onLoad(GoalsLoad event, Emitter<GoalsState> emit) async {
    emit(state.copyWith(loading: true));
    final Either<Failure, List<Goal>> r = await _repo.getGoals();
    r.fold(
      (Failure l) => emit(state.copyWith(loading: false, error: l.message)),
      (List<Goal> list) => emit(state.copyWith(loading: false, items: list)),
    );
  }

  Future<void> _onCreate(GoalCreate event, Emitter<GoalsState> emit) async {
    emit(state.copyWith(loading: true));
    final Either<Failure, Goal> r = await _repo.createGoal(event.payload);
    r.fold(
      (Failure l) => emit(state.copyWith(loading: false, error: l.message)),
      (Goal g) => emit(
        state.copyWith(
          loading: false,
          items: List<Goal>.from(state.items)..add(g),
        ),
      ),
    );
  }

  Future<void> _onUpdate(GoalUpdate event, Emitter<GoalsState> emit) async {
    emit(state.copyWith(loading: true));
    final Either<Failure, Goal> r = await _repo.updateGoal(event.payload);
    r.fold(
      (Failure l) => emit(state.copyWith(loading: false, error: l.message)),
      (Goal g) => emit(
        state.copyWith(
          loading: false,
          items: state.items.map((Goal e) => e.id == g.id ? g : e).toList(),
        ),
      ),
    );
  }

  Future<void> _onDelete(GoalDelete event, Emitter<GoalsState> emit) async {
    emit(state.copyWith(loading: true));
    final Either<Failure, void> r = await _repo.deleteGoal(event.id);
    r.fold(
      (Failure l) => emit(state.copyWith(loading: false, error: l.message)),
      (_) => emit(
        state.copyWith(
          loading: false,
          items: state.items.where((Goal e) => e.id != event.id).toList(),
        ),
      ),
    );
  }
}
