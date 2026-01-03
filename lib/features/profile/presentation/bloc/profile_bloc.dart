import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/core/error/failures.dart';

import 'package:personal_finance/features/profile/domain/entities/profile_info.dart';
import 'package:personal_finance/features/profile/domain/repositories/profile_backend_repository.dart';

// Events
abstract class ProfileEvent extends Equatable {
  @override
  List<Object?> get props => <Object?>[];
}

class ProfileLoadMe extends ProfileEvent {}

// State
class ProfileState extends Equatable {
  const ProfileState({this.loading = false, this.error, this.info});

  final bool loading;
  final String? error;
  final ProfileInfo? info;

  ProfileState copyWith({bool? loading, String? error, ProfileInfo? info}) =>
      ProfileState(
        loading: loading ?? this.loading,
        error: error,
        info: info ?? this.info,
      );

  @override
  List<Object?> get props => <Object?>[loading, error, info ?? ''];
}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._repo) : super(const ProfileState()) {
    on<ProfileLoadMe>(_onLoadMe);
  }

  final ProfileBackendRepository _repo;

  Future<void> _onLoadMe(
    ProfileLoadMe event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    final Either<Failure, ProfileInfo> res = await _repo.getMe();
    res.fold(
      (Failure l) => emit(state.copyWith(loading: false, error: l.message)),
      (ProfileInfo r) => emit(state.copyWith(loading: false, info: r)),
    );
  }
}
