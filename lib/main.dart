import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:personal_finance/features/data/model/expense.dart';
import 'package:personal_finance/features/data/model/income.dart';
import 'package:personal_finance/utils/app.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'utils/offline_sync_service.dart';
import 'package:personal_finance/utils/pending_action.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseAdapter());
  await Hive.openBox<Expense>('expenses');
  Hive.registerAdapter(IncomeAdapter());
  await Hive.openBox<Income>('incomes');
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(PendingActionAdapter());
  }
  await OfflineSyncService().init();

  // Inicializa Firebase
  await Firebase.initializeApp();

  // Configura dependencias
  await initDependencies();

  runApp(const MyApp());
}
