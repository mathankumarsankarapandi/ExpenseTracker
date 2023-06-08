import 'package:daily_expenses/DailyExpenseModel.dart';

class DailyExpenseViewModel{
  final String dateTime;
  final String totalAmount;
  List<DailyExpensesModel> dailyExpenseList;
  DailyExpenseViewModel(this.dateTime, this.totalAmount, this.dailyExpenseList);
}