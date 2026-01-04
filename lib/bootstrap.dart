import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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

    // Inicializa Hive con timeout
    try {
      await Hive.initFlutter().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('Hive init timed out, proceeding anyway');
          return;
        },
      );

      if (!Hive.isAdapterRegistered(ExpenseAdapter().typeId)) {
        Hive.registerAdapter(ExpenseAdapter());
      }
      await Hive.openBox<Expense>('expenses').timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          throw TimeoutException('Hive box open timeout');
        },
      );

      if (!Hive.isAdapterRegistered(IncomeAdapter().typeId)) {
        Hive.registerAdapter(IncomeAdapter());
      }
      await Hive.openBox<Income>('incomes').timeout(const Duration(seconds: 1));

      if (!Hive.isAdapterRegistered(AlertItemAdapter().typeId)) {
        Hive.registerAdapter(AlertItemAdapter());
      }
      await Hive.openBox<AlertItem>(
        'alerts',
      ).timeout(const Duration(seconds: 1));

      if (!Hive.isAdapterRegistered(PendingActionAdapter().typeId)) {
        Hive.registerAdapter(PendingActionAdapter());
      }

      await OfflineSyncService().init().timeout(const Duration(seconds: 1));
    } catch (e) {
      debugPrint('Error initializing Hive: $e');
      // No re-lanzamos para permitir que la app intente arrancar aunque sea sin caché
    }

    // Inicializa Firebase con timeout
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Firebase init timed out');
          throw Exception('Firebase Init Timeout');
        },
      );

      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      ui.PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
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
