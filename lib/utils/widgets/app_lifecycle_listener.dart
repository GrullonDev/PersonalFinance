import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';

class AppLifecycleWrapper extends StatefulWidget {
  const AppLifecycleWrapper({required this.child, super.key});

  final Widget child;

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Al volver a primer plano, intentar renovar sesión si es necesario
      final AuthProvider auth = context.read<AuthProvider>();
      auth.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
