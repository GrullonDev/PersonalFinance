import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:personal_finance/bootstrap.dart';

Future<void> main() async {
  const String env = String.fromEnvironment(
    'ENV',
    defaultValue: kReleaseMode ? 'production' : 'development',
  );
  await bootstrap(env: env);
}
