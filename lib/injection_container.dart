import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/quick_finance/data/datasources/quick_finance_local_datasource.dart';
import 'features/quick_finance/data/datasources/quick_finance_remote_datasource.dart';
import 'features/quick_finance/data/models/transaction_model.dart';
import 'features/quick_finance/data/models/sync_operation_model.dart';
import 'features/quick_finance/data/repositories/quick_finance_repository_impl.dart';
import 'features/quick_finance/domain/repositories/quick_finance_repository.dart';
import 'features/quick_finance/domain/usecases/add_transaction.dart';
import 'features/quick_finance/domain/usecases/delete_transaction.dart';
import 'features/quick_finance/domain/usecases/sync_pending_transactions.dart';
import 'features/quick_finance/domain/usecases/update_transaction.dart';
import 'features/quick_finance/domain/usecases/watch_balance.dart';
import 'features/quick_finance/domain/usecases/watch_transactions.dart';
import 'features/quick_finance/presentation/bloc/quick_finance_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Quick Finance
  // Bloc
  sl.registerFactory(
    () => QuickFinanceBloc(
      addTransaction: sl(),
      deleteTransaction: sl(),
      watchBalance: sl(),
      watchTransactions: sl(),
      syncPendingTransactions: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => AddTransaction(sl()));
  sl.registerLazySingleton(() => DeleteTransaction(sl()));
  sl.registerLazySingleton(() => WatchBalance(sl()));
  sl.registerLazySingleton(() => WatchTransactions(sl()));
  sl.registerLazySingleton(() => SyncPendingTransactions(sl()));
  sl.registerLazySingleton(() => UpdateTransaction(sl()));

  // Repository
  sl.registerLazySingleton<QuickFinanceRepository>(
    () => QuickFinanceRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<QuickFinanceLocalDataSource>(
    () => QuickFinanceLocalDataSourceImpl(
      transactionBox: sl(),
      syncOperationBox: sl(),
    ),
  );

  sl.registerLazySingleton<QuickFinanceRemoteDataSource>(
    () => QuickFinanceRemoteDataSourceImpl(firestore: sl()),
  );

  // External
  final transactionBox = await Hive.openBox<TransactionModel>('transactions');
  final syncOperationBox = await Hive.openBox<SyncOperationModel>('sync_operations');
  
  sl.registerLazySingleton(() => transactionBox);
  sl.registerLazySingleton(() => syncOperationBox);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
}
