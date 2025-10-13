import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:personal_finance/features/profile/logic/profile_logic.dart';
import 'package:personal_finance/features/profile/widgets/profile_view.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<ProfileLogic>(
    create: (_) => ProfileLogic()..loadProfile(),
    child: const ProfileView(),
  );
}
