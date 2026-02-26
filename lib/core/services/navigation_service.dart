import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> navigateTo(String routeName, {Object? arguments}) => navigatorKey.currentState!.pushNamed(
      routeName,
      arguments: arguments,
    );

  void goBack() => navigatorKey.currentState!.pop();
}
