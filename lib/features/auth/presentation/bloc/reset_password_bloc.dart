import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

import 'package:personal_finance/features/auth/domain/auth_failure.dart';
import 'package:personal_finance/features/auth/domain/auth_repository.dart';

abstract class ResetPasswordEvent extends Equatable {
  @override
  List<Object?> get props => <Object?>[];
}

class ResetSubmitted extends ResetPasswordEvent {
  ResetSubmitted({required this.token, required this.newPassword, required this.confirmPassword});
  final String token;
  final String newPassword;
  final String confirmPassword;
}

class ToggleNewObscure extends ResetPasswordEvent {}
class ToggleConfirmObscure extends ResetPasswordEvent {}

class ResetPasswordState extends Equatable {
  const ResetPasswordState({this.loading = false, this.error, this.success = false, this.obscureNew = true, this.obscureConfirm = true});
  final bool loading;
  final String? error;
  final bool success;
  final bool obscureNew;
  final bool obscureConfirm;

  ResetPasswordState copyWith({bool? loading, String? error, bool? success, bool? obscureNew, bool? obscureConfirm}) => ResetPasswordState(
        loading: loading ?? this.loading,
        error: error,
        success: success ?? this.success,
        obscureNew: obscureNew ?? this.obscureNew,
        obscureConfirm: obscureConfirm ?? this.obscureConfirm,
      );

  @override
  List<Object?> get props => <Object?>[loading, error, success, obscureNew, obscureConfirm];
}

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  ResetPasswordBloc(this._repo) : super(const ResetPasswordState()) {
    on<ResetSubmitted>(_onSubmit);
    on<ToggleNewObscure>((e, emit) => emit(state.copyWith(obscureNew: !state.obscureNew)));
    on<ToggleConfirmObscure>((e, emit) => emit(state.copyWith(obscureConfirm: !state.obscureConfirm)));
  }

  final AuthRepository _repo;

  Future<void> _onSubmit(ResetSubmitted e, Emitter<ResetPasswordState> emit) async {
    emit(state.copyWith(loading: true, error: null, success: false));
    if (e.newPassword != e.confirmPassword) {
      emit(state.copyWith(loading: false, error: 'Las contraseñas no coinciden'));
      return;
    }
    final Either<AuthFailure, Unit> r = await _repo.resetPassword(
      token: e.token,
      newPassword: e.newPassword,
      confirmPassword: e.confirmPassword,
    );
    r.fold(
      (AuthFailure l) => emit(state.copyWith(loading: false, error: l.message, success: false)),
      (_) => emit(state.copyWith(loading: false, error: null, success: true)),
    );
  }
}

