import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/core/error/failures.dart';

import 'package:personal_finance/features/transactions/domain/entities/transaction_backend.dart';
import 'package:personal_finance/features/transactions/domain/repositories/transaction_backend_repository.dart';

abstract class TransactionsEvent extends Equatable {
  @override
  List<Object?> get props => <Object?>[];
}

class TransactionsLoad extends TransactionsEvent {
  TransactionsLoad({this.desde, this.hasta, this.categoriaId, this.tipo});
  final DateTime? desde;
  final DateTime? hasta;
  final int? categoriaId;
  final String? tipo;
}

class TransactionCreate extends TransactionsEvent {
  TransactionCreate(this.payload);
  final TransactionBackend payload;
}

class TransactionUpdate extends TransactionsEvent {
  TransactionUpdate(this.payload);
  final TransactionBackend payload;
}

class TransactionDelete extends TransactionsEvent {
  TransactionDelete(this.id);
  final int id;
}

class TransactionsState extends Equatable {
  const TransactionsState({
    this.loading = false,
    this.error,
    this.items = const <TransactionBackend>[],
    this.desde,
    this.hasta,
    this.categoriaId,
    this.tipo,
  });
  final bool loading;
  final String? error;
  final List<TransactionBackend> items;
  final DateTime? desde;
  final DateTime? hasta;
  final int? categoriaId;
  final String? tipo;

  TransactionsState copyWith({
    bool? loading,
    String? error,
    List<TransactionBackend>? items,
    DateTime? desde,
    DateTime? hasta,
    int? categoriaId,
    String? tipo,
  }) => TransactionsState(
    loading: loading ?? this.loading,
    error: error,
    items: items ?? this.items,
    desde: desde ?? this.desde,
    hasta: hasta ?? this.hasta,
    categoriaId: categoriaId ?? this.categoriaId,
    tipo: tipo ?? this.tipo,
  );

  @override
  List<Object?> get props => <Object?>[
    loading,
    error,
    items,
    desde,
    hasta,
    categoriaId,
    tipo,
  ];
}

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  TransactionsBloc(this._repo) : super(const TransactionsState()) {
    on<TransactionsLoad>(_onLoad);
    on<TransactionCreate>(_onCreate);
    on<TransactionUpdate>(_onUpdate);
    on<TransactionDelete>(_onDelete);
  }
  final TransactionBackendRepository _repo;

  Future<void> _onLoad(
    TransactionsLoad e,
    Emitter<TransactionsState> emit,
  ) async {
    emit(
      state.copyWith(
        loading: true,
        desde: e.desde ?? state.desde,
        hasta: e.hasta ?? state.hasta,
        categoriaId: e.categoriaId ?? state.categoriaId,
        tipo: e.tipo ?? state.tipo,
      ),
    );
    final Either<Failure, List<TransactionBackend>> r = await _repo.list(
      fechaDesde: e.desde ?? state.desde,
      fechaHasta: e.hasta ?? state.hasta,
      categoriaId: e.categoriaId ?? state.categoriaId,
      tipo: e.tipo ?? state.tipo,
    );
    r.fold(
      (Failure l) => emit(state.copyWith(loading: false, error: l.message)),
      (List<TransactionBackend> list) =>
          emit(state.copyWith(loading: false, items: list)),
    );
  }

  Future<void> _onCreate(
    TransactionCreate e,
    Emitter<TransactionsState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    final Either<Failure, TransactionBackend> r = await _repo.create(e.payload);
    r.fold(
      (Failure l) => emit(state.copyWith(loading: false, error: l.message)),
      (TransactionBackend t) => emit(
        state.copyWith(
          loading: false,
          items: <TransactionBackend>[t, ...state.items],
        ),
      ),
    );
  }

  Future<void> _onUpdate(
    TransactionUpdate e,
    Emitter<TransactionsState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    final Either<Failure, TransactionBackend> r = await _repo.update(e.payload);
    r.fold(
      (Failure l) => emit(state.copyWith(loading: false, error: l.message)),
      (TransactionBackend t) => emit(
        state.copyWith(
          loading: false,
          items:
              state.items
                  .map((TransactionBackend i) => i.id == t.id ? t : i)
                  .toList(),
        ),
      ),
    );
  }

  Future<void> _onDelete(
    TransactionDelete e,
    Emitter<TransactionsState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    final Either<Failure, void> r = await _repo.delete(e.id);
    r.fold(
      (Failure l) => emit(state.copyWith(loading: false, error: l.message)),
      (_) => emit(
        state.copyWith(
          loading: false,
          items:
              state.items
                  .where((TransactionBackend i) => i.id != e.id)
                  .toList(),
        ),
      ),
    );
  }
}
