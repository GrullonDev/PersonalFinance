import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:personal_finance/features/profile/presentation/widgets/profile_view.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/features/profile/domain/repositories/profile_backend_repository.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<ProfileBloc>(
    create:
        (_) =>
            ProfileBloc(getIt<ProfileBackendRepository>())
              ..add(ProfileLoadMe()),
    child: const ProfileView(),
  );
}
