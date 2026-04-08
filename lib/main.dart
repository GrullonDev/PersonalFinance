import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:personal_finance/firebase_options.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import 'package:personal_finance/features/alerts/domain/entities/alert_item.dart';
import 'package:personal_finance/features/data/model/expense.dart';
import 'package:personal_finance/features/data/model/income.dart';
import 'package:personal_finance/utils/injection_container.dart' as old_di;
import 'package:personal_finance/injection_container.dart' as mvp_di;
import 'package:personal_finance/utils/offline_sync_service.dart';
import 'package:personal_finance/utils/pending_action.dart';
import 'package:personal_finance/features/quick_finance/presentation/pages/quick_finance_home_page.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Settings or other init logic can go here if needed

  // Establece la configuración regional predeterminada según el dispositivo
  final Locale deviceLocale = ui.PlatformDispatcher.instance.locale;
  Intl.defaultLocale = deviceLocale.toLanguageTag();

  // Inicializa Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseAdapter());
  await Hive.openBox<Expense>('expenses');
  Hive.registerAdapter(IncomeAdapter());
  await Hive.openBox<Income>('incomes');
  Hive.registerAdapter(AlertItemAdapter());
  await Hive.openBox<AlertItem>('alerts');
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(PendingActionAdapter());
  }
  await OfflineSyncService().init();

  // Inicializa Firebase con las opciones generadas por FlutterFire
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configura dependencias (Old Architecture)
  await old_di.initDependencies();

  // Configura dependencias (New MVP Architecture)
  await mvp_di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => GetIt.instance<QuickFinanceBloc>(),
    child: MaterialApp(
      title: 'Personal Finance MVP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0E8F5B),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E8F5B)),
        useMaterial3: true,
      ),
      home: const QuickFinanceHomePage(),
    ),
  );
}
