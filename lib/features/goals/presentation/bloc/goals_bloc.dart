import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/core/services/notifications/notification_service.dart';
import 'package:personal_finance/features/goals/domain/entities/goal.dart';
import 'package:personal_finance/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_finance/utils/currency_helper.dart';
import 'package:personal_finance/utils/routes/route_path.dart';

// ── Milestone helpers ────────────────────────────────────────────────────────

/// Returns the highest milestone (50, 60, 70, 80, 90, 100) just crossed,
/// or null if no milestone boundary was passed.
int? _crossedGoalMilestone(double oldPct, double newPct) {
  int? highest;
  for (final int m in const <int>[50, 60, 70, 80, 90, 100]) {
    if (oldPct < m && newPct >= m) highest = m;
  }
  return highest;
}

String _goalMilestoneTitle(int pct) {
  if (pct == 100) return '🏆 ¡Meta Completada!';
  if (pct >= 80) return '🔥 ¡Casi lo logras!';
  if (pct >= 60) return '💪 ¡Muy buen progreso!';
  return '🚀 ¡Vas a la mitad!';
}

String _goalMilestoneBody(int pct, String nombre, double current, double target) {
  final String curr = '${CurrencyHelper.symbol}${current.toStringAsFixed(0)}';
  final String tgt = '${CurrencyHelper.symbol}${target.toStringAsFixed(0)}';
  switch (pct) {
    case 100:
      return '¡Felicidades! Completaste tu meta "$nombre" ($curr). ¡Lo lograste! 🎉';
    case 90:
      return '¡Ya llevas el 90% de "$nombre"! ($curr / $tgt). Un último esfuerzo. ✨';
    case 80:
      return '¡Increíble! Tienes el 80% de "$nombre" ($curr / $tgt). ¡La recta final! 💪';
    case 70:
      return '¡70% completado de "$nombre"! ($curr / $tgt). Vas muy bien. 💚';
    case 60:
      return '¡Llevas el 60% de "$nombre"! ($curr / $tgt). Más de la mitad. 🌟';
    default:
      return '¡Ya llevas el 50% de "$nombre"! ($curr / $tgt). La mitad del camino. 🚀';
  }
}

// ── Events ───────────────────────────────────────────────────────────────────

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
  final String id;
}

// ── State ────────────────────────────────────────────────────────────────────

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

// ── BLoC ─────────────────────────────────────────────────────────────────────

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
      (Goal g) {
        emit(
          state.copyWith(
            loading: false,
            items: List<Goal>.from(state.items)..add(g),
          ),
        );
        try {
          final notif = GetIt.instance<NotificationService>();
          final double target = double.tryParse(g.montoObjetivo) ?? 0.0;
          notif.local.showNotification(
            id: g.id.hashCode,
            title: '🎯 ¡Meta de Ahorro Creada!',
            body: 'Has creado la meta "${g.nombre}" con un objetivo de ${CurrencyHelper.symbol}${target.toStringAsFixed(0)}. ¡Mucho éxito!',
            payload: RoutePath.goalsCrud,
          );
        } catch (_) {}
      },
    );
  }

  Future<void> _onUpdate(GoalUpdate event, Emitter<GoalsState> emit) async {
    // Capture old value before any state change so we can detect milestone crossings.
    Goal? oldGoal;
    try {
      oldGoal = state.items.firstWhere((Goal e) => e.id == event.payload.id);
    } catch (_) {}

    emit(state.copyWith(loading: true));
    final Either<Failure, Goal> r = await _repo.updateGoal(event.payload);
    r.fold(
      (Failure l) => emit(state.copyWith(loading: false, error: l.message)),
      (Goal g) {
        emit(
          state.copyWith(
            loading: false,
            items: state.items.map((Goal e) => e.id == g.id ? g : e).toList(),
          ),
        );
        try {
          final notif = GetIt.instance<NotificationService>();
          final double newAmount = double.tryParse(g.montoActual) ?? 0.0;
          final double target = double.tryParse(g.montoObjetivo) ?? 0.0;

          final double oldPct = (target > 0 && oldGoal != null)
              ? (oldGoal.actualAsDouble / target) * 100
              : 0;
          final double newPct =
              target > 0 ? (newAmount / target) * 100 : 0;

          if (oldPct < 100 && newPct >= 100) {
            notif.local.showNotification(
              id: g.id.hashCode,
              title: '🏆 ¡Meta Completada!',
              body: '¡Felicidades! Completaste tu meta "${g.nombre}" (${CurrencyHelper.symbol}${newAmount.toStringAsFixed(0)}). ¡Lo lograste! 🎉',
              payload: RoutePath.goalsCrud,
            );
          }
        } catch (_) {}
      },
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
