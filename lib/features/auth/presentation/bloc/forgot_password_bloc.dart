import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

import 'package:personal_finance/features/auth/domain/auth_failure.dart';
import 'package:personal_finance/features/auth/domain/auth_repository.dart';

abstract class ForgotPasswordEvent extends Equatable {
  @override
  List<Object?> get props => <Object?>[];
}

class ForgotSubmitted extends ForgotPasswordEvent {
  ForgotSubmitted(this.email);
  final String email;
}

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.loading = false,
    this.error,
    this.success = false,
  });
  final bool loading;
  final String? error;
  final bool success;

  ForgotPasswordState copyWith({bool? loading, String? error, bool? success}) =>
      ForgotPasswordState(
        loading: loading ?? this.loading,
        error: error,
        success: success ?? this.success,
      );

  @override
  List<Object?> get props => <Object?>[loading, error, success];
}

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc(this._repo) : super(const ForgotPasswordState()) {
    on<ForgotSubmitted>(_onSubmit);
  }

  final AuthRepository _repo;

  Future<void> _onSubmit(
    ForgotSubmitted e,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(state.copyWith(loading: true, success: false));
    final Either<AuthFailure, Unit> r = await _repo.recoverPassword(e.email);
    r.fold(
      (AuthFailure l) => emit(
        state.copyWith(loading: false, error: l.message, success: false),
      ),
      (_) => emit(state.copyWith(loading: false, success: true)),
    );
  }
}
