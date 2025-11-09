import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:personal_finance/core/network/api_service.dart';
import 'package:personal_finance/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:personal_finance/features/categories/data/repositories/category_repository_impl.dart';
import 'package:personal_finance/features/categories/domain/repositories/category_repository.dart';
import 'package:personal_finance/features/accounts/data/datasources/account_remote_data_source.dart';
import 'package:personal_finance/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:personal_finance/features/accounts/domain/repositories/account_repository.dart';
import 'package:personal_finance/features/alerts/domain/entities/alert_item.dart';
import 'package:personal_finance/features/auth/data/datasources/auth_backend_datasource.dart';
import 'package:personal_finance/features/auth/data/firebase_auth_service.dart';
import 'package:personal_finance/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:personal_finance/features/auth/domain/auth_datasource.dart';
import 'package:personal_finance/features/auth/domain/auth_repository.dart';
import 'package:personal_finance/features/dashboard/presentation/providers/dashboard_logic_v2.dart';
import 'package:personal_finance/features/data/model/expense.dart';
import 'package:personal_finance/features/data/model/income.dart';
import 'package:personal_finance/features/data/repositories/transaction_repository_impl.dart';
import 'package:personal_finance/features/domain/repositories/transaction_repository.dart';
import 'package:personal_finance/features/domain/usecases/add_transaction_usecase.dart';
import 'package:personal_finance/features/domain/usecases/get_dashboard_data_usecase.dart';
import 'package:personal_finance/features/budgets/data/datasources/budget_remote_data_source.dart';
import 'package:personal_finance/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:personal_finance/features/budgets/domain/repositories/budget_repository.dart';
import 'package:personal_finance/features/goals/data/datasources/goal_remote_data_source.dart';
import 'package:personal_finance/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:personal_finance/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_finance/features/profile/data/firebase_profile_service.dart';
import 'package:personal_finance/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:personal_finance/features/profile/data/repositories/profile_backend_repository_impl.dart';
import 'package:personal_finance/features/profile/domain/profile_datasource.dart';
import 'package:personal_finance/features/profile/domain/profile_repository.dart';
import 'package:personal_finance/features/profile/domain/repositories/profile_backend_repository.dart';
import 'package:personal_finance/features/transactions/data/datasources/transaction_remote_data_source.dart';
import 'package:personal_finance/features/transactions/data/repositories/transaction_repository_impl.dart'
    as new_transactions;
import 'package:personal_finance/features/transactions/domain/repositories/transaction_repository.dart'
    as new_transactions_repo;
import 'package:personal_finance/features/transactions/data/datasources/transaction_backend_remote_data_source.dart'
    as backend_tx_ds;
import 'package:personal_finance/features/transactions/data/repositories/transaction_backend_repository_impl.dart'
    as backend_tx_repo_impl;
import 'package:personal_finance/features/transactions/domain/repositories/transaction_backend_repository.dart'
    as backend_tx_repo;
import 'package:personal_finance/features/notifications/data/datasources/notification_remote_data_source.dart'
    as notif_ds;
import 'package:personal_finance/features/notifications/data/repositories/notification_repository_impl.dart'
    as notif_repo_impl;
import 'package:personal_finance/features/notifications/domain/repositories/notification_repository.dart'
    as notif_repo;

final GetIt getIt = GetIt.instance;

