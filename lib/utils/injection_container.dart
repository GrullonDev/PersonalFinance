import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:personal_finance/features/auth/data/firebase_auth_service.dart';
import 'package:personal_finance/features/auth/domain/auth_datasource.dart';
import 'package:personal_finance/features/auth/domain/auth_repository.dart';
import 'package:personal_finance/features/dashboard/logic/dashboard_logic_v2.dart';
import 'package:personal_finance/features/data/model/expense.dart';
import 'package:personal_finance/features/data/model/income.dart';
import 'package:personal_finance/features/data/repositories/transaction_repository_impl.dart';
import 'package:personal_finance/features/domain/repositories/transaction_repository.dart';
import 'package:personal_finance/features/domain/usecases/add_transaction_usecase.dart';
import 'package:personal_finance/features/domain/usecases/get_dashboard_data_usecase.dart';
import 'package:personal_finance/features/profile/data/firebase_profile_service.dart';
import 'package:personal_finance/features/profile/domain/profile_datasource.dart';
import 'package:personal_finance/features/profile/domain/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Profile DataSource
  if (!getIt.isRegistered<ProfileDataSource>()) {
    getIt.registerLazySingleton<ProfileDataSource>(
      () => FirebaseProfileService(),
    );
  }

  // Profile Repository
  if (!getIt.isRegistered<ProfileRepository>()) {
    getIt.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(getIt<ProfileDataSource>()),
    );
  }

  // AuthProvider
  /*   if (!getIt.isRegistered<AuthProvider>()) {
    getIt.registerFactory<AuthProvider>(
      () => AuthProvider(authRepository: getIt<AuthRepository>()),
    );
  } */

  // Hive Boxes
  if (!getIt.isRegistered<Box<Expense>>()) {
    getIt.registerLazySingleton<Box<Expense>>(
      () => Hive.box<Expense>('expenses'),
    );
  }

  if (!getIt.isRegistered<Box<Income>>()) {
    getIt.registerLazySingleton<Box<Income>>(() => Hive.box<Income>('incomes'));
  }

  // Transaction Repository
  if (!getIt.isRegistered<TransactionRepository>()) {
    getIt.registerLazySingleton<TransactionRepository>(
      () => TransactionRepositoryImpl(
        getIt<Box<Expense>>(),
        getIt<Box<Income>>(),
      ),
    );
  }

  // Use Cases
  if (!getIt.isRegistered<GetDashboardDataUseCase>()) {
    getIt.registerLazySingleton<GetDashboardDataUseCase>(
      () => GetDashboardDataUseCase(getIt<TransactionRepository>()),
    );
  }

  if (!getIt.isRegistered<AddTransactionUseCase>()) {
    getIt.registerLazySingleton<AddTransactionUseCase>(
      () => AddTransactionUseCase(getIt<TransactionRepository>()),
    );
  }

  // Dashboard Logic V2
  if (!getIt.isRegistered<DashboardLogicV2>()) {
    getIt.registerLazySingleton<DashboardLogicV2>(
      () => DashboardLogicV2(
        getDashboardDataUseCase: getIt<GetDashboardDataUseCase>(),
        addTransactionUseCase: getIt<AddTransactionUseCase>(),
      ),
    );
  }
}
