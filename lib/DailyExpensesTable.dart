
import 'package:floor/floor.dart';

@entity
class DailyExpensesTable {
  @PrimaryKey(autoGenerate: true)
  int? id;

  final String dateTime;

  final String date;

  final String city;

  final String reason;

  final String amount;

  DailyExpensesTable(this.dateTime,this.date, this.amount,this.reason, this.city);
}