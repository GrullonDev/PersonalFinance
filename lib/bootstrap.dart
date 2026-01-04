import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:personal_finance/firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import 'package:personal_finance/features/alerts/domain/entities/alert_item.dart';
import 'package:personal_finance/features/data/model/expense.dart';
import 'package:personal_finance/features/data/model/income.dart';
import 'package:personal_finance/utils/app.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/utils/offline_sync_service.dart';
import 'package:personal_finance/utils/pending_action.dart';

Future<void> bootstrap({required String env}) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Establece la configuración regional predeterminada según el dispositivo
    try {
      final Locale deviceLocale = ui.PlatformDispatcher.instance.locale;
      Intl.defaultLocale = deviceLocale.toLanguageTag();
    } catch (e) {
      debugPrint('Error setting locale: $e');
    }

    // Inicializa Hive
    try {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(ExpenseAdapter().typeId)) {
        Hive.registerAdapter(ExpenseAdapter());
      }
      await Hive.openBox<Expense>('expenses');

      if (!Hive.isAdapterRegistered(IncomeAdapter().typeId)) {
        Hive.registerAdapter(IncomeAdapter());
      }
      await Hive.openBox<Income>('incomes');

      if (!Hive.isAdapterRegistered(AlertItemAdapter().typeId)) {
        Hive.registerAdapter(AlertItemAdapter());
      }
      await Hive.openBox<AlertItem>('alerts');

      if (!Hive.isAdapterRegistered(PendingActionAdapter().typeId)) {
        Hive.registerAdapter(PendingActionAdapter());
      }

      await OfflineSyncService().init();
    } catch (e) {
      debugPrint('Error initializing Hive: $e');
    }

    // Inicializa Firebase con las opciones generadas por FlutterFire
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
    }

    // Configura dependencias
    try {
      await initDependencies();
    } catch (e) {
      debugPrint('Error initializing dependencies: $e');
    }
  } catch (e) {
    debugPrint('Critical error during bootstrap: $e');
  } finally {
    runApp(const MyApp());
  }
}
