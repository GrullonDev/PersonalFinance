import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:personal_finance/firebase_options.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:personal_finance/features/alerts/domain/entities/alert_item.dart';
import 'package:personal_finance/features/data/model/expense.dart';
import 'package:personal_finance/features/data/model/income.dart';
import 'package:personal_finance/utils/injection_container.dart' as old_di;
import 'package:personal_finance/injection_container.dart' as mvp_di;
import 'package:personal_finance/utils/offline_sync_service.dart';
import 'package:personal_finance/utils/pending_action.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/data/models/transaction_model.dart';
import 'package:personal_finance/features/quick_finance/data/models/sync_operation_model.dart';
import 'package:personal_finance/features/quick_finance/presentation/pages/quick_finance_home_page.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

Future<void> main() async {
  runZonedGuarded<Future<void>>(
    () async {
      try {
        WidgetsFlutterBinding.ensureInitialized();

        // Manejar posibles errores con el Locale nativo en iOS
        try {
          final Locale deviceLocale = ui.PlatformDispatcher.instance.locale;
          Intl.defaultLocale = deviceLocale.toLanguageTag();
          await initializeDateFormatting(Intl.defaultLocale);
        } catch (locErr) {
          debugPrint('Error al inicializar Locale: $locErr');
          await initializeDateFormatting('en_US'); // Fallback
        }

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

        // Registra adapters del MVP (quick_finance feature)
        if (!Hive.isAdapterRegistered(TransactionTypeAdapter().typeId)) {
          Hive.registerAdapter(TransactionTypeAdapter());
        }
        if (!Hive.isAdapterRegistered(SyncStatusAdapter().typeId)) {
          Hive.registerAdapter(SyncStatusAdapter());
        }
        if (!Hive.isAdapterRegistered(SyncActionAdapter().typeId)) {
          Hive.registerAdapter(SyncActionAdapter());
        }
        if (!Hive.isAdapterRegistered(TransactionModelAdapter().typeId)) {
          Hive.registerAdapter(TransactionModelAdapter());
        }
        if (!Hive.isAdapterRegistered(SyncOperationModelAdapter().typeId)) {
          Hive.registerAdapter(SyncOperationModelAdapter());
        }

        // Inicializa Firebase con las opciones generadas por FlutterFire
        try {
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
          }
        } catch (e) {
          if (e.toString().contains('duplicate-app')) {
            debugPrint('Firebase ya está inicializado.');
          } else {
            debugPrint('Error al inicializar Firebase: $e');
            // No hacemos rethrow para no causar pantalla blanca y permitir arrancar en modo offline
          }
        }

        // Configura dependencias (Old Architecture)
        await old_di.initDependencies();

        // Configura dependencias (New MVP Architecture)
        await mvp_di.init();

        runApp(const MyApp());
      } catch (e, stackTrace) {
        debugPrint('Error fatal durante la inicialización: $e\n$stackTrace');

        // Fallback UI si ocurre una excepción y MyApp() no puede arrancar
        runApp(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Ha ocurrido un error al inicializar:\n\n$e',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    },
    (error, stack) {
      debugPrint('Zoned Error no capturado: $error\n$stack');
    },
  );
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
