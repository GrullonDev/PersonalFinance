import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/core/security/hive_encryption_service.dart';
import 'package:personal_finance/features/alerts/domain/entities/alert_item.dart';
import 'package:personal_finance/features/data/model/expense.dart';
import 'package:personal_finance/features/data/model/income.dart';
import 'package:personal_finance/features/quick_finance/data/models/sync_operation_model.dart';
import 'package:personal_finance/features/quick_finance/data/models/transaction_model.dart';
import 'package:personal_finance/firebase_options.dart';
import 'package:personal_finance/injection_container.dart' as mvp_di;
import 'package:personal_finance/utils/app.dart';
import 'package:personal_finance/utils/injection_container.dart' as old_di;
import 'package:personal_finance/utils/offline_sync_service.dart';
import 'package:personal_finance/utils/pending_action.dart';

Future<void> main() async {
  runZonedGuarded<Future<void>>(
    () async {
      try {
        WidgetsFlutterBinding.ensureInitialized();

        // ── Portrait-only (alineado con Info.plist) ─────────────────────────
        // Hacerlo "fire-and-forget" para no bloquear el arranque si el sistema
        // demora en responder.
        unawaited(
          SystemChrome.setPreferredOrientations(<DeviceOrientation>[
            DeviceOrientation.portraitUp,
          ]),
        );

        // ── Locale e Internacionalización ──────────────────────────────────
        try {
          final Locale deviceLocale = ui.PlatformDispatcher.instance.locale;
          Intl.defaultLocale = deviceLocale.toLanguageTag();
          await initializeDateFormatting(Intl.defaultLocale);
        } catch (locErr) {
          if (kDebugMode) debugPrint('[init] locale error: $locErr');
          await initializeDateFormatting('en_US');
        }

        await Hive.initFlutter();

        // Derive the AES-256 cipher once — all boxes share the same key,
        // stored in iOS Keychain / Android EncryptedSharedPreferences.
        final hiveCipher = await HiveEncryptionService.getCipher();

        // Legacy adapters
        if (!Hive.isAdapterRegistered(ExpenseAdapter().typeId)) {
          Hive.registerAdapter(ExpenseAdapter());
        }
        await HiveEncryptionService.openBoxSafe<Expense>(
          'expenses',
          hiveCipher,
        );

        if (!Hive.isAdapterRegistered(IncomeAdapter().typeId)) {
          Hive.registerAdapter(IncomeAdapter());
        }
        await HiveEncryptionService.openBoxSafe<Income>('incomes', hiveCipher);

        if (!Hive.isAdapterRegistered(AlertItemAdapter().typeId)) {
          Hive.registerAdapter(AlertItemAdapter());
        }
        await HiveEncryptionService.openBoxSafe<AlertItem>(
          'alerts',
          hiveCipher,
        );

        if (!Hive.isAdapterRegistered(0)) {
          Hive.registerAdapter(PendingActionAdapter());
        }
        await OfflineSyncService().init(hiveCipher);

        // MVP (quick_finance) adapters
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

        // ── Firebase + Crashlytics + Analytics ─────────────────────────────
        // Cualquier error aquí se loggea pero NO impide arrancar la UI.
        try {
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
          }

          await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
            !kDebugMode,
          );

          FlutterError.onError = (FlutterErrorDetails details) {
            FlutterError.presentError(details);
            FirebaseCrashlytics.instance.recordFlutterFatalError(details);
          };

          ui.PlatformDispatcher.instance.onError = (
            Object error,
            StackTrace stack,
          ) {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
            return true;
          };

          unawaited(FirebaseAnalytics.instance.logAppOpen());
        } catch (e, st) {
          if (kDebugMode)
            debugPrint('[init] Firebase error (continuing offline): $e\n$st');
        }

        // ── Dependency Injection ───────────────────────────────────────────
        await old_di.initDependencies();
        await mvp_di.init(hiveCipher);

        runApp(const MyApp());
      } catch (e, stackTrace) {
        // En debug: loguear detalles para diagnosticar. En producción: silenciar.
        if (kDebugMode) debugPrint('[init] FATAL: $e\n$stackTrace');

        // UI de fallback genérica — no expone detalles internos en producción.
        // En debug se muestra el error crudo para facilitar el diagnóstico.
        runApp(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: const Color(0xFF0E8F5B),
              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No pudimos iniciar la app',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          kDebugMode
                              ? '$e'
                              : 'Ocurrió un problema inesperado. Por favor reinstala la app o contacta soporte.',
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    },
    (Object error, StackTrace stack) {
      if (kDebugMode) debugPrint('[zoned] $error\n$stack');
      // Best-effort: si Firebase ya está inicializado, reportar.
      try {
        FirebaseCrashlytics.instance
            .recordError(error, stack, fatal: true)
            .ignore();
      } catch (_) {
        /* noop */
      }
    },
  );
}
