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

  // Configura dependencias
  await initDependencies();

  runApp(const MyApp());
}
