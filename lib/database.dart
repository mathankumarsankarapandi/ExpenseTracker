import 'dart:async';
import 'package:daily_expenses/DailyExpensesDao.dart';
import 'package:daily_expenses/DailyExpensesTable.dart';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;


part 'database.g.dart'; // the generated code will be there

@Database(version: 1, entities: [DailyExpensesTable])
abstract class AppDatabase extends FloorDatabase {
  DailyExpensesDao get dailyExpensesDao;
}