Future<void> initDependencies() async {
  // SharedPreferences
  if (!getIt.isRegistered<SharedPreferences>()) {
    final SharedPreferences sharedPrefs = await SharedPreferences.getInstance();
    getIt.registerLazySingleton<SharedPreferences>(() => sharedPrefs);
  }

  // ApiService
  if (!getIt.isRegistered<ApiService>()) {
    getIt.registerLazySingleton<ApiService>(
      () => ApiService(prefs: getIt<SharedPreferences>()),
    );
  }

  // AuthDataSource
  if (!getIt.isRegistered<AuthDataSource>()) {
    getIt.registerLazySingleton<AuthDataSource>(() => FirebaseAuthService());
  }

  // Auth Backend DataSource
  if (!getIt.isRegistered<AuthBackendDataSource>()) {
    getIt.registerLazySingleton<AuthBackendDataSource>(
      () => AuthBackendDataSource(getIt<ApiService>()),
    );
  }

  // AuthRepository
  if (!getIt.isRegistered<AuthRepository>()) {
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        getIt<AuthDataSource>(),
        getIt<AuthBackendDataSource>(),
      ),
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

  // Profile Backend Remote Data Source (FastAPI profiles/me)
  if (!getIt.isRegistered<ProfileRemoteDataSource>()) {
    getIt.registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSourceImpl(getIt<ApiService>()),
    );
  }

  // Profile Backend Repository
  if (!getIt.isRegistered<ProfileBackendRepository>()) {
    getIt.registerLazySingleton<ProfileBackendRepository>(
      () => ProfileBackendRepositoryImpl(getIt<ProfileRemoteDataSource>()),
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

  if (!getIt.isRegistered<Box<AlertItem>>()) {
    getIt.registerLazySingleton<Box<AlertItem>>(
      () => Hive.box<AlertItem>('alerts'),
    );
  }

  // New Transaction Data Source
  if (!getIt.isRegistered<TransactionRemoteDataSource>()) {
    getIt.registerLazySingleton<TransactionRemoteDataSource>(
      () => TransactionRemoteDataSourceImpl(getIt<ApiService>()),
    );
  }

  // Categories Data Source
  if (!getIt.isRegistered<CategoryRemoteDataSource>()) {
    getIt.registerLazySingleton<CategoryRemoteDataSource>(
      () => CategoryRemoteDataSourceImpl(getIt<ApiService>()),
    );
  }

  // Categories Repository
  if (!getIt.isRegistered<CategoryRepository>()) {
    getIt.registerLazySingleton<CategoryRepository>(
      () => CategoryRepositoryImpl(getIt<CategoryRemoteDataSource>()),
    );
  }

  // Budgets Data Source
  if (!getIt.isRegistered<BudgetRemoteDataSource>()) {
    getIt.registerLazySingleton<BudgetRemoteDataSource>(
      () => BudgetRemoteDataSourceImpl(getIt<ApiService>()),
    );
  }

  // Budgets Repository
  if (!getIt.isRegistered<BudgetRepository>()) {
    getIt.registerLazySingleton<BudgetRepository>(
      () => BudgetRepositoryImpl(getIt<BudgetRemoteDataSource>()),
    );
  }

  // Goals Data Source
  if (!getIt.isRegistered<GoalRemoteDataSource>()) {
    getIt.registerLazySingleton<GoalRemoteDataSource>(
      () => GoalRemoteDataSourceImpl(getIt<ApiService>()),
    );
  }

  // Goals Repository
  if (!getIt.isRegistered<GoalRepository>()) {
    getIt.registerLazySingleton<GoalRepository>(
      () => GoalRepositoryImpl(getIt<GoalRemoteDataSource>()),
    );
  }

  // New Transaction Repository
  if (!getIt.isRegistered<new_transactions_repo.TransactionRepository>()) {
    getIt.registerLazySingleton<new_transactions_repo.TransactionRepository>(
      () => new_transactions.TransactionRepositoryImpl(
        getIt<TransactionRemoteDataSource>(),
      ),
    );
  }

  // Backend Transactions Data Source (FastAPI endpoints)
  if (!getIt.isRegistered<backend_tx_ds.TransactionBackendRemoteDataSource>()) {
    getIt.registerLazySingleton<
      backend_tx_ds.TransactionBackendRemoteDataSource
    >(
      () => backend_tx_ds.TransactionBackendRemoteDataSourceImpl(
        getIt<ApiService>(),
      ),
    );
  }

  // Backend Transactions Repository
  if (!getIt.isRegistered<backend_tx_repo.TransactionBackendRepository>()) {
    getIt.registerLazySingleton<backend_tx_repo.TransactionBackendRepository>(
      () => backend_tx_repo_impl.TransactionBackendRepositoryImpl(
        getIt<backend_tx_ds.TransactionBackendRemoteDataSource>(),
      ),
    );
  }

  // Notifications Remote Data Source
  if (!getIt.isRegistered<notif_ds.NotificationRemoteDataSource>()) {
    getIt.registerLazySingleton<notif_ds.NotificationRemoteDataSource>(
      () => notif_ds.NotificationRemoteDataSourceImpl(getIt<ApiService>()),
    );
  }

  // Notifications Repository
  if (!getIt.isRegistered<notif_repo.NotificationRepository>()) {
    getIt.registerLazySingleton<notif_repo.NotificationRepository>(
      () => notif_repo_impl.NotificationRepositoryImpl(
        getIt<notif_ds.NotificationRemoteDataSource>(),
      ),
    );
  }

  // Account Data Source
  if (!getIt.isRegistered<AccountRemoteDataSource>()) {
    getIt.registerLazySingleton<AccountRemoteDataSource>(
      () => AccountRemoteDataSourceImpl(getIt<ApiService>()),
    );
  }

  // Account Repository
  if (!getIt.isRegistered<AccountRepository>()) {
    getIt.registerLazySingleton<AccountRepository>(
      () => AccountRepositoryImpl(getIt<AccountRemoteDataSource>()),
    );
  }

  // Old Transaction Repository (to be deprecated)
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
