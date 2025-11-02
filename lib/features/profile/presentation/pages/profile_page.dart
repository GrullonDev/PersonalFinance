import 'package:flutter/material.dart';
import 'package:personal_finance/features/profile/presentation/providers/profile_logic.dart';
import 'package:personal_finance/features/profile/presentation/widgets/profile_view.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<ProfileLogic>(
    create: (_) => ProfileLogic()..loadProfile(),
    child: const ProfileView(),
  );
}
