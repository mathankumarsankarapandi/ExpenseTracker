

import 'package:daily_expenses/database.dart';

class FloorDBViewModel {
  late AppDatabase database;

  static final FloorDBViewModel floorDBViewModel = FloorDBViewModel.privateConstructor();

  FloorDBViewModel.privateConstructor();

  factory FloorDBViewModel(AppDatabase databaseParam) {
    floorDBViewModel.database = databaseParam;
    return floorDBViewModel;
  }
}
