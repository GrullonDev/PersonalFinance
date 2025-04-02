import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:personal_finance/features/data/model/expense.dart';
import 'package:personal_finance/features/data/model/income.dart';
import 'package:personal_finance/utils/app.dart';
import 'package:personal_finance/utils/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.deleteFromDisk(); // Esto borrará todos los datos almacenados
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseAdapter());
  await Hive.openBox<Expense>('expenses');

  Hive.registerAdapter(IncomeAdapter());
  await Hive.openBox<Income>('incomes');

  await Firebase.initializeApp();
  await initDependencies();

  await initDependencies();

  runApp(const MyApp());
}
