import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:personal_finance/firebase_options.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import 'package:personal_finance/features/alerts/domain/entities/alert_item.dart';
import 'package:personal_finance/features/data/model/expense.dart';
import 'package:personal_finance/features/data/model/income.dart';
import 'package:personal_finance/features/notifications/domain/entities/notification_item.dart';
import 'package:personal_finance/utils/app.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/core/services/version_service.dart';
import 'package:personal_finance/core/services/notifications/notification_service.dart';
import 'package:personal_finance/utils/offline_sync_service.dart';
import 'package:personal_finance/utils/pending_action.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Core initialization
    final Locale deviceLocale = ui.PlatformDispatcher.instance.locale;
    Intl.defaultLocale = deviceLocale.toLanguageTag();

    await Hive.initFlutter();

    // 2. Register all adapters
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(IncomeAdapter());
    Hive.registerAdapter(AlertItemAdapter());
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PendingActionAdapter());
    }
    Hive.registerAdapter(NotificationItemAdapter());

    // 3. Open ALL boxes required by Providers synchronously to avoid initialization crashes
    // These are required by global providers in app.dart
    await Hive.openBox<Expense>('expenses');
    await Hive.openBox<Income>('incomes');
    await Hive.openBox<AlertItem>('alerts');
    await Hive.openBox<NotificationItem>('notifications_inbox');
    await Hive.openBox<PendingAction>('pending_actions');

    // 4. Firebase Initialization (Must happen before runApp because of AnalyticsObserver)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 5. Dependency Injection
    await initDependencies();

    // 6. Pre-runApp Services
    await getIt<VersionService>().init();

    // 7. Start the app
    runApp(const MyApp());

    // 8. Post-runApp initialization (Services that don't block the UI)
    _initializeBackgroundServices();
  } catch (e) {
    debugPrint('Fatal error in main: $e');
    runApp(const MyApp());
  }
}

Future<void> _initializeBackgroundServices() async {
  try {
    // OfflineSyncService uses 'pending_actions' which is already open now
    await OfflineSyncService().init();

    // Services that depend on Firebase (Already initialized)
    // VersionService initialized in main()
    await getIt<NotificationService>().init();

    debugPrint('Background services initialized successfully');
  } catch (e) {
    debugPrint('Error initializing background services: $e');
  }
}
