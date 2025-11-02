import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:personal_finance/features/profile/presentation/widgets/profile_view.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/features/profile/domain/repositories/profile_backend_repository.dart';
import 'package:personal_finance/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:personal_finance/features/profile/data/repositories/profile_backend_repository_impl.dart';
import 'package:personal_finance/core/network/api_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<ProfileBloc>(
        create: (_) {
          final ProfileBackendRepository repo =
              getIt.isRegistered<ProfileBackendRepository>()
                  ? getIt<ProfileBackendRepository>()
                  : ProfileBackendRepositoryImpl(
                      ProfileRemoteDataSourceImpl(getIt<ApiService>()),
                    );
          return ProfileBloc(repo)..add(ProfileLoadMe());
        },
        child: const ProfileView(),
      );
}
