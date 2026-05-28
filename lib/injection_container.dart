import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:personal_finance/core/security/hive_encryption_service.dart';
import 'package:personal_finance/features/quick_finance/data/datasources/quick_finance_local_datasource.dart';
import 'package:personal_finance/features/quick_finance/data/datasources/quick_finance_local_datasource_impl.dart';
import 'package:personal_finance/features/quick_finance/data/datasources/quick_finance_remote_datasource.dart';
import 'package:personal_finance/features/quick_finance/data/datasources/quick_finance_remote_datasource_impl.dart';
import 'package:personal_finance/features/quick_finance/data/models/transaction_model.dart';
import 'package:personal_finance/features/quick_finance/data/models/sync_operation_model.dart';
import 'package:personal_finance/features/quick_finance/data/repositories/quick_finance_repository_impl.dart';
import 'package:personal_finance/features/quick_finance/data/sync/sync_manager.dart';
import 'package:personal_finance/features/quick_finance/domain/repositories/quick_finance_repository.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/add_transaction.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/delete_transaction.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/hydrate_current_user_transactions.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/update_transaction.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/watch_balance.dart';
import 'package:personal_finance/features/quick_finance/domain/usecases/watch_transactions.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_bloc.dart';
import 'package:personal_finance/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_finance/features/debts/domain/repositories/debt_repository.dart';

final sl = GetIt.instance;

Future<void> init(HiveAesCipher hiveCipher) async {
  // -------------------------------------------------------------------------
  // External
  // -------------------------------------------------------------------------

  final transactionBox =
      await HiveEncryptionService.openBoxSafe<TransactionModel>(
        'transactions',
        hiveCipher,
      );
  final syncOperationBox =
      await HiveEncryptionService.openBoxSafe<SyncOperationModel>(
        'sync_operations',
        hiveCipher,
      );

  sl.registerLazySingleton(() => transactionBox);
  sl.registerLazySingleton(() => syncOperationBox);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);

  // -------------------------------------------------------------------------
  // Data sources
  // -------------------------------------------------------------------------

  sl.registerLazySingleton<QuickFinanceLocalDataSource>(
    () => QuickFinanceLocalDataSourceImpl(
      transactionBox: sl(),
      syncOperationBox: sl(),
    ),
  );

  sl.registerLazySingleton<QuickFinanceRemoteDataSource>(
    () => QuickFinanceRemoteDataSourceImpl(firestore: sl()),
  );

  // -------------------------------------------------------------------------
  // SyncManager
  // -------------------------------------------------------------------------

  sl.registerLazySingleton(
    () => SyncManager(localDataSource: sl(), remoteDataSource: sl()),
  );

  // -------------------------------------------------------------------------
  // Repository
  // -------------------------------------------------------------------------

  sl.registerLazySingleton<QuickFinanceRepository>(
    () => QuickFinanceRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );

  // -------------------------------------------------------------------------
  // Use cases
  // -------------------------------------------------------------------------

  sl.registerLazySingleton(() => AddTransaction(sl()));
  sl.registerLazySingleton(() => DeleteTransaction(sl()));
  sl.registerLazySingleton(() => HydrateCurrentUserTransactions(sl()));
  sl.registerLazySingleton(() => WatchBalance(sl()));
  sl.registerLazySingleton(() => WatchTransactions(sl()));
  sl.registerLazySingleton(() => UpdateTransaction(sl()));

  // -------------------------------------------------------------------------
  // Bloc
  // -------------------------------------------------------------------------

  sl.registerFactory(
    () => QuickFinanceBloc(
      addTransaction: sl(),
      deleteTransaction: sl(),
      // AuthDataSource ya registrado por old_di.initDependencies() (mismo
      // GetIt.instance) — mvp_di.init() se llama después, por lo que sl<AuthDataSource>()
      // resuelve correctamente en el momento de construir el Bloc.
      hydrateCurrentUserTransactions: sl(),
      watchBalance: sl(),
      watchTransactions: sl(),
      updateTransaction: sl(),
      syncManager: sl(),
      authDataSource: sl(),
      goalRepository: sl<GoalRepository>(),
      debtRepository: sl<DebtRepository>(),
    ),
  );
}
