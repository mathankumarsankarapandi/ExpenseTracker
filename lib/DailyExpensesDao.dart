import 'package:daily_expenses/DailyExpensesTable.dart';
import 'package:floor/floor.dart';

@dao
abstract class DailyExpensesDao {
  @Query('SELECT * FROM DailyExpensesTable ORDER by datetime DESC, reason ASC')
  Future<List<DailyExpensesTable>> getAllExpenses();

  @Query('SELECT * FROM DailyExpensesTable WHERE id = :id ORDER by datetime DESC, reason ASC')
  Future<DailyExpensesTable?> getExpensesByID(int id);

  @Query('SELECT * FROM DailyExpensesTable WHERE date = :date ORDER by datetime DESC, reason ASC')
  Future<List<DailyExpensesTable>> getExpensesByDate(String date);

  @Query('SELECT * FROM DailyExpensesTable WHERE date >= :startDate AND date <= :endDate ORDER by datetime DESC, reason ASC')
  Future<List<DailyExpensesTable>> getExpensesBetweenDay(String startDate, String endDate);

  @insert
  Future<void> insertExpenses(DailyExpensesTable user);

  @insert
  Future<void> insertExpensesList(List<DailyExpensesTable> user);
}