import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:personal_finance/features/auth/data/firebase_auth_service.dart';
import 'package:personal_finance/features/auth/domain/auth_datasource.dart';
import 'package:personal_finance/features/auth/domain/auth_repository.dart';
import 'package:personal_finance/features/auth/logic/auth_provider.dart';

final GetIt getIt = GetIt.instance;

Future<void> initDependencies() async {
  // SharedPreferences
  if (!getIt.isRegistered<SharedPreferences>()) {
    final SharedPreferences sharedPrefs = await SharedPreferences.getInstance();
    getIt.registerLazySingleton<SharedPreferences>(() => sharedPrefs);
  }

  // AuthDataSource
  if (!getIt.isRegistered<AuthDataSource>()) {
    getIt.registerLazySingleton<AuthDataSource>(() => FirebaseAuthService());
  }

  // AuthRepository
  if (!getIt.isRegistered<AuthRepository>()) {
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt<AuthDataSource>()),
    );
  }

  // AuthProvider
  if (!getIt.isRegistered<AuthProvider>()) {
    getIt.registerFactory<AuthProvider>(
      () => AuthProvider(authRepository: getIt()),
    );
  }
}